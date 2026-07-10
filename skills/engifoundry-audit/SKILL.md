---
name: engifoundry-audit
description: Classify new EngiFoundry work as direct Agent action, Package orchestration, or factually blocked before a Package exists. Use when deciding whether new work needs Orch.
---

# EngiFoundry Audit

Read the configured Workflow file and inspect only the new task facts needed for classification.

## Boundary

The Agent applies these rules only to classify new work as `direct`, `package`, or `blocked`. Classification does not execute, plan, split Jobs, edit files, ask for approval, or write durable records. Work already bound to a PAK or Job does not need another Audit classification.

Keep only concise observed facts sufficient to support the classification. Do not introduce recommendations or proposed implementation.

## Decision

Classify as `package` regardless of preference when the user explicitly requests a Package or Job orchestration, the work requires dependent Jobs, Executor delegation, durable cross-session or human handoff, or direct action cannot reliably control material security, data, release, migration, destructive, or delivery risk.

Otherwise apply `actionPreference`:

- `package-first`: use `direct` only when the work is mechanical or trivial, bounded to one known action, and immediately verifiable; otherwise use `package`.
- `balanced`: use `package` for multi-step, cross-module, unclear, delegated, or meaningfully risky work; otherwise use `direct`.
- `direct-first`: use `direct` for clear controlled work; use `package` when direct action cannot reliably control scope, risk, or delivery quality.

Ambiguity produces `package`, not `blocked`. Use `blocked` only when an objective inaccessible or invalid required input prevents classification and no available fact supports either actionable result. State the exact input and observed failure.

With `direct`, continue under the Router Group Rules without Package artifacts. With `package`, read Orch and continue with the task facts.
