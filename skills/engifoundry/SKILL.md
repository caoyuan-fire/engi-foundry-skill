---
name: engifoundry
description: Platform-neutral engineering workflow skill for ad-hoc tasks and structured task packages. Use when a user wants EngiFoundry, structured engineering delivery, package planning, durable artifacts, Job-level execution, review policy, role handoff, verification, closeout, or an ad-hoc task under EngiFoundry rules.
---

# EngiFoundry

EngiFoundry is a platform-neutral engineering workflow skill.

It routes engineering work into the lightest process compatible with risk, while preserving durable artifacts for planning, execution, review, verification, and closeout.

## Machine Interface

README is the human entry point; this skill directory is the machine entry point.

Read `references/operating-model.md` before mode-specific references. It defines the control loop, workflow modes, role establishment, and mode exit contract.

`references/contracts.md` defines non-negotiable invariants. Apply those invariants before mode-specific implementation detail.

`references/namespaces.md` maps workflow modes to implementation references. Use it after classification to load only the required detail.

## Required First Step

Before acting, classify the current request:

1. `ad-hoc`: bounded low-risk task without package ceremony.
2. `package-planning`: create or revise a structured task package.
3. `package-alignment`: review whether package planning can be marked ready.
4. `job-execution`: execute one or more package Jobs.
5. `review-only`: review a package, Job result, diff, or implementation.
6. `package-revision`: update package rules, Job contracts, policies, or records.
7. `closeout`: final acceptance, handoff, or delivery record.
8. `audit`: cost, process, quality, or workflow retrospective.

Use the least ceremony compatible with risk. Absence of a package is not enough to choose ad-hoc for substantial work.

`ad-hoc` remains a first-class mode. Package-only governance must not be applied to bounded low-risk work that has not entered a package flow.

If the user asks to start implementing a broad, risky, multi-step, cross-module, handoff-oriented, or ambiguous feature and no package exists, do not ask the user to manually compile a package first and do not start direct TDD implementation. Treat package planning as the next automatic `primary/control` step, clarify only missing information that cannot be inferred safely, drive the package to `planning.status=ready` when possible, and then proceed from the ready package contract. This is not a default user approval pause; pause only when the user requested approval, the package requires human approval before implementation, or a concrete blocker remains.

Skill version is a maintenance label, not a hard execution requirement. Check at most once per session during the first EngiFoundry alignment, only when network access is available. Use `scripts/check_version.sh` or `scripts/check_version.ps1`; if no update is available, say nothing. If the check fails or network is unavailable, do not mention it unless the user explicitly asks. Version checks must not block normal EngiFoundry work.

## Required References

Read only the references needed by the classified mode:

- Intent routing: `references/intent-routing.md`
- Artifact root: `references/artifact-root.md`
- Execution config: `references/execution-config.md`
- Execution policy: `references/execution-policy.md`
- Role protocol: `references/role-protocol.md`
- Package format: `references/package-format.md`
- Package planning: `references/package-planning.md`
- Phase and roadmap: `references/phase-roadmap.md`
- Job format: `references/job-format.md`
- Handoff and checkpoint: `references/handoff-and-checkpoint.md`
- Operating model: `references/operating-model.md`
- Runtime contracts: `references/contracts.md`
- Runtime namespaces: `references/namespaces.md`
- Engineering discipline: `references/engineering-discipline.md`
- Adapter contract: `references/adapter-contract.md`
- Module resolution: `references/module-resolution.md`
- Publication and platforms: `references/publication-and-platforms.md`

## Non-Negotiable Rules

- New EngiFoundry work starts as `primary/control` by default.
- If resuming a package and control ownership is inferable with high confidence, resume as `primary/control`.
- If role is uncertain, ask whether to take over `primary/control` or perform bounded executor/reviewer work.
- Bounded executor/reviewer work has `autoDrive=false`; finish the assigned task and stop.
- When a package or Job contract exists, bounded executor/reviewer work must follow the package-first conflict rule.
- Primary-only actions require `primary/control` authority.
- When the user asks to create, compile, or prepare a task package, `primary/control` must target `planning.status=ready` in the same request; do not stop at draft to ask whether alignment should run unless a concrete blocker prevents readiness or the user explicitly asks for a draft.
- When aligning a new project or new EngiFoundry session to project workflow state, prefer reading `<artifact-root>/execution.config.json` after locating the artifact root, if it exists.
- If no package, Job, prompt, or execution config specifies an executor, use `direct` for ad-hoc and simple `primary/control` work.
- If package work requires bounded or isolated execution and no usable executor config exists, safely discover local executor capability or ask the user before using a bounded executor.
- If EngiFoundry workflow starts in a project with no `.engifoundry.config.json`, artifact root, or package root, initialize the default project config, artifact root, directory config, and package root automatically before the first durable EngiFoundry read or write. Do not require the user to request initialization as a separate step.
- The artifact root defaults to `.engifoundry/`, unless `.engifoundry.config.json` or the user specifies another path.
- The artifact root is for durable work products only. Do not write cache, temporary files, session dumps, credentials, or private runtime state there.
- The package root defaults to `.engifoundry-packages/`, unless `.engifoundry.config.json` or the user specifies another path.
- Package root Git visibility is determined by Git. Do not store ignore state in `.engifoundry.config.json`.
- Roadmap state belongs under the package root, either as a master roadmap or scoped by phase. Do not store roadmap state in `.engifoundry.config.json`.
- Missing modules may be resolved only through `references/module-resolution.md`; ask before downloading and keep caches outside artifact roots.
- `summary.md` is for humans only. Machine control belongs in JSON config files.
- Markdown explains. JSON controls.
- Do not claim completion without fresh verification evidence or an explicit non-runnable verification record.
