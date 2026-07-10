param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("init", "check")]
  [string]$Command,
  [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"

function Write-Stderr {
  param([string]$Message)
  [Console]::Error.WriteLine($Message)
}

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
  Write-Output "status: blocked"
  Write-Stderr "project root is not a directory: $ProjectRoot"
  exit 1
}

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$SkillRoot = Split-Path -Parent $PSScriptRoot
$WorkspaceTemplate = Join-Path $SkillRoot "references/workspace.md"
$TemplateRoot = Join-Path $SkillRoot "references/templates"
$RootConfig = Join-Path $ProjectRoot "engifoundry.config.json"
$DataRoot = Join-Path $ProjectRoot ".engifoundry"
$GitIgnore = Join-Path $ProjectRoot ".gitignore"
$GitIgnoreRule = ".engifoundry/packages/"

function Test-Scaffold {
  param([string]$Root)

  $data = Join-Path $Root ".engifoundry"
  $errors = @()
  $directories = @(
    $data,
    (Join-Path $data "artifacts/plans"),
    (Join-Path $data "artifacts/records"),
    (Join-Path $data "artifacts/reviews"),
    (Join-Path $data "artifacts/verification"),
    (Join-Path $data "artifacts/delivery"),
    (Join-Path $data "packages")
  )
  $files = @(
    (Join-Path $Root "engifoundry.config.json"),
    (Join-Path $data "workspace.md"),
    (Join-Path $data "initialization.json"),
    (Join-Path $data "executors.json"),
    (Join-Path $data "workflows.json")
  )

  foreach ($directory in $directories) {
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
      $errors += "missing directory: $directory"
    }
  }
  foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
      $errors += "missing or empty file: $file"
      continue
    }
    if ((Get-Item -LiteralPath $file).Length -eq 0) {
      $errors += "missing or empty file: $file"
    }
  }
  $gitignore = Join-Path $Root ".gitignore"
  if (-not (Test-Path -LiteralPath $gitignore -PathType Leaf) -or -not ((Get-Content -LiteralPath $gitignore) -contains $GitIgnoreRule)) {
    $errors += "missing .gitignore rule: $GitIgnoreRule"
  }
  return $errors
}

if ($Command -eq "check") {
  $errors = @(Test-Scaffold -Root $ProjectRoot)
  if ($errors.Count -eq 0) {
    Write-Output "status: ok"
    exit 0
  }
  Write-Output "status: failed"
  $errors | ForEach-Object { Write-Stderr $_ }
  exit 1
}

$collisions = @($RootConfig, $DataRoot) | Where-Object { Test-Path -LiteralPath $_ }
if ($collisions.Count -gt 0) {
  Write-Output "status: blocked"
  $collisions | ForEach-Object { Write-Stderr "path already exists: $_" }
  exit 1
}

$templates = @(
  $WorkspaceTemplate,
  (Join-Path $TemplateRoot "engifoundry.config.json"),
  (Join-Path $TemplateRoot "initialization.json"),
  (Join-Path $TemplateRoot "executors.json"),
  (Join-Path $TemplateRoot "workflows.json")
)
foreach ($template in $templates) {
  if (-not (Test-Path -LiteralPath $template -PathType Leaf) -or (Get-Item -LiteralPath $template).Length -eq 0) {
    Write-Output "status: failed"
    Write-Stderr "missing or empty template: $template"
    exit 1
  }
}

$Staging = Join-Path $ProjectRoot (".engifoundry-init." + [guid]::NewGuid().ToString("N"))
$InstalledData = $false
$InstalledRoot = $false
$GitIgnoreChanged = $false
$GitIgnoreExisted = $false
$Committed = $false
$RootTemporary = Join-Path $ProjectRoot (".engifoundry.config.json.tmp." + [guid]::NewGuid().ToString("N"))

