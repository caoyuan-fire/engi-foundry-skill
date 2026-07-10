# Orch Contracts

## Layout

```text
<package-root>/
|-- phase.index.json
|-- ROADMAP.md                         # only when a cross-Phase roadmap exists
`-- PHASE-001/
    |-- phase.config.json
    |-- ROADMAP.md                     # only when Phase planning exists
    `-- PAK-001/
        |-- summary.md
        |-- package.config.json
        `-- jobs/
            `-- JOB-001/
                |-- job.md
                `-- job.config.json
```

## Level Responsibilities

| Level | Semantic | Responsibility | Quality Gate |
| --- | --- | --- | --- |
| `PHASE-*` | Engineering period, implementation stage, or milestone | Groups the task goals scheduled for the same period and carries their roadmap context. It is not a task goal. | Phase status and roadmap alignment. |
| `PAK-*` | One complete task goal within a Phase | Defines goal scope, acceptance criteria, required artifacts, Jobs, and closeout requirements. Multiple independent goals require multiple PAKs. | Package Review before execution; formal Verify after all Jobs complete. |
| `JOB-*` | One ordered implementation step within a PAK | Defines a bounded part of the PAK goal under dependencies, allowed areas, stop conditions, and required outputs. It is not an independent task goal or delivery. | Clean-context Review after execution. |

## Roadmaps

`<package-root>/ROADMAP.md` holds direction spanning multiple engineering periods. `<package-root>/<phase-id>/ROADMAP.md` holds planning limited to that period. Create either only when meaningful roadmap facts exist; absence is valid.

The Agent reads the most specific applicable Roadmap before planning and updates it when accepted direction, period boundaries, sequencing, or dependencies change. Markdown provides planning context and never overrides JSON control facts. A Phase is `closed` only when its Package commitments are completed, discarded, or explicitly moved and no unresolved Phase roadmap commitment remains.

## Identifiers

- Main Phase: `PHASE-001`
- Extension Phase: `PHASE-001-EX01`
- PAK within one Phase: `PAK-001`
- Job within one PAK: `JOB-001`

Allocate from the highest existing identifier plus one regardless of status. Never reuse discarded, blocked, closed, or invalidated identifiers.

## Phase Index

```json
{
  "schemaVersion": 1,
  "mainlineOrder": ["PHASE-001"],
  "phases": {
    "PHASE-001": {
      "kind": "mainline",
      "status": "available",
      "basePhaseId": null
    }
  },
  "latestAvailablePhase": "PHASE-001",
  "latestClosedPhase": null,
  "nextMainlinePhaseId": "PHASE-002"
}
```

Phase status is `available`, `blocked`, `closed`, or `invalidated`. Do not automatically reopen closed or invalidated Phases.

## Phase Contract

```json
{
  "schemaVersion": 1,
  "phaseId": "PHASE-001",
  "kind": "mainline",
  "basePhaseId": null,
  "status": "available",
  "statusReason": null,
  "roadmap": null,
  "packages": ["PAK-001"]
}
```

## PAK Contract

```json
{
  "schemaVersion": 1,
  "phaseId": "PHASE-001",
  "packageId": "PAK-001",
  "title": "Task goal",
  "planning": {
    "status": "draft",
    "reviewRef": null
  },
  "execution": {
    "status": "not-started",
    "verificationRef": null,
    "deliveryRef": null
  },
  "jobs": [
    {
      "jobId": "JOB-001",
      "dependsOn": []
    }
  ],
  "acceptanceCriteria": [],
  "requiredArtifacts": [],
  "closeoutRequirements": []
}
```

## State Meanings

Planning status meanings:

| Status | Current fact |
| --- | --- |
| `draft` | Planning content is incomplete and not executable. |
| `pending-review` | Complete planning content exists, but no current clean-context Review conclusion is recorded. |
| `ready` | Every Job contract exists and is consistent, a current clean-context Review passed, and no newer fact invalidates the contract. |
| `rework-required` | Review, Verify, Deliver, or user evidence shows that current planning facts are inconsistent or changed. |
| `blocked` | An objective fact prevents usable planning or its required Review. |
| `discarded` | The PAK is intentionally not executable and its identifier remains allocated. |

`planning.reviewRef` points to the latest planning Review. A later downstream finding may make `ready` inaccurate without changing the historical Review record.

Execution status begins as `not-started`; its later meanings are defined by Exec, Verify, and Deliver contracts.

## Job Contract

```json
{
  "schemaVersion": 1,
  "phaseId": "PHASE-001",
  "packageId": "PAK-001",
  "jobId": "JOB-001",
  "status": "planned",
  "reviewRef": null,
  "reworkFacts": [],
  "type": "delegable",
  "dependsOn": [],
  "allowedAreas": [],
  "forbiddenAreas": [],
  "stopConditions": [],
  "acceptanceCriteria": [],
  "reviewRequirements": [],
  "requiredOutputs": []
}
```

Job type is `delegable`, `primary-control-only`, `review-only`, or `blocked`. PAK and Job contracts contain task facts only; they do not contain Executor, model, isolation, discipline, or runtime invocation policy.

`reviewRef` points to the latest clean-context Job Review. User rejection under `job-approval` appends an `implementation` or `contract` fact to `reworkFacts`; new Job contracts initialize both fields, and contract facts are planning input during revision.

## Human Files

`summary.md` explains background, goal, scope, non-goals, current and target state, Job overview, risks, acceptance criteria, and closeout requirements.

`job.md` explains background, step outcome, scope, non-goals, business meaning, risks, acceptance criteria, and implementation notes.

Markdown never overrides JSON control fields.

## Review Facts

A Reviewer Agent records `pass`, `rework-required`, or factual `blocked` in clean context. The planning state and `planning.reviewRef` must describe that evidence together with any newer downstream finding. Review findings are evidence, not Jobs.
