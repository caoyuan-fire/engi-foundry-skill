# Runtime Contracts

These are EngiFoundry invariants. They apply before mode-specific implementation detail.

## Control Source

Markdown explains. JSON controls.

Machine control belongs in JSON config files. Human narrative belongs in Markdown. `summary.md` is for humans only and must not be treated as the authoritative machine-control source.

JSON must not duplicate long Markdown narratives. Markdown must not duplicate machine-control state.

## Role Authority

New EngiFoundry work starts as `primary/control` by default.

Primary-only actions require `primary/control` authority.

Adapters cannot grant primary/control authority by themselves. Product names do not bind roles.

Bounded executor/reviewer sessions must not approve Job completion, modify package scope, modify Job order, modify acceptance policy, revise default execution policy, or drive the next Job automatically.

## Package-First Conflict Rule

Package-first conflict rule applies after work enters a package flow.

When an approved package or Job contract exists, package and Job JSON are the execution contract for executor and reviewer sessions. Later chat instructions do not override that contract.

Executor and reviewer sessions must refuse or escalate instructions that conflict with the package, including out-of-order Jobs, unmet dependencies, non-delegable work, scope expansion, forbidden edits, skipped verification, bypassed stop conditions, changed acceptance criteria, changed execution policy, or role changes not recorded by `primary/control`.

Only `primary/control` may revise package rules, and the revision must be recorded in package artifacts before executor or reviewer work follows the new rule.

## Package Planning

Package planning must auto-drive to `planning.status=ready` or a formal blocker unless the user explicitly requested draft output or the package is intentionally discarded.

`draft` is a transient writing state, not a completion state for an explicit request to create, compile, or prepare a task package.

Before setting or reporting `planning.status=ready`, evaluate whether Package Alignment Gate is required.

When Package Alignment Gate is required, primary/control self-review is not sufficient evidence.

For direct-control continuity, explicit user approval may satisfy package alignment when all package and Job execution remains direct/current-session and no isolated, external, human, reviewer, or later-session handoff is used.

When package planning is blocked, the user-facing output must prominently state the blocker reason and ask which executor, reviewer, clean session, external CLI, or human reviewer path to use.

Do not report package planning as complete while leaving `planning.status=draft`.

## Root Boundaries

The artifact root is for durable work products only: execution records, review records, verification evidence, closeout records, ad-hoc records, audit records, and generated docs with review or delivery value.

The package root is for execution inputs: task packages, Job contracts, package-flow control data, phase registries, and roadmaps.

Do not write cache files, temporary files, session dumps, downloaded modules, raw model logs, secrets, tokens, private runtime state, or transient executor state into the artifact root.

Roadmap state belongs under the package root, either as a master roadmap or scoped by phase. Do not store roadmap state in `.engifoundry.config.json`.

## Executor and Adapter Authority

If no package, Job, prompt, or execution config specifies an executor, use `direct` for ad-hoc and simple `primary/control` work.

If package work requires bounded or isolated execution and no usable executor config exists, safely discover local executor capability or ask the user before using a bounded executor.

Do not infer durable executor capability from product names, installed binaries, or examples alone.

Primary/control must not abort a long-running executor solely because a fixed elapsed-time or wait-turn window has passed.

Primary/control should not continuously ingest raw executor streams during normal monitoring.

## Verification

Do not claim completion without fresh verification evidence or an explicit non-runnable verification record.

Failed verification is a failed result.

If verification cannot be run, record why, what alternative evidence was collected, and what residual risk remains.

Executor completion does not complete the Job. A Job is complete only after required records, verification evidence, review, and primary/control approval are consistent with the package contract.
