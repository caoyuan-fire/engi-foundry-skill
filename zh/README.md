# EngiFoundry

EngiFoundry 是一组平台无关的工程 Agent Skills。

它帮助编码 Agent 从一次性回答转向受控交付：选择足够轻量的工程路径、保留持久工程事实、验证完成声明，并在干净上下文中 Review 重要产出物。

> 优先优化一次交付成功，而不是最低生成成本。

关键词：`engifoundry`。

English documentation: [../README.md](../README.md).

## 为什么需要 EngiFoundry

小而明确的改动通常可以直接执行。较大的任务更容易因为范围不清、上下文漂移、缺少验证、交接薄弱或自我 Review 偏差而失败。

EngiFoundry 为 Agent 提供明确的工程契约，同时仍由 Agent 负责判断和执行：

- 对边界明确、低风险的请求直接执行；
- 对宽泛、模糊、多目标或需要交接的工作编制 Package；
- 在 `.engifoundry/` 下保存工程事实和持久产出物；
- 使用证据验证任务目标；
- 由新的干净上下文 Reviewer Agent Review 重要产出物。

工程严谨程度应随任务复杂度变化，默认不采用重型流程。

## 运行结构

```text
Entry
Router
Init | Orch | Exec | Verify | Deliver
Audit | Review | Docs
```

- Entry 只检查 `./engifoundry.config.json`。
- Router 声明可用契约、典型契约组合和已记录的状态事实。
- Agent 根据用户目标选择并读取足够完整的契约集合。
- Audit 判断新任务应直接执行还是编制 Package。
- Review 是可复用规则集，必须在新的干净上下文 Reviewer Agent 中执行。
- Docs 只在用户明确要求时提炼详细人读文档。
- 状态描述当前工程事实，不是工作流事件。

典型 Package 契约集合是 Orch、Exec、Verify、Deliver。Direct 工作不创建 Package，但仍遵守 Router 的工程质量底线。

## 快速开始

为当前 Agent 宿主安装插件，打开需要管理的工程，然后显式初始化：

```text
$engifoundry init
```

也可以使用“用 EngiFoundry 初始化这个工程”等自然语言。请求必须显式指明 EngiFoundry；普通的初始化表述不会激活它。

初始化只在工程根目录创建一个入口文件和 `.engifoundry/`：

```text
engifoundry.config.json
.engifoundry/
  workspace.md
  initialization.json
  executors.json
  workflows.json
  artifacts/
  packages/
```

当前 EngiFoundry Skill 需要完成上述初始化。如果工程已经使用旧版目录结构初始化，可通过 `.engifoundry.config.json` 或 `.engifoundry-packages/` 识别，应改为显式请求 EngiFoundry 迁移。历史产出物应优先原样继承到活跃结构，无法可靠继承时才归档；活跃控制 JSON 则由 Agent 根据检索到的工程事实重建。Init 会判断应执行迁移还是完整重新初始化。

## 安装

不同 Agent 宿主的安装方式不同。使用多个宿主时，需要分别安装 EngiFoundry。

推荐使用插件安装，因为兼容宿主可以在会话开始时注入轻量 Entry。不支持插件的宿主可以使用 Skills-only 方式。

插件包名是 `engifoundry-bundle`，手动入口是 `$engifoundry`。

### Codex

Codex 兼容安装使用本仓库作为 Git marketplace。

注册 marketplace：

```bash
codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
```

安装插件：

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
hooks/
skills/
```

### Claude

Claude 兼容安装使用本仓库作为 Claude plugin marketplace。

注册 marketplace：

```text
/plugin marketplace add caoyuan-fire/engi-foundry-skill
```

安装插件：

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

Kimi Code 可以直接从本仓库安装。

安装插件：

```text
/plugins install https://github.com/caoyuan-fire/engi-foundry-skill
```

仓库安装使用：

```text
.kimi-plugin/plugin.json
skills/
```

### GitHub Copilot CLI

GitHub Copilot CLI 可以使用本仓库作为 plugin marketplace。

注册 marketplace：

```bash
copilot plugin marketplace add caoyuan-fire/engi-foundry-skill
```

安装插件：

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

在 Cursor Agent 对话或插件界面中安装：

```text
/add-plugin https://github.com/caoyuan-fire/engi-foundry-skill
```

相关文件：

```text
.cursor-plugin/plugin.json
hooks/hooks-cursor.json
skills/
```

不同版本的 Cursor IDE 插件支持与 Cursor Agent CLI 支持可能并不完全一致。

### Factory Droid

Factory Droid 可以使用本仓库作为 plugin marketplace。

注册 marketplace：

```bash
droid plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
```

安装插件：

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

对于不支持插件的宿主，将完整的 `skills/` 目录安装或符号链接到宿主的 skills 目录。所有 EngiFoundry skill 目录共同组成一套运行时，必须一起更新。

纯 Skill 安装不保证在会话开始时强制加载。当宿主不会自动加载 `skills/engifoundry/SKILL.md` 时，应在请求中显式调用 `$engifoundry`。不要在同一宿主目录同时安装插件和 Skills-only 副本，否则可能暴露重复的 Skill 入口。

## 更新

使用与安装时相同的渠道更新：

- Codex 用户执行 Codex 章节列出的两条更新命令。
- 其他 marketplace 用户应刷新已配置的 marketplace，并使用对应宿主的插件管理器重新安装或更新 `engifoundry-bundle`。
- 直接仓库安装应从本仓库重新安装或刷新。
- Skills-only 用户应更新完整的 `skills/` 目录，而不是单独更新某个 EngiFoundry skill。

发布版本记录在插件与 marketplace manifests 中。已淘汰的运行时实现仍可从 Git 历史中查阅。

## 包含内容

```text
skills/engifoundry/            会话 Entry 契约
skills/engifoundry-router/     契约清单与路由上下文
skills/engifoundry-init/       初始化、配置与迁移
skills/engifoundry-orch/       Package、Phase、PAK 与 Job 编排
skills/engifoundry-exec/       遵守纪律的 Job 执行与记录
skills/engifoundry-verify/     目标级证据与验证状态
skills/engifoundry-deliver/    用户验收与交付收口
skills/engifoundry-audit/      Direct 与 Package 任务判定
skills/engifoundry-review/     干净上下文 Review 规则
skills/engifoundry-docs/       从工程记录提炼详细人读文档
hooks/                         会话开始时注入 Entry
.codex-plugin/                 Codex 插件 manifest
.claude-plugin/                Claude 插件 manifest 与 marketplace metadata
.agents/plugins/               Codex Git marketplace metadata
.github/plugin/                GitHub Copilot CLI 插件 metadata
.cursor-plugin/                Cursor 插件 manifest
.factory-plugin/               Factory Droid 插件 manifest 与 marketplace metadata
tests/                         仓库级校验
zh/                            中文文档
```

## 开发

运行仓库测试：

```bash
python3 -m unittest discover -s tests -p 'test_*.py'
```

## License

本项目使用 Apache License, Version 2.0。详见 [LICENSE](../LICENSE)。
