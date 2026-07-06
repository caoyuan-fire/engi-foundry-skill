# EngiFoundry

EngiFoundry 是一个面向 AI 辅助软件工程的执行框架。

它帮助编码 agent 从一次性回答转向受控的工程交付：在风险较高时先规划，用与任务匹配的最轻流程执行，保存持久工程产物，基于证据验证完成声明，并在重要工作中使用更干净的上下文进行审查。

> 优化目标不是最低生成成本，而是更高的一次性交付可靠性。

关键词：`engifoundry`。

English documentation: [../README.md](../README.md).

## 为什么需要 EngiFoundry

大多数 coding agent 优先优化生成速度。对于小改动，这通常足够；但较大的工程工作容易因为范围不清、上下文漂移、缺少验证、交接薄弱或自我审查偏差而反复返工。

EngiFoundry 在 agent 外围增加一套工程执行模型：

- 高风险执行前先规划；
- 按任务风险决定协作强度；
- 对范围较大或含糊的工作使用任务包；
- 分离执行输入和持久记录；
- 用证据验证完成声明；
- 在值得投入时使用隔离执行或隔离审查。

## 渐进式工程

EngiFoundry 会把工作路由到与风险匹配的最轻流程。

| 工作类型 | 典型路径 |
| --- | --- |
| 小型、清晰、低风险变更 | 直接 ad-hoc 执行 |
| 多步骤或含糊变更 | 任务包 |
| 跨模块或高风险变更 | 任务包加更强验证 |
| 对审查敏感的工作 | 干净上下文或外部审查 |
| 需要交接的工作 | 持久记录和 closeout |

重流程不是默认值。工程严谨度应该随任务复杂度增加。

## 预加载 Gate

EngiFoundry 会被预加载，但不会总是被激活。

autoload gate 只判断当前工作区是否可使用 EngiFoundry。它本身不会强制进入 package 模式、创建 Jobs，也不会应用 package governance。

复杂工程任务仍然会按设计消耗更多 token。EngiFoundry 把额外上下文投入到规划、记录、验证和审查中，用来减少反复返工。

## 快速开始

为你的 agent 宿主安装 plugin 或 skills，然后在工程仓库中正常工作。当 autoload gate 检测到工程环境，并且当前请求需要工程工作流支持时，EngiFoundry 会自动可用。

手动入口：

```text
$engifoundry
```

自动加载门入口：

```text
$engifoundry-gate
```

gate 只判断当前工作区是否可使用 EngiFoundry。它本身不会强制进入 package 模式、创建 Jobs，也不会应用 package governance。

## 工作方式

EngiFoundry 的主 skill 会把每个请求分类到与当前风险和交接需求匹配的工作流模式：

- 边界清晰、低风险任务可以作为 ad-hoc 工作执行；
- 范围大、高风险、多步骤、含糊或需要交接的变更使用结构化任务包；
- 当干净上下文有价值时，可以使用隔离执行或隔离审查；
- package 工作把执行依据和持久输出分开记录；
- 声称完成前需要验证证据，或明确记录无法运行验证的原因。

对于行为变更，EngiFoundry 在可行时优先 test-first development。对于较重的工作，它可以先创建 package contract，然后继续按该 contract 执行，不要求用户单独发起“初始化”或“编制任务包”请求。

## 安装

安装方式因 agent 宿主而异。如果你使用多个宿主，需要分别为每个宿主安装 EngiFoundry。

当宿主支持 plugin 时，plugin 安装是首选的完整安装方式。对于不支持 plugin 的宿主，使用 skills-only fallback。

plugin 包名是 `engifoundry-bundle`。手动 skill 入口仍是 `$engifoundry`。

### Codex

Codex 兼容安装使用本仓库作为 Git marketplace：

- 注册 marketplace：

```bash
codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
```

- 安装 plugin：

```bash
codex plugin add engifoundry-bundle@engi-foundry-skill
```

更新：

```bash
codex plugin marketplace upgrade engi-foundry-skill
codex plugin add engifoundry-bundle@engi-foundry-skill
```

相关文件：

```text
.agents/plugins/marketplace.json
.codex-plugin/plugin.json
skills/
```

### Claude

Claude 兼容安装使用本仓库作为 Claude plugin marketplace：

