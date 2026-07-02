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
<package-root>/
├── ROADMAP.md
└── PHASE-001/
    ├── ROADMAP.md
    └── PAK-001/
        ├── summary.md
        ├── package.config.json
        └── jobs/
            └── JOB-001/
                ├── job.md
                └── job.config.json
```

The package-root `ROADMAP.md` is an optional master roadmap for cross-phase planning. It may cover multiple phases and should capture the long-range direction, boundaries, phase sequence, and cross-phase dependencies.

Phase `ROADMAP.md` files are optional phase sub-roadmaps. They should capture the executable view for that phase, including additional phase-local load that does not change the master roadmap direction.

Do not mechanically create one phase directory per phase merely because the master roadmap mentions multiple phases. Create `PHASE-*` directories when a phase is being refined, packaged, executed, handed off, or used as current decision input.

When roadmap alignment produces content and the target is not explicitly stated, Agent should infer the storage target from package-root facts and conversation content. Default to the package-root `ROADMAP.md` unless there is strong evidence that the discussion is extending a specific existing, progressing, latest completed, or pending phase.

When executing or planning inside a phase, prefer `<package-root>/PHASE-001/ROADMAP.md` when it exists. If it does not exist, use the relevant section of `<package-root>/ROADMAP.md` when present.

Package layout:

```text
<package-root>/PHASE-001/
├── ROADMAP.md
└── PAK-001/
    ├── summary.md
    ├── package.config.json
    └── jobs/
        └── JOB-001/
            ├── job.md
            └── job.config.json
```

`PHASE-001` is the default phase when a project has no meaningful phase or schedule concept. Longer engineering efforts may continue with `PHASE-002`, `PHASE-003`, and so on.

`PAK-001` is the package identifier. Package identifiers must use the `PAK-001` sequence format within a phase. Human-readable names may appear as package titles or slugs, but machine references should use the numbered package id.

Job identifiers must use the `JOB-001` sequence format within a package.

The full package reference is the phase id plus the package id, for example `PHASE-001/PAK-001`. A bare `packageId` is scoped to its phase.

Legacy packages at `<package-root>/<package-id>/jobs/JOB-001/` may be read as `PHASE-001/<package-id>/jobs/JOB-001/` for compatibility, but new packages should use the phase/package layout.

If phase-level planning happened, the phase may contain a roadmap:

```text
<package-root>/PHASE-001/ROADMAP.md
```

`ROADMAP.md` is package-flow planning input, not an execution record. A master roadmap exists only when cross-phase planning produced one. A phase roadmap exists only when planning or alignment produced one for that phase.

Package-flow durable outputs use the package records area:

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

Legacy durable outputs at `<artifact-root>/records/packages/<package-id>/` may be read for compatibility.

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

`package.config.json` is machine-readable. It defines package planning status, package execution status, Job order, defaults, checkpoints, and acceptance gates.

It should record:

- `schemaVersion`;
- `phaseId`;
- `packageId`;
- optional package title or slug;
- planning status;
- execution status;
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

Before executor or reviewer work starts on a package or Job, the session should acknowledge that it has read the relevant phase roadmap when present, package summary, package config, Job config, dependencies, allowed areas, forbidden areas, stop conditions, and verification requirements.

The acknowledgement confirms understanding. It does not grant primary/control authority.

`package.config.json` may record `handoff.entrypoint` and `handoff.requiredAcknowledgement`.

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

Alignment evidence is recorded as review evidence. Alignment records capture reviewer identity, reviewer role, reviewed files, understanding restatement, findings, required package revisions, accepted non-blocking risks, pass/block decision, and primary/control decision.

Alignment records are review records, not Jobs. Do not add package alignment as a synthetic Job in the Job order.

A package may be reported as compiled only after `planning.status` can be set to `ready`. If package alignment finds blocking issues, keep `planning.status` as `draft` or set it to `blocked`, revise the package, and do not report package planning as complete.

Package execution start must check `planning.status=ready`. It must not defer required package alignment to execution startup.

## Job Layout

Each Job has control inputs under the package root:

```text
<package-root>/PHASE-001/PAK-001/jobs/JOB-001/
├── job.md
└── job.config.json
```

Each Job has durable outputs under the artifact root:

```text
<artifact-root>/records/packages/PHASE-001/PAK-001/jobs/JOB-001/
├── record.md
├── review.md
└── verification.md
```

`job.md` is human-readable. It defines semantic intent, background, goal, scope, non-goals, business meaning, risks, acceptance criteria, and implementation notes.

`job.config.json` is machine-readable. It defines:

- `schemaVersion`;
- `phaseId`;
- `packageId`;
- `jobId`;
- status;
- dependencies;
- allowed areas;
- forbidden areas;
- execution policy;
- verification commands;
- output contract;
- required return format;
- required outputs;
- review requirement.
- `type`: `delegable | primary-control-only | review-only | blocked`;
- `stopConditions`;
- delegation or primary-execution reason when relevant.

Executor completion does not complete the Job. A Job is complete only after required records, verification evidence, review, and primary/control approval are consistent with the package contract.

`outputContract` carries detailed formatting and verbosity constraints. `requiredReturnFormat` is the named handback shape, `requiredOutputs` is the durable file checklist, and `outputContract` defines limits such as maximum length, evidence-index requirements, and raw stream handling.

Normal executor handback should be compact. It should include enough evidence paths and known gaps for primary/control review without copying raw command logs, full file contents, or verbose process streams.

`record.md` is the executor's execution record. Include actual work summary, changed areas, verification evidence, deviations, remaining risks, and follow-up recommendations. Do not dump raw long logs. Prefer concise evidence indexes.

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

Checkpoints record package state at pause points: completed Jobs, pending Jobs, package planning status, package execution status, blocking issues, verification status, review status, next step, and open primary-only decisions.

Handoffs prepare another session, tool, or human to continue. They should state package id, current status, completed work, incomplete work, next entry point, recommended role, and primary-only decisions.

Checkpoints and handoffs support role recovery but do not permanently bind control authority to any product.
