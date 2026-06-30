# Engineering Foundry Skill

EngiFoundry 是一个平台无关的 AI 辅助工程工作流 skill。

关键词：`engifoundry`。

它把工程意图转化为执行依据和可持久保存、可审查、可交接的成果物：任务包计划、Job 契约、执行记录、审查记录、验证证据和收尾记录。它适用于小型临时任务、中等规模工程变更，以及可能跨 Codex、Kimi、Claude、本地 CLI 或人类操作者流转的大型多阶段任务包。

EngiFoundry 不把任何单一产品绑定为永久主控。角色是会话级的，并由成果物和用户意图共同约束。

English documentation: [../README.md](../README.md).

## 仓库结构

```text
EngiFoundrySkill/
├── README.md
├── engifoundry.manifest.json
├── docs/
│   ├── adapter-contract.md
│   ├── artifact-protocol.md
│   ├── configuration.md
│   ├── engineering-discipline.md
│   ├── execution-policy.md
│   ├── handoff-and-checkpoint.md
│   ├── job-format.md
│   ├── module-resolution.md
│   ├── package-format.md
│   ├── platform-metadata.md
│   ├── publication.md
│   ├── role-protocol.md
│   └── repository-structure.md
├── skills/
│   └── engifoundry/
│       ├── SKILL.md
│       ├── agents/
│       │   ├── generic.json
│       │   └── openai.yaml
│       ├── references/
│       ├── scripts/
│       └── modules/
├── examples/
│   └── README.md
├── tests/
│   └── test_resolve_module.py
└── zh/
    └── README.md
```

可安装的 skill 本体位于 `skills/engifoundry/`。根目录文档面向用户和维护者。

## 核心概念

EngiFoundry 只有一个公开入口，但内部会根据请求进入不同模式：

| 模式 | 用途 |
| --- | --- |
| `ad-hoc` | 低风险、有明确边界的小任务，不创建完整任务包 |
| `package-planning` | 创建或修订结构化任务包 |
| `package-alignment` | 审查 package 编制是否可以标记为 ready |
| `job-execution` | 执行一个或多个 package Job |
| `review-only` | 审查任务包、Job 结果、diff 或实现 |
| `package-revision` | 更新任务包规则、Job 契约、策略或记录 |
| `closeout` | 最终验收、交接或交付记录 |
| `audit` | 流程、成本、质量或工作流复盘 |

EngiFoundry 使用与风险匹配的最小流程。小任务可以保持 ad-hoc；范围大、高风险、多步骤或需要交接的工作应进入 package 模式。

## 成果物根目录

EngiFoundry 会把持久成果物写入用户项目中的 artifact root。

默认路径：

```text
<project-root>/.engifoundry/
```

用户可以指定其它路径，例如：

```text
<project-root>/MyEngiFoundry/
<project-root>/docs/engifoundry/
```

项目根目录应包含一个定位配置：

```text
<project-root>/.engifoundry.config.json
```

示例：

```json
{
  "schemaVersion": 1,
  "artifactRoot": ".engifoundry",
  "packageRoot": ".engifoundry-packages",
  "recordsPolicy": "durable",
  "defaultPackagePolicy": "package-when-risky"
}
```

artifact root 不是运行时缓存目录。EngiFoundry 不应向其中写入缓存、临时文件、会话转储、下载模块或其它不具备审查价值的运行状态。如果某个 adapter 需要私有运行状态，必须使用显式的外部缓存位置，而不是 artifact root。

artifact root 用于持久成果物。package root 用于任务包和 Job 契约等执行依据。

## 成果物目录结构

```text
<artifact-root>/
├── execution.config.json
├── directory.config.json
├── roadmaps/
│   ├── ROADMAP.md
│   ├── roadmap.index.json
│   └── archive/
├── records/
│   ├── ad-hoc/
│   ├── packages/
│   ├── reviews/
│   └── audits/
└── docs/
    ├── generated/
    ├── integration/
    ├── design/
    ├── reference/
    └── archive/
```

artifact root 只应包含持久、可检查、有价值的工作成果。

## ROADMAP

ROADMAP 存档是持久对齐成果物，位于 `<artifact-root>/roadmaps/`。

当用户已经做过需求对齐、规划或任务前讨论，并要求持久化、保存、归档或落地时，EngiFoundry 写入或更新 `ROADMAP.md` 和 `roadmap.index.json`。当用户询问“下一步做什么”或要求确认下一步时，EngiFoundry 检查是否存在 active roadmap，并结合当前进展使用它做决策。若不存在 roadmap，则根据当前会话上下文、可见工程状态和用户声明的目标决策。

不要在 `.engifoundry.config.json` 中保存 roadmap 状态；项目根配置只负责定位 artifact root。

## 初始化脚本

EngiFoundry 提供面向 macOS、Linux 和 Windows 的功能性初始化脚本。它们不依赖 Python。

按以下顺序执行：

1. `create_root_config`
2. `create_standard_dirs`
3. `create_directory_config`

