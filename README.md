# EngiFoundry

EngiFoundry is an execution framework for AI-assisted software engineering.

It helps coding agents move from one-shot answers to controlled engineering delivery: plan when risk is high, execute through the lightest suitable path, preserve durable artifacts, verify claims, and review important work from cleaner context.

> Optimize for first-pass delivery, not cheapest generation.

Keyword: `engifoundry`.

中文说明见 [zh/README.md](zh/README.md).

## Why EngiFoundry

Most coding agents optimize for generation speed. That works for small changes, but larger work often fails through unclear scope, context drift, missing verification, weak handoff, or self-review bias.

EngiFoundry adds an engineering execution model around the agent:

- plan before high-risk execution;
- scale collaboration by task risk;
- use task packages for broad or ambiguous work;
- separate execution inputs from durable records;
- verify completion claims with evidence;
- use isolated execution or review when the work justifies it.

## Progressive Engineering

EngiFoundry routes work into the lightest process compatible with risk.

| Work type | Typical path |
| --- | --- |
| Small, clear, low-risk change | Direct ad-hoc execution |
| Multi-step or ambiguous change | Task package |
| Cross-module or high-risk change | Package plus stronger verification |
| Review-sensitive work | Clean-context or external review |
| Handoff-oriented work | Durable records and closeout |

Heavyweight process is not the default. Engineering rigor should scale with task complexity.

## Preload Gate

EngiFoundry is preloaded, but not always activated.

The autoload gate only decides whether EngiFoundry is available in the current workspace. It does not force package mode, create Jobs, or apply package governance by itself.

Complex engineering tasks may still consume more tokens by design. EngiFoundry spends extra context on planning, records, verification, and review to reduce repeated rework.

## Quickstart

Install the plugin or skills for your agent host, then work normally in an engineering repository. When the autoload gate detects a project and the request needs engineering workflow support, EngiFoundry becomes available automatically.

Manual entry point:

```text
$engifoundry
```

Autoload gate entry point:

```text
$engifoundry-gate
```

The gate only decides whether EngiFoundry is available in the current workspace. It does not force package mode, create Jobs, or apply package governance by itself.

## How It Works

EngiFoundry's main skill classifies each request into the workflow mode that matches the current risk and handoff needs:

- bounded low-risk tasks can run as ad-hoc work;
- broad, risky, multi-step, ambiguous, or handoff-oriented changes use structured task packages;
- isolated execution or review can be used when clean context matters;
- package work records execution inputs separately from durable outputs;
- completion claims require verification evidence or a clear non-runnable verification record.

For behavior changes, EngiFoundry prefers test-first development when feasible. For heavier work, it can first create a package contract and then continue from that contract without requiring a separate "initialize" or "compile a task package" request.

## Installation

Installation differs by agent host. If you use more than one host, install EngiFoundry separately for each one.

Plugin installation is the preferred full installation mode when the host supports plugins. For hosts without plugin support, use the skills-only fallback.

The plugin package name is `engifoundry-bundle`. The main manual skill remains `$engifoundry`.

### Codex

Codex-compatible installations use this repository as a Git marketplace:

- Register the marketplace:

```bash
codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
```

- Install the plugin:

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
skills/
```

### Claude

Claude-compatible installations use this repository as a Claude plugin marketplace:

- Register the marketplace:

```text
/plugin marketplace add caoyuan-fire/engi-foundry-skill
```

- Install the plugin:

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

Kimi Code can install directly from this repository:

- Install the plugin:

```text
/plugins install https://github.com/caoyuan-fire/engi-foundry-skill
```

Repository installs use:

```text
.kimi-plugin/plugin.json
skills/
```

### GitHub Copilot CLI

GitHub Copilot CLI can use this repository as a plugin marketplace:

- Register the marketplace:

```bash
copilot plugin marketplace add caoyuan-fire/engi-foundry-skill
```

- Install the plugin:

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

- Install from Cursor Agent chat or the plugin UI:

```text
/add-plugin https://github.com/caoyuan-fire/engi-foundry-skill
```

Relevant files:

```text
.cursor-plugin/plugin.json
skills/
```

Cursor IDE plugin support and Cursor Agent CLI support may not be identical in all versions.

### Factory Droid

Factory Droid can use this repository as a plugin marketplace:

- Register the marketplace:

```bash
droid plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
```

- Install the plugin:

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

For hosts without plugin marketplace support, install or symlink both skill folders into the host's skills directory:

```text
skills/engifoundry-gate/
skills/engifoundry/
```

Do not install both the plugin package and skills-only entries into the same host home; doing both can expose duplicate `$engifoundry-gate` and `$engifoundry` entries.

Detailed installation and publication rules live in [docs/publication.md](docs/publication.md) and [docs/platform-metadata.md](docs/platform-metadata.md).

## Updating

Update through the same installation channel you used:

- plugin users should refresh or reinstall from the configured Git marketplace;
- skills-only users should update the copied or symlinked `skills/engifoundry-gate/` and `skills/engifoundry/` directories together.

The installable skill version is recorded in [skills/engifoundry/VERSION](skills/engifoundry/VERSION).

## What's Inside

```text
docs/                         Formal specification and maintainer docs
skills/engifoundry-gate/       Lightweight autoload gate
skills/engifoundry/            Main skill, references, scripts, metadata
.codex-plugin/                 Codex plugin manifest
.claude-plugin/                Claude plugin manifest and marketplace metadata
.agents/plugins/               Codex Git marketplace metadata
.github/plugin/                GitHub Copilot CLI plugin metadata
.cursor-plugin/                Cursor plugin manifest
.factory-plugin/               Factory Droid plugin manifest and marketplace metadata
tests/                         Repository-level validation
zh/                            Chinese README
```

Start with:

- [Configuration](docs/configuration.md)
- [Artifact protocol](docs/artifact-protocol.md)
- [Execution policy](docs/execution-policy.md)
- [Package format](docs/package-format.md)
- [Job format](docs/job-format.md)
- [Role protocol](docs/role-protocol.md)
- [Publication](docs/publication.md)

## Development

Run the repository tests with:

```bash
python3 -m unittest discover -s tests
```

Keep root documentation readable for humans. Detailed workflow rules belong in `docs/` and agent-facing operational details belong in `skills/engifoundry/references/`.

## License

This repository does not currently include a license file. Until a license is added, do not assume permission to redistribute or reuse it outside the terms granted by the repository owner.
