# EngiFoundry

EngiFoundry is a platform-neutral engineering workflow skill for AI-assisted software work.

It helps coding agents decide when to work directly, when to create a structured task package, how to preserve useful engineering records, and how to hand work across tools or sessions without losing control of scope, verification, and review.

Keyword: `engifoundry`.

中文说明见 [zh/README.md](zh/README.md).

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

EngiFoundry routes engineering requests into the lightest workflow that still protects quality:

- small, clear, low-risk changes can run as ad-hoc work;
- broad, risky, multi-step, ambiguous, or handoff-oriented changes use structured task packages;
- package work records execution inputs separately from durable outputs;
- completion claims require verification evidence or a clear non-runnable verification record.

For behavior changes, EngiFoundry prefers test-first development when feasible. For heavier work, it can first create a package contract and then continue from that contract without requiring a separate "initialize" or "compile a task package" request.

## Installation

Plugin installation is the preferred full installation mode when the host supports plugins.

The plugin package name is `engifoundry-bundle`. The main manual skill remains `$engifoundry`.

### Codex

Codex-compatible installations use this repository as a Git marketplace:

```bash
codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
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

```text
/plugin marketplace add caoyuan-fire/engi-foundry-skill
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

```text
/plugins install https://github.com/caoyuan-fire/engi-foundry-skill
```

You can also search the Kimi plugin UI with:

```text
/plugins
```

Repository installs use:

```text
.kimi-plugin/plugin.json
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
