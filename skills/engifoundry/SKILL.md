---
name: engifoundry
description: Platform-neutral engineering workflow skill for ad-hoc tasks and structured task packages. Use when a user wants EngiFoundry, structured engineering delivery, package planning, durable artifacts, Job-level execution, review policy, role handoff, verification, closeout, or an ad-hoc task under EngiFoundry rules.
---

# EngiFoundry

EngiFoundry is a platform-neutral engineering workflow skill.

It routes engineering work into the lightest process compatible with risk, while preserving durable artifacts for planning, execution, review, verification, and closeout.

## Machine Interface

README is the human entry point; this skill directory is the machine entry point.

Read `references/contract.yaml` before mode-specific references. It is the structured index for the skill contract layer and points to the YAML contract parts.

Read `references/contract-operating-model.yaml` before mode-specific references. It defines the control loop, workflow modes, role establishment, and mode exit contract.

`references/contract-invariants.yaml` defines non-negotiable invariants. Apply those invariants before mode-specific implementation detail.

`references/contract-namespaces.yaml` maps workflow modes to implementation references. Use it after classification to load only the required detail.

`references/workflow.yaml` defines the ordered workflow and gate levels. Follow its `must` gates before reporting readiness, completion, or approval.

Markdown references remain the detail layer for nuance, examples, exceptions, and implementation guidance.

## Required First Step

Before acting, classify the current request using `references/contract-operating-model.yaml`, then load the detail references selected by `references/contract-namespaces.yaml`.

Use the least ceremony compatible with risk. `ad-hoc` remains a first-class mode. Package-only governance must not be applied to bounded low-risk work that has not entered a package flow.

For broad, risky, multi-step, cross-module, handoff-oriented, or ambiguous implementation requests with no package, follow the automatic package planning contract in `references/contract-operating-model.yaml`.

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

Apply `references/contract-invariants.yaml` before mode-specific implementation detail.

Resolve missing modules only through `references/module-resolution.md`; ask before downloading and keep caches outside artifact roots.
