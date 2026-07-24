param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("status", "answer", "resolve", "cancel")]
  [string]$Action,
  [Parameter(Mandatory = $true)]
  [string]$ProjectRoot,
  [Parameter(Mandatory = $true)]
  [string]$CurrentCli,
  [string]$Locale = "en",
  [switch]$InitModify,
  [string]$UserInput = "",
  [ValidateSet("", "confirmed", "unconfirmed")]
  [string]$ResolutionStatus = "",
  [string]$ExecutorId = "",
  [string]$Label = "",
  [string]$Command = "",
  [string]$Model = "",
  [string]$Usage = "",
  [string]$Reason = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)

function Emit-Json {
  param($Value, [int]$Code = 0)
  $Value | ConvertTo-Json -Depth 20 -Compress
  exit $Code
}

function Get-InvalidMessage {
  param([string]$Reason)
  $zh = switch ($Reason) {
    "empty-input" { "请输入一个选项编号。" }
    "invalid-format" { "请输入有效的数字选项。" }
    "multiple-not-allowed" { "每次只能选择一个选项。" }
    "duplicate-option" { "不能重复选择同一个选项。" }
    "unknown-option" { "该选项不存在，请重新选择。" }
    "empty-custom-description" { "请描述你希望使用的 CLI 或模型。" }
    "invalid-custom-description" { "自定义描述格式无效，请使用普通文本重新描述。" }
    default { "当前输入无效，请重新回答。" }
  }
  $en = switch ($Reason) {
    "empty-input" { "Enter one option number." }
    "invalid-format" { "Enter a valid numeric option." }
    "multiple-not-allowed" { "Choose only one option at a time." }
    "duplicate-option" { "Do not repeat an option." }
    "unknown-option" { "That option is not available. Choose again." }
    "empty-custom-description" { "Describe the CLI or model you want to use." }
    "invalid-custom-description" { "The custom description is invalid. Describe it again using plain text." }
    default { "The current input is invalid. Answer again." }
  }
  if ($Locale -like "zh*") { return $zh }
  return $en
}

function Emit-Invalid {
  param([string]$Reason)
  Emit-Json ([ordered]@{ status = "invalid"; reason = $Reason; message = Get-InvalidMessage $Reason }) 1
}

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
  Emit-Json ([ordered]@{ status = "error"; reason = "invalid-project-root" }) 2
}
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$DataRoot = Join-Path $ProjectRoot ".engifoundry"
if (-not (Test-Path -LiteralPath $DataRoot -PathType Container)) {
  Emit-Json ([ordered]@{ status = "error"; reason = "missing-engifoundry-scaffold" }) 2
}
$StateRoot = Join-Path $DataRoot "cache/configurator"
$StateFile = Join-Path $StateRoot "state.json"
$Verifier = Join-Path $PSScriptRoot "verify.ps1"

