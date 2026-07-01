# EngiFoundry

EngiFoundry 是一个平台无关的 AI 辅助工程工作流 skill。

它帮助编码 agent 判断什么时候可以直接实现，什么时候应该创建结构化任务包，如何保存有价值的工程记录，以及如何在不同工具或会话之间交接工作而不丢失范围、验证和审查控制。

关键词：`engifoundry`。

English documentation: [../README.md](../README.md).

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

EngiFoundry 会把工程请求路由到与风险匹配的最轻流程：

- 小型、清晰、低风险变更可以作为 ad-hoc 工作执行；
- 范围大、高风险、多步骤、含糊或需要交接的变更使用结构化任务包；
- package 工作把执行依据和持久输出分开记录；
- 声称完成前需要验证证据，或明确记录无法运行验证的原因。

对于行为变更，EngiFoundry 在可行时优先 test-first development。对于较重的工作，它可以先创建 package contract，然后继续按该 contract 执行，不要求用户单独发起“初始化”或“编制任务包”请求。

## 安装

当宿主支持 plugin 时，plugin 安装是首选的完整安装方式。

plugin 包名是 `engifoundry-bundle`。手动 skill 入口仍是 `$engifoundry`。

### Codex

Codex 兼容安装使用本仓库作为 Git marketplace：

```bash
codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
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

```text
/plugin marketplace add caoyuan-fire/engi-foundry-skill
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
