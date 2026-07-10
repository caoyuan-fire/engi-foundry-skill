# EngiFoundry

EngiFoundry is a platform-neutral set of Agent Skills for structured engineering work.

It helps coding agents move from one-shot answers to controlled delivery: select the lightest suitable engineering path, preserve durable project facts, verify claims, and review important outputs from clean context.

> Optimize for first-pass delivery, not cheapest generation.

Keyword: `engifoundry`.

中文说明见 [zh/README.md](zh/README.md).

## Why EngiFoundry

Small, clear changes often need only direct execution. Larger work fails more often through unclear scope, context drift, missing verification, weak handoff, or self-review bias.

EngiFoundry gives the Agent explicit engineering contracts while leaving the Agent responsible for judgment and execution:

- use direct work for bounded, low-risk requests;
- use Packages for broad, ambiguous, multi-goal, or handoff-oriented work;
- preserve project facts and durable artifacts under `.engifoundry/`;
- verify task goals with evidence;
- review important outputs through a fresh Reviewer Agent context.

Engineering rigor scales with the task. Heavyweight process is not the default.

## Runtime

```text
Entry
Router
Init | Orch | Exec | Verify | Deliver
Audit | Review | Docs
```

- Entry checks only `./engifoundry.config.json`.
- Router declares the available contracts, typical contract combinations, and recorded state signals.
- The Agent selects and reads the contracts needed to reach the user's requested endpoint.
- Audit classifies new work as direct or packaged.
- Review is a reusable rule set and always runs in a fresh Reviewer Agent context.
- Docs produces detailed human-readable documents only when explicitly requested.
- States describe current project facts; they are not workflow events.

The typical packaged contract set is Orch, Exec, Verify, and Deliver. Direct work does not create a Package, but it still follows Router quality rules.

## Quickstart

Install the plugin for your Agent host, open the project you want to manage, and initialize it explicitly:

```text
$engifoundry init
```

Natural-language requests such as "initialize this project with EngiFoundry" work too. The request must explicitly identify EngiFoundry; ordinary initialization language does not activate it.

Initialization creates only the root entry file and `.engifoundry/` tree:

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

The initialization above is required for the current EngiFoundry Skill. If a project was initialized by an older EngiFoundry layout, identified by `.engifoundry.config.json` or `.engifoundry-packages/`, explicitly request an EngiFoundry migration instead. Historical artifacts are inherited into the active structure without rewriting their contents whenever possible; archival is only a fallback. Active control JSON is rebuilt from inspected project facts. Init determines whether migration or a full re-initialization is appropriate.

## Installation

Installation differs by Agent host. If you use more than one host, install EngiFoundry separately for each one.

Plugin installation is preferred because compatible hosts can inject the lightweight Entry at session start. For hosts without plugin support, use the skills-only fallback.

The plugin package name is `engifoundry-bundle`. The manual entry point is `$engifoundry`.

### Codex

Codex-compatible installations use this repository as a Git marketplace.

Register the marketplace:

```bash
codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
```

Install the plugin:

```bash
codex plugin add engifoundry-bundle@engi-foundry-skill
```

Update with:

```bash
codex plugin marketplace upgrade engi-foundry-skill
codex plugin add engifoundry-bundle@engi-foundry-skill
```

Relevant files:

```text
.agents/plugins/marketplace.json
.codex-plugin/plugin.json
hooks/
skills/
```

### Claude

Claude-compatible installations use this repository as a Claude plugin marketplace.

Register the marketplace:

```text
/plugin marketplace add caoyuan-fire/engi-foundry-skill
```

Install the plugin:

```text
/plugin install engifoundry-bundle@engi-foundry-skill
```

Relevant files:

```text
.claude-plugin/marketplace.json
.claude-plugin/plugin.json
skills/
```

### Kimi Code

Kimi Code can install directly from this repository.

Install the plugin:

```text
/plugins install https://github.com/caoyuan-fire/engi-foundry-skill
```

Repository installs use:

```text
.kimi-plugin/plugin.json
skills/
```

### GitHub Copilot CLI

GitHub Copilot CLI can use this repository as a plugin marketplace.

Register the marketplace:

```bash
copilot plugin marketplace add caoyuan-fire/engi-foundry-skill
```

Install the plugin:

```bash
copilot plugin install engifoundry-bundle@engi-foundry-skill
```

Relevant files:

```text
.github/plugin/marketplace.json
.github/plugin/plugin.json
skills/
```

### Cursor

Cursor-compatible installations use the Cursor plugin manifest in this repository.

Install from Cursor Agent chat or the plugin UI:

```text
/add-plugin https://github.com/caoyuan-fire/engi-foundry-skill
```

Relevant files:

```text
.cursor-plugin/plugin.json
hooks/hooks-cursor.json
skills/
```

Cursor IDE plugin support and Cursor Agent CLI support may not be identical in all versions.

### Factory Droid

Factory Droid can use this repository as a plugin marketplace.

Register the marketplace:

```bash
droid plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
```

Install the plugin:

```bash
droid plugin install engifoundry-bundle@engi-foundry-skill
```

Relevant files:

```text
.factory-plugin/marketplace.json
.factory-plugin/plugin.json
skills/
```

### Skills-Only Hosts

For hosts without plugin support, install or symlink the complete `skills/` directory into the host's skills directory. All EngiFoundry skill directories are part of one runtime and must be updated together.

Skills-only installation does not guarantee forced loading at session start. When the host does not autoload `skills/engifoundry/SKILL.md`, explicitly invoke `$engifoundry` for the request. Do not install both the plugin and skills-only copies in the same host home, because doing so can expose duplicate skill entries.

## Updating

Update through the same channel used for installation:

- Codex users should run the two update commands shown in the Codex section.
- Marketplace users on other hosts should refresh the configured marketplace and reinstall or update `engifoundry-bundle` with that host's plugin manager.
- Direct repository installations should reinstall or refresh from this repository.
- Skills-only users should update the complete `skills/` directory, not individual EngiFoundry skills.

Release versions are recorded in the plugin and marketplace manifests. Superseded runtime implementations remain available through Git history.

## What's Inside

```text
skills/engifoundry/            Session Entry contract
skills/engifoundry-router/     Contract registry and routing context
skills/engifoundry-init/       Initialization, configuration, and migration
skills/engifoundry-orch/       Package, Phase, PAK, and Job orchestration
skills/engifoundry-exec/       Disciplined Job execution and records
skills/engifoundry-verify/     Goal-level evidence and verification status
skills/engifoundry-deliver/    User acceptance and delivery closeout
skills/engifoundry-audit/      Direct-versus-packaged task assessment
skills/engifoundry-review/     Fresh-context review rules
skills/engifoundry-docs/       Detailed human-readable documents from project records
hooks/                         Session-start Entry injection
.codex-plugin/                 Codex plugin manifest
.claude-plugin/                Claude plugin manifest and marketplace metadata
.agents/plugins/               Codex Git marketplace metadata
.github/plugin/                GitHub Copilot CLI plugin metadata
.cursor-plugin/                Cursor plugin manifest
.factory-plugin/               Factory Droid plugin manifest and marketplace metadata
tests/                         Repository-level validation
zh/                            Chinese documentation
```

## Development

Run the repository test suite with:

```bash
python3 -m unittest discover -s tests -p 'test_*.py'
```

## License

This project is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
