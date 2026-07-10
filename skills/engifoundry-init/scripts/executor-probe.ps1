param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("codex-cli", "claude-cli", "gemini-cli", "kimi-cli")]
  [string]$Executor,
  [Parameter(Mandatory = $true)]
  [ValidateSet("codex", "claude", "gemini", "kimi")]
  [string]$Command,
  [string]$Model = ""
)

$ErrorActionPreference = "Stop"

function Emit($Value) {
  $Value | ConvertTo-Json -Compress
}

if ($Model.Length -gt 0 -and $Model -notmatch '^[A-Za-z0-9._:/+@-]+$') {
  Emit ([ordered]@{ status = "invalid"; reason = "invalid-model-id" })
  exit 1
}
if ($null -eq (Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue)) {
  Emit ([ordered]@{ status = "invalid"; reason = "executor-command-unavailable" })
  exit 1
}

$ProbeRoot = Join-Path ([IO.Path]::GetTempPath()) ("engifoundry-executor-probe." + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $ProbeRoot | Out-Null
$Prompt = "Reply with exactly: hello"

try {
  Push-Location $ProbeRoot
  try {
    $arguments = switch ($Executor) {
      "codex-cli" {
        $value = @("exec", "--ephemeral", "--skip-git-repo-check", "--json", "--color", "never", "-C", $ProbeRoot)
        if ($Model.Length -gt 0) { $value += @("--model", $Model) }
        $value + @($Prompt)
      }
      "kimi-cli" {
        $value = @("--prompt", $Prompt, "--output-format", "stream-json")
        if ($Model.Length -gt 0) { $value = @("--model", $Model) + $value }
        $value
      }
      "claude-cli" {
        $value = @("--print", "--output-format", "json")
        if ($Model.Length -gt 0) { $value += @("--model", $Model) }
        $value + @($Prompt)
      }
      "gemini-cli" {
        $value = @("--prompt", $Prompt, "--output-format", "json")
        if ($Model.Length -gt 0) { $value += @("--model", $Model) }
        $value
      }
    }
    $output = (& $Command @arguments 2>&1 | Out-String)
    $probeStatus = $LASTEXITCODE
  }
  finally {
    Pop-Location
  }
}
catch {
  Emit ([ordered]@{ status = "invalid"; reason = "executor-probe-failed" })
  exit 1
}
finally {
  Remove-Item -LiteralPath $ProbeRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($probeStatus -ne 0) {
  Emit ([ordered]@{ status = "invalid"; reason = "executor-probe-failed" })
  exit 1
}
if ($output -notmatch '(?i)hello') {
  Emit ([ordered]@{ status = "invalid"; reason = "executor-probe-invalid-response" })
  exit 1
}

$mode = if ($Model.Length -gt 0) { "pinned" } else { "cli-default" }
Emit ([ordered]@{ status = "passed"; executorId = $Executor; modelMode = $mode })
