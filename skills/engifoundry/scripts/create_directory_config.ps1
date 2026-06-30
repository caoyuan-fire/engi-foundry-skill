param(
  [ValidateSet("empty", "filled")]
  [string]$Mode = "filled",
  [string]$ProjectRoot = ".",
  [string]$ArtifactRoot = "",
  [string]$PackageRoot = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$rootConfigPath = Join-Path $ProjectRoot ".engifoundry.config.json"
if (Test-Path $rootConfigPath) {
  $rootConfig = Get-Content -Path $rootConfigPath -Raw | ConvertFrom-Json
  if ([string]::IsNullOrWhiteSpace($ArtifactRoot)) {
    $ArtifactRoot = $rootConfig.artifactRoot
  }
  if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $PackageRoot = $rootConfig.packageRoot
  }
}

if ([string]::IsNullOrWhiteSpace($ArtifactRoot)) {
  $ArtifactRoot = ".engifoundry"
}
if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
  $PackageRoot = ".engifoundry-packages"
}

$artifactPath = Join-Path $ProjectRoot $ArtifactRoot
$configPath = Join-Path $artifactPath "directory.config.json"
if ((Test-Path $configPath) -and -not $Force) {
  throw "$configPath already exists; pass -Force to overwrite"
}

New-Item -ItemType Directory -Force -Path $artifactPath | Out-Null

if ($Mode -eq "empty") {
  $config = [ordered]@{
    schemaVersion = 1
    createdBy = "engifoundry"
    directories = @(
      [ordered]@{
        path = ""
        category = ""
        purpose = ""
        mustNotContain = @()
      }
    )
  }
} else {
  $config = [ordered]@{
    schemaVersion = 1
    createdBy = "engifoundry"
    artifactRoot = $ArtifactRoot
    packageRoot = $PackageRoot
    directories = @(
      [ordered]@{ path = "<project-root>/.engifoundry.config.json"; category = "Project discovery config"; purpose = "Locates EngiFoundry roots and durable workflow defaults for session alignment."; mustNotContain = @("secrets", "tokens", "runtime state", "Git ignore state", "roadmap state") },
      [ordered]@{ path = "<artifact-root>/execution.config.json"; category = "Artifact-root execution config"; purpose = "Records executor registry and selection policy."; mustNotContain = @("secrets", "tokens", "package authority grants", "transient executor state") },
      [ordered]@{ path = "<artifact-root>/roadmaps/ROADMAP.md"; category = "Durable output"; purpose = "Current roadmap for requirement alignment, sequencing, and next-step decisions."; mustNotContain = @("raw chat dumps", "private runtime state", "package control JSON") },
      [ordered]@{ path = "<artifact-root>/roadmaps/roadmap.index.json"; category = "Artifact-root index"; purpose = "Points to the current roadmap and records roadmap metadata."; mustNotContain = @("project root discovery settings", "Git ignore state", "secrets") },
      [ordered]@{ path = "<artifact-root>/roadmaps/archive/"; category = "Durable output archive"; purpose = "Historical roadmap snapshots that still have alignment or audit value."; mustNotContain = @("temporary drafts", "cache files", "raw model logs") },
      [ordered]@{ path = "<artifact-root>/records/ad-hoc/"; category = "Durable output"; purpose = "Records from bounded low-risk work that did not enter package flow."; mustNotContain = @("task package control inputs", "caches", "session dumps") },
      [ordered]@{ path = "<artifact-root>/records/packages/<package-id>/"; category = "Durable output"; purpose = "Package-flow execution records, reviews, verification evidence, checkpoints, handoffs, and closeout notes."; mustNotContain = @("package root control inputs unless copied as explicit evidence", "raw long logs", "private state") },
      [ordered]@{ path = "<artifact-root>/records/reviews/"; category = "Durable output"; purpose = "Review-only records that are not owned by a specific package record tree."; mustNotContain = @("implementation scratch files", "task package control inputs", "secrets") },
      [ordered]@{ path = "<artifact-root>/records/audits/"; category = "Durable output"; purpose = "Process, cost, quality, migration, policy, and workflow retrospective records."; mustNotContain = @("runtime cache", "downloaded modules", "unreviewable session dumps") },
      [ordered]@{ path = "<artifact-root>/docs/generated/"; category = "Durable output"; purpose = "Generated documents with review, delivery, or handoff value."; mustNotContain = @("cache output", "throwaway drafts", "raw model logs") },
      [ordered]@{ path = "<artifact-root>/docs/integration/"; category = "Durable output"; purpose = "Host integration, API integration, installation, and adapter-facing user documentation."; mustNotContain = @("executor runtime state", "package control JSON") },
      [ordered]@{ path = "<artifact-root>/docs/design/"; category = "Durable output"; purpose = "Architecture, UX, data-flow, test-strategy, and domain design documents."; mustNotContain = @("temporary scratch notes", "raw chat transcripts") },
      [ordered]@{ path = "<artifact-root>/docs/reference/"; category = "Durable input reference"; purpose = "External or upstream reference material used as context for decisions."; mustNotContain = @("secrets", "credentials", "downloaded dependency caches") },
      [ordered]@{ path = "<artifact-root>/docs/archive/"; category = "Durable output archive"; purpose = "Historical documents that remain useful as readable background but are not current records."; mustNotContain = @("current ROADMAP", "active package contracts", "cache files") },
      [ordered]@{ path = "<package-root>/<package-id>/"; category = "Execution input"; purpose = "Task package summary, package control JSON, Job contracts, and package-flow control data."; mustNotContain = @("execution records", "reviews", "verification evidence", "closeout notes", "raw logs") }
    )
  }
}

$config | ConvertTo-Json -Depth 8 | Set-Content -Path $configPath -Encoding UTF8
Write-Output $configPath
