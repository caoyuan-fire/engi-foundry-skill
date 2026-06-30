param(
  [ValidateSet("empty", "filled")]
  [string]$Mode = "filled",
  [string]$ProjectRoot = ".",
  [string]$ArtifactRoot = ".engifoundry",
  [string]$PackageRoot = ".engifoundry-packages",
  [string]$RecordsPolicy = "durable",
  [string]$DefaultPackagePolicy = "package-when-risky",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

if ($Mode -eq "empty") {
  $ArtifactRoot = ""
  $PackageRoot = ""
  $RecordsPolicy = ""
  $DefaultPackagePolicy = ""
}

$configPath = Join-Path $ProjectRoot ".engifoundry.config.json"
if ((Test-Path $configPath) -and -not $Force) {
  throw "$configPath already exists; pass -Force to overwrite"
}

New-Item -ItemType Directory -Force -Path $ProjectRoot | Out-Null
$config = [ordered]@{
  schemaVersion = 1
  artifactRoot = $ArtifactRoot
  packageRoot = $PackageRoot
  recordsPolicy = $RecordsPolicy
  defaultPackagePolicy = $DefaultPackagePolicy
}
$config | ConvertTo-Json -Depth 4 | Set-Content -Path $configPath -Encoding UTF8
Write-Output $configPath
