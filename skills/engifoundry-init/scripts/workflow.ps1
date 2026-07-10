param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("begin", "status", "select", "commit", "cancel")]
  [string]$Action,
  [string]$ProjectRoot = ".",
  [AllowEmptyString()]
  [string]$UserInput = ""
)

$ErrorActionPreference = "Stop"

function Emit($Value) {
  $Value | ConvertTo-Json -Compress -Depth 6
}

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
  Emit ([ordered]@{ status = "error"; reason = "invalid-project-root" })
  exit 2
}

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$DataRoot = Join-Path $ProjectRoot ".engifoundry"
$ConfigFile = Join-Path $DataRoot "workflows.json"
$SetupRoot = Join-Path $DataRoot ".workflow-setup"
$SetupFile = Join-Path $SetupRoot "state.json"
$Verifier = Join-Path $PSScriptRoot "verify.ps1"
$PowerShellExecutable = (Get-Process -Id $PID).Path
$AutomationOptions = @(
  [ordered]@{ optionId = 1; automationMode = "job-approval" },
  [ordered]@{ optionId = 2; automationMode = "package-approval"; recommended = $true },
  [ordered]@{ optionId = 3; automationMode = "full-auto" }
)
$ActionOptions = @(
  [ordered]@{ optionId = 1; actionPreference = "package-first" },
  [ordered]@{ optionId = 2; actionPreference = "balanced"; recommended = $true },
  [ordered]@{ optionId = 3; actionPreference = "direct-first" }
)

if (-not (Test-Path -LiteralPath $DataRoot -PathType Container) -or -not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) {
  Emit ([ordered]@{ status = "error"; reason = "missing-workflow-config" })
  exit 2
}

function Read-State {
  if (-not (Test-Path -LiteralPath $SetupFile -PathType Leaf)) { return $null }
  try { return Get-Content -LiteralPath $SetupFile -Raw | ConvertFrom-Json }
  catch {
    Emit ([ordered]@{ status = "error"; reason = "invalid-workflow-setup" })
    exit 2
  }
}

function Write-State($State) {
  New-Item -ItemType Directory -Force -Path $SetupRoot | Out-Null
  $temporary = Join-Path $DataRoot (".workflow-state.tmp." + [guid]::NewGuid().ToString("N"))
  try {
    $json = $State | ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText($temporary, "$json$([Environment]::NewLine)", [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $SetupFile -Force
  }
  finally {
    Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
  }
}

function State-Output($State) {
  if ($null -eq $State) { return [ordered]@{ status = "idle" } }
  if ($State.phase -eq "automation") {
    return [ordered]@{ status = "in_progress"; phase = "automation"; selection = "single"; options = $AutomationOptions }
  }
  if ($State.phase -eq "action-preference") {
    return [ordered]@{
      status = "in_progress"
      phase = "action-preference"
      selection = "single"
      automationMode = $State.automationMode
      options = $ActionOptions
    }
  }
  if ($State.phase -eq "ready") {
    return [ordered]@{
      status = "ready"
      automationMode = $State.automationMode
      actionPreference = $State.actionPreference
    }
  }
  Emit ([ordered]@{ status = "error"; reason = "invalid-workflow-setup" })
  exit 2
}

if ($Action -eq "begin") {
  $existing = Read-State
  if ($null -ne $existing) {
    Emit (State-Output $existing)
    exit 0
  }
  $state = [ordered]@{ phase = "automation"; automationMode = $null; actionPreference = $null }
  Remove-Item -LiteralPath $SetupRoot -Recurse -Force -ErrorAction SilentlyContinue
  Write-State $state
  Emit (State-Output $state)
  exit 0
}

$state = Read-State
if ($Action -eq "status") {
  Emit (State-Output $state)
  exit 0
}
if ($Action -eq "cancel") {
  Remove-Item -LiteralPath $SetupRoot -Recurse -Force -ErrorAction SilentlyContinue
  Emit ([ordered]@{ status = "cancelled" })
  exit 0
}
if ($null -eq $state) {
  Emit ([ordered]@{ status = "invalid"; reason = "workflow-setup-not-started" })
  exit 1
}

if ($Action -eq "select") {
  if ($state.phase -notin @("automation", "action-preference")) {
    Emit ([ordered]@{ status = "invalid"; reason = "wrong-workflow-phase" })
    exit 1
  }
  $raw = & $PowerShellExecutable -NoProfile -ExecutionPolicy Bypass -File $Verifier -Source 1,2,3 -Selection single -UserInput $UserInput
  if ($LASTEXITCODE -ne 0) { Write-Output $raw; exit $LASTEXITCODE }
  $selected = [int](($raw | ConvertFrom-Json).selectedIds[0])
  if ($state.phase -eq "automation") {
    $state.automationMode = @("job-approval", "package-approval", "full-auto")[$selected - 1]
    $state.phase = "action-preference"
  }
  else {
    $state.actionPreference = @("package-first", "balanced", "direct-first")[$selected - 1]
    $state.phase = "ready"
  }
  Write-State $state
  Emit (State-Output $state)
  exit 0
}

if ($Action -eq "commit") {
  if (
    $state.phase -ne "ready" -or
    $state.automationMode -notin @("job-approval", "package-approval", "full-auto") -or
    $state.actionPreference -notin @("package-first", "balanced", "direct-first")
  ) {
    Emit ([ordered]@{ status = "invalid"; reason = "wrong-workflow-phase" })
    exit 1
  }
  $value = [ordered]@{
    schemaVersion = 1
    configured = $true
    actionPreference = $state.actionPreference
    automationMode = $state.automationMode
  }
  $temporary = Join-Path $DataRoot (".workflows.json.tmp." + [guid]::NewGuid().ToString("N"))
  try {
    $json = $value | ConvertTo-Json
    [IO.File]::WriteAllText($temporary, "$json$([Environment]::NewLine)", [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $ConfigFile -Force
  }
  finally {
    Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
  }
  Remove-Item -LiteralPath $SetupRoot -Recurse -Force
  Get-Content -LiteralPath $ConfigFile -Raw
  exit 0
}

Emit ([ordered]@{ status = "error"; reason = "unsupported-action" })
exit 2
