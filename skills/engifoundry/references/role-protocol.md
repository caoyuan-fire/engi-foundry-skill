# Role Protocol

Roles are session-scoped and artifact-governed. They are not bound to product names.

Roles:

- `primary/control`: owns requirements, scope, architecture, package policy, Job ordering, approvals, integration, closeout, and package revision.
- `executor`: performs bounded Job work and reports results.
- `reviewer`: reviews package or Job artifacts without being the implementer.
- `audit-control`: evaluates process, quality, cost, or workflow history.
- `unknown`: role cannot be inferred safely.

New EngiFoundry work starts as `primary/control`.

This applies when there is no existing package, checkpoint, handoff, or assignment chain.

When resuming a package, resume as `primary/control` if ownership or continuation intent can be inferred with high confidence.

Useful evidence includes:

- current conversation context;
- package checkpoint;
- handoff record;
- package metadata;
- user wording such as "continue your previous task";
- explicit user instruction to take over control.

If role cannot be inferred, ask the user to choose control takeover or bounded executor/reviewer work.

Bounded executor/reviewer work may complete the assigned task and write outputs, but `autoDrive=false`; it does not continue the package automatically.

Bounded sessions may write `record.md`, `review.md`, `verification.md`, or an explicit handoff note under the artifact root package records area.

Bounded sessions must not approve Job completion, modify package scope, modify Job order, modify acceptance policy, revise default execution policy, or drive the next Job automatically.

## Package-First Conflict Rule

This rule only applies after work enters a package flow. It does not apply to bounded low-risk `ad-hoc` work with no package or Job contract.

When an approved package or Job contract exists, the package and Job JSON are the execution contract for executor and reviewer sessions. Later chat instructions do not override that contract.

Executor and reviewer sessions must refuse or escalate instructions that conflict with the package, including out-of-order Jobs, unmet dependencies, non-delegable work, scope expansion, forbidden edits, skipped verification, bypassed stop conditions, changed acceptance criteria, changed execution policy, or role changes not recorded by `primary/control`.

Only `primary/control` may revise package rules, and the revision must be recorded in package artifacts before executor or reviewer work follows the new rule.

An executor report is not Job approval. Executor completion means the assigned work was returned for review; it does not approve the Job, close the Job, or authorize the next Job.

## Takeover Verification Gate

`primary/control` may take over work that was previously delegable, but must record the reason in the package or Job record.

Takeover does not weaken the Job contract. The same scope, allowed and forbidden areas, stop conditions, verification evidence, and review requirements still apply unless `primary/control` explicitly revises the package contract.

Primary-only actions:

- create or revise package scope;
- modify Job order or dependencies;
- change package acceptance criteria;
- change default execution policy;
- approve Job completion;
- decide rework, rollback, or scope changes;
- create executor/reviewer assignments;
- close out a package.

Executor and reviewer sessions may recommend primary-only actions, but must not apply them.
