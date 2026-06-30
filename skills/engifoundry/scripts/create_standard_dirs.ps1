param(
  [string]$ProjectRoot = ".",
  [string]$ArtifactRoot = "",
  [string]$PackageRoot = ""
)

$ErrorActionPreference = "Stop"

$configPath = Join-Path $ProjectRoot ".engifoundry.config.json"
if (Test-Path $configPath) {
  $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
  if ([string]::IsNullOrWhiteSpace($ArtifactRoot)) {
    $ArtifactRoot = $config.artifactRoot
  }
  if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $PackageRoot = $config.packageRoot
  }
}

if ([string]::IsNullOrWhiteSpace($ArtifactRoot)) {
  $ArtifactRoot = ".engifoundry"
}
if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
  $PackageRoot = ".engifoundry-packages"
}

$directories = @(
  "$ArtifactRoot/roadmaps/archive",
  "$ArtifactRoot/records/ad-hoc",
  "$ArtifactRoot/records/packages",
  "$ArtifactRoot/records/reviews",
  "$ArtifactRoot/records/audits",
  "$ArtifactRoot/docs/generated",
  "$ArtifactRoot/docs/integration",
  "$ArtifactRoot/docs/design",
  "$ArtifactRoot/docs/reference",
  "$ArtifactRoot/docs/archive",
  "$PackageRoot"
)

foreach ($directory in $directories) {
  New-Item -ItemType Directory -Force -Path (Join-Path $ProjectRoot $directory) | Out-Null
}

Write-Output (Join-Path $ProjectRoot $ArtifactRoot)
Write-Output (Join-Path $ProjectRoot $PackageRoot)
