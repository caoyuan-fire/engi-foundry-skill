param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("create-phase", "create-package", "check")]
  [string]$Action,
  [string]$ProjectRoot = ".",
  [ValidateSet("mainline", "extension")]
  [string]$Kind = "mainline",
  [string]$BasePhaseId = "",
  [string]$PhaseId = "",
  [string]$PackageId = "",
  [int]$JobCount = 0,
  [string]$Title = "Task goal"
)

$ErrorActionPreference = "Stop"

function Emit($Value) {
  $Value | ConvertTo-Json -Compress -Depth 10
}

function Write-Json([string]$Path, $Value) {
  $temporary = "$Path.tmp.$([guid]::NewGuid().ToString('N'))"
  try {
    $json = $Value | ConvertTo-Json -Depth 12
    [IO.File]::WriteAllText($temporary, "$json$([Environment]::NewLine)", [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $Path -Force
  }
  finally {
    Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
  }
}

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
  Emit ([ordered]@{ status = "error"; reason = "invalid-project-root" })
  exit 2
}
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$RootConfigPath = Join-Path $ProjectRoot "engifoundry.config.json"
if (-not (Test-Path -LiteralPath $RootConfigPath -PathType Leaf)) {
  Emit ([ordered]@{ status = "error"; reason = "missing-root-config" })
  exit 2
}
try { $RootConfig = Get-Content -LiteralPath $RootConfigPath -Raw | ConvertFrom-Json }
catch {
  Emit ([ordered]@{ status = "error"; reason = "invalid-root-config" })
  exit 2
}

$PackageRelative = [string]$RootConfig.packageRoot
if (
  [string]::IsNullOrWhiteSpace($PackageRelative) -or
  [IO.Path]::IsPathRooted($PackageRelative) -or
  $PackageRelative.Split('/\') -contains ".."
) {
  Emit ([ordered]@{ status = "error"; reason = "invalid-package-root" })
  exit 2
}
$PackageRoot = Join-Path $ProjectRoot $PackageRelative
New-Item -ItemType Directory -Force -Path $PackageRoot | Out-Null

function Read-Json([string]$Path) {
  try { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
  catch {
    Emit ([ordered]@{ status = "error"; reason = "invalid-json"; path = $Path })
    exit 2
  }
}

function Next-Number([string]$Parent, [string]$Regex, [int]$Group = 1) {
  $max = 0
  if (Test-Path -LiteralPath $Parent -PathType Container) {
    foreach ($directory in Get-ChildItem -LiteralPath $Parent -Directory) {
      if ($directory.Name -match $Regex) {
        $value = [int]$Matches[$Group]
        if ($value -gt $max) { $max = $value }
      }
    }
  }
  return $max + 1
}

function Rebuild-PhaseIndex {
  $phases = [ordered]@{}
  $mainline = @()
  $latestAvailable = $null
  $latestClosed = $null
  foreach ($directory in @(Get-ChildItem -LiteralPath $PackageRoot -Directory -Filter "PHASE-*" | Sort-Object Name)) {
    $configPath = Join-Path $directory.FullName "phase.config.json"
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { continue }
    $config = Read-Json $configPath
    $phases[[string]$config.phaseId] = [ordered]@{
      kind = [string]$config.kind
      status = [string]$config.status
      basePhaseId = $config.basePhaseId
    }
    if ($config.kind -eq "mainline") { $mainline += [string]$config.phaseId }
    if ($config.status -eq "available") { $latestAvailable = [string]$config.phaseId }
    if ($config.status -eq "closed") { $latestClosed = [string]$config.phaseId }
  }
  $next = Next-Number $PackageRoot '^PHASE-(\d{3})$'
  Write-Json (Join-Path $PackageRoot "phase.index.json") ([ordered]@{
    schemaVersion = 1
    mainlineOrder = $mainline
    phases = $phases
    latestAvailablePhase = $latestAvailable
    latestClosedPhase = $latestClosed
    nextMainlinePhaseId = "PHASE-$($next.ToString('D3'))"
  })
}

function Rebuild-PhasePackages([string]$PhaseDirectory) {
  $path = Join-Path $PhaseDirectory "phase.config.json"
  $config = Read-Json $path
  $config.packages = @(
    Get-ChildItem -LiteralPath $PhaseDirectory -Directory -Filter "PAK-*" |
      Sort-Object Name |
      ForEach-Object { $_.Name }
  )
  Write-Json $path $config
}

function Package-Directory {
  return Join-Path (Join-Path $PackageRoot $PhaseId) $PackageId
}

function Test-Package {
  $directory = Package-Directory
  $errors = [Collections.Generic.List[string]]::new()
  foreach ($file in @("summary.md", "package.config.json")) {
    $path = Join-Path $directory $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -eq 0) {
      $errors.Add("missing-$file")
    }
  }
  $summaryPath = Join-Path $directory "summary.md"
  if (Test-Path -LiteralPath $summaryPath -PathType Leaf) {
    if ((Get-Content -LiteralPath $summaryPath -Raw) -match 'TODO') { $errors.Add("incomplete-summary") }
  }
  $jobsRoot = Join-Path $directory "jobs"
  if (-not (Test-Path -LiteralPath $jobsRoot -PathType Container)) { $errors.Add("missing-jobs") }
  if (Test-Path -LiteralPath (Join-Path $directory "package.config.json") -PathType Leaf) {
    $package = Read-Json (Join-Path $directory "package.config.json")
    if ($package.phaseId -ne $PhaseId) { $errors.Add("phase-mismatch") }
    if ($package.packageId -ne $PackageId) { $errors.Add("package-mismatch") }
    foreach ($field in @("acceptanceCriteria", "requiredArtifacts", "closeoutRequirements")) {
      if (@($package.$field).Count -eq 0) { $errors.Add("empty-$field") }
    }
  }
  $jobs = if (Test-Path -LiteralPath $jobsRoot -PathType Container) {
    @(Get-ChildItem -LiteralPath $jobsRoot -Directory -Filter "JOB-*" | Sort-Object Name)
  }
  else { @() }
  if ($jobs.Count -eq 0) { $errors.Add("no-jobs") }
  foreach ($job in $jobs) {
    foreach ($file in @("job.md", "job.config.json")) {
      $path = Join-Path $job.FullName $file
      if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -eq 0) {
        $errors.Add("missing-$file")
      }
    }
    $jobMdPath = Join-Path $job.FullName "job.md"
    if (Test-Path -LiteralPath $jobMdPath -PathType Leaf) {
      if ((Get-Content -LiteralPath $jobMdPath -Raw) -match 'TODO') { $errors.Add("incomplete-job-md") }
    }
    $jobConfigPath = Join-Path $job.FullName "job.config.json"
    if (Test-Path -LiteralPath $jobConfigPath -PathType Leaf) {
      $jobConfig = Read-Json $jobConfigPath
      if ($jobConfig.jobId -ne $job.Name) { $errors.Add("job-mismatch") }
      foreach ($field in @("allowedAreas", "stopConditions", "acceptanceCriteria", "reviewRequirements", "requiredOutputs")) {
        if (@($jobConfig.$field).Count -eq 0) { $errors.Add("empty-job-$field") }
      }
    }
  }
  if ($errors.Count -gt 0) {
    return [ordered]@{ status = "invalid"; reason = "package-check-failed"; details = @($errors) }
  }
  return [ordered]@{ status = "ok"; phaseId = $PhaseId; packageId = $PackageId; jobCount = $jobs.Count }
}

if ($Action -eq "create-phase") {
  if ($Kind -eq "mainline") {
    $number = Next-Number $PackageRoot '^PHASE-(\d{3})$'
    $PhaseId = "PHASE-$($number.ToString('D3'))"
    $BasePhaseId = ""
  }
  else {
    if ($BasePhaseId -notmatch '^PHASE-\d{3}$' -or -not (Test-Path -LiteralPath (Join-Path $PackageRoot $BasePhaseId) -PathType Container)) {
      Emit ([ordered]@{ status = "invalid"; reason = "missing-base-phase" })
      exit 1
    }
    $number = Next-Number $PackageRoot ("^" + [regex]::Escape($BasePhaseId) + "-EX(\d{2})$")
    $PhaseId = "$BasePhaseId-EX$($number.ToString('D2'))"
  }
  $directory = Join-Path $PackageRoot $PhaseId
  New-Item -ItemType Directory -Path $directory | Out-Null
  Write-Json (Join-Path $directory "phase.config.json") ([ordered]@{
    schemaVersion = 1
    phaseId = $PhaseId
    kind = $Kind
    basePhaseId = if ($BasePhaseId.Length -gt 0) { $BasePhaseId } else { $null }
    status = "available"
    statusReason = $null
    roadmap = $null
    packages = @()
  })
  Rebuild-PhaseIndex
  Emit ([ordered]@{ status = "created"; phaseId = $PhaseId })
  exit 0
}

if ($PhaseId -notmatch '^PHASE-\d{3}(-EX\d{2})?$') {
  Emit ([ordered]@{ status = "error"; reason = "invalid-phase-id" })
  exit 2
}
$PhaseDirectory = Join-Path $PackageRoot $PhaseId
if (-not (Test-Path -LiteralPath $PhaseDirectory -PathType Container)) {
  Emit ([ordered]@{ status = "invalid"; reason = "missing-phase" })
  exit 1
}

if ($Action -eq "create-package") {
  if ($JobCount -lt 1 -or $JobCount -gt 999) {
    Emit ([ordered]@{ status = "error"; reason = "invalid-job-count" })
    exit 2
  }
  $phase = Read-Json (Join-Path $PhaseDirectory "phase.config.json")
  if ($phase.status -ne "available") {
    Emit ([ordered]@{ status = "invalid"; reason = "phase-not-available" })
    exit 1
  }
  $number = Next-Number $PhaseDirectory '^PAK-(\d{3})$'
  $PackageId = "PAK-$($number.ToString('D3'))"
  $directory = Join-Path $PhaseDirectory $PackageId
  $jobsRoot = Join-Path $directory "jobs"
  New-Item -ItemType Directory -Force -Path $jobsRoot | Out-Null
  $jobs = @()
  for ($index = 1; $index -le $JobCount; $index++) {
    $jobId = "JOB-$($index.ToString('D3'))"
    $jobDirectory = Join-Path $jobsRoot $jobId
    New-Item -ItemType Directory -Path $jobDirectory | Out-Null
    [IO.File]::WriteAllText((Join-Path $jobDirectory "job.md"), "# $jobId$([Environment]::NewLine)$([Environment]::NewLine)## Step Outcome$([Environment]::NewLine)$([Environment]::NewLine)TODO$([Environment]::NewLine)", [Text.UTF8Encoding]::new($false))
    Write-Json (Join-Path $jobDirectory "job.config.json") ([ordered]@{
      schemaVersion = 1
      phaseId = $PhaseId
      packageId = $PackageId
      jobId = $jobId
      status = "planned"
      reviewRef = $null
      reworkFacts = @()
      type = "delegable"
      dependsOn = @()
      allowedAreas = @()
      forbiddenAreas = @()
      stopConditions = @()
      acceptanceCriteria = @()
      reviewRequirements = @()
      requiredOutputs = @()
    })
    $jobs += [ordered]@{ jobId = $jobId; dependsOn = @() }
  }
  [IO.File]::WriteAllText((Join-Path $directory "summary.md"), "# $PackageId`: $Title$([Environment]::NewLine)$([Environment]::NewLine)## Goal$([Environment]::NewLine)$([Environment]::NewLine)TODO$([Environment]::NewLine)", [Text.UTF8Encoding]::new($false))
  Write-Json (Join-Path $directory "package.config.json") ([ordered]@{
    schemaVersion = 1
    phaseId = $PhaseId
    packageId = $PackageId
    title = $Title
    planning = [ordered]@{ status = "draft"; reviewRef = $null }
    execution = [ordered]@{ status = "not-started"; verificationRef = $null; deliveryRef = $null }
    jobs = $jobs
    acceptanceCriteria = @()
    requiredArtifacts = @()
    closeoutRequirements = @()
  })
  Rebuild-PhasePackages $PhaseDirectory
  Emit ([ordered]@{ status = "created"; phaseId = $PhaseId; packageId = $PackageId; jobCount = $JobCount })
  exit 0
}

if ($PackageId -notmatch '^PAK-\d{3}$') {
  Emit ([ordered]@{ status = "error"; reason = "invalid-package-id" })
  exit 2
}
$directory = Package-Directory
if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
  Emit ([ordered]@{ status = "invalid"; reason = "missing-package" })
  exit 1
}

if ($Action -eq "check") {
  $result = Test-Package
  Emit $result
  if ($result.status -eq "ok") { exit 0 } else { exit 1 }
}

Emit ([ordered]@{ status = "error"; reason = "unsupported-action" })
exit 2
