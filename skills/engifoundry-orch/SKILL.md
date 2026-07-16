---
name: engifoundry-orch
description: Audit new engineering work and orchestrate Phase, PAK, and Job contracts without executing them. Use for task orchestration, package creation or revision, roadmap planning, Job decomposition, and rework after package review.
---

# EngiFoundry Orch

`<project-root>` is the root of the target project and contains `engifoundry.config.json`. `<orch-skill-root>` is the directory containing this `SKILL.md`. These are independent locations: never infer the project root from the Skill installation path, and never look for bundled Orch resources under the project root.

Read `<project-root>/engifoundry.config.json`, the project-owned workspace guide and Workflow config, and `<orch-skill-root>/references/contracts.md` before writing orchestration artifacts.

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

- macOS/Linux: `sh <orch-skill-root>/scripts/orch.sh create-phase|create-package|check --project-root <project-root> [options]`
- Windows: `powershell -ExecutionPolicy Bypass -File <orch-skill-root>/scripts/orch.ps1 -Action create-phase|create-package|check -ProjectRoot <project-root> [options]`

Resolve the bundled script from `<orch-skill-root>/scripts/` and always pass `<project-root>` explicitly, regardless of the current working directory. Prefer `create-phase` and `create-package` for allocation and skeleton creation. Only when the correctly resolved bundled script remains unavailable or non-runnable may the Agent fall back to manual allocation and skeleton creation from the complete reference contract. Failure to find the script under `<project-root>` is not evidence that the bundled script is unavailable.

The helpers handle only allocation and skeleton creation. Fill every semantic field and require `check` before recording `pending-review`; when the helper itself is non-runnable, perform the equivalent contract checks manually. The Agent writes Review evidence, `reviewRef`, and conclusion state directly from the applicable contracts.

## Continuation

For an endpoint that includes implementation or delivery, a `ready` PAK is the fact that lets the Agent read Exec and continue. A request bounded to orchestration ends with its recorded planning fact. `direct`, `blocked`, `discarded`, and an explicitly requested draft are terminal facts for this contract.
