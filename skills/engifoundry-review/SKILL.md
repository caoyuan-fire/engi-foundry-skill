---
name: engifoundry-review
description: Review EngiFoundry planning, Job work, code, documents, research, or other durable outputs in clean context and record pass, rework-required, or factual blocked conclusions.
---

# EngiFoundry Review

The Agent arranging Review establishes a fresh context through any exposed host subagent, new-session, or CLI capability. Review isolation is independent of `executorOrder`; the same model is acceptable when the context is genuinely fresh. The Reviewer Agent must not have performed the reviewed work or receive its implementation discussion or intended conclusion.

When no fresh-context mechanism is actually available after inspecting host capabilities, Review is unavailable. Record that objective fact in the subject state; do not fabricate a Review attempt or reuse the producing context.

Read `./engifoundry.config.json`, the project-owned workspace guide, [contracts.md](references/contracts.md), the complete subject, its applicable requirements and contracts, and the evidence needed to assess it. Do not rely on handback summaries when primary evidence is available.

## Review

Inspect every applicable concern:

- requirement and contract compliance;
- scope, dependencies, allowed and forbidden areas;
- correctness and completeness;
- tests and verification evidence supporting the claimed result;
- record and reference consistency;
- material delivery risk.

Order findings by impact and tie each to evidence. After rework, review the complete current subject again; never perform a delta-only approval.

The Reviewer Agent records exactly one conclusion:

- `pass`: no actionable factual defect remains.
- `rework-required`: at least one correctable subject or contract finding exists.
- `blocked`: an objective condition prevents Review itself from reaching a conclusion and no valid alternative evidence exists.

A missing output, failed check, incorrect content, contract conflict, or insufficient evidence is `rework-required`, not `blocked`. Never use `blocked` for uncertainty, difficulty, preference, or work the producing Agent can correct.

## Record And State

For every actual Review attempt, the Reviewer Agent writes one new immutable Review record and updates the subject's `reviewRef` when it has one. Never overwrite an earlier attempt.

- Planning `ready` means the current planning subject has a clean-context pass and no newer invalidating fact. `rework-required` means a current finding remains. `blocked` means Review itself is factually unavailable.
- Job `pending-review` with a pass `reviewRef` means Review is complete but Exec completion or approval facts are not yet recorded. `rework-required` and `blocked` carry the matching current Review evidence.
- Other durable outputs use the immutable Review record without an invented control state.

The Reviewer Agent records findings and applicable state facts. It does not repair the reviewed subject, change its contract, accept delivery, or continue unrelated work.
