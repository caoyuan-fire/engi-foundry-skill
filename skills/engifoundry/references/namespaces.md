# Runtime Namespaces

This file maps runtime modes to implementation references.

The runtime interface should load the smallest set of implementation references needed for the selected mode.

## Mode Routing

- `ad-hoc`: apply `references/intent-routing.md`, `references/engineering-discipline.md`, and `references/artifact-root.md` when durable records are needed.
- `package-planning`: apply `references/package-planning.md`, `references/package-format.md`, `references/phase-roadmap.md`, `references/artifact-root.md`, `references/role-protocol.md`, `references/execution-config.md`, `references/execution-policy.md`, and `references/engineering-discipline.md`.
- `package-alignment`: apply `references/package-planning.md`, `references/role-protocol.md`, `references/adapter-contract.md`, `references/execution-config.md`, `references/execution-policy.md`, and `references/engineering-discipline.md`.
- `job-execution`: apply `references/package-format.md`, `references/job-format.md`, `references/role-protocol.md`, `references/execution-policy.md`, `references/adapter-contract.md`, and `references/engineering-discipline.md`.
- `review-only`: apply `references/role-protocol.md`, `references/engineering-discipline.md`, and the package or Job format reference being reviewed.
- `package-revision`: apply `references/package-format.md`, `references/role-protocol.md`, and the specific policy reference being revised.
- `closeout`: apply `references/handoff-and-checkpoint.md`, `references/package-format.md`, `references/artifact-root.md`, and `references/engineering-discipline.md`.
- `audit`: apply `references/engineering-discipline.md`, `references/artifact-root.md`, and any target reference under review.

## Stable Document Namespaces

- `references/operating-model.md`: runtime control loop, workflow modes, authority establishment, and mode exit contract.
- `references/contracts.md`: non-negotiable runtime invariants that apply before mode-specific implementation detail.
- `references/namespaces.md`: workflow mode to reference mapping and stable document namespace index.
- `references/intent-routing.md`: detailed mode selection and risk routing.
- `references/package-planning.md`: task package creation, alignment, ready/blocked progression, and planning exit behavior.
- `references/package-format.md`: package summary, package config, package status values, and package control format.
- `references/phase-roadmap.md`: phase ids, phase status, roadmap location, and phase registry format.
- `references/job-format.md`: Job file structure, execution record, review record, verification record, and handback shape.
- `references/artifact-root.md`: artifact root, package root, records location, directory function table, initialization, and Git policy.
- `references/execution-config.md`: execution config, executor invocation profiles, and executor bootstrap.
- `references/execution-policy.md`: executor selection, isolation dimensions, discipline presets, liveness, and output cost control.
- `references/role-protocol.md`: `primary/control`, executor, reviewer, audit-control, unknown role, and package-first conflict rules.
- `references/adapter-contract.md`: adapter capability facts, executor contract gate, liveness, output control, and bounded execution mechanisms.
- `references/engineering-discipline.md`: TDD, systematic debugging, review, bounded rework, and verification before completion.
- `references/module-resolution.md`: optional module resolution and cache policy.
- `references/publication-and-platforms.md`: publication contract, platform metadata, installation modes, and plugin manifests.

## Runtime Reference Boundary

Runtime references define interface, contracts, routing, and implementation detail inside the self-contained skill directory.

Do not point runtime rules outside `skills/engifoundry/`.
