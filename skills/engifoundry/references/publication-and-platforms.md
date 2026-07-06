# Publication and Platforms

This repository follows the official self-contained skill directory model. README files are human entry points. Runtime protocol details live under `skills/engifoundry/references/`.

## Public Files

- `README.md`: English public introduction and quick reference.
- `zh/README.md`: Chinese public introduction with equivalent content.
- `.agents/plugins/marketplace.json`: Codex Git marketplace manifest.
- `.codex-plugin/plugin.json`: Codex plugin manifest.
- `.claude-plugin/marketplace.json`: Claude Git marketplace manifest.
- `.claude-plugin/plugin.json`: Claude plugin manifest.
- `.kimi-plugin/plugin.json`: Kimi plugin manifest for direct repository installation.
- `.github/plugin/marketplace.json`: GitHub Copilot CLI marketplace manifest.
- `.github/plugin/plugin.json`: GitHub Copilot CLI plugin manifest.
- `.cursor-plugin/plugin.json`: Cursor plugin manifest.
- `.factory-plugin/marketplace.json`: Factory Droid marketplace manifest.
- `.factory-plugin/plugin.json`: Factory Droid plugin manifest.
- `skills/engifoundry-gate/`: lightweight plugin autoload gate.
- `skills/engifoundry/`: main manual skill entry point and workflow launcher.
- `examples/`: examples after the format stabilizes.
- `tests/`: repository-level validation for scripts and publishable behavior.

## Documentation Responsibilities

The README explains what EngiFoundry is, quickstart usage, high-level workflow behavior, installation and update entry points, repository contents at a glance, runtime reference location, and license status.

`skills/engifoundry-gate/SKILL.md` stays lightweight. It may inspect only first-level current-working-directory children, and it must not apply package governance.

`skills/engifoundry/SKILL.md` stays concise and operational. It is the main manual entry point and the workflow launcher after the gate matches.

The plugin package name is `engifoundry-bundle`. Do not rename the main manual skill to match the package; keeping `$engifoundry` separate from the plugin package avoids ambiguous host UI entries.

`skills/engifoundry/references/` contains agent-facing details loaded on demand.

Reference files should be focused and one level deep from `SKILL.md`. Each reference should cover one operational concern, such as artifact handling, role protocol, package format, or engineering discipline.

`skills/engifoundry/agents/` contains optional platform and tooling metadata. Core discovery must still work from `SKILL.md`.

`skills/engifoundry/scripts/` contains deterministic helper scripts that support optional workflows such as module resolution.

Generated runtime state, private notes, local experiments, and non-publishable materials must stay out of publishable files.

## Entry Points

EngiFoundry exposes two skill entry points:

```text
$engifoundry-gate
$engifoundry
```

`$engifoundry` is the main manual entry point. Users who want EngiFoundry should prefer this entry point.

`$engifoundry-gate` is the plugin autoload gate. Plugin installation should target this entry point for session-start preheating. It only decides whether EngiFoundry is available in the current workspace; it does not apply the full workflow.

The gate only decides whether the current workspace makes EngiFoundry available. It inspects only first-level current-working-directory children, treats `.git/` as a super signal, recognizes ordinary project scaffold signals such as build files, package manifests, source directories, app directories, or test directories, recognizes EngiFoundry initialization signals such as `.engifoundry.config.json`, `.engifoundry/`, and `.engifoundry-packages/`, and does not force package governance.

The canonical runtime metadata is the YAML frontmatter in `skills/engifoundry-gate/SKILL.md` and `skills/engifoundry/SKILL.md`. That frontmatter contains the required `name` and `description` fields. Platforms that support Agent Skills should be able to discover the skill from those fields.

## Platform Metadata

The Codex marketplace and plugin manifests declare the Git-hosted marketplace entry for `engifoundry-bundle`, the plugin name and interface metadata, the shared `skills/` directory, and the `engifoundry-gate` autoload gate and `engifoundry` main entry through normal skill discovery.

EngiFoundry also includes OpenAI/Codex-facing UI metadata in `skills/engifoundry/agents/openai.yaml`; this file provides display name, short description, and default prompt metadata for OpenAI surfaces that support it.

EngiFoundry also includes platform-neutral metadata in `skills/engifoundry/agents/generic.json`; this file is for humans, installers, and third-party tooling. It is not required for EngiFoundry runtime behavior.

Claude-compatible skill surfaces should use the Claude marketplace and plugin manifests when available and `SKILL.md` frontmatter as the core skill metadata source. Claude does not use Codex's `.agents/plugins/marketplace.json`.

The Kimi manifest declares the plugin package name `engifoundry-bundle`, the shared `skills/` directory, and `engifoundry-gate` as the session-start skill. Kimi-compatible usage should also rely on `SKILL.md` frontmatter, `agents/generic.json`, and public documentation in this repository.

