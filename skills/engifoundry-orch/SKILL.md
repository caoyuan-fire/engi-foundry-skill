---
name: engifoundry-orch
description: Audit new engineering work and orchestrate Phase, PAK, and Job contracts without executing them. Use for task orchestration, package creation or revision, roadmap planning, Job decomposition, and rework after package review.
---

# EngiFoundry Orch

Read `./engifoundry.config.json`, the project-owned workspace guide, Workflow config, and [contracts.md](references/contracts.md) before writing orchestration artifacts.

## Boundary

The Agent applies this contract to turn a task goal into execution input. While doing so, it does not select an Executor, edit implementation, perform delivery verification, or close delivery.

For a new actionable task not already bound to a PAK or Job, read `engifoundry-audit` and classify the task facts:

- `direct`: the Agent continues under the Router Group Rules without package files.
- `package`: the Agent applies this contract to create execution input.
- `blocked`: the available facts do not support safe direct action or packaging.

Do not re-audit explicit continuation of an existing PAK or Job.

## Orchestration

1. Resolve the relevant Phase from `phase.index.json`, Phase status, and Roadmaps. Use `PHASE-001` when the project has no meaningful period model.
2. Allocate Phase, PAK, and Job identifiers monotonically. Never reuse or renumber identifiers.
3. Write human narrative in Markdown and machine control in JSON using the reference contract.
4. Keep `planning.status: draft` while content is incomplete.
5. When the PAK and every Job are internally consistent, record `planning.status: pending-review`. A fresh Reviewer Agent reads `engifoundry-review`, examines the complete planning subject, and records its conclusion.
6. Planning is `ready` only while a current clean-context Review pass exists and no newer fact invalidates the contract.
7. Planning is `rework-required` while Review or later evidence identifies a contract defect. Revise the cited facts, record `pending-review`, and obtain another complete Review.
8. Planning is `blocked` only while an objective fact prevents the Agent from producing or reviewing a usable contract.

`draft`, `pending-review`, and `rework-required` do not describe executable planning. The Agent continues applying this contract until the facts satisfy `ready`, the user explicitly requests a draft, the PAK is discarded, or a factual blocker remains.

## Output

Write execution input only under the configured package root. Reviewer Agents write evidence under the configured artifact review directory. Never store raw model output, credentials, cache state, or transient sessions in either location.

## Commands

- macOS/Linux: `sh scripts/orch.sh create-phase|create-package|check [options]`
- Windows: `powershell -ExecutionPolicy Bypass -File scripts/orch.ps1 -Action create-phase|create-package|check [options]`

Use `create-phase` and `create-package` only for allocation and skeleton creation. Fill every semantic field and require `check` before recording `pending-review`. The Agent writes Review evidence, `reviewRef`, and conclusion state directly from the applicable contracts.

## Continuation

For an endpoint that includes implementation or delivery, a `ready` PAK is the fact that lets the Agent read Exec and continue. A request bounded to orchestration ends with its recorded planning fact. `direct`, `blocked`, `discarded`, and an explicitly requested draft are terminal facts for this contract.
