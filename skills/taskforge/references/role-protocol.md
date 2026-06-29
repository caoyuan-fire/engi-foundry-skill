# Role Protocol

Roles are session-scoped and artifact-governed. They are not bound to product names.

Roles:

- `primary/control`: owns requirements, scope, architecture, package policy, Job ordering, approvals, integration, closeout, and package revision.
- `executor`: performs bounded Job work and reports results.
- `reviewer`: reviews package or Job artifacts without being the implementer.
- `audit-control`: evaluates process, quality, cost, or workflow history.
- `unknown`: role cannot be inferred safely.

New TaskForge work starts as `primary/control`.

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

Bounded sessions may write `record.md`, `review.md`, `verification.md`, or an explicit handoff note.

Bounded sessions must not approve Job completion, modify package scope, modify Job order, modify acceptance policy, revise default execution policy, or drive the next Job automatically.

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
