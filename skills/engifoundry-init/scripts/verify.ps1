param(
  [Parameter(Mandatory = $true)]
  [string]$Source,
  [Parameter(Mandatory = $true)]
  [ValidateSet("single", "multiple")]
  [string]$Selection,
  [Parameter(Mandatory = $true)]
  [AllowEmptyString()]
  [string]$UserInput
)

$ErrorActionPreference = "Stop"

function Write-Result {
  param([Collections.Specialized.OrderedDictionary]$Value)
  $Value | ConvertTo-Json -Compress
}

function Normalize-Input {
  param([string]$Value)
  $fullwidthComma = [string][char]0xFF0C
  return [regex]::Replace($Value.Replace($fullwidthComma, ",").Trim(), "\s*,\s*", ",")
}

function Parse-Ids {
  param([string]$Value)
  $ids = @()
  foreach ($part in $Value.Split(',')) {
    $number = 0L
    if (-not [long]::TryParse($part, [Globalization.NumberStyles]::None, [Globalization.CultureInfo]::InvariantCulture, [ref]$number)) {
      return $null
    }
    $ids += $number
  }
  return $ids
}

$sourceNormalized = Normalize-Input $Source
if ($sourceNormalized -notmatch '^[0-9]+(,[0-9]+)*$') {
  Write-Result ([ordered]@{ status = "error"; reason = "invalid-source" })
  exit 2
}
$allowedIds = @(Parse-Ids $sourceNormalized)
if (($allowedIds | Select-Object -Unique).Count -ne $allowedIds.Count) {
  Write-Result ([ordered]@{ status = "error"; reason = "duplicate-source-option" })
  exit 2
}
for ($index = 0; $index -lt $allowedIds.Count; $index++) {
  if ($allowedIds[$index] -ne ($index + 1)) {
    Write-Result ([ordered]@{ status = "error"; reason = "invalid-source-sequence" })
    exit 2
  }
}

$normalized = Normalize-Input $UserInput
if ($normalized.Length -eq 0) {
  Write-Result ([ordered]@{ status = "invalid"; reason = "empty-input"; allowedIds = $allowedIds })
  exit 1
}
if ($normalized -notmatch '^[0-9]+(,[0-9]+)*$') {
  Write-Result ([ordered]@{ status = "invalid"; reason = "invalid-format"; allowedIds = $allowedIds })
  exit 1
}
$selectedIds = @(Parse-Ids $normalized)
if ($Selection -eq "single" -and $selectedIds.Count -ne 1) {
  Write-Result ([ordered]@{ status = "invalid"; reason = "multiple-not-allowed"; allowedIds = $allowedIds })
  exit 1
}
if (($selectedIds | Select-Object -Unique).Count -ne $selectedIds.Count) {
  Write-Result ([ordered]@{ status = "invalid"; reason = "duplicate-option"; allowedIds = $allowedIds })
  exit 1
}
$invalidIds = @($selectedIds | Where-Object { $_ -notin $allowedIds })
if ($invalidIds.Count -gt 0) {
  Write-Result ([ordered]@{ status = "invalid"; reason = "unknown-option"; invalidIds = $invalidIds; allowedIds = $allowedIds })
  exit 1
}

Write-Result ([ordered]@{
  status = "valid"
  selection = $Selection
  normalizedInput = ($selectedIds -join ',')
  selectedIds = $selectedIds
})
