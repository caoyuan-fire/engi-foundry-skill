# Operating Model

This file is the runtime state machine for EngiFoundry.

It tells an agent how to proceed. Detailed implementation rules live in the documents named by `references/namespaces.md`.

## Control Loop

For every EngiFoundry request:

1. classify the request into one workflow mode;
2. establish authority and role before primary-only or bounded work;
3. locate or initialize roots when durable work is needed;
4. select the mode target state;
5. execute until the target state, an explicit user pause, or a concrete blocker;
6. verify and record the evidence required by the selected mode;
7. report only a terminal state.

Do not treat an intermediate artifact write as completion. A draft file, partial record, executor report, or unchecked review is progress evidence only.

## Modes

Allowed modes:

- `ad-hoc`: bounded low-risk task without package ceremony.
- `package-planning`: create or revise a structured task package.
- `package-alignment`: review whether package planning can be marked ready.
- `job-execution`: execute one or more package Jobs.
- `review-only`: review a package, Job result, diff, or implementation.
- `package-revision`: update package rules, Job contracts, policies, or records.
- `closeout`: final acceptance, handoff, or delivery record.
- `audit`: cost, process, quality, or workflow retrospective.

Use the least ceremony compatible with risk. Absence of a package is not enough to choose `ad-hoc` for broad, risky, multi-step, cross-module, handoff-oriented, or ambiguous work.

Package-only governance must not be applied to bounded low-risk `ad-hoc` work that has not entered a package flow.

## Authority

New EngiFoundry work starts as `primary/control` by default.

If resuming a package and control ownership is inferable with high confidence, resume as `primary/control`.

If role is uncertain, ask whether to take over `primary/control` or perform bounded executor/reviewer work.

Bounded executor/reviewer work has `autoDrive=false`: finish the assigned task and stop.

Primary-only actions require `primary/control` authority.

## Mode Exit Contract

Each mode has a target terminal state. The agent must drive to one of the listed states unless the user explicitly asks to pause earlier.

| Mode | Terminal state |
| --- | --- |
| `ad-hoc` | requested work completed with verification evidence, non-runnable verification record, or concrete blocker |
| `package-planning` | `planning.status=ready`, `planning.status=blocked`, `planning.status=discarded`, or user explicitly requested draft output |
| `package-alignment` | pass decision, block decision, or concrete blocker preventing independent alignment |
| `job-execution` | Job returned for review with required records and verification, Job blocked, package blocked, or explicit bounded handoff |
| `review-only` | pass, needs-rework, or blocked review decision tied to evidence |
| `package-revision` | package rules updated and recorded, or concrete blocker |
| `closeout` | final acceptance, remaining risk, verification status, and handoff notes recorded, or concrete blocker |
| `audit` | audit findings and evidence recorded, or concrete blocker |

For `package-planning`, `draft` is a transient writing state. It is not a valid final state for a request to create, compile, or prepare a task package unless the user explicitly requested draft output.

If package planning cannot reach `planning.status=ready`, primary/control must set or keep a formal blocker state and report the blocker. Do not leave a package at `draft` while reporting package planning as complete.

## Automatic Package Planning

When the user asks to start implementing a broad, risky, multi-step, cross-module, handoff-oriented, or ambiguous feature and no package exists, treat package planning as the next automatic `primary/control` step.

Do not ask the user to manually compile a package as a separate prerequisite. Do not start direct TDD implementation for that class of work before the package path is resolved.

Clarify only missing information that cannot be inferred safely, create or revise the task package, drive it to `planning.status=ready` when possible, and then proceed according to the ready package contract.

Package planning for such implementation requests is not a default user approval pause. After the package is ready, continue into execution unless the user explicitly requested an approval gate, package acceptance criteria require human approval before implementation, or a concrete blocker remains.

## Durable Roots

Read project configuration when locating artifact or package roots, resuming package flow, writing durable records, or aligning a new session to project workflow state.

If EngiFoundry workflow starts in a project with no `.engifoundry.config.json`, artifact root, or package root, initialize the default project config, artifact root, directory config, and package root automatically before the first durable EngiFoundry read or write.

Use `.engifoundry/` as the default artifact root and `.engifoundry-packages/` as the default package root unless project config or the user specifies otherwise.

## Evidence

Do not claim completion without fresh verification evidence or an explicit non-runnable verification record.

Failed verification is a failed result.

If verification cannot be run, record why, what alternative evidence was collected, and what residual risk remains.
