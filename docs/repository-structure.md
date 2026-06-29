# Repository Structure

TaskForge uses a publishable repository layout with the installable skill under `skills/`.

```text
TaskForgeSkill/
├── README.md
├── taskforge.manifest.json
├── docs/
├── skills/
│   └── taskforge/
├── examples/
└── zh/
```

## Root Files

- `README.md`: public English introduction and quick reference.
- `taskforge.manifest.json`: repository-level skill manifest.
- `.gitignore`: repository hygiene only.

## `docs/`

`docs/` contains the formal human-facing specification for TaskForge.

These documents are the main basis for future implementation work:

- `configuration.md`
- `artifact-protocol.md`
- `execution-policy.md`
- `package-format.md`
- `job-format.md`
- `role-protocol.md`
- `handoff-and-checkpoint.md`
- `engineering-discipline.md`
- `adapter-contract.md`
- `publication.md`

## `skills/taskforge/`

`skills/taskforge/` is the installable skill.

It contains:

- `SKILL.md`: concise entry point and routing rules;
- `agents/openai.yaml`: product-facing skill metadata;
- `references/`: agent-facing operational rules loaded on demand;
- `modules/`: optional extensions.

The skill body should stay concise. Detailed rules belong in references and docs.

## `examples/`

`examples/` contains example packages, Jobs, handoffs, reviews, and closeouts when the format stabilizes.

## `zh/`

`zh/README.md` is the Chinese version of the public README.
