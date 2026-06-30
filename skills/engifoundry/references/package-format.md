# Package and Job Format

EngiFoundry separates human narrative from machine control.

Markdown explains. JSON controls.

JSON must not duplicate long Markdown narratives. Markdown must not be treated as the authoritative machine-control source.

Package governance only applies after work enters a package flow; bounded low-risk `ad-hoc` work does not need package artifacts.

A package is execution input by default and lives under the package root, not the artifact root.

Execution records, reviews, verification evidence, and closeout notes are durable outputs and live under the artifact root.

## Package Layout

Package layout:

```text
<package-root>/<package-id>/
├── summary.md
├── package.config.json
└── jobs/
    └── JOB-001/
        ├── job.md
        └── job.config.json
```

Package-flow durable outputs use the package records area:

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

`summary.md` should also state the package reading entrypoint, current state, and next expected action when another session, tool, or human may continue the work.

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
- handoff entrypoint;
- required reader acknowledgement.

## Reader Acknowledgement

Reader Acknowledgement only applies after work enters a package flow.

Before executor or reviewer work starts on a package or Job, the session should acknowledge that it has read the relevant package summary, package config, Job config, dependencies, allowed areas, forbidden areas, stop conditions, and verification requirements.

The acknowledgement confirms understanding. It does not grant primary/control authority.

`package.config.json` may record `handoff.entrypoint` and `handoff.requiredAcknowledgement`.

## Package Alignment Gate

Package Alignment Gate only applies after work enters a package flow.

Package alignment is required before implementation starts when the package uses isolated executors or reviewers, external CLI execution, human handoff, cross-module or high-risk work, security-sensitive work, data-sensitive work, release-sensitive work, unclear verification, or known ambiguity.

Package alignment is optional for simple direct packages and does not apply to `ad-hoc` work with no package.

Alignment records are review records. They capture reviewer role, understanding restatement, findings, required package revisions, accepted non-blocking risks, and primary/control decision.

Alignment records are review records, not Jobs. Do not add package alignment as a synthetic Job in the Job order.

## Job Layout

Each Job has control inputs under the package root:

```text
<package-root>/<package-id>/jobs/JOB-001/
├── job.md
└── job.config.json
```

Each Job has durable outputs under the artifact root:

```text
<artifact-root>/records/packages/<package-id>/jobs/JOB-001/
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
- `type`: `delegable | primary-control-only | review-only | blocked`;
- `stopConditions`;
- `requiredReturnFormat`;
- delegation or primary-execution reason when relevant.

Executor completion does not complete the Job. A Job is complete only after required records, verification evidence, review, and primary/control approval are consistent with the package contract.

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
