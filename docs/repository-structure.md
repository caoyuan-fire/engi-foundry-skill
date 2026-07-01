# Repository Structure

EngiFoundry uses a publishable repository layout with the installable skill under `skills/`.

```text
EngiFoundrySkill/
├── README.md
├── .codex-plugin/
│   └── plugin.json
├── .claude-plugin/
│   └── plugin.json
├── engifoundry.manifest.json
├── docs/
├── skills/
│   ├── engifoundry-gate/
│   └── engifoundry/
├── examples/
├── tests/
└── zh/
```

## Root Files

- `README.md`: public English introduction and quick reference.
- `engifoundry.manifest.json`: repository-level skill manifest.
- `.codex-plugin/plugin.json`: Codex plugin manifest.
- `.claude-plugin/plugin.json`: Claude plugin manifest.
- `.gitignore`: repository hygiene only.

## `docs/`

`docs/` contains the formal human-facing specification for EngiFoundry.

These documents are the main basis for future implementation work:

- `configuration.md`
- `artifact-protocol.md`
- `execution-policy.md`
- `package-format.md`
- `job-format.md`
- `module-resolution.md`
- `role-protocol.md`
- `handoff-and-checkpoint.md`
- `engineering-discipline.md`
- `adapter-contract.md`
- `platform-metadata.md`
- `publication.md`

## `skills/engifoundry-gate/`

`skills/engifoundry-gate/` is the plugin autoload gate.

It contains:

- `SKILL.md`: lightweight environment gate for current-working-directory detection.

The gate inspects only first-level children of the current working directory. It treats `.git/` as a super signal. A gate match only makes EngiFoundry available; it does not force package governance.

## `skills/engifoundry/`

`skills/engifoundry/` is the main manual skill entry point and workflow launcher.

It contains:

- `SKILL.md`: concise main entry point and routing rules;
- `agents/openai.yaml`: product-facing skill metadata;
- `agents/generic.json`: platform-neutral metadata for humans and tooling;
- `references/`: agent-facing operational rules loaded on demand;
- `scripts/`: deterministic helper scripts;
- `modules/`: optional extensions.

The skill body should stay concise. Detailed rules belong in references and docs.

## `examples/`

`examples/` contains example packages, Jobs, handoffs, reviews, and closeouts when the format stabilizes.

## `tests/`

`tests/` contains repository-level tests for deterministic helper scripts and publishable behavior.

## `zh/`

`zh/README.md` is the Chinese version of the public README.
