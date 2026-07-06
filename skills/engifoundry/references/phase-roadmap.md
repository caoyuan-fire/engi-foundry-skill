# Phase and Roadmap

Phase and roadmap state lives under the package root.

Roadmaps are package-flow planning inputs. They capture agreed planning, requirement alignment, sequencing decisions, and next-step intent.

## Roadmap Locations

The package root may contain a master roadmap for cross-phase planning:

```text
<package-root>/
└── ROADMAP.md
```

The master roadmap may cover multiple phases and should capture long-range direction, boundaries, phase sequence, and cross-phase dependencies.

Phases may contain sub-roadmaps:

```text
<package-root>/PHASE-001/
├── phase.config.json
└── ROADMAP.md
```

Phase roadmaps should capture the executable view for that phase, including additional phase-local load that does not change the master roadmap direction.

Do not mechanically create one phase directory per phase merely because the master roadmap mentions multiple phases. Create `PHASE-*` directories when a phase is being refined, packaged, executed, handed off, or used as current decision input.

`ROADMAP.md` exists only when planning or alignment produced one. Projects without a meaningful phase concept use `PHASE-001` for executable phase work.

## Roadmap Placement

When discussion or alignment produces roadmap content, EngiFoundry should decide where to store it from project facts and conversation content. Do not require the user to explicitly say whether the roadmap is master-level or phase-level.

Default to the package-root `ROADMAP.md` when there is no strong evidence that the discussion belongs to a specific phase. This keeps broad alignment as the master plan until execution context narrows it.

Create or update a phase `ROADMAP.md` when known facts or conversation content show that the discussion is extending a specific `available` phase. Strong signals include an available phase, active package or Job work under that phase, or discussion framed around carrying forward from that phase.

Use the discussion content as evidence. Future direction, cross-phase sequencing, broad scope boundaries, or long-range dependency planning usually belongs in the master roadmap. Execution detail, phase-local load, or refinements to an `available` phase usually belong in that phase roadmap.

When executing or planning inside a phase, prefer `<package-root>/PHASE-001/ROADMAP.md` when it exists. If it does not exist, use the relevant section of `<package-root>/ROADMAP.md` when present.

When the user asks what to do next, asks to confirm the next step, or requests an engineering decision that depends on prior alignment, check the relevant package-root phase for `ROADMAP.md` before deciding. If no phase roadmap exists, check `<package-root>/ROADMAP.md` for the relevant phase section. If a roadmap exists, use it as decision input together with current progress. If no roadmap exists, decide from the current session context, visible project state, and the user's stated goal.

Ask the user only when local facts and conversation evidence conflict or when choosing the wrong roadmap would materially change execution scope.

Do not store roadmap state in `.engifoundry.config.json`. The project config locates the package root. Package-root and phase `ROADMAP.md` files are the source of truth for roadmap state.

## Phase Status

Phase status is machine-readable and intentionally coarse. It describes whether a phase is usable for planning and execution governance, not fine-grained progress.

Allowed phase statuses:

- `available`: the phase may accept roadmap updates, packages, Jobs, and execution.
- `blocked`: the phase cannot progress until a blocker or upstream decision is resolved.
- `closed`: the phase is normally sealed; do not automatically reopen it.
- `invalidated`: the phase's assumptions, scope, target, or dependency basis is no longer valid; do not use it as execution input.

Phase status is coarse machine state. `available` phases may accept planning and execution input. `blocked` phases require blocker resolution before scope expansion. `closed` phases are sealed; do not automatically reopen them. `invalidated` phases are no longer reliable execution input.

If the relevant base phase is `closed`, do not automatically reopen it. If the discussion is a non-mainline extension, bridge, preparation, validation, cleanup, risk-reduction, or compatibility follow-up tied to that base phase and not suitable for the master roadmap or next main phase, create or update an extension phase such as `PHASE-002-EX01`.

If the relevant base phase is `invalidated`, do not create ordinary extension work from it. Create only migration, replacement, or mitigation work when the reason is explicit in the phase metadata or roadmap. Otherwise use the master roadmap or a replacement phase.

## Phase Identifiers

Main phase identifiers use `PHASE-001`.

Extension phase identifiers use `PHASE-001-EX01`. Extension phases are attached to a base phase, do not participate in mainline phase ordering, and must not cause later main phases to be renumbered.

Do not insert a mainline phase between existing phase numbers, and do not renumber existing phases, packages, Jobs, roadmaps, or records, unless the user explicitly authorizes the insertion or migration. When authorized, record the affected references and migration decision.

`PHASE-001` is the default phase when a project has no meaningful phase or schedule concept. Longer engineering efforts may continue with `PHASE-002`, `PHASE-003`, and so on.

## `phase.index.json`

`phase.index.json` is the machine-readable phase registry for the package root.

It records allocated mainline phase ids, allocated extension phase ids, mainline phase order, phase statuses, extension phase base links, latest known available or closed phases, and the next unallocated mainline phase id.

It should record:

- `schemaVersion`;
- allocated mainline phase ids;
- allocated extension phase ids;
- phase order for mainline phases;
- phase statuses;
- extension phase base links;
- latest available phase when known;
- latest closed phase when known;
- next unallocated mainline phase id.

## `phase.config.json`

`phase.config.json` is the machine-readable phase contract for one phase.

It should record:

- `schemaVersion`;
- `phaseId`;
- `kind`: `mainline | extension`;
- `basePhaseId` for extension phases;
- `status`: `available | blocked | closed | invalidated`;
- status reason when relevant;
- roadmap path when present;
- package list;
- closeout or invalidation record references when relevant.