Templates are formal editable files，不是参考示例。macOS/Linux 使用 `.sh` 脚本，Windows 使用 `.ps1` 脚本。配置模板脚本支持 `empty` 和 `filled` 模式；当 prompt 上下文已有明确值时，由 agent 映射为脚本参数。

## 任务包根目录结构

```text
<package-root>/
└── <package-id>/
    ├── summary.md
    ├── package.config.json
    └── jobs/
        └── JOB-001/
            ├── job.md
            └── job.config.json
```

默认 package root 是 `.engifoundry-packages/`。它默认是执行依据目录，不是交付成果物。

package flow 的持久成果物，包括 Job 执行记录、审查记录、验证证据、交接摘要和收尾文档，写入 `<artifact-root>/records/packages/<package-id>/`。

## 执行配置

每个 artifact root 应包含：

```text
execution.config.json
```

该文件描述 executor 能力和选择偏好。它不保存密钥、token、私有 session ID 或临时状态。

示例：

```json
{
  "schemaVersion": 1,
  "executors": {
    "multi-session": {
      "type": "local-multi-session",
      "command": "codex",
      "supportsStdin": true,
      "stdinMode": "prompt-pipe",
      "bestInvocation": "codex exec --json",
      "supportsStructuredOutput": true,
      "structuredOutputFormat": "jsonl",
      "outputNoise": "low",
      "requiresOutputPreprocessing": true,
      "preprocessingNotes": "Extract the final assistant result from JSONL event output.",
      "timeoutBehavior": "long-running; do not abort solely because a fixed elapsed-time or wait-turn window passed",
      "livenessSignals": ["process-alive", "progress-event", "probe-response"],
      "probeBehavior": "on silence, request status before fallback or abort",
      "stallCriteria": "no probe response or repeated non-evidential working reports",
      "abortCriteria": "process exit without handback, explicit blocked status, repeated failed probes, contract violation, or stop condition",
      "heartbeatSchema": ["status", "phase", "last_event", "next", "needs_control", "blocked_reason"],
      "finalReportSchema": ["job_id", "status", "changed_files", "behavior_summary", "evidence_paths", "verification", "known_gaps", "recommendation"],
      "rawStreamPolicy": "read raw stream only on failure, blocked execution, verification mismatch, strict review escalation, or explicit user request",
      "supportsParallel": true,
      "supportsReviewOnly": true
    },
    "external-cli": {
      "type": "third-party-cli",
      "command": "kimi",
      "supportsStdin": false,
      "stdinMode": "interactive-only",
      "bestInvocation": "kimi",
      "supportsStructuredOutput": false,
      "outputNoise": "medium",
      "requiresOutputPreprocessing": true,
      "preprocessingNotes": "Manual summary extraction may be required.",
      "timeoutBehavior": "human-observed; do not abort solely because a fixed elapsed-time or wait-turn window passed",
      "livenessSignals": ["human-status", "probe-response"],
      "probeBehavior": "ask for current status, recent work, next action, and blockers",
      "stallCriteria": "no response or repeated non-evidential working reports",
      "abortCriteria": "explicit blocked status, repeated failed probes, contract violation, or stop condition",
      "heartbeatSchema": ["status", "phase", "last_event", "next", "needs_control", "blocked_reason"],
      "finalReportSchema": ["job_id", "status", "changed_files", "behavior_summary", "evidence_paths", "verification", "known_gaps", "recommendation"],
      "rawStreamPolicy": "human observed; summarize raw output before review context unless escalated",
      "supportsParallel": false,
      "supportsReviewOnly": true
    }
  },
  "selectionPolicy": {
    "prefer": ["multi-session", "external-cli"],
    "fallback": "direct"
  }
}
```

`selectionPolicy.prefer` 是有序数组；第一个可用 executor 优先调用。

对于没有可用 `execution.config.json` 的新工程，EngiFoundry 对 ad-hoc 和简单 `primary/control` 工作使用 `direct`。如果 package 工作需要有边界或隔离执行，但没有可用 executor 配置，primary/control 会先安全发现本地 executor 能力，无法确认时再询问用户注册或使用哪个 executor。

对齐新工程或新的 EngiFoundry 会话时，EngiFoundry 在定位 artifact root 后应优先读取已存在的 `execution.config.json`，把 executor 顺序、调用方法、能力字段和已知限制带入当前会话上下文。这不是每次 ad-hoc 任务前的强制读取。若对齐或安全发现时发现 executor 认知缺失，EngiFoundry 应建议把可持久、非敏感事实记录到对应 `execution.config.json` 字段，但不强制写入。

executor 选择和质量纪律是分离的。EngiFoundry 用三个独立维度描述执行：

```text
executor   = 谁或什么机制执行工作
isolation  = 执行/审查上下文如何隔离
discipline = quick、standard、strict 等质量预设
```

正常监视期间，primary/control 不应持续摄入 executor 的原始输出流。`quick` 优先 direct execution 或只接收最终报告；`standard` 优先紧凑 heartbeat 和紧凑最终 handback；`strict` 保留更强的审查和证据要求，但仍避免默认摄入原始输出流。

