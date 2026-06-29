# Publication

TaskForge uses a public repository structure that separates user documentation, formal specification, and installable skill content.

## Public Files

- `README.md`: English public introduction and quick reference.
- `zh/README.md`: Chinese public introduction with equivalent content.
- `docs/`: formal specification basis.
- `skills/taskforge/`: installable skill.
- `examples/`: examples after the format stabilizes.

## Documentation Responsibilities

The README explains:

- what TaskForge is;
- how the repository is structured;
- where the installable skill lives;
- core artifact, package, Job, role, and Git policies;
- where to read more.

`docs/` explains the full specification.

`skills/taskforge/SKILL.md` stays concise and operational.

`skills/taskforge/references/` contains agent-facing details loaded on demand.

## Publishing Principles

- Do not expose local scratch paths or private notes in public documentation.
- Do not make the skill body a long specification document.
- Do not duplicate long rules across README, docs, and references.
- Keep public docs readable for humans.
- Keep references actionable for agents.
- Keep generated runtime state out of publishable files.
