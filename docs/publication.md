# Publication

EngiFoundry uses a public repository structure that separates user documentation, formal specification, and installable skill content.

## Public Files

- `README.md`: English public introduction and quick reference.
- `zh/README.md`: Chinese public introduction with equivalent content.
- `docs/`: formal specification basis.
- `skills/engifoundry/`: installable skill.
- `examples/`: examples after the format stabilizes.
- `tests/`: repository-level validation for scripts and publishable behavior.

## Documentation Responsibilities

The README explains:

- what EngiFoundry is;
- how the repository is structured;
- where the installable skill lives;
- core artifact, package, Job, role, and Git policies;
- where to read more.

`docs/` explains the full specification.

`skills/engifoundry/SKILL.md` stays concise and operational.

`skills/engifoundry/references/` contains agent-facing details loaded on demand.

`skills/engifoundry/agents/` contains optional platform and tooling metadata. Core discovery must still work from `SKILL.md`.

`skills/engifoundry/scripts/` contains deterministic helper scripts that support optional workflows such as module resolution.

## Version Policy

Skill version is a maintenance label, not a hard execution requirement.

The canonical installable version is recorded in:

```text
skills/engifoundry/VERSION
```

The repository manifest should carry the same version:

```text
engifoundry.manifest.json
```

Check at most once per session, during the first EngiFoundry alignment, only when network access is available. Use `check_version` scripts for this low-noise check:

```text
skills/engifoundry/scripts/check_version.sh
skills/engifoundry/scripts/check_version.ps1
```

If no newer version is available, say nothing. If the check fails or network is unavailable, do not mention it unless the user explicitly asks. Version checks must not block normal EngiFoundry work.

## Publishing Principles

- Do not expose local scratch paths or private notes in public documentation.
- Do not make the skill body a long specification document.
- Do not duplicate long rules across README, docs, and references.
- Do not add platform-specific metadata files without a stable schema.
- Do not write module caches or resolver lockfiles into project artifact roots.
- Keep public docs readable for humans.
- Keep references actionable for agents.
- Keep generated runtime state out of publishable files.