## 任务包格式

一个 package 同时包含人类可读内容和机器可读内容。

```text
<package-root>/<package-id>/
├── summary.md
├── package.config.json
└── jobs/
    └── JOB-001/
        ├── job.md
        └── job.config.json
```

`summary.md` 只面向人类。它说明目的、范围、非目标、目标状态、风险、Job 概览、验收标准和收尾要求。它不是机器控制源。

`package.config.json` 是机器可读的 package 契约，应定义 package 编制状态、执行状态、Job 顺序、默认执行策略、验收门槛、checkpoint 引用和 closeout 要求。

## Job 格式

每个 Job 的控制输入位于 package root：

```text
<package-root>/<package-id>/jobs/JOB-001/
├── job.md
└── job.config.json
```

每个 Job 的持久成果物位于 artifact root：

```text
<artifact-root>/records/packages/<package-id>/jobs/JOB-001/
├── record.md
├── review.md
└── verification.md
```

`job.md` 用于人类语义理解：背景、目标、范围、非目标、业务含义、风险和验收标准。

`job.config.json` 用于稳定执行：状态、依赖、允许和禁止区域、执行策略、验证命令、输出契约和必需记录。

JSON 文件不应复制 Markdown 中的长篇叙述。Markdown 负责解释，JSON 负责控制。

## 角色

EngiFoundry 角色不绑定产品名。

Codex 可以是 primary/control，也可以是 executor。Kimi 可以是 primary/control，也可以是 executor。人类用户也可以手动驱动任一角色。角色是会话级的，由成果物和用户意图共同约束。

角色包括：

- `primary/control`：负责需求、范围、架构、package 策略、Job 顺序、审查决策、集成、收尾和 package 修订。
- `executor`：执行有边界的 Job，并输出结果。
- `reviewer`：审查 package 或 Job 成果，但不是实现者。
- `audit-control`：评估流程、质量、成本或工作流历史。

新的 EngiFoundry 工作默认从 `primary/control` 开始。

恢复已有 package 时，如果能从会话上下文、checkpoint、handoff 或用户措辞中高置信推断出归属或延续意图，则当前会话恢复为 `primary/control`。

如果无法推断角色，EngiFoundry 会让用户在接管主控和执行有边界的 executor/reviewer 工作之间选择。

有边界的 executor/reviewer 可以完成指定任务并写出结果，但不能自动驱动 package 继续推进。它的 `autoDrive` 能力为 false。

以下 primary-only 动作必须具备 `primary/control` 权限：

- 创建或修订 package 范围；
- 修改 Job 顺序或依赖；
- 修改 package 验收标准；
- 修改默认执行策略；
- 批准 Job 完成；
- 决定 rework、rollback 或 scope change；
- 创建 executor/reviewer assignment；
- 关闭 package。

## Git 策略

artifact root 包含持久工作成果，默认不应被忽略。

EngiFoundry 不应为 artifact root 静默修改 `.gitignore`。如果用户不希望成果物进入版本控制，可以显式忽略自己选择的 artifact root。

package root 不同。它保存执行依据，可以被 EngiFoundry 自动加入 `.gitignore`。只有首次加入 ignore 规则时才告知用户。若用户要求任务包入库，或手动修改 `.gitignore` 后 `git status` 能看到 package root，EngiFoundry 应将任务包视为可入库内容。Git 是唯一状态来源；`.engifoundry.config.json` 不保存 Git ignore 状态。

## 安装

已安装 skill 的版本记录在 `skills/engifoundry/VERSION`。版本只是维护标签。EngiFoundry 可以在每个会话首次对齐时、且有网络权限时最多检查一次更新；没有更新或检查失败时保持静默。

推荐使用完整安装。复制或软链接可安装的 skill 目录：

```text
skills/engifoundry/
```

到 Codex skills 目录：

```text
~/.codex/skills/engifoundry/
```

然后重启 Codex，让它重新扫描 skill metadata。

也支持 kernel-only 轻量分享模式。该模式需要 `SKILL.md`、`engifoundry.manifest.json` 和 `skills/engifoundry/scripts/resolve_module.py`。缺失模块只会在用户明确确认后从 manifest 声明的 GitHub 源下载，下载内容会缓存到项目 artifact root 之外。

## 文档

更多文档：

- [Configuration](../docs/configuration.md)
- [Artifact protocol](../docs/artifact-protocol.md)
- [Execution policy](../docs/execution-policy.md)
- [Role protocol](../docs/role-protocol.md)
- [Package format](../docs/package-format.md)
- [Job format](../docs/job-format.md)
- [Module resolution](../docs/module-resolution.md)
- [Handoff and checkpoint](../docs/handoff-and-checkpoint.md)
- [Engineering discipline](../docs/engineering-discipline.md)
- [Adapter contract](../docs/adapter-contract.md)
- [Platform metadata](../docs/platform-metadata.md)
- [Repository structure](../docs/repository-structure.md)
- [Publication](../docs/publication.md)
