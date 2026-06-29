# Handoff and Checkpoint

Checkpoints and handoffs let EngiFoundry packages pause and resume across sessions, tools, or humans.

They support role recovery but do not permanently bind primary/control authority to any product.

## Checkpoints

A checkpoint records package state at a pause point.

It should include:

- completed Jobs;
- pending Jobs;
- current package status;
- blocking issues;
- verification status;
- review status;
- next recommended step;
- primary-only decisions that remain open.

Checkpoints may be referenced from `package.config.json`.

## Handoffs

A handoff prepares another session, tool, or human to continue.

Handoffs may occur:

- from Codex to Kimi;
- from Kimi to Codex;
- from an agent to a human;
- from a human to an agent;
- between two sessions of the same product.

A handoff should state:

- package id;
- current status;
- completed work;
- incomplete work;
- next entry point;
- whether primary/control takeover is recommended;
- whether bounded executor/reviewer work is requested;
- primary-only decisions that must not be performed without control authority.

## Role Interaction

When a new session starts from a checkpoint or handoff, it applies the role protocol:

- infer `primary/control` only when ownership or continuation intent is high confidence;
- ask the user when role is unclear;
- treat bounded executor/reviewer work as `autoDrive=false`;
- require `primary/control` for primary-only actions.
