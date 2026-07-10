---
name: engifoundry-exec
description: Execute ready EngiFoundry Jobs in dependency order, apply configured Executor fallback, enforce engineering discipline, and record concise results. Use for implementation or rework of an existing ready PAK.
---

# EngiFoundry Exec

Read `./engifoundry.config.json`, the project-owned workspace guide, Executor and Workflow configs, and [contracts.md](references/contracts.md). Then read the Phase, PAK, and Job contracts before acting.

## Boundary

Execute only a PAK with `planning.status: ready`. Treat its JSON as authoritative. Never change scope, dependencies, acceptance criteria, allowed or forbidden areas, stop conditions, or Review requirements. Contract revision belongs to Orch.

Run eligible Jobs in dependency order. A Job is eligible only when every dependency is complete. Obey its type, allowed areas, forbidden areas, and stop conditions.

Select Executors strictly by `executorOrder`. Use the first usable entry; fall back in order only after a factual unavailability or failed attempt. Do not invent, reorder, or silently skip configured entries. `primary-control-only` work stays in the current control session.

An Executor is usable only when the Agent knows a verified invocation for its configured host mechanism or command. Run bounded work from the project root, provide the Job contract paths and required concise handback, and inspect actual process state before fallback. A running or quiet process is not a failed attempt; probe available liveness facts before declaring failure. Do not persist prompts, raw streams, or transient process state.

## Discipline

Apply all four rules:

1. **TDD:** For behavior changes, write the failing test first when feasible. Otherwise record the factual exception and use alternative verification.
2. **Systematic debugging:** Reproduce or characterize, gather evidence, form a hypothesis, make a targeted fix, then verify. Never jump from a symptom to a broad rewrite.
3. **Review:** After Job output and fresh execution evidence exist, record `pending-review`. A fresh Reviewer Agent reads `engifoundry-review`, reviews the complete Job result, and records the Review facts. Rework receives another complete Review. A blocked Review requires objective facts.
4. **Verification before completion:** Produce fresh, task-appropriate execution evidence for Review. Failed checks are failed results. Do not claim a Job complete from Executor handback alone.

If the same rework class fails more than twice, stop retrying and realign the failure facts. Rework never permits scope expansion, forbidden edits, skipped verification, or self-approval.

## Completion

Write one concise Job result using the reference contract. Normal results contain only effective information. Add `exceptions` only for fallback, deviation, failure, or blocker facts. Never store prompts, reasoning, raw streams, routine progress, command transcripts, or long logs.

Before implementation begins, the Package and selected Job record `in-progress`. Finished implementation with required outputs and fresh evidence is `pending-review`, not `completed`. Executor handback alone is never completion.

A Job is `completed` only while its required outputs exist, its current Review is `pass`, and any configured user approval exists. The other completion facts are:

- `approval-pending`: current Review passed, but `job-approval` has no user decision.
- `rework-required`: current Review, Verify, Deliver, or user evidence shows that Job output or its contract does not satisfy the required facts.
- `blocked`: an objective condition prevents bounded execution or Review and cannot be resolved or routed around.

Under `job-approval`, present the current Review result. User approval supplies the missing completion fact. An actionable implementation rejection is recorded in `reworkFacts`; a rejection that changes the contract also makes Package planning `rework-required`.

Implementation rework evidence identifies the affected Jobs; those Jobs are `rework-required`, and Package execution is `rework-required` until every Job again satisfies `completed`. Contract rework evidence means Package planning is `rework-required`; the Agent reads Orch before changing implementation. A rejection without an actionable fact leaves `approval-pending` and requires the reason.

Package execution is `jobs-completed` only while every Job satisfies `completed`. The Agent does not perform final Package verification or delivery while applying Exec.

## Continuation

For an endpoint that includes verification or delivery, `jobs-completed` is the fact that lets the Agent read Verify and continue with the PAK. An approval pause, factual blocker, or explicit user boundary is terminal for the current application of Exec.
