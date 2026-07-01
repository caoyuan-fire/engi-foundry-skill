# Platform Metadata

EngiFoundry exposes two skill entry points:

```text
$engifoundry-gate
$engifoundry
```

`$engifoundry` is the main manual entry point. Users who want EngiFoundry should prefer this entry point.

`$engifoundry-gate` is the plugin autoload gate. Plugin installation should target this entry point for session-start preheating. It only decides whether EngiFoundry is available in the current workspace; it does not apply the full workflow.

The gate only decides whether the current workspace makes EngiFoundry available. It inspects only first-level current-working-directory children, treats `.git/` as a super signal, recognizes ordinary project scaffold signals such as build files, package manifests, source directories, app directories, or test directories, recognizes EngiFoundry initialization signals such as `.engifoundry.config.json`, `.engifoundry/`, and `.engifoundry-packages/`, and does not force package governance.

The canonical runtime metadata is the YAML frontmatter in:

```text
skills/engifoundry-gate/SKILL.md
skills/engifoundry/SKILL.md
```

That frontmatter contains the required `name` and `description` fields. Platforms that support Agent Skills should be able to discover the skill from those fields.

## OpenAI / Codex

EngiFoundry includes a Codex plugin manifest:

```text
.agents/plugins/marketplace.json
.codex-plugin/plugin.json
```

The plugin package name is `engifoundry-bundle`. The package name intentionally differs from the main `$engifoundry` skill name so host UIs that expose both plugin packages and skills do not show two ambiguous `engifoundry` entries.

The Codex marketplace and plugin manifests declare:

- the Git-hosted marketplace entry for `engifoundry-bundle`;
- the plugin name and interface metadata;
- the shared `skills/` directory;
- the `engifoundry-gate` autoload gate and `engifoundry` main entry through normal skill discovery.

Codex-compatible installers should treat repository-level requests such as "install the latest EngiFoundry skill from GitHub" or "install this skill: <repository URL>" as hosted marketplace installation requests when `.agents/plugins/marketplace.json` and `.codex-plugin/plugin.json` are present. Copying only `skills/engifoundry/`, or maintaining a separate local `~/plugins/` source mirror, is not the preferred full installation.

EngiFoundry also includes OpenAI/Codex-facing UI metadata:

```text
skills/engifoundry/agents/openai.yaml
```

This file provides display name, short description, and default prompt metadata for OpenAI surfaces that support it.

## Generic Metadata

EngiFoundry also includes platform-neutral metadata:

```text
skills/engifoundry/agents/generic.json
```

This file is for humans, installers, and third-party tooling. It is not required for EngiFoundry runtime behavior.

## Claude-Compatible Surfaces

EngiFoundry includes a Claude plugin manifest:

```text
.claude-plugin/marketplace.json
.claude-plugin/plugin.json
```

The Claude plugin package uses the same `engifoundry-bundle` package name.

Claude-compatible skill surfaces should use the Claude marketplace and plugin manifests when available and `SKILL.md` frontmatter as the core skill metadata source. Claude does not use Codex's `.agents/plugins/marketplace.json`.

## Kimi-Compatible Surfaces

EngiFoundry does not currently include a Kimi marketplace manifest because no stable marketplace catalog contract is assumed here.

Kimi-compatible usage should rely on:

- `SKILL.md` frontmatter;
- `agents/generic.json`;
- public documentation in this repository.

Install or symlink both `skills/engifoundry-gate/` and `skills/engifoundry/` into a Kimi-supported skills directory. If Kimi plugin installation is used, the plugin package must still expose the shared `skills/` directory.

Kimi Code currently supports explicit skill loading through `--skills-dir <dir>`, so repository compatibility is maintained through the `skills/` layout and `SKILL.md` files rather than a marketplace manifest.

## Rule

Do not add platform-specific metadata files unless the platform has a stable schema or the repository explicitly documents the file as non-authoritative tooling metadata.
