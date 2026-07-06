# Artifact Root

EngiFoundry writes durable work products to an artifact root inside the user's project.

The artifact root and package root have different purposes. The artifact root is for durable work products. The package root is for execution inputs and package roadmaps.

## Project Config

The project root may contain:

```text
<project-root>/.engifoundry.config.json
```

This file is the discovery entry point for EngiFoundry inside a user project.

It should be safe to commit.

Fields:

- `schemaVersion`: config schema version.
- `artifactRoot`: output directory for durable EngiFoundry artifacts. Defaults to `.engifoundry`.
- `packageRoot`: discovery path for task packages and Job contracts. Defaults to `.engifoundry-packages`.
- `recordsPolicy`: how aggressively EngiFoundry should preserve records.
- `defaultPackagePolicy`: when EngiFoundry should prefer package mode over ad-hoc mode.

`artifactRoot` and `packageRoot` may be relative paths. Absolute paths should be used only when the user explicitly requests them.

Do not store Git ignore state in `.engifoundry.config.json`. Git is the source of truth for whether packages are versioned.

Do not store secrets, tokens, private session IDs, cache state, roadmap state, or transient runtime state in `.engifoundry.config.json`.

Project config is a discovery and alignment aid. It should not be treated as a mandatory read before every ad-hoc task. Read it when locating artifact or package roots, resuming package flow, writing durable records, or aligning a new session to project workflow state.

## Automatic Initialization

EngiFoundry supports lazy automatic initialization.

If EngiFoundry workflow starts in a project with no `.engifoundry.config.json`, artifact root, or package root, initialize the default project config, artifact root, directory config, and package root automatically before the first durable EngiFoundry read or write.

Do not require the user to request "initialize EngiFoundry" as a separate step before planning, package creation, roadmap use, execution records, reviews, verification records, or closeout records.

Use the default paths unless the user specified alternatives:

- artifact root: `.engifoundry/`;
- package root: `.engifoundry-packages/`.

Prefer the provided initialization scripts for this setup:

1. `create_root_config`
2. `create_standard_dirs`
3. `create_directory_config`

Ask before initializing only when the default paths are unsafe or ambiguous, such as an existing conflicting file, a path collision, missing write permission, or an explicit user instruction not to create EngiFoundry artifacts.

EngiFoundry provides functional initialization scripts for macOS, Linux, and Windows. They do not require Python. Use POSIX shell scripts on macOS and Linux, and PowerShell scripts on Windows.

Templates are formal editable files. They are not examples or reference snippets; they are pre-generated standard files intended to be edited and committed when appropriate.

## Artifact Root Layout

The default artifact root is:

```text
<project-root>/.engifoundry/
```

Users may choose another path. The selected path is recorded in `.engifoundry.config.json` at the project root.

The artifact root is not a runtime workspace, cache directory, or scratch area. It exists to preserve inspectable engineering artifacts.

The artifact root is for durable work products such as execution records, review records, verification evidence, closeout records, audit records, and generated docs with delivery value. It is not the default home for work-state task packages or package roadmaps.

The artifact root may contain:

- execution records;
- review records;
- verification evidence;
- closeout records;
- ad-hoc records;
- audit records;
- generated docs with review or delivery value.

The artifact root must not contain:

- cache files;
- temporary files;
- session dumps;
- downloaded modules;
- raw model logs;
- secrets;
- tokens;
- private runtime state;
- transient executor state.

Do not write cache files, temporary files, session dumps, downloaded modules, raw model logs, secrets, tokens, private runtime state, or transient executor state into the artifact root.

If an adapter needs runtime state, it must use an explicit external location outside the artifact root.

Standard layout:

```text
<artifact-root>/
├── execution.config.json
├── directory.config.json
├── records/
│   ├── ad-hoc/
│   ├── packages/
│   ├── reviews/
│   └── audits/
└── docs/
    ├── generated/
    ├── integration/
    ├── design/
    ├── reference/
    └── archive/
```

## Package Root

The package root stores the phase registry, phase roadmaps, task packages, Job contracts, and other package-flow control inputs.

The default package root is:

```text
<project-root>/.engifoundry-packages/
```

Users may choose another package root. If `.engifoundry.config.json` exists, it may record `packageRoot` as a discovery hint, but Git ignore state does not belong in the project config.

The package root is for execution inputs: task packages, Job contracts, package-flow control data, phase registries, and roadmaps.

Package-flow execution inputs live under the package root:

```text
<package-root>/
├── phase.index.json
├── ROADMAP.md
└── PHASE-001/
    ├── phase.config.json
    ├── ROADMAP.md
    └── PAK-001/
        ├── summary.md
        ├── package.config.json
        └── jobs/
```

