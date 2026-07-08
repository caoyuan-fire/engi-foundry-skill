# Package Planning

Package planning creates or revises a package until it is executable planning input, formally blocked, intentionally discarded, or explicitly left as draft by user instruction.

This document is the implementation detail for the `package-planning` and `package-alignment` workflow modes.

## Target State

The default target for package compilation is `planning.status=ready`.

A package records only two status dimensions: `planning.status` and `execution.status`.

Do not add `alignmentStatus`, `alignmentRequired`, or `alignmentPassed`.

`draft` is a transient writing state. In plain terms, draft is a transient writing state: package content is being written and is not ready for execution.

Only a concrete blocker, discarded package decision, or explicit user instruction may stop package planning before ready.

Do not report package planning as complete while leaving `planning.status=draft`.

A package may be reported as compiled only after `planning.status` can be set to `ready`.

## Planning Control Loop

For an explicit request to create, compile, or prepare a task package:

1. establish `primary/control` authority;
2. locate or initialize the package root and artifact root when durable work is needed;
3. allocate phase, package, and Job identifiers without reusing discarded or blocked package ids;
4. write or revise package summary, package config, and Job contracts;
5. evaluate whether Package Alignment Gate is required;
6. if alignment is not required, set `planning.status=ready` when package content is internally consistent;
7. if alignment is required, obtain independent alignment evidence before setting `planning.status=ready`;
8. if alignment finds blocking issues, revise the package and rerun alignment;
9. if ready cannot be reached, set or keep `planning.status=blocked` with the blocker reason.

Do not stop at `planning.status=draft` to ask whether alignment should run unless the user explicitly requested draft output.

When the user asks to create, compile, or prepare a task package, primary/control must treat `planning.status=ready` as the target state for the same request.

## Package Alignment Gate

Before setting or reporting `planning.status=ready`, evaluate whether Package Alignment Gate is required.

Before setting or reporting `planning.status=ready`, primary/control must evaluate whether Package Alignment Gate is required.

Package alignment is a hard gate for reporting package planning as ready when any of these conditions are true:

- any Job uses an executor other than `direct`;
- any Job uses isolated execution or isolated review;
- the package is intended for external CLI execution, reviewer handoff, human handoff, later session execution, or other bounded execution;
- the package touches cross-module behavior, build behavior, AIDL or interface contracts, release behavior, security-sensitive behavior, data-sensitive behavior, or target-device behavior;
- the verification path is unclear, non-runnable, target-dependent, or depends on evidence that cannot be produced in the current planning session;
- any known ambiguity or unresolved dependency exists.

Package alignment is required when any Job uses an executor other than `direct`.

If Package Alignment Gate is required, primary/control self-review is not sufficient evidence. The package must receive an independent alignment review from the configured executor, reviewer, clean session, external CLI, or human reviewer before planning may be marked ready, except for the direct-control continuity case below.

Direct-control continuity applies when project history shows the same project has been planned and executed by `primary/control` with `direct` or `current-session` execution, the current `execution.config.json` names `direct` or `current-session` as the usable default, the package and every Job use `direct` or `current-session` execution without isolated execution, reviewer handoff, external CLI execution, human handoff, or later-session handoff, and the current user prompt explicitly approves continuing the package in that same direct-control pattern.

In direct-control continuity, explicit user approval may satisfy package alignment without independent executor handoff. Record the continuity facts, the triggering alignment factors, the user approval text or summary, and the primary/control decision as alignment evidence before setting `planning.status=ready`. This is user-approved direct-control alignment, not primary/control self-review.

When direct-control continuity is present but explicit user approval is missing, do not set `planning.status=blocked` only because no independent reviewer is configured. Pause or ask for user approval of direct/current-session execution, unless a separate concrete blocker exists.

For an explicit package compilation request, primary/control must automatically drive the required alignment work in the same request when a usable reviewer, clean session, external CLI, or configured executor is available.

For an explicit package compilation request, primary/control must automatically drive the required alignment work in the same turn when a usable reviewer, clean session, external CLI, or configured executor is available.

If alignment finds blocking issues, primary/control must revise the package and rerun alignment until the package can be marked `ready` or a real blocker remains.

## Alignment Unavailable

If no usable independent reviewer, clean session, external CLI, configured executor, or human reviewer is available, and direct-control continuity with explicit user approval does not apply, set or keep `planning.status=blocked` and record why alignment cannot be completed.

Unavailable alignment reviewer capability is a blocker, not successful package compilation.

Blocked package planning output must prominently state the blocker reason and ask the user which executor, reviewer, clean session, external CLI, or human reviewer to use. The user-facing message should make the block impossible to miss, name the missing capability or unresolved decision, and ask how to choose executor or reviewer path before continuing.

Do not write `planning.status=ready`, report the package as ready, report package planning as complete, or describe the package as compiled when Package Alignment Gate is required and neither independent alignment review nor direct-control continuity with explicit user approval has passed.

When Package Alignment Gate is required and neither independent alignment review nor direct-control continuity with explicit user approval has passed, primary/control must not write `planning.status=ready`, report the package as ready, report package planning as complete, or describe the package as compiled.

## Allowed Draft Stop

Stopping at `draft` is only acceptable when a concrete blocker prevents a ready package.

Stopping at `draft` is only acceptable when:

- a concrete blocker prevents a ready package and the blocker has not yet been formalized;
- missing requirements cannot be inferred safely;
- required reviewer capability is unavailable and a blocked state cannot yet be written safely;
- a failed alignment review cannot be resolved without user or external input;
- the user explicitly instructed the agent to leave the package as draft.

When a blocked state can be written safely, prefer `planning.status=blocked` over an unexplained draft.

## Alignment Evidence

Alignment evidence is recorded as review evidence.

Alignment records capture reviewer identity, reviewer role, reviewed files, understanding restatement, findings, required package revisions, accepted non-blocking risks, pass/block decision, and primary/control decision.

Alignment records are review records, not Jobs.

Do not add package alignment as a synthetic Job in the Job order.

## Execution Boundary

Package execution start must check `planning.status=ready`.

Package execution must not defer required package alignment to execution startup.

If package alignment finds blocking issues, keep `planning.status` as `draft` or set it to `blocked`, revise the package, and do not report package planning as complete.
