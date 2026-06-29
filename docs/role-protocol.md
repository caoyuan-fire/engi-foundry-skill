# Role Protocol

EngiFoundry roles are session-scoped and artifact-governed. They are not bound to product names.

Codex may be `primary/control` or `executor`. Kimi may be `primary/control` or `executor`. A human may manually drive either.

## Roles

- `primary/control`: owns requirements, scope, architecture, package policy, Job ordering, approvals, integration, closeout, and package revision.
- `executor`: performs bounded Job work and reports results.
- `reviewer`: reviews package or Job artifacts without being the implementer.
- `audit-control`: evaluates process, quality, cost, or workflow history.
- `unknown`: role cannot be inferred safely.

## New Work

New EngiFoundry work starts as `primary/control` by default.

This applies when there is no existing package, checkpoint, handoff, or assignment chain. The current session is the only reasonable controller for planning, scope, execution policy, and acceptance decisions.

## Resuming Work

When resuming an existing package, the session resumes as `primary/control` if ownership or continuation intent can be inferred with high confidence.

Useful evidence includes:

- current conversation context;
- package checkpoint;
- handoff record;
- package metadata;
- user wording such as "continue your previous task";
- explicit user instruction to take over control.

## Unclear Role

If role cannot be inferred, ask the user to choose:

- take over `primary/control`;
- perform bounded executor work;
- perform bounded reviewer work.

Do not silently perform primary-only actions while role is unclear.

## Bounded Executor and Reviewer Work

Executor or reviewer sessions may complete the bounded task and write outputs.

They have:

```text
autoDrive=false
```

That means they do not continue the package automatically after their assigned task.

They may write:

- `record.md`;
- `review.md`;
- `verification.md`;
- a handoff note requested by the primary/control session or human user.

They must not:

- approve Job completion;
- modify package scope;
- modify Job order;
- modify package acceptance policy;
- revise default execution policy;
- drive the next Job automatically.

## Primary-Only Actions

The following actions require `primary/control` authority:

- create or revise package scope;
- modify Job order or dependencies;
- change acceptance criteria;
- change default execution policy;
- approve Job completion;
- decide rework;
- decide rollback;
- decide scope change;
- create executor or reviewer assignments;
- close out a package.

Executor and reviewer sessions may recommend these actions, but must not apply them.