Package execution outputs with durable value, such as Job records, reviews, verification evidence, checkpoints, handoff summaries, and closeout notes, belong in the artifact root as records.

Package-flow durable outputs live under:

```text
<artifact-root>/records/packages/PHASE-001/PAK-001/
├── jobs/
│   └── JOB-001/
│       ├── record.md
│       ├── review.md
│       └── verification.md
├── checkpoints/
├── handoffs/
└── closeout.md
```

## Directory Function Table

| Path | Category | Purpose | Must Not Contain |
| --- | --- | --- | --- |
| `<project-root>/.engifoundry.config.json` | Project discovery config | Locates EngiFoundry roots and durable workflow defaults for session alignment. | Secrets, tokens, runtime state, Git ignore state, roadmap state. |
| `<artifact-root>/execution.config.json` | Artifact-root execution config | Records executor registry and selection policy. | Secrets, tokens, package authority grants, transient executor state. |
| `<artifact-root>/directory.config.json` | Artifact-root directory config | Records the standard directory taxonomy as a formal editable file. | Runtime state, secrets, task package content, raw logs. |
| `<artifact-root>/records/ad-hoc/` | Durable output | Records from bounded low-risk work that did not enter package flow. | Task package control inputs, caches, session dumps. |
| `<artifact-root>/records/packages/PHASE-001/PAK-001/` | Durable output | Package-flow execution records, reviews, verification evidence, checkpoints, handoffs, and closeout notes. | Package root control inputs unless copied as explicit evidence; raw long logs; private state. |
| `<artifact-root>/records/reviews/` | Durable output | Review-only records that are not owned by a specific package record tree. | Implementation scratch files, task package control inputs, secrets. |
| `<artifact-root>/records/audits/` | Durable output | Process, cost, quality, migration, policy, and workflow retrospective records. | Runtime cache, downloaded modules, unreviewable session dumps. |
| `<artifact-root>/docs/generated/` | Durable output | Generated documents with review, delivery, or handoff value. | Cache output, throwaway drafts, raw model logs. |
| `<artifact-root>/docs/integration/` | Durable output | Host integration, API integration, installation, and adapter-facing user documentation. | Executor runtime state, package control JSON. |
| `<artifact-root>/docs/design/` | Durable output | Architecture, UX, data-flow, test-strategy, and domain design documents. | Temporary scratch notes, raw chat transcripts. |
| `<artifact-root>/docs/reference/` | Durable input reference | External or upstream reference material used as context for decisions. | Secrets, credentials, downloaded dependency caches. |
| `<artifact-root>/docs/archive/` | Durable output archive | Historical documents that remain useful as readable background but are not current records. | Active package contracts, cache files. |
| `<package-root>/phase.index.json` | Execution input | Machine-readable phase registry, mainline order, extension links, statuses, and next unallocated phase id. | Execution records, verification evidence, reviews, raw logs. |
| `<package-root>/ROADMAP.md` | Planning input | Master roadmap for cross-phase direction, boundaries, sequencing, and dependencies when one exists. | Execution records, verification evidence, reviews, raw logs. |
| `<package-root>/PHASE-001/phase.config.json` | Execution input | Machine-readable phase contract and status for one phase. | Execution records, verification evidence, reviews, raw logs. |
| `<package-root>/PHASE-001/ROADMAP.md` | Planning input | Phase sub-roadmap for executable phase planning and phase-local load when one exists. | Execution records, verification evidence, reviews, raw logs. |
| `<package-root>/PHASE-001/PAK-001/` | Execution input | Task package summary, package control JSON, Job contracts, and package-flow control data. | Execution records, reviews, verification evidence, closeout notes, raw logs. |

Ad-hoc, review-only, and audit work may write records under `records/` when the output has durable value.

## Git Policy

EngiFoundry must not silently modify `.gitignore` for the artifact root.

The artifact root should not be ignored by default because it contains durable work products, not temporary files.

If users do not want EngiFoundry artifacts in version control, they may explicitly ignore their chosen artifact root.

EngiFoundry may explain the tradeoff, but it must not apply the artifact-root ignore rule without user approval.

The package root is different. EngiFoundry may automatically add the package root to `.gitignore` because phase roadmaps and packages are planning and execution inputs by default. Tell the user only when the ignore rule is first added.

Use a recognizable block when EngiFoundry writes the ignore rule:

```gitignore
# BEGIN EngiFoundry package root
.engifoundry-packages/
# END EngiFoundry package root
```

If the user explicitly asks to version task packages, remove the EngiFoundry package-root ignore block when it exists. If the user manually edits `.gitignore`, respect the resulting Git behavior. A package root that appears in `git status` may be treated as versioned; a package root ignored by Git remains local execution state.