- 注册 marketplace：

```text
/plugin marketplace add caoyuan-fire/engi-foundry-skill
```

- 安装 plugin：

```text
/plugin install engifoundry-bundle@engi-foundry-skill
```

相关文件：

```text
.claude-plugin/marketplace.json
.claude-plugin/plugin.json
skills/
```

### Kimi Code

Kimi Code 可以直接从本仓库安装：

- 安装 plugin：

```text
/plugins install https://github.com/caoyuan-fire/engi-foundry-skill
```

也可以在 Kimi 插件界面搜索：

```text
/plugins
```

仓库安装使用：

```text
.kimi-plugin/plugin.json
skills/
```

### GitHub Copilot CLI

GitHub Copilot CLI 可以使用本仓库作为 plugin marketplace：

- 注册 marketplace：

```bash
copilot plugin marketplace add caoyuan-fire/engi-foundry-skill
```

- 安装 plugin：

```bash
copilot plugin install engifoundry-bundle@engi-foundry-skill
```

相关文件：

```text
.github/plugin/marketplace.json
.github/plugin/plugin.json
skills/
```

### Cursor

Cursor 兼容安装使用本仓库中的 Cursor plugin manifest。

- 在 Cursor Agent chat 或 plugin UI 中安装：

```text
/add-plugin https://github.com/caoyuan-fire/engi-foundry-skill
```

相关文件：

```text
.cursor-plugin/plugin.json
skills/
```

Cursor IDE plugin 支持和 Cursor Agent CLI 支持在不同版本中可能并不完全一致。

### Factory Droid

Factory Droid 可以使用本仓库作为 plugin marketplace：

- 注册 marketplace：

```bash
droid plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
```

- 安装 plugin：

```bash
droid plugin install engifoundry-bundle@engi-foundry-skill
```

相关文件：

```text
.factory-plugin/marketplace.json
.factory-plugin/plugin.json
skills/
```

### Skills-Only 宿主

对于不支持 plugin marketplace 的宿主，把两个 skill 目录安装或符号链接到宿主的 skills 目录：

```text
skills/engifoundry-gate/
skills/engifoundry/
```

不要在同一个 host home 中同时安装 plugin 包和 skills-only 入口；两者并存可能暴露重复的 `$engifoundry-gate` 和 `$engifoundry` 条目。

详细安装和发布规则见 [docs/publication.md](../docs/publication.md) 和 [docs/platform-metadata.md](../docs/platform-metadata.md)。

## 更新

通过你原来的安装渠道更新：

- plugin 用户应刷新或重新安装已配置 Git marketplace 中的 plugin；
- skills-only 用户应同时更新复制或符号链接的 `skills/engifoundry-gate/` 和 `skills/engifoundry/` 目录。

可安装 skill 的版本记录在 [skills/engifoundry/VERSION](../skills/engifoundry/VERSION)。

## 包含内容

```text
docs/                         正式规范和维护者文档
skills/engifoundry-gate/       轻量 autoload gate
skills/engifoundry/            主 skill、references、scripts、metadata
.codex-plugin/                 Codex plugin manifest
.claude-plugin/                Claude plugin manifest 和 marketplace metadata
.agents/plugins/               Codex Git marketplace metadata
.github/plugin/                GitHub Copilot CLI plugin metadata
.cursor-plugin/                Cursor plugin manifest
.factory-plugin/               Factory Droid plugin manifest 和 marketplace metadata
tests/                         仓库级验证
zh/                            中文 README
```

建议从这些文档开始：

- [Configuration](../docs/configuration.md)
- [Artifact protocol](../docs/artifact-protocol.md)
- [Execution policy](../docs/execution-policy.md)
- [Package format](../docs/package-format.md)
- [Job format](../docs/job-format.md)
- [Role protocol](../docs/role-protocol.md)
- [Publication](../docs/publication.md)

## 开发

运行仓库测试：

```bash
python3 -m unittest discover -s tests
```

根 README 应保持为面向人类的入口文档。详细工作流规则属于 `docs/`，agent-facing 操作细节属于 `skills/engifoundry/references/`。

## License

本仓库当前没有 license 文件。在添加 license 之前，不要假定可以在仓库所有者授权范围之外重新分发或复用。
