# Package Format

EngiFoundry packages separate human narrative from machine control.

Markdown explains. JSON controls.

## Directory Layout

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

## Package Rules

- A package is both human-readable and machine-readable.
- A package is execution input by default and lives under the package root, not the artifact root.
- Execution records, reviews, verification evidence, and closeout notes are durable outputs and live under the artifact root.
- Markdown files carry human meaning and review context.
- JSON files carry machine-readable control data.
- JSON must not duplicate long Markdown narratives.
- Markdown must not be treated as the authoritative machine-control source.
- Package governance only applies after work enters a package flow; bounded low-risk `ad-hoc` work does not need package artifacts.

## `summary.md`

`summary.md` is for humans only.

It should explain:

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

It may include a Job overview table:

```markdown
| Job | Purpose | Depends On | Discipline | Status |
| --- | --- | --- | --- | --- |
```

The table is a readable summary. It is not authoritative configuration.

`summary.md` should also state the package reading entrypoint, current state, and next expected action when another session, tool, or human may continue the work.

## `package.config.json`

`package.config.json` is the machine-readable package contract.

It should record:

- `schemaVersion`;
- `packageId`;
- package planning status;
- package execution status;
- Job list;
- Job order and dependencies;
- default execution policy;
- acceptance gates;
- checkpoint references;
- handoff references;
- closeout requirements.
- handoff entrypoint;
- required reader acknowledgement;

Example:

```json
{
  "schemaVersion": 1,
  "packageId": "pkg-example",
  "planning": {
    "status": "draft"
  },
  "execution": {
    "status": "not-started"
  },
  "jobs": ["JOB-001", "JOB-002"],
  "jobOrder": [
    {
      "jobId": "JOB-001",
      "dependsOn": []
    },
    {
      "jobId": "JOB-002",
      "dependsOn": ["JOB-001"]
    }
  ],
  "defaultExecutionPolicy": {
    "executor": "multi-session",
    "isolation": "isolated-execution",
    "discipline": "standard",
    "reviewRequired": true
  },
  "acceptance": {
    "requiresAllJobsApproved": true,
    "requiresVerificationEvidence": true,
    "requiresCloseout": true
  }
}
```

## Reader Acknowledgement

Reader Acknowledgement only applies after work enters a package flow.

Before executor or reviewer work starts on a package or Job, the session should acknowledge that it has read the relevant package summary, package config, Job config, dependencies, allowed areas, forbidden areas, stop conditions, and verification requirements.

The acknowledgement does not grant extra authority. It confirms the reader understands the package-first contract before acting.

`package.config.json` may record acknowledgement requirements in a compact form, for example:

```json
{
  "handoff": {
    "entrypoint": "summary.md",
    "requiredAcknowledgement": [
      "package-summary",
      "package-config",
      "job-config",
      "allowed-and-forbidden-areas",
      "verification"
    ]
  }
}
```

## Package Alignment Gate

Package Alignment Gate only applies after work enters a package flow.

A package records only two status dimensions: `planning.status` and `execution.status`. Do not add `alignmentStatus`, `alignmentRequired`, or `alignmentPassed` to the package state model.

When the user asks to create, compile, or prepare a task package, primary/control must treat `planning.status=ready` as the target state for the same request. Do not stop at `planning.status=draft` to ask whether alignment should run. Draft is an intermediate writing state, not a normal completion state for an explicit package compilation request.

Before setting or reporting `planning.status=ready`, primary/control must evaluate whether Package Alignment Gate is required.

Package alignment is a hard gate for reporting package planning as ready when any of these conditions are true:

- any Job uses an executor other than `direct`;
- any Job uses isolated execution or isolated review;
- the package is intended for external CLI execution, reviewer handoff, human handoff, later session execution, or other bounded execution;
- the package touches cross-module behavior, build behavior, AIDL or interface contracts, release behavior, security-sensitive behavior, data-sensitive behavior, or target-device behavior;
- the verification path is unclear, non-runnable, target-dependent, or depends on evidence that cannot be produced in the current planning session;
- any known ambiguity or unresolved dependency exists.

If Package Alignment Gate is required, primary/control self-review is not sufficient evidence. The package must receive an independent alignment review from the configured executor, reviewer, clean session, external CLI, or human reviewer before planning may be marked ready.

For an explicit package compilation request, primary/control must automatically drive the required alignment work in the same turn when a usable reviewer, clean session, external CLI, or configured executor is available. If alignment finds blocking issues, primary/control must revise the package and rerun alignment until the package can be marked `ready` or a real blocker remains.

When Package Alignment Gate is required and no independent alignment review has passed, primary/control must not write `planning.status=ready`, report the package as ready, report package planning as complete, or describe the package as compiled. Keep `planning.status` as `draft` or set it to `blocked`.

Stopping at `draft` is only acceptable when a concrete blocker prevents a ready package, such as missing requirements that cannot be inferred, unavailable required reviewer capability, a failed alignment review that cannot be resolved without user or external input, or an explicit user instruction to leave the package as draft.

Package alignment is optional for simple direct packages and does not apply to `ad-hoc` work with no package.

Alignment evidence is recorded as review evidence. Alignment records should capture reviewer identity, reviewer role, reviewed files, understanding restatement, findings, required package revisions, accepted non-blocking risks, pass/block decision, and primary/control decision.

Alignment records are review records, not Jobs. Do not add package alignment as a synthetic Job in the Job order.

A package may be reported as compiled only after `planning.status` can be set to `ready`. If package alignment finds blocking issues, keep `planning.status` as `draft` or set it to `blocked`, revise the package, and do not report package planning as complete.

Package execution start must check `planning.status=ready`. It must not defer required package alignment to execution startup.

## Checkpoints and Handoffs

Checkpoints record package state at a pause point.

Handoffs prepare another session, tool, or human to continue.

These files support role recovery but do not permanently bind control authority to any product.

## Closeout

`closeout.md` records final acceptance, remaining risks, verification status, and handoff notes for future work.
