# Artifact Protocol

EngiFoundry uses a durable artifact root in the user's project.

The artifact root and package root have different purposes. The artifact root is for durable work products. The package root is for execution inputs.

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
  "packageRoot": ".engifoundry-packages",
  "recordsPolicy": "durable",
  "defaultPackagePolicy": "package-when-risky"
}
```

`artifactRoot` and `packageRoot` may be relative. Use absolute paths only when the user explicitly requests them.

Do not store Git ignore state in `.engifoundry.config.json`. Git is the source of truth for whether packages are versioned.

Do not store secrets, tokens, private session IDs, cache state, or transient runtime state in `.engifoundry.config.json`.

Project config is a discovery and alignment aid. It should not be treated as a mandatory read before every ad-hoc task. Read it when locating artifact or package roots, resuming package flow, writing durable records, or aligning a new session to project workflow state.

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
├── roadmaps/
│   ├── ROADMAP.md
│   ├── roadmap.index.json
│   └── archive/
├── records/
│   ├── ad-hoc/
│   ├── packages/
│   ├── reviews/
│   └── audits/
└── docs/
    └── generated/
```

The artifact root stores durable outputs only:

- execution records;
- review records;
- verification evidence;
- closeout records;
- ad-hoc records;
- audit records;
- roadmap archives;
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

## Roadmaps

ROADMAP archives are durable alignment artifacts. They capture agreed planning, requirement alignment, sequencing decisions, and next-step intent that may guide the current session or a later session.

Roadmaps live under the artifact root:

```text
<artifact-root>/roadmaps/
├── ROADMAP.md
├── roadmap.index.json
└── archive/
```

`ROADMAP.md` is the current roadmap. `roadmap.index.json` is the artifact-root-local roadmap index and may record `schemaVersion`, `current`, `updatedAt`, `source`, and whether the current roadmap should be considered active input for planning decisions.

Create or update a ROADMAP archive when the user has performed requirement alignment, planning, roadmap, or pre-task discussion and asks to persist, archive, save, land, or use it as later execution input.

When the user asks what to do next, asks to confirm the next step, or requests an engineering decision that depends on prior alignment, EngiFoundry should check the artifact root for an active roadmap. If a roadmap exists, use it as decision input together with current progress. If no roadmap exists, decide from the current session context, visible project state, and the user's stated goal.

Do not store roadmap state in `.engifoundry.config.json`. The project config locates the artifact root. The roadmap files and `roadmap.index.json` are the source of truth for roadmap state.

Package-flow durable outputs live under:

```text
<artifact-root>/records/packages/<package-id>/
├── jobs/
│   └── JOB-001/
│       ├── record.md
│       ├── review.md
│       └── verification.md
├── checkpoints/
├── handoffs/
└── closeout.md
```

## Package Root

Default:

```text
<project-root>/.engifoundry-packages/
```

The package root stores execution inputs:

- task packages;
- Job contracts;
- package-flow control data.

Package root layout:

```text
<package-root>/
└── <package-id>/
    ├── summary.md
    ├── package.config.json
    └── jobs/
```

Package execution outputs with durable value belong in the artifact root as records.

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

Do not silently modify `.gitignore` for the artifact root. The artifact root is presumed reviewable and useful unless the user says otherwise.

If users do not want EngiFoundry artifacts in version control, they may explicitly ignore their chosen artifact root.

EngiFoundry may automatically add the package root to `.gitignore` because packages are execution inputs by default. Tell the user only when the ignore rule is first added.

Use a recognizable block when EngiFoundry writes the ignore rule:

```gitignore
# BEGIN EngiFoundry package root
.engifoundry-packages/
# END EngiFoundry package root
```

If the user explicitly asks to version task packages, remove the EngiFoundry package-root ignore block when it exists. If the user manually edits `.gitignore`, respect the resulting Git behavior. A package root that appears in `git status` may be treated as versioned; a package root ignored by Git remains local execution state.
