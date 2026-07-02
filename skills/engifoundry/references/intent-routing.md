# Intent Routing

Classify the user's request before acting.

Modes:

- `ad-hoc`
- `package-planning`
- `package-alignment`
- `job-execution`
- `review-only`
- `package-revision`
- `closeout`
- `audit`

Use the least ceremony compatible with risk.

Choose `ad-hoc` for bounded low-risk work. Use package mode for broad, risky, multi-step, or handoff-oriented work.

`ad-hoc` remains a first-class mode. Package-only governance must not be applied to bounded low-risk work that has not entered a package flow.

Package-only governance starts when the user asks to create or resume a package, an existing package or Job contract is the target of work, or the task requires durable handoff, delegation, Job sequencing, package records, or package closeout.

When the user asks to start implementing a feature and no package exists, classify the request by risk and clarity before editing code.

For bounded low-risk implementation requests with clear scope and acceptance criteria, use `ad-hoc` and apply the engineering discipline, including test-first development for behavior changes when feasible.

For broad, risky, multi-step, cross-module, handoff-oriented, or ambiguous implementation requests, do not ask the user to manually compile a package as a separate prerequisite and do not start direct TDD implementation. Treat package planning as the next automatic primary/control step: clarify only the missing information that cannot be inferred safely, create or revise the task package, drive it to `planning.status=ready` when possible, and then proceed according to the ready package contract.

Package planning for such implementation requests is not a default user approval pause. After the package is ready, continue into execution unless the user explicitly requested an approval gate, package acceptance criteria require human approval before implementation, or a concrete blocker remains.

When the user asks what to do next, asks to confirm the next step, or requests an engineering decision that depends on prior alignment, check the relevant package-root phase for `ROADMAP.md` before deciding. If no phase roadmap exists, check `<package-root>/ROADMAP.md` for the relevant phase section. If a roadmap exists, use it as decision input together with current progress. If no roadmap exists, decide from the current session context, visible project state, and the user's stated goal.

When the wrong mode could affect quality and context is insufficient, ask one concise question.
