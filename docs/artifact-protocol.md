# Artifact Protocol

EngiFoundry writes durable work products to an artifact root inside the user's project.

The artifact root and package root have different purposes. The artifact root is for durable work products. The package root is for execution inputs and package roadmaps.

## Artifact Root

The default artifact root is:

```text
<project-root>/.engifoundry/
```

Users may choose another path, such as:

```text
<project-root>/MyEngiFoundry/
<project-root>/docs/engifoundry/
```

The selected path is recorded in `.engifoundry.config.json` at the project root.

The artifact root is not a runtime workspace, cache directory, or scratch area. It exists to preserve inspectable engineering artifacts.

The artifact root is for durable work products such as execution records, review records, verification evidence, closeout records, audit records, and generated docs with delivery value. It is not the default home for work-state task packages or package roadmaps.

## Roadmaps

Roadmaps are package-flow planning inputs. They capture agreed planning, requirement alignment, sequencing decisions, and next-step intent.

The package root may contain a master roadmap for cross-phase planning:

```text
<package-root>/
└── ROADMAP.md
```

The master roadmap may cover multiple phases and should capture long-range direction, boundaries, phase sequence, and cross-phase dependencies.

Phases may contain sub-roadmaps:

```text
<package-root>/PHASE-001/
└── ROADMAP.md
```

Phase roadmaps should capture the executable view for that phase, including additional phase-local load that does not change the master roadmap direction.

Do not mechanically create one phase directory per phase merely because the master roadmap mentions multiple phases. Create `PHASE-*` directories when a phase is being refined, packaged, executed, handed off, or used as current decision input.

`ROADMAP.md` exists only when planning or alignment produced one. Projects without a meaningful phase concept use `PHASE-001` for executable phase work.

When discussion or alignment produces roadmap content, EngiFoundry should decide where to store it from project facts and conversation content. Do not require the user to explicitly say whether the roadmap is master-level or phase-level.

Default to the package-root `ROADMAP.md` when there is no strong evidence that the discussion belongs to a specific phase. This keeps broad alignment as the master plan until execution context narrows it.

Create or update a phase `ROADMAP.md` when known facts or conversation content show that the discussion is extending a specific phase. Strong signals include an existing progressing phase, a latest completed phase being extended, an explicitly pending phase, active package or Job work under that phase, or discussion framed around carrying forward from a completed/progressing/pending phase.

Use the discussion content as evidence. Future direction, cross-phase sequencing, broad scope boundaries, or long-range dependency planning usually belongs in the master roadmap. Execution detail, phase-local load, refinements to current phase scope, or work derived from the latest completed/progressing/pending phase usually belongs in that phase roadmap.

Ask the user only when local facts and conversation evidence conflict or when choosing the wrong roadmap would materially change execution scope.

When the user asks what to do next, asks to confirm the next step, or requests an engineering decision that depends on prior alignment, EngiFoundry should check the relevant phase for `ROADMAP.md` first. If no phase roadmap exists, check `<package-root>/ROADMAP.md` for the relevant phase section. If no roadmap exists, decide from the current session context, visible project state, and the user's stated goal.

Do not store roadmap state in `.engifoundry.config.json`. The project config locates the package root. Package-root and phase `ROADMAP.md` files are the source of truth for roadmap state.

## Package Root

The package root stores phase roadmaps, task packages, Job contracts, and other package-flow control inputs.

The default package root is:

```text
<project-root>/.engifoundry-packages/
```

Users may choose another package root. If `.engifoundry.config.json` exists, it may record `packageRoot` as a discovery hint, but Git ignore state does not belong in the project config.

Do not store Git ignore state in `.engifoundry.config.json`. Git is the source of truth for whether packages are versioned.

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

## Allowed Contents

The artifact root may contain:

- execution records;
- review records;
- verification evidence;
- closeout records;
- ad-hoc records;
- audit records;
- generated docs with review or delivery value.

## Forbidden Contents

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

If an adapter needs runtime state, it must use an explicit external location outside the artifact root.

## Standard Layout

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
| `<package-root>/ROADMAP.md` | Planning input | Master roadmap for cross-phase direction, boundaries, sequencing, and dependencies when one exists. | Execution records, verification evidence, reviews, raw logs. |
| `<package-root>/PHASE-001/ROADMAP.md` | Planning input | Phase sub-roadmap for executable phase planning and phase-local load when one exists. | Execution records, verification evidence, reviews, raw logs. |
| `<package-root>/PHASE-001/PAK-001/` | Execution input | Task package summary, package control JSON, Job contracts, and package-flow control data. | Execution records, reviews, verification evidence, closeout notes, raw logs. |

Ad-hoc, review-only, and audit work may write records under `records/` when the output has durable value.

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

Package-flow execution inputs live under the package root:

```text
<package-root>/
├── ROADMAP.md
└── PHASE-001/
    ├── ROADMAP.md
    └── PAK-001/
        ├── summary.md
        ├── package.config.json
        └── jobs/
```

Package execution outputs with durable value, such as Job records, reviews, verification evidence, checkpoints, handoff summaries, and closeout notes, belong in the artifact root as records.

## Git Policy

EngiFoundry must not silently modify `.gitignore` for the artifact root.

The artifact root should not be ignored by default because it contains durable work products, not temporary files.

If users do not want EngiFoundry artifacts in version control, they may explicitly ignore their chosen artifact root.

EngiFoundry may explain the tradeoff, but it must not apply the ignore rule without user approval.

The package root is different. EngiFoundry may automatically add the package root to `.gitignore` because phase roadmaps and packages are planning and execution inputs by default. Tell the user only when the ignore rule is first added.

Use a recognizable block when EngiFoundry writes the ignore rule:

```gitignore
# BEGIN EngiFoundry package root
.engifoundry-packages/
# END EngiFoundry package root
```

If the user explicitly asks to version task packages, remove the EngiFoundry package-root ignore block when it exists. If the user manually edits `.gitignore`, respect the resulting Git behavior. A package root that appears in `git status` may be treated as versioned; a package root ignored by Git remains local execution state.
