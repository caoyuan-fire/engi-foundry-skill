# Package Format

EngiFoundry packages separate human narrative from machine control.

Markdown explains. JSON controls.

## Directory Layout

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
            └── JOB-001/
                ├── job.md
                └── job.config.json
```

The package-root `ROADMAP.md` is an optional master roadmap for cross-phase planning. It may cover multiple phases and should capture the long-range direction, boundaries, phase sequence, and cross-phase dependencies.

Phase `ROADMAP.md` files are optional phase sub-roadmaps. They should capture the executable view for that phase, including additional phase-local load that does not change the master roadmap direction.

Do not mechanically create one phase directory per phase merely because the master roadmap mentions multiple phases. Create `PHASE-*` directories when a phase is being refined, packaged, executed, handed off, or used as current decision input.

Phase status is machine-readable and intentionally coarse. It describes whether a phase is usable for planning and execution governance, not fine-grained progress.

Allowed phase statuses:

- `available`: the phase may accept roadmap updates, packages, Jobs, and execution.
- `blocked`: the phase cannot progress until a blocker or upstream decision is resolved.
- `closed`: the phase is normally sealed; do not automatically reopen it.
- `invalidated`: the phase's assumptions, scope, target, or dependency basis is no longer valid; do not use it as execution input.

When roadmap alignment produces content and the target is not explicitly stated, Agent should infer the storage target from package-root facts and conversation content. Default to the package-root `ROADMAP.md` unless there is strong evidence that the discussion is extending a specific `available` phase.

If the relevant base phase is `closed`, do not automatically reopen it. If the discussion is a non-mainline extension, bridge, preparation, validation, cleanup, risk-reduction, or compatibility follow-up tied to that base phase and not suitable for the master roadmap or next main phase, create or update an extension phase such as `PHASE-002-EX01`.

If the relevant base phase is `invalidated`, do not create ordinary extension work from it. Create only migration, replacement, or mitigation work when the reason is explicit in the phase metadata or roadmap.

Main phase identifiers use `PHASE-001`. Extension phase identifiers use `PHASE-001-EX01`. Extension phases are attached to a base phase, do not participate in mainline phase ordering, and must not cause later main phases to be renumbered.

Do not insert a new mainline phase between existing phase numbers, or renumber existing phase, package, Job, roadmap, or record references, unless the user explicitly authorizes an insertion or migration. When authorized, record the affected references and migration decision.

When executing or planning inside a phase, prefer `<package-root>/PHASE-001/ROADMAP.md` when it exists. If it does not exist, use the relevant section of `<package-root>/ROADMAP.md` when present.

Package layout:

```text
<package-root>/PHASE-001/
├── phase.config.json
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

Extension phases use the same layout:

```text
<package-root>/PHASE-001-EX01/
├── phase.config.json
├── ROADMAP.md
└── PAK-001/
```

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

## Package Rules

- A package is both human-readable and machine-readable.
- A package is execution input by default and lives under the package root, not the artifact root.
- A phase is a coarse engineering period or planning stage. Projects without that concept use only `PHASE-001`.
- A phase can contain one or more packages. A package usually contains multiple Jobs.
- `phaseId` must use `PHASE-001` sequence format.
- Extension `phaseId` values must use `PHASE-001-EX01` sequence format and record `basePhaseId`.
- `packageId` must use `PAK-001` sequence format within its phase.
- `jobId` must use `JOB-001` sequence format within its package.
- Execution records, reviews, verification evidence, and closeout notes are durable outputs and live under the artifact root.
- Roadmaps are package-flow planning inputs and live under the package root when present.
- A package-root roadmap is the master cross-phase plan. Phase roadmaps are executable sub-roadmaps that may add phase-local detail without changing the master direction.
- Phase status is one of `available`, `blocked`, `closed`, or `invalidated`.
- Markdown files carry human meaning and review context.
- JSON files carry machine-readable control data.
- JSON must not duplicate long Markdown narratives.
- Markdown must not be treated as the authoritative machine-control source.
- Package governance only applies after work enters a package flow; bounded low-risk `ad-hoc` work does not need package artifacts.

## `phase.index.json`

`phase.index.json` is the machine-readable phase registry for the package root.

It should record:

- `schemaVersion`;
- allocated mainline phase ids;
- allocated extension phase ids;
- phase order for mainline phases;
- phase statuses;
- extension phase base links;
- latest available phase when known;
- latest closed phase when known;
- next unallocated mainline phase id.

Example:

```json
{
  "schemaVersion": 1,
  "mainlinePhases": ["PHASE-001", "PHASE-002", "PHASE-003"],
  "extensionPhases": ["PHASE-002-EX01"],
  "phaseOrder": ["PHASE-001", "PHASE-002", "PHASE-003"],
  "phases": {
    "PHASE-001": {
      "status": "closed"
    },
    "PHASE-002": {
      "status": "closed"
    },
    "PHASE-002-EX01": {
      "status": "available",
      "kind": "extension",
      "basePhaseId": "PHASE-002"
    },
    "PHASE-003": {
      "status": "available"
    }
  },
  "latestClosedPhase": "PHASE-002",
  "latestAvailablePhase": "PHASE-003",
  "nextMainlinePhaseId": "PHASE-004"
}
```

## `phase.config.json`

`phase.config.json` is the machine-readable phase contract for one phase.

It should record:

- `schemaVersion`;
- `phaseId`;
- `kind`: `mainline | extension`;
- `basePhaseId` for extension phases;
- `status`: `available | blocked | closed | invalidated`;
- status reason when relevant;
- roadmap path when present;
- package list;
- closeout or invalidation record references when relevant.

Example:

```json
{
  "schemaVersion": 1,
  "phaseId": "PHASE-002-EX01",
  "kind": "extension",
  "basePhaseId": "PHASE-002",
  "status": "available",
  "statusReason": "Post-closeout validation and compatibility work tied to PHASE-002.",
  "roadmap": "ROADMAP.md",
  "packages": ["PAK-001"]
}
```

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
- `phaseId`;
- `packageId`;
- optional package title or slug;
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
  "phaseId": "PHASE-001",
  "packageId": "PAK-001",
  "packageRef": "PHASE-001/PAK-001",
  "title": "Example package",
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

Before executor or reviewer work starts on a package or Job, the session should acknowledge that it has read the relevant phase roadmap when present, package summary, package config, Job config, dependencies, allowed areas, forbidden areas, stop conditions, and verification requirements.

The acknowledgement does not grant extra authority. It confirms the reader understands the package-first contract before acting.

`package.config.json` may record acknowledgement requirements in a compact form, for example:

```json
{
  "handoff": {
    "entrypoint": "summary.md",
    "requiredAcknowledgement": [
      "phase-roadmap-if-present",
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
