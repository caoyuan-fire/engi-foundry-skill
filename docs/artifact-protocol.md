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
