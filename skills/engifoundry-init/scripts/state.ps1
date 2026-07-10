param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("status", "advance", "cancel")]
  [string]$Action,
  [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"

function Emit {
  param([Collections.Specialized.OrderedDictionary]$Value)
  $Value | ConvertTo-Json -Compress
}

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
  Emit ([ordered]@{ status = "error"; reason = "invalid-project-root" })
  exit 2
}

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$DataRoot = Join-Path $ProjectRoot ".engifoundry"
$StateFile = Join-Path $DataRoot "initialization.json"
if (-not (Test-Path -LiteralPath $StateFile -PathType Leaf)) {
  Emit ([ordered]@{ status = "error"; reason = "missing-initialization-state" })
  exit 2
}

try {
  $State = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json
}
catch {
  Emit ([ordered]@{ status = "error"; reason = "invalid-initialization-state" })
  exit 2
}

$Steps = @("executor", "workflow")
if ($State.schemaVersion -ne 1 -or $State.status -notin @("in_progress", "complete", "cancelled")) {
  Emit ([ordered]@{ status = "error"; reason = "invalid-initialization-state" })
  exit 2
}
if ($State.status -eq "in_progress" -and $State.currentStep -notin $Steps) {
  Emit ([ordered]@{ status = "error"; reason = "invalid-initialization-state" })
  exit 2
}
if ($State.status -ne "in_progress" -and $null -ne $State.currentStep) {
  Emit ([ordered]@{ status = "error"; reason = "invalid-initialization-state" })
  exit 2
}

function Write-State {
  param([string]$Status, $CurrentStep, [string[]]$CompletedSteps)
  $value = [ordered]@{
    schemaVersion = 1
    status = $Status
    currentStep = $CurrentStep
    completedSteps = $CompletedSteps
  }
  $json = $value | ConvertTo-Json
  $temporary = Join-Path $DataRoot (".initialization.json.tmp." + [guid]::NewGuid().ToString("N"))
  try {
    [IO.File]::WriteAllText($temporary, "$json$([Environment]::NewLine)", [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $StateFile -Force
  }
  finally {
    Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
  }
  Get-Content -LiteralPath $StateFile -Raw
}

function Test-Configured {
  param([string]$Name)
  $path = Join-Path $DataRoot "$Name.json"
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
  try {
    return [bool]((Get-Content -LiteralPath $path -Raw | ConvertFrom-Json).configured)
  }
  catch {
    return $false
  }
}

function Test-FinalState {
  foreach ($name in @("executors", "workflows")) {
    if (-not (Test-Configured $name)) { return $false }
  }
  foreach ($path in @(
    (Join-Path $ProjectRoot "engifoundry.config.json"),
    (Join-Path $DataRoot "workspace.md"),
    (Join-Path $DataRoot "initialization.json"),
    (Join-Path $DataRoot "artifacts/plans"),
    (Join-Path $DataRoot "artifacts/records"),
    (Join-Path $DataRoot "artifacts/reviews"),
    (Join-Path $DataRoot "artifacts/verification"),
    (Join-Path $DataRoot "artifacts/delivery"),
    (Join-Path $DataRoot "packages")
  )) {
    if (-not (Test-Path -LiteralPath $path)) { return $false }
  }
  $gitignore = Join-Path $ProjectRoot ".gitignore"
  return (Test-Path -LiteralPath $gitignore -PathType Leaf) -and ((Get-Content -LiteralPath $gitignore) -contains ".engifoundry/packages/")
}

if ($Action -eq "status") {
  Get-Content -LiteralPath $StateFile -Raw
  exit 0
}
if ($State.status -ne "in_progress") {
  Emit ([ordered]@{ status = "invalid"; reason = "terminal-state"; state = $State.status })
  exit 1
}
$index = [array]::IndexOf($Steps, [string]$State.currentStep)
if ($Action -eq "cancel") {
  $completed = if ($index -eq 0) { @() } else { @($Steps[0..($index - 1)]) }
  Write-State -Status "cancelled" -CurrentStep $null -CompletedSteps $completed
  exit 0
}

if ($State.currentStep -eq "workflow") {
  if (-not (Test-Configured "workflows")) {
    Emit ([ordered]@{ status = "invalid"; reason = "workflow-not-configured" })
    exit 1
  }
  if (-not (Test-FinalState)) {
    Emit ([ordered]@{ status = "invalid"; reason = "final-validation-failed" })
    exit 1
  }
  Write-State -Status "complete" -CurrentStep $null -CompletedSteps @("executor", "workflow")
  exit 0
}
$configNames = @("executors")
if (-not (Test-Configured $configNames[$index])) {
  Emit ([ordered]@{ status = "invalid"; reason = "$($State.currentStep)-not-configured" })
  exit 1
}

Write-State -Status "in_progress" -CurrentStep $Steps[$index + 1] -CompletedSteps $Steps[0..$index]
