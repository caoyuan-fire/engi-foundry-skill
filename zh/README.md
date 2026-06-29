# Engineering Foundry Skill

EngiFoundry 是一个平台无关的 AI 辅助工程工作流 skill。

它把工程意图转化为可持久保存、可审查、可交接的成果物：计划、任务包、Job 契约、执行记录、审查记录、验证证据和收尾记录。它适用于小型临时任务、中等规模工程变更，以及可能跨 Codex、Kimi、Claude、本地 CLI 或人类操作者流转的大型多阶段任务包。

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
| `package-planning` | 创建或修订可持久保存的任务包 |
| `package-alignment` | 执行前检查任务包是否可执行 |
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
  "recordsPolicy": "durable",
  "defaultPackagePolicy": "package-when-risky"
}
```

artifact root 不是运行时缓存目录。EngiFoundry 不应向其中写入缓存、临时文件、会话转储、下载模块或其它不具备审查价值的运行状态。如果某个 adapter 需要私有运行状态，必须使用显式的外部缓存位置，而不是 artifact root。

## 成果物目录结构

```text
<artifact-root>/
├── execution.config.json
├── packages/
│   └── <package-id>/
│       ├── summary.md
│       ├── package.config.json
│       ├── jobs/
│       │   └── JOB-001/
│       │       ├── job.md
│       │       ├── job.config.json
│       │       ├── record.md
│       │       ├── review.md
│       │       └── verification.md
│       ├── checkpoints/
│       ├── handoffs/
│       └── closeout.md
├── records/
│   ├── ad-hoc/
│   ├── reviews/
│   └── audits/
└── docs/
    └── generated/
```

artifact root 只应包含持久、可检查、有价值的工作成果。

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
  "defaultExecutor": "multi-session",
  "executors": {
    "multi-session": {
      "type": "local-multi-session",
      "supportsStdin": true,
      "supportsStructuredOutput": true,
      "outputNoise": "low",
      "supportsParallel": true,
      "supportsReviewOnly": true
    },
    "external-cli": {
      "type": "third-party-cli",
      "command": "kimi",
      "supportsStdin": true,
      "supportsStructuredOutput": false,
      "outputNoise": "medium",
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

executor 选择和质量纪律是分离的。EngiFoundry 用三个独立维度描述执行：

```text
executor   = 谁或什么机制执行工作
isolation  = 执行/审查上下文如何隔离
discipline = quick、standard、strict 等质量预设
```

## 任务包格式

一个 package 同时包含人类可读内容和机器可读内容。

```text
packages/<package-id>/
├── summary.md
├── package.config.json
├── jobs/
│   └── JOB-001/
│       ├── job.md
│       └── job.config.json
└── closeout.md
```

`summary.md` 只面向人类。它说明目的、范围、非目标、目标状态、风险、Job 概览、验收标准和收尾要求。它不是机器控制源。

`package.config.json` 是机器可读的 package 契约，应定义 package 状态、Job 顺序、默认执行策略、验收门槛、checkpoint 引用和 closeout 要求。

## Job 格式

每个 Job 是一个目录：

```text
jobs/JOB-001/
├── job.md
├── job.config.json
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

EngiFoundry 不应静默修改 `.gitignore`。如果用户不希望成果物进入版本控制，可以显式忽略自己选择的 artifact root。

## 安装

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
