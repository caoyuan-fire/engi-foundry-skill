# Package and Job Format

EngiFoundry separates human narrative from machine control.

Markdown explains. JSON controls.

JSON must not duplicate long Markdown narratives. Markdown must not be treated as the authoritative machine-control source.

## Package Layout

Package layout:

```text
packages/<package-id>/
├── summary.md
├── package.config.json
├── jobs/
│   └── JOB-001/
│       ├── job.md
│       ├── job.config.json
│       ├── record.md
│       ├── review.md
│       └── verification.md
├── checkpoints/
├── handoffs/
└── closeout.md
```

## `summary.md`

`summary.md` is human-only. It is not the machine-control source.

It explains:

- package background;
- purpose;
- scope;
- non-goals;
- current state;
- target state;
- Job overview;
- risks;
- acceptance criteria;
- closeout requirements.

It may include a Job overview table, but the table is only a readable summary.

## `package.config.json`

`package.config.json` is machine-readable. It defines package status, Job order, defaults, checkpoints, and acceptance gates.

It should record:

- `schemaVersion`;
- `packageId`;
- status;
- Job list;
- Job order and dependencies;
- default execution policy;
- acceptance gates;
- checkpoint references;
- handoff references;
- closeout requirements.

## Job Layout

Each Job is a directory:

```text
jobs/JOB-001/
├── job.md
├── job.config.json
├── record.md
├── review.md
└── verification.md
```

`job.md` is human-readable. It defines semantic intent, background, goal, scope, non-goals, business meaning, risks, acceptance criteria, and implementation notes.

`job.config.json` is machine-readable. It defines:

- `schemaVersion`;
- `jobId`;
- status;
- dependencies;
- allowed areas;
- forbidden areas;
- execution policy;
- verification commands;
- output contract;
- required outputs;
- review requirement.

`record.md` is the executor's execution record. Include actual work summary, changed areas, verification evidence, deviations, remaining risks, and follow-up recommendations. Do not dump raw long logs.

`review.md` is reviewer output. Include result (`pass`, `blocked`, or `needs-rework`), findings, evidence, affected acceptance criteria, required rework, and follow-up review requirements.

`verification.md` records validation commands, context, pass/fail result, failure details, non-runnable reasons, and alternative evidence.

## Execution Policy

Example Job execution policy:

```json
{
  "executor": "multi-session",
  "isolation": "isolated-execution",
  "discipline": "standard",
  "reviewRequired": true,
  "reviewer": "clean-session"
}
```

`quick`, `standard`, and `strict` are discipline presets, not executor identities.

Execution has three dimensions:

```text
executor   = who or what performs the work
isolation  = how separated the execution/review context is
discipline = quality preset
```

Package defaults belong in `package.config.json`. Job overrides belong in `job.config.json`.

## Checkpoints and Handoffs

Checkpoints record package state at pause points: completed Jobs, pending Jobs, package status, blocking issues, verification status, review status, next step, and open primary-only decisions.

Handoffs prepare another session, tool, or human to continue. They should state package id, current status, completed work, incomplete work, next entry point, recommended role, and primary-only decisions.

Checkpoints and handoffs support role recovery but do not permanently bind control authority to any product.