function Save-State {
  param($State)
  New-Item -ItemType Directory -Force -Path $StateRoot | Out-Null
  $temporary = "$StateFile.tmp.$PID"
  [IO.File]::WriteAllText($temporary, (($State | ConvertTo-Json -Depth 20) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $StateFile -Force
}

function ConvertTo-OrderedMap {
  param($Value)
  if ($null -eq $Value) { return $null }
  if ($Value -is [Management.Automation.PSCustomObject]) {
    $result = [ordered]@{}
    foreach ($property in $Value.PSObject.Properties) {
      $result[$property.Name] = ConvertTo-OrderedMap $property.Value
    }
    return $result
  }
  if ($Value -is [Collections.IDictionary]) {
    $result = [ordered]@{}
    foreach ($key in $Value.Keys) { $result[$key] = ConvertTo-OrderedMap $Value[$key] }
    return $result
  }
  if ($Value -is [Collections.IEnumerable] -and $Value -isnot [string]) {
    return @($Value | ForEach-Object { ConvertTo-OrderedMap $_ })
  }
  return $Value
}

function New-State {
  param([string]$Mode)
  $state = [ordered]@{
    schemaVersion = 1
    mode = $Mode
    phase = "executor-choice"
    revision = 1
    currentCli = $CurrentCli
    executor = $null
    reviewer = $null
    automationMode = $null
    actionPreference = $null
    customDescription = $null
    options = @()
  }
  if ($Mode -eq "modify") {
    Copy-Item -LiteralPath (Join-Path $DataRoot "executors.json") -Destination (Join-Path $StateRoot "baseline-executors.json") -Force
    Copy-Item -LiteralPath (Join-Path $DataRoot "workflows.json") -Destination (Join-Path $StateRoot "baseline-workflows.json") -Force
  }
  Save-State $state
  return $state
}

if ($InitModify) {
  if ($Action -ne "status") {
    Emit-Json ([ordered]@{ status = "error"; reason = "init-modify-requires-status" }) 2
  }
  if (Test-Path -LiteralPath $StateRoot) {
    Get-ChildItem -LiteralPath $StateRoot -Force | Remove-Item -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $StateRoot | Out-Null
  $State = New-State "modify"
}
elseif (Test-Path -LiteralPath $StateFile -PathType Leaf) {
  $State = ConvertTo-OrderedMap (Get-Content -LiteralPath $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json)
}
else {
  $State = New-State "initialize"
}

function Get-KnownSpec {
  param([string]$Id)
  switch ($Id) {
    { $_ -in @("codex", "codex-cli") } { return [ordered]@{ id = "codex-cli"; label = "Codex"; command = "codex"; usage = "codex exec --ephemeral --json --color never -C {workspace} {prompt}" } }
    { $_ -in @("claude", "claude-cli") } { return [ordered]@{ id = "claude-cli"; label = "Claude Code"; command = "claude"; usage = "claude --print --output-format json {prompt}" } }
    { $_ -in @("gemini", "gemini-cli") } { return [ordered]@{ id = "gemini-cli"; label = "Gemini CLI"; command = "gemini"; usage = "gemini --prompt {prompt} --output-format json" } }
    { $_ -in @("kimi", "kimi-cli") } { return [ordered]@{ id = "kimi-cli"; label = "Kimi"; command = "kimi"; usage = "kimi --prompt {prompt} --output-format stream-json" } }
    { $_ -in @("cursor", "cursor-agent", "cursor-cli") } { return [ordered]@{ id = "cursor-cli"; label = "Cursor"; command = "cursor-agent"; usage = "cursor-agent --print {prompt}" } }
    default { return $null }
  }
}

function Test-CliVersion {
  param([string]$CommandName)
  $resolved = Get-Command $CommandName -ErrorAction SilentlyContinue
  if ($null -eq $resolved) { return $null }
  try {
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $resolved.Source
    $psi.Arguments = "--version"
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $process = [Diagnostics.Process]::Start($psi)
    if (-not $process.WaitForExit(5000)) {
      $process.Kill($true)
      return $null
    }
    if ($process.ExitCode -ne 0) { return $null }
    $line = ($process.StandardOutput.ReadToEnd() -split "`r?`n")[0]
    if ([string]::IsNullOrWhiteSpace($line)) { $line = "available" }
    if ($line.Length -gt 120) { $line = $line.Substring(0, 120) }
    return $line
  }
  catch { return $null }
}

function Get-Options {
  param([string]$Role)
  $ids = [Collections.Generic.List[string]]::new()
  $current = Get-KnownSpec $CurrentCli
  if ($null -ne $current) { $ids.Add($current.id) }
  foreach ($id in @("codex-cli", "claude-cli", "gemini-cli", "kimi-cli", "cursor-cli")) {
    if (-not $ids.Contains($id)) { $ids.Add($id) }
  }
  $options = [Collections.Generic.List[object]]::new()
  foreach ($id in $ids) {
    $spec = Get-KnownSpec $id
    $version = Test-CliVersion $spec.command
    if ($null -ne $version) {
      $options.Add([ordered]@{
        id = $spec.id; label = $spec.label; command = $spec.command; version = $version
        behavior = "select-known-executor"; source = "known"; model = ""; usage = $spec.usage
        originalDescription = ""
      })
    }
  }
  if ($Role -eq "reviewer" -and $null -ne $State.executor -and $State.executor.source -eq "custom") {
    $options.Add([ordered]@{
      id = "inherited-custom"; label = $State.executor.originalDescription
      command = $State.executor.command; version = "verified"; behavior = "select-known-executor"
      source = "custom"; model = $State.executor.model; usage = $State.executor.usage
      originalDescription = $State.executor.originalDescription; resolvedId = $State.executor.executorId
    })
  }
  $options.Add([ordered]@{
    id = "custom"; label = $(if ($Locale -like "zh*") { "自定义" } else { "Custom" })
    behavior = "branch"; source = "branch"; command = ""; version = ""; model = ""; usage = ""
    originalDescription = ""
  })
  for ($index = 0; $index -lt $options.Count; $index++) { $options[$index].displayNumber = $index + 1 }
  $State.options = @($options)
  Save-State $State
  return @($options)
}

function Emit-Choice {
  param([string]$Role, [string]$Warning = "")
  $options = Get-Options $Role
  $prompt = if ($Locale -like "zh*") {
    if ($Role -eq "executor") { "请选择参与协作执行的 Agent CLI：" } else { "请选择参与独立审查的 Agent CLI：" }
  } else {
    if ($Role -eq "executor") { "Choose the Agent CLI that will collaborate on execution:" } else { "Choose the Agent CLI that will perform independent review:" }
  }
  $context = if ($State.mode -eq "modify") {
    if ($Locale -like "zh*") { "这是 EngiFoundry 配置修改流程；提交最后一个答案前，当前配置保持生效。" }
    else { "This is the EngiFoundry configuration update flow. The current configuration remains active until the final answer is submitted." }
  } else { "" }
  $value = [ordered]@{
    schemaVersion = 1; status = "question"; mode = $State.mode; revision = $State.revision
    question = [ordered]@{ id = "$Role.choice"; kind = "single-choice"; prompt = $prompt; context = $context; options = $options }
  }
  if ($Warning) { $value.notice = [ordered]@{ level = "warning"; message = $Warning } }
  Emit-Json $value
}

function Emit-Custom {
  param([string]$Role)
  if ($Locale -like "zh*") {
    $prompt = "请描述你希望使用的 CLI，以及需要固定的模型或调用偏好。"
    $hints = @("例如：Codex 的 5.3 Spark 模型", "例如：使用默认模型的 Kimi CLI", "例如：Claude Code 的 Sonnet 模型")
  } else {
    $prompt = "Describe the CLI, pinned model, or invocation preference you want to use."
    $hints = @("For example: Codex with the 5.3 Spark model", "For example: Kimi CLI with its default model", "For example: Claude Code with a Sonnet model")
  }
  Emit-Json ([ordered]@{
    schemaVersion = 1; status = "question"; mode = $State.mode; revision = $State.revision
    question = [ordered]@{ id = "$Role.custom-description"; kind = "free-text"; prompt = $prompt; hints = $hints; agentHandling = "relay-user-input-unchanged" }
  })
}

function Emit-AgentAction {
  param([string]$Role)
  Emit-Json ([ordered]@{
    schemaVersion = 1; status = "agent-action-required"; mode = $State.mode
    action = [ordered]@{
      type = "resolve-and-probe-cli"; subject = $Role; userDescription = $State.customDescription
      returnQuestionId = "$Role.choice"
    }
  })
}

function Emit-Workflow {
  param([string]$Phase)
  if ($Phase -eq "automation") {
    $id = "workflow.automation"
    $prompt = if ($Locale -like "zh*") { "请选择任务流程的自动化程度：" } else { "Choose how automatically the task workflow should advance:" }
    $labels = if ($Locale -like "zh*") { @("逐项审批（每个 Job Review 结果及最终 PAK Verify 结果都需要审批）", "仅最终审批（自动推进 Job Review，只在 Deliver 前审批最终 PAK Verify 结果，推荐）", "全自动（自动推进 Job Review、PAK Verify 和 Deliver）") } else { @("Approve each step (approve every Job Review result and the final PAK Verify result)", "Final approval only (advance through Job Review automatically and approve the final PAK Verify result before Deliver; recommended)", "Full auto (advance through Job Review, PAK Verify, and Deliver automatically)") }
  } else {
    $id = "workflow.action-preference"
    $prompt = if ($Locale -like "zh*") { "请选择你偏好的任务处理方式：" } else { "Choose your preferred way to handle tasks:" }
    $labels = if ($Locale -like "zh*") { @("优先创建 Package（除机械、琐碎修改外，所有行动都创建 Package）", "平衡模式（多步骤、跨模块、边界不清、委派或有显著风险时创建 Package，推荐）", "优先直接执行（明确且可控时直接执行；无法可靠控制范围、风险或交付质量时仍创建 Package）") } else { @("Package first (create a Package for every action except mechanical, trivial changes)", "Balanced (create a Package for multi-step, cross-module, unclear, delegated, or meaningfully risky work; recommended)", "Direct first (act directly on clear, controlled work, but still create a Package when scope, risk, or delivery quality cannot be controlled reliably)") }
  }
  $options = for ($index = 0; $index -lt 3; $index++) {
    [ordered]@{ id = "$($index + 1)"; displayNumber = $index + 1; label = $labels[$index]; behavior = "select-value" }
  }
  Emit-Json ([ordered]@{
    schemaVersion = 1; status = "question"; mode = $State.mode; revision = $State.revision
    question = [ordered]@{ id = $id; kind = "single-choice"; prompt = $prompt; options = @($options) }
  })
}

function Emit-Current {
  switch ($State.phase) {
    "executor-choice" { Emit-Choice "executor" }
    "executor-custom" { Emit-Custom "executor" }
    "executor-resolve" { Emit-AgentAction "executor" }
    "reviewer-choice" { Emit-Choice "reviewer" }
    "reviewer-custom" { Emit-Custom "reviewer" }
    "reviewer-resolve" { Emit-AgentAction "reviewer" }
    "automation" { Emit-Workflow "automation" }
    "action-preference" { Emit-Workflow "action-preference" }
    "complete" { Emit-Json ([ordered]@{ schemaVersion = 1; status = "complete"; mode = $State.mode; completion = $State.completion }) }
    "cancelled" { Emit-Json ([ordered]@{ schemaVersion = 1; status = "cancelled"; mode = $State.mode }) }
    default { Emit-Json ([ordered]@{ status = "error"; reason = "invalid-configurator-state" }) 2 }
  }
}

function Read-SingleChoice {
  param([int]$Count)
  $source = (1..$Count) -join ","
  $powerShell = (Get-Process -Id $PID).Path
  $result = & $powerShell -NoProfile -ExecutionPolicy Bypass -File $Verifier -Source $source -Selection single -UserInput $UserInput
  $verificationCode = $LASTEXITCODE
  if ($verificationCode -ne 0) {
    if ($verificationCode -eq 1) {
      $invalid = $result | ConvertFrom-Json
      Emit-Invalid $invalid.reason
    }
    Write-Output $result
    exit $verificationCode
  }
  return [int](($result | ConvertFrom-Json).normalizedInput)
}

function Commit-Configuration {
  $executorValue = [ordered]@{
    schemaVersion = 2
    schemaRef = ".engifoundry/contracts/executors.schema.json"
    configured = $true
    executor = $State.executor
    reviewer = $State.reviewer
    gate = [ordered]@{
      executorUnavailable = [ordered]@{ action = "ask-user"; fallbackTarget = "current-session"; decisionScope = "task" }
    }
  }
  foreach ($role in @("executor", "reviewer")) {
    $entry = $executorValue[$role]
    [void]$entry.Remove("source")
    if ([string]::IsNullOrEmpty($entry.model)) { [void]$entry.Remove("model") }
    if ([string]::IsNullOrEmpty($entry.originalDescription)) { [void]$entry.Remove("originalDescription") }
  }
  $workflowValue = [ordered]@{
    schemaVersion = 1; configured = $true
    actionPreference = $State.actionPreference; automationMode = $State.automationMode
  }
  $executorTemp = Join-Path $StateRoot "executors.json.new"
  $workflowTemp = Join-Path $StateRoot "workflows.json.new"
  [IO.File]::WriteAllText($executorTemp, (($executorValue | ConvertTo-Json -Depth 20) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText($workflowTemp, (($workflowValue | ConvertTo-Json -Depth 20) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $executorTemp -Destination (Join-Path $DataRoot "executors.json") -Force
  Move-Item -LiteralPath $workflowTemp -Destination (Join-Path $DataRoot "workflows.json") -Force
  if ($State.mode -eq "initialize") {
    $initialization = [ordered]@{
      schemaVersion = 1; status = "complete"; currentStep = $null
      completedSteps = @("executor", "reviewer", "automation", "action-preference")
    }
    [IO.File]::WriteAllText((Join-Path $DataRoot "initialization.json"), (($initialization | ConvertTo-Json -Depth 10) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
  }
  $State.phase = "complete"; $State.revision++; Save-State $State
  if ($Locale -like "zh*") {
    $automationLabel = switch ($State.automationMode) {
      "job-approval" { "逐项审批（每个 Job Review 结果及最终 PAK Verify 结果都需要审批）" }
      "package-approval" { "仅最终审批（自动推进 Job Review，只在 Deliver 前审批最终 PAK Verify 结果，推荐）" }
      "full-auto" { "全自动（自动推进 Job Review、PAK Verify 和 Deliver）" }
    }
    $actionLabel = switch ($State.actionPreference) {
      "package-first" { "优先创建 Package（除机械、琐碎修改外，所有行动都创建 Package）" }
      "balanced" { "平衡模式（多步骤、跨模块、边界不清、委派或有显著风险时创建 Package，推荐）" }
      "direct-first" { "优先直接执行（明确且可控时直接执行；无法可靠控制范围、风险或交付质量时仍创建 Package）" }
    }
    $lines = @(
      "协作执行 Agent CLI：$($State.executor.label)",
      "独立审查 Agent CLI：$($State.reviewer.label)",
      "任务流程自动化程度：$automationLabel",
      "任务处理方式：$actionLabel"
    )
    $message = if ($State.mode -eq "initialize") { "🎉 EngiFoundry 初始化完成。" } else { "EngiFoundry 配置修改完成。" }
  }
  else {
    $automationLabel = switch ($State.automationMode) {
      "job-approval" { "Approve each step (approve every Job Review result and the final PAK Verify result)" }
      "package-approval" { "Final approval only (advance through Job Review automatically and approve the final PAK Verify result before Deliver; recommended)" }
      "full-auto" { "Full auto (advance through Job Review, PAK Verify, and Deliver automatically)" }
    }
    $actionLabel = switch ($State.actionPreference) {
      "package-first" { "Package first (create a Package for every action except mechanical, trivial changes)" }
      "balanced" { "Balanced (create a Package for multi-step, cross-module, unclear, delegated, or meaningfully risky work; recommended)" }
      "direct-first" { "Direct first (act directly on clear, controlled work, but still create a Package when scope, risk, or delivery quality cannot be controlled reliably)" }
    }
    $lines = @(
      "Execution Agent CLI: $($State.executor.label)",
      "Independent Review Agent CLI: $($State.reviewer.label)",
      "Workflow automation: $automationLabel",
      "Task handling: $actionLabel"
    )
    $message = if ($State.mode -eq "initialize") { "🎉 EngiFoundry initialization is complete." } else { "EngiFoundry configuration update is complete." }
  }
  $State["completion"] = [ordered]@{ lines = $lines; message = $message }
  Save-State $State
  Emit-Current
}

if ($Action -eq "status") { Emit-Current }
if ($Action -eq "cancel") { $State.phase = "cancelled"; $State.revision++; Save-State $State; Emit-Current }

if ($Action -eq "answer") {
  switch ($State.phase) {
    { $_ -in @("executor-choice", "reviewer-choice") } {
      $role = ($State.phase -split "-")[0]
      $options = Get-Options $role
      $selected = Read-SingleChoice $options.Count
      $option = $options[$selected - 1]
      if ($option.id -eq "custom") { $State.phase = "$role-custom" }
      else {
        $resolvedId = if ($option.id -eq "inherited-custom") { $option.resolvedId } else { $option.id }
        $selection = [ordered]@{
          executorId = $resolvedId; kind = "cli"; label = $option.label; command = $option.command
          modelMode = $(if ($option.model) { "pinned" } else { "cli-default" })
          model = $option.model; originalDescription = $option.originalDescription
          usage = $option.usage; source = $option.source
        }
        $State[$role] = $selection
        $State.phase = if ($role -eq "executor") { "reviewer-choice" } else { "automation" }
      }
      $State.revision++; Save-State $State; Emit-Current
    }
    { $_ -in @("executor-custom", "reviewer-custom") } {
      if ([string]::IsNullOrWhiteSpace($UserInput)) { Emit-Invalid "empty-custom-description" }
      if ($UserInput.Length -gt 500 -or $UserInput -match "[\x00-\x1F\x7F]") { Emit-Invalid "invalid-custom-description" }
      $role = ($State.phase -split "-")[0]
      $State.customDescription = $UserInput; $State.phase = "$role-resolve"; $State.revision++
      Save-State $State; Emit-Current
    }
    "automation" {
      $selected = Read-SingleChoice 3
      $State.automationMode = @("job-approval", "package-approval", "full-auto")[$selected - 1]
      $State.phase = "action-preference"; $State.revision++; Save-State $State; Emit-Current
    }
    "action-preference" {
      $selected = Read-SingleChoice 3
      $State.actionPreference = @("package-first", "balanced", "direct-first")[$selected - 1]
      Commit-Configuration
    }
    default { Emit-Invalid "answer-not-expected" }
  }
}

if ($Action -eq "resolve") {
  if ($State.phase -notin @("executor-resolve", "reviewer-resolve")) {
    Emit-Invalid "resolution-not-expected"
  }
  $role = ($State.phase -split "-")[0]
  if ($ResolutionStatus -eq "unconfirmed") {
    $State.phase = "$role-choice"; $State.revision++; Save-State $State
    $warning = if ($Locale -like "zh*") { "刚刚输入的自定义 CLI 或模型无法确认可用，请重新选择。" } else { "The custom CLI or model could not be confirmed as available. Choose again." }
    Emit-Choice $role $warning
  }
  if ($ResolutionStatus -ne "confirmed") { Emit-Invalid "missing-resolution-status" }
  if ($ExecutorId -notmatch '^[A-Za-z0-9._:/+@-]+$' -or $Command -notmatch '^[A-Za-z0-9._:/+@-]+$' -or [string]::IsNullOrWhiteSpace($Label) -or [string]::IsNullOrWhiteSpace($Usage)) {
    Emit-Invalid "invalid-resolution"
  }
  if ($Model -and $Model -notmatch '^[A-Za-z0-9._:/+@-]+$') { Emit-Invalid "invalid-model-id" }
  $State[$role] = [ordered]@{
    executorId = $ExecutorId; kind = "cli"; label = $Label; command = $Command
    modelMode = $(if ($Model) { "pinned" } else { "cli-default" }); model = $Model
    originalDescription = $State.customDescription; usage = $Usage; source = "custom"
  }
  $State.phase = if ($role -eq "executor") { "reviewer-choice" } else { "automation" }
  $State.revision++; Save-State $State; Emit-Current
}
