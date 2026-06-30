# Configuration

EngiFoundry uses two durable configuration layers:

- project-level discovery config;
- artifact-root execution config.

Neither layer may store secrets, tokens, private session IDs, cache state, or transient runtime state.

## Project Config

The project root may contain:

```text
<project-root>/.engifoundry.config.json
```

This file is the discovery entry point for EngiFoundry inside a user project.

It should be safe to commit.

Example:

```json
{
  "schemaVersion": 1,
  "artifactRoot": ".engifoundry",
  "packageRoot": ".engifoundry-packages",
  "recordsPolicy": "durable",
  "defaultPackagePolicy": "package-when-risky"
}
```

Fields:

- `schemaVersion`: config schema version.
- `artifactRoot`: output directory for durable EngiFoundry artifacts. Defaults to `.engifoundry`.
- `packageRoot`: discovery path for task packages and Job contracts. Defaults to `.engifoundry-packages`.
- `recordsPolicy`: how aggressively EngiFoundry should preserve records.
- `defaultPackagePolicy`: when EngiFoundry should prefer package mode over ad-hoc mode.

`artifactRoot` and `packageRoot` may be relative paths. Absolute paths should be used only when the user explicitly requests them.

Project config is a discovery and alignment aid. It should not be treated as a mandatory read before every ad-hoc task. Read it when locating artifact or package roots, resuming package flow, writing durable records, or aligning a new session to project workflow state.

Do not store Git ignore state in project config. Whether the package root is versioned comes from Git behavior, especially `.gitignore` and `git status`.

Do not store roadmap state in project config. The project config locates the artifact root; roadmap state belongs to `<artifact-root>/roadmaps/ROADMAP.md` and `<artifact-root>/roadmaps/roadmap.index.json`.

## Artifact Root Config

The artifact root should contain:

```text
<artifact-root>/execution.config.json
```

This file describes executor registry and selection policy.

It is part of the durable EngiFoundry protocol and should be safe to commit.

Example:

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
    }
  },
  "selectionPolicy": {
    "prefer": ["multi-session"],
    "fallback": "direct"
  }
}
```

Fields:

- `schemaVersion`: config schema version.
- `defaultExecutor`: preferred executor key.
- `executors`: registry of available executor mechanisms.
- `selectionPolicy`: priority and fallback behavior.

Executor configs describe capability and preference. They do not grant package authority by themselves.
