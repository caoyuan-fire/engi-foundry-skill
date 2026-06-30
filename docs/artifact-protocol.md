# Artifact Protocol

EngiFoundry writes durable work products to an artifact root inside the user's project.

The artifact root and package root have different purposes. The artifact root is for durable work products. The package root is for execution inputs.

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

The artifact root is for durable work products such as execution records, review records, verification evidence, closeout records, audit records, and generated docs with delivery value. It is not the default home for work-state task packages.

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

## Package Root

The package root stores task packages, Job contracts, and other package-flow control inputs.

The default package root is:

```text
<project-root>/.engifoundry-packages/
```

Users may choose another package root. If `.engifoundry.config.json` exists, it may record `packageRoot` as a discovery hint, but Git ignore state does not belong in the project config.

Do not store Git ignore state in `.engifoundry.config.json`. Git is the source of truth for whether packages are versioned.

Project config is a discovery and alignment aid. It should not be treated as a mandatory read before every ad-hoc task. Read it when locating artifact or package roots, resuming package flow, writing durable records, or aligning a new session to project workflow state.

## Allowed Contents

The artifact root may contain:

- execution records;
- review records;
- verification evidence;
- closeout records;
- ad-hoc records;
- audit records;
- roadmap archives;
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

Ad-hoc, review-only, and audit work may write records under `records/` when the output has durable value.

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

Package-flow execution inputs live under the package root:

```text
<package-root>/
└── <package-id>/
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

The package root is different. EngiFoundry may automatically add the package root to `.gitignore` because packages are execution inputs by default. Tell the user only when the ignore rule is first added.

Use a recognizable block when EngiFoundry writes the ignore rule:

```gitignore
# BEGIN EngiFoundry package root
.engifoundry-packages/
# END EngiFoundry package root
```

If the user explicitly asks to version task packages, remove the EngiFoundry package-root ignore block when it exists. If the user manually edits `.gitignore`, respect the resulting Git behavior. A package root that appears in `git status` may be treated as versioned; a package root ignored by Git remains local execution state.
