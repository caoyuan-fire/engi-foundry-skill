# Artifact Protocol

EngiFoundry uses a durable artifact root in the user's project.

## Project Config

The project root may contain:

```text
<project-root>/.engifoundry.config.json
```

This is the discovery entry point for EngiFoundry inside the project.

Example:

```json
{
  "schemaVersion": 1,
  "artifactRoot": ".engifoundry",
  "recordsPolicy": "durable",
  "defaultPackagePolicy": "package-when-risky"
}
```

`artifactRoot` may be relative. Use absolute paths only when the user explicitly requests them.

Do not store secrets, tokens, private session IDs, cache state, or transient runtime state in `.engifoundry.config.json`.

## Artifact Root

Default:

```text
<project-root>/.engifoundry/
```

The user may specify another path such as `MyEngiFoundry/` or `docs/engifoundry/`.

Artifact root layout:

```text
<artifact-root>/
├── execution.config.json
├── packages/
├── records/
│   ├── ad-hoc/
│   ├── reviews/
│   └── audits/
└── docs/
    └── generated/
```

The artifact root stores durable outputs only:

- task packages;
- Job contracts;
- execution records;
- review records;
- verification evidence;
- closeout records;
- ad-hoc records;
- audit records;
- generated docs with review or delivery value.

Do not write these into the artifact root:

- cache files;
- temporary files;
- session dumps;
- downloaded modules;
- raw model logs;
- secrets;
- tokens;
- private runtime state;
- transient executor state.

If an adapter needs runtime state, use an explicit external location outside the artifact root.

## Execution Config

The artifact root should contain:

```text
<artifact-root>/execution.config.json
```

This file describes executor registry and selection policy. It is durable configuration, not a secret store.

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

Executor configs describe capability and preference. They do not grant package authority.

## Git Policy

Do not silently modify `.gitignore`. The artifact root is presumed reviewable and useful unless the user says otherwise.

If users do not want EngiFoundry artifacts in version control, they may explicitly ignore their chosen artifact root.