try {
  $StagingData = Join-Path $Staging ".engifoundry"
  @(
    "artifacts/plans",
    "artifacts/records",
    "artifacts/reviews",
    "artifacts/verification",
    "artifacts/delivery",
    "packages"
  ) | ForEach-Object {
    New-Item -ItemType Directory -Force -Path (Join-Path $StagingData $_) | Out-Null
  }

  Copy-Item -LiteralPath $WorkspaceTemplate -Destination (Join-Path $StagingData "workspace.md")
  Copy-Item -LiteralPath (Join-Path $TemplateRoot "initialization.json") -Destination (Join-Path $StagingData "initialization.json")
  Copy-Item -LiteralPath (Join-Path $TemplateRoot "executors.json") -Destination (Join-Path $StagingData "executors.json")
  Copy-Item -LiteralPath (Join-Path $TemplateRoot "workflows.json") -Destination (Join-Path $StagingData "workflows.json")
  Copy-Item -LiteralPath (Join-Path $TemplateRoot "engifoundry.config.json") -Destination (Join-Path $Staging "engifoundry.config.json")
  [IO.File]::WriteAllText((Join-Path $Staging ".gitignore"), "$GitIgnoreRule$([Environment]::NewLine)", [Text.UTF8Encoding]::new($false))

  $errors = @(Test-Scaffold -Root $Staging)
  if ($errors.Count -gt 0) {
    Write-Output "status: failed"
    $errors | ForEach-Object { Write-Stderr $_ }
    exit 1
  }

  Move-Item -LiteralPath $StagingData -Destination $DataRoot
  $InstalledData = $true

  if (-not (Test-Path -LiteralPath $GitIgnore -PathType Leaf) -or -not ((Get-Content -LiteralPath $GitIgnore) -contains $GitIgnoreRule)) {
    if (Test-Path -LiteralPath $GitIgnore) {
      $GitIgnoreExisted = $true
      Copy-Item -LiteralPath $GitIgnore -Destination (Join-Path $Staging "gitignore.backup")
      $content = [IO.File]::ReadAllText($GitIgnore)
    }
    else {
      $content = ""
    }
    $separator = if ($content.Length -eq 0 -or $content.EndsWith("`n") -or $content.EndsWith("`r")) { "" } else { [Environment]::NewLine }
    [IO.File]::AppendAllText($GitIgnore, "$separator$GitIgnoreRule$([Environment]::NewLine)", [Text.UTF8Encoding]::new($false))
    $GitIgnoreChanged = $true
  }

  Copy-Item -LiteralPath (Join-Path $TemplateRoot "engifoundry.config.json") -Destination $RootTemporary
  Move-Item -LiteralPath $RootTemporary -Destination $RootConfig
  $InstalledRoot = $true

  $errors = @(Test-Scaffold -Root $ProjectRoot)
  if ($errors.Count -gt 0) {
    Write-Output "status: failed"
    $errors | ForEach-Object { Write-Stderr $_ }
    exit 1
  }

  $Committed = $true
  Write-Output "status: ok"
  exit 0
}
catch {
  if ($InstalledData -and -not (Test-Path -LiteralPath $RootConfig)) {
    Remove-Item -LiteralPath $DataRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
  Write-Output "status: failed"
  Write-Stderr $_
  exit 1
}
finally {
  if (-not $Committed -and $GitIgnoreChanged) {
    if ($GitIgnoreExisted) {
      Copy-Item -LiteralPath (Join-Path $Staging "gitignore.backup") -Destination $GitIgnore -Force
    }
    else {
      Remove-Item -LiteralPath $GitIgnore -Force -ErrorAction SilentlyContinue
    }
  }
  if (-not $Committed -and $InstalledRoot) {
    Remove-Item -LiteralPath $RootConfig -Force -ErrorAction SilentlyContinue
  }
  if (-not $Committed -and $InstalledData) {
    Remove-Item -LiteralPath $DataRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
  Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $RootTemporary -Force -ErrorAction SilentlyContinue
}