Official Kimi marketplace search visibility is separate from repository compatibility. It depends on Kimi marketplace publication or curation outside this repository.

The GitHub Copilot plugin manifest declares the shared `skills/` directory. Runtime skill discovery still comes from `SKILL.md` frontmatter.

The Cursor manifest declares the plugin package name `engifoundry-bundle`, display and repository metadata, and the shared `skills/` directory. Cursor IDE plugin behavior and Cursor Agent CLI behavior may differ by Cursor version. Do not assume CLI parity unless the target Cursor version documents it.

The Factory manifest declares the shared `skills/` directory and does not add runtime code beyond the existing skill files.

Do not add platform-specific metadata files unless the platform has a stable schema or the repository explicitly documents the file as supported tooling metadata.

## Version Policy

Skill version is a maintenance label, not a hard execution requirement.

The canonical installable version is recorded in `skills/engifoundry/VERSION`.

The repository manifest should carry the same version in `engifoundry.manifest.json`.

Check at most once per session, during the first EngiFoundry alignment, only when network access is available. Use `check_version` scripts for this low-noise check.

If no newer version is available, say nothing. If the check fails or network is unavailable, do not mention it unless the user explicitly asks. Version checks must not block normal EngiFoundry work.

## Publishing Principles

- Do not expose local scratch paths or private notes in public documentation.
- Do not make the skill body a long specification document.
- Do not duplicate long rules across README and references.
- Keep README as a human-facing project entry point, not a protocol specification.
- Do not add platform-specific metadata files without a stable schema or an explicit adapter policy.
- Do not write module caches or resolver lockfiles into project artifact roots.
- Keep public docs readable for humans.
- Keep references actionable for agents.
- Keep generated runtime state out of publishable files.

## Installer Contract

When a user asks to install EngiFoundry from a GitHub repository, installers must prefer plugin installation if the target host supports plugins and the repository contains that host's plugin manifest.

For Codex-compatible hosts, `.agents/plugins/marketplace.json` makes the GitHub repository a marketplace, and `.codex-plugin/plugin.json` makes the repository root the `engifoundry-bundle` plugin package. A request phrased as "install the latest EngiFoundry skill from GitHub" or "install this skill: <repository URL>" should add the hosted repository as a Git marketplace and install the plugin from that marketplace, not copy `skills/engifoundry/` or maintain a local `~/plugins/` mirror as the source of truth.

Codex updates must refresh the configured Git marketplace snapshot and reinstall from that hosted marketplace. Local source directories are acceptable only as transient Codex cache output, not as maintained plugin sources.

For Claude-compatible hosts, `.claude-plugin/marketplace.json` makes the GitHub repository a Claude plugin marketplace, and `.claude-plugin/plugin.json` makes the repository root the `engifoundry-bundle` plugin package. Claude does not use `.agents/plugins/marketplace.json`; that file is Codex-specific.

For Kimi Code, `.kimi-plugin/plugin.json` makes the GitHub repository directly installable with `/plugins install https://github.com/caoyuan-fire/engi-foundry-skill`. Official Kimi marketplace search visibility is a separate publication channel and is not guaranteed by repository metadata alone.

For GitHub Copilot CLI, `.github/plugin/marketplace.json` makes the GitHub repository a plugin marketplace, and `.github/plugin/plugin.json` makes the repository root the `engifoundry-bundle` plugin package.

For Cursor-compatible hosts, `.cursor-plugin/plugin.json` declares the repository root as the `engifoundry-bundle` plugin package and exposes the shared `skills/` directory. Cursor IDE and Cursor Agent CLI parity should not be assumed unless the target Cursor version documents it.

For Factory Droid, `.factory-plugin/marketplace.json` makes the GitHub repository a Droid plugin marketplace, and `.factory-plugin/plugin.json` makes the repository root the `engifoundry-bundle` plugin package.

Skills-only installation is a fallback for hosts without plugin support or for explicit user requests for skills-only installation.

Plugin installation and skills-only installation are mutually exclusive within one host home. Do not keep plugin-provided skill entries and copied global skill entries for the same EngiFoundry version in the same host home, because the host may expose duplicate `$engifoundry-gate` and `$engifoundry` entries.

## Repository Structure

EngiFoundry uses a publishable repository layout with the installable skill under `skills/`.

Root files declare plugin marketplace metadata, plugin manifests, repository manifest, tests, examples, and localized README content.

`skills/engifoundry-gate/` is the plugin autoload gate.

`skills/engifoundry/` contains `SKILL.md`, `agents/openai.yaml`, `agents/generic.json`, `references/`, `scripts/`, and `modules/`.

The skill body should stay concise. Detailed rules belong in references.

`tests/` contains repository-level tests for deterministic helper scripts and publishable behavior.
