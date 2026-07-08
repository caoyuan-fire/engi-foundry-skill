# Package Format

EngiFoundry packages separate human narrative from machine control.

Markdown explains. JSON controls.

JSON must not duplicate long Markdown narratives. Markdown must not be treated as the authoritative machine-control source.

Package governance only applies after work enters a package flow; bounded low-risk `ad-hoc` work does not need package artifacts.

A package is execution input by default and lives under the package root, not the artifact root.

Execution records, reviews, verification evidence, and closeout notes are durable outputs and live under the artifact root.

Phase and roadmap rules live in `phase-roadmap.md`. Job rules live in `job-format.md`. Package planning and alignment rules live in `package-planning.md`.

Contract anchor: `references/contract.yaml` indexes this file as the package-control detail layer. The high-level control-source and root-boundary rules live in `references/contract-invariants.yaml`; this file keeps package-specific layout, identifiers, status values, and reader acknowledgement rules near the package format they constrain.

## Package Layout

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

`PAK-001` is the package identifier. Package identifiers must use the `PAK-001` sequence format within a phase. Human-readable names may appear as package titles or slugs, but machine references should use the numbered package id.

The full package reference is the phase id plus the package id, for example `PHASE-001/PAK-001`. A bare `packageId` is scoped to its phase.

Legacy packages at `<package-root>/<package-id>/jobs/JOB-001/` may be read as `PHASE-001/<package-id>/jobs/JOB-001/` for compatibility, but new packages should use the phase/package layout.

## Package Identity and Allocation

A phase can contain one or more packages. A package usually contains multiple Jobs.

`packageId` must use `PAK-001` sequence format within its phase.

Package id allocation uses the highest allocated `PAK-*` id in the phase, regardless of package status.

Package identifiers are allocated monotonically within a phase. Discarded, blocked, closed, or otherwise inactive packages keep their allocated ids and must not be reused or skipped over when allocating the next package id. If the latest allocated package in a phase is `PAK-003` and it is discarded, the next new package is `PAK-004`.

Discarding a package does not roll back numbering. New package allocation must continue from the highest allocated `PAK-*` id in the phase, independent of `planning.status` or `execution.status`.

## `summary.md`

`summary.md` is human-only. It is not the machine-control source.

`summary.md` should explain:

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

The Job overview table must include each Job's executor and whether agent execution is requested. Use explicit columns such as `Job`, `Type`, `Executor`, `Agent execution`, `Status`, and `Notes`.

The human-readable executor column should mirror the effective `executor` from `package.config.json` defaults or the Job's `job.config.json` override. The agent-execution column should mirror the effective `agentExecution` marker, such as whether the Job is intended for direct/current-session work, bounded agent execution, external CLI execution, isolated reviewer handoff, or human handoff.

It may include additional Job overview columns, but the table is only a readable summary. It is not authoritative configuration.

`summary.md` should also state the package reading entrypoint, current state, and next expected action when another session, tool, or human may continue the work.

## `package.config.json`

`package.config.json` is the machine-readable package contract.

It defines package planning status, package execution status, Job order, defaults, checkpoints, and acceptance gates.

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
- closeout requirements;
- handoff entrypoint;
- required reader acknowledgement.

Package planning status values:

- `draft`: package content is being written and is not ready for execution.
- `ready`: package content is approved as executable planning input.
- `blocked`: package planning cannot become ready until a blocker is resolved.
- `discarded`: package content is not approved or is no longer applicable; keep it only as archive and do not execute it.

Package execution status values:

- `not-started`: no execution has started.
- `in-progress`: one or more Jobs are active or partially complete.
- `blocked`: execution cannot continue until a blocker is resolved.
- `completed`: package execution has completed under the package acceptance rules.
- `discarded`: execution is intentionally abandoned or skipped; keep the package only as archive and do not execute remaining Jobs.

A discarded package is retained for traceability but is not executable input. The execution layer must ignore discarded packages: do not start their Jobs, do not treat their unfinished Jobs as pending work, and do not let a discarded latest package block creation of a newer package.

## Reader Acknowledgement

Reader Acknowledgement only applies after work enters a package flow.

Before executor or reviewer work starts on a package or Job, the session should acknowledge that it has read the relevant phase roadmap when present, package summary, package config, Job config, dependencies, allowed areas, forbidden areas, stop conditions, and verification requirements.

The acknowledgement confirms understanding. It does not grant primary/control authority.

`package.config.json` may record `handoff.entrypoint` and `handoff.requiredAcknowledgement`.
