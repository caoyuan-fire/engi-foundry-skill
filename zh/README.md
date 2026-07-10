# EngiFoundry

EngiFoundry 是一组平台无关的工程 Agent Skills。Agent 读取任务分类、编排、执行、干净上下文 Review、目标验证和交付收口契约；工程事实保存在项目自己的 `.engifoundry/` 中。

## 运行结构

```text
Entry
Router
Init | Orch | Exec | Verify | Deliver
Audit | Review
```

- Entry 只检查 `./engifoundry.config.json`。
- Router 声明可用契约和状态事实。
- Agent 根据用户目标选择并读取足够完整的契约集合。
- Audit 判断新任务应直接执行还是编制 Package。
- Review 必须由新的干净上下文 Agent 完成。
- 状态描述当前工程事实，不是工作流事件。

典型 Package 契约集合是 Orch、Exec、Verify、Deliver。Direct 工作不创建 Package，但仍遵守 Router 的工程质量底线。

## 工程结构

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

用户显式要求 EngiFoundry 迁移时，可以迁移旧工程。历史内容原样移动，活跃控制 JSON 由 Agent 检索事实后重建。

## 安装

推荐以插件安装，因为兼容宿主可以在会话开始时注入 Entry。

### Codex

```bash
codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
codex plugin add engifoundry-bundle@engi-foundry-skill
```

### Claude

```text
/plugin marketplace add caoyuan-fire/engi-foundry-skill
/plugin install engifoundry-bundle@engi-foundry-skill
```

### Kimi Code

```text
/plugins install https://github.com/caoyuan-fire/engi-foundry-skill
```

### GitHub Copilot CLI

```bash
copilot plugin marketplace add caoyuan-fire/engi-foundry-skill
copilot plugin install engifoundry-bundle@engi-foundry-skill
```

### Cursor

```text
/add-plugin https://github.com/caoyuan-fire/engi-foundry-skill
```

### Factory Droid

```bash
droid plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
droid plugin install engifoundry-bundle@engi-foundry-skill
```

Skills-only 宿主应安装完整的 `skills/` 目录。纯 Skill 安装不保证强制会话加载；宿主不自动加载 Entry 时，应显式调用 `$engifoundry`。不要在同一宿主目录同时安装插件和 Skills-only 副本。

## 开发

当前运行时位于 `skills/`。已经淘汰的实现仍可从 Git 历史中查阅。

```bash
python3 -m unittest discover -s tests -p 'test_*.py'
```

## License

Apache-2.0
