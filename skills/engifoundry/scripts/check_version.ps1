param(
  [string]$LocalVersionFile = "",
  [string]$RemoteVersionUrl = "https://raw.githubusercontent.com/caoyuan-fire/engi-foundry-skill/main/skills/engifoundry/VERSION"
)

$ErrorActionPreference = "SilentlyContinue"

if ([string]::IsNullOrWhiteSpace($LocalVersionFile)) {
  $LocalVersionFile = Join-Path $PSScriptRoot "..\VERSION"
}

if (-not (Test-Path $LocalVersionFile)) {
  exit 0
}

$localVersion = (Get-Content -Path $LocalVersionFile -TotalCount 1).Trim()
if ([string]::IsNullOrWhiteSpace($localVersion)) {
  exit 0
}

try {
  if ($RemoteVersionUrl.StartsWith("file://")) {
    $remotePath = $RemoteVersionUrl.Substring(7)
    if (-not (Test-Path $remotePath)) {
      exit 0
    }
    $remoteVersion = (Get-Content -Path $remotePath -TotalCount 1).Trim()
  } else {
    $remoteVersion = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 -Uri $RemoteVersionUrl).Content.Trim().Split("`n")[0].Trim()
  }
} catch {
  exit 0
}

if ([string]::IsNullOrWhiteSpace($remoteVersion)) {
  exit 0
}

try {
  $local = [version]$localVersion
  $remote = [version]$remoteVersion
  if ($remote -gt $local) {
    Write-Output "EngiFoundry update available: local $localVersion, latest $remoteVersion"
  }
} catch {
  exit 0
}

exit 0
