# Configuration

TaskForge uses two durable configuration layers:

- project-level discovery config;
- artifact-root execution config.

Neither layer may store secrets, tokens, private session IDs, cache state, or transient runtime state.

## Project Config

The project root may contain:

```text
<project-root>/.taskforge.config.json
```

This file is the discovery entry point for TaskForge inside a user project.

It should be safe to commit.

Example:

```json
{
  "schemaVersion": 1,
  "artifactRoot": ".taskforge",
  "recordsPolicy": "durable",
  "defaultPackagePolicy": "package-when-risky"
}
```

Fields:

- `schemaVersion`: config schema version.
- `artifactRoot`: output directory for durable TaskForge artifacts. Defaults to `.taskforge`.
- `recordsPolicy`: how aggressively TaskForge should preserve records.
- `defaultPackagePolicy`: when TaskForge should prefer package mode over ad-hoc mode.

`artifactRoot` may be a relative path. Absolute paths should be used only when the user explicitly requests them.

## Artifact Root Config

The artifact root should contain:

```text
<artifact-root>/execution.config.json
```

This file describes executor registry and selection policy.

It is part of the durable TaskForge protocol and should be safe to commit.

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
