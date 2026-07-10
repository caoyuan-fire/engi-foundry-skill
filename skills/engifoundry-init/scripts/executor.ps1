param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("begin", "status", "select", "prefer", "commit", "cancel")]
  [string]$Action,
  [string]$ProjectRoot = ".",
  [switch]$NativeSubagent,
  [AllowEmptyString()]
  [string]$UserInput = ""
)

$ErrorActionPreference = "Stop"

function Emit($Value) {
  $Value | ConvertTo-Json -Compress -Depth 8
}

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
  Emit ([ordered]@{ status = "error"; reason = "invalid-project-root" })
  exit 2
}

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$DataRoot = Join-Path $ProjectRoot ".engifoundry"
$ConfigFile = Join-Path $DataRoot "executors.json"
$SetupRoot = Join-Path $DataRoot ".executor-setup"
$SetupFile = Join-Path $SetupRoot "state.json"
$Verifier = Join-Path $PSScriptRoot "verify.ps1"
$PowerShellExecutable = (Get-Process -Id $PID).Path

if (-not (Test-Path -LiteralPath $DataRoot -PathType Container) -or -not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) {
  Emit ([ordered]@{ status = "error"; reason = "missing-executor-config" })
  exit 2
}

function Read-State {
  if (-not (Test-Path -LiteralPath $SetupFile -PathType Leaf)) { return $null }
  try { return Get-Content -LiteralPath $SetupFile -Raw | ConvertFrom-Json }
  catch {
    Emit ([ordered]@{ status = "error"; reason = "invalid-executor-setup" })
    exit 2
  }
}

function Write-State($State) {
  New-Item -ItemType Directory -Force -Path $SetupRoot | Out-Null
  $temporary = Join-Path $DataRoot (".executor-state.tmp." + [guid]::NewGuid().ToString("N"))
  try {
    $json = $State | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($temporary, "$json$([Environment]::NewLine)", [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $SetupFile -Force
  }
  finally {
    Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
  }
}

function State-Output($State) {
  if ($null -eq $State) { return [ordered]@{ status = "idle" } }
  if ($State.phase -eq "select") {
    return [ordered]@{ status = "in_progress"; phase = "select"; selection = "multiple"; options = @($State.candidates) }
  }
  if ($State.phase -eq "prefer") {
    return [ordered]@{
      status = "in_progress"
      phase = "prefer"
      selection = "single"
      selectedExecutors = @($State.selected | ForEach-Object { $_.executorId })
      options = @($State.selected)
    }
  }
  if ($State.phase -eq "ready") {
    return [ordered]@{ status = "ready"; executorOrder = @($State.order | ForEach-Object { $_.executorId }) }
  }
  Emit ([ordered]@{ status = "error"; reason = "invalid-executor-setup" })
  exit 2
}

if ($Action -eq "begin") {
  $existing = Read-State
  if ($null -ne $existing) {
    Emit (State-Output $existing)
    exit 0
  }
  $candidates = [Collections.Generic.List[object]]::new()
  if ($NativeSubagent.IsPresent) {
    $candidates.Add([ordered]@{ optionId = $candidates.Count + 1; executorId = "native-subagent"; kind = "host-subagent" })
  }
  foreach ($item in @(
    @("codex-cli", "codex"),
    @("claude-cli", "claude"),
    @("gemini-cli", "gemini"),
    @("kimi-cli", "kimi")
  )) {
    if ($null -ne (Get-Command $item[1] -CommandType Application -ErrorAction SilentlyContinue)) {
      $candidates.Add([ordered]@{ optionId = $candidates.Count + 1; executorId = $item[0]; kind = "cli"; command = $item[1] })
    }
  }
  $candidates.Add([ordered]@{ optionId = $candidates.Count + 1; executorId = "direct"; kind = "current-session" })
  $state = [ordered]@{
    phase = "select"
    candidates = @($candidates)
    selected = @()
    order = @()
  }
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
  Emit ([ordered]@{ status = "invalid"; reason = "executor-setup-not-started" })
  exit 1
}

if ($Action -eq "select") {
  if ($state.phase -ne "select") {
    Emit ([ordered]@{ status = "invalid"; reason = "wrong-executor-phase" })
    exit 1
  }
  $source = (1..@($state.candidates).Count) -join ','
  $raw = & $PowerShellExecutable -NoProfile -ExecutionPolicy Bypass -File $Verifier -Source $source -Selection multiple -UserInput $UserInput
  if ($LASTEXITCODE -ne 0) { Write-Output $raw; exit $LASTEXITCODE }
  $ids = @(($raw | ConvertFrom-Json).selectedIds)
  $state.selected = @($ids | ForEach-Object {
    $selectedId = $_
    $state.candidates | Where-Object { $_.optionId -eq $selectedId } | Select-Object -First 1
  })
  for ($index = 0; $index -lt $state.selected.Count; $index++) { $state.selected[$index].optionId = $index + 1 }
  if ($state.selected.Count -eq 1) {
    $state.order = @($state.selected)
    $state.phase = "ready"
  }
  else { $state.phase = "prefer" }
  Write-State $state
  Emit (State-Output $state)
  exit 0
}

if ($Action -eq "prefer") {
  if ($state.phase -ne "prefer") {
    Emit ([ordered]@{ status = "invalid"; reason = "wrong-executor-phase" })
    exit 1
  }
  $source = (1..@($state.selected).Count) -join ','
  $raw = & $PowerShellExecutable -NoProfile -ExecutionPolicy Bypass -File $Verifier -Source $source -Selection single -UserInput $UserInput
  if ($LASTEXITCODE -ne 0) { Write-Output $raw; exit $LASTEXITCODE }
  $preferred = [int](($raw | ConvertFrom-Json).selectedIds[0])
  $state.order = @($state.selected[$preferred - 1]) + @($state.selected | Where-Object { $_.optionId -ne $preferred })
  $state.phase = "ready"
  Write-State $state
  Emit (State-Output $state)
  exit 0
}

if ($Action -eq "commit") {
  if ($state.phase -ne "ready") {
    Emit ([ordered]@{ status = "invalid"; reason = "wrong-executor-phase" })
    exit 1
  }
  $executors = [ordered]@{}
  foreach ($executor in $state.selected) {
    $entry = [ordered]@{ kind = $executor.kind }
    if ($null -ne $executor.command) {
      $entry.command = $executor.command
    }
    $executors[$executor.executorId] = $entry
  }
  $value = [ordered]@{
    schemaVersion = 1
    configured = $true
    executorOrder = @($state.order | ForEach-Object { $_.executorId })
    executors = $executors
  }
  $temporary = Join-Path $DataRoot (".executors.json.tmp." + [guid]::NewGuid().ToString("N"))
  try {
    $json = $value | ConvertTo-Json -Depth 8
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
