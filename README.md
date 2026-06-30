# Engineering Foundry Skill

EngiFoundry is a platform-neutral engineering workflow skill for AI-assisted software work.

Keyword: `engifoundry`.

It turns engineering intent into execution inputs and durable artifacts: package plans, Job contracts, execution records, reviews, verification evidence, and closeout notes. It supports small ad-hoc tasks, medium engineering changes, and large multi-phase packages that may move across tools such as Codex, Kimi, Claude, local CLIs, or human operators.

EngiFoundry is not tied to any single product as the permanent controller. Roles are session-scoped and artifact-governed.

中文说明见 [zh/README.md](zh/README.md).

## Repository Layout

```text
EngiFoundrySkill/
├── README.md
├── engifoundry.manifest.json
├── docs/
│   ├── adapter-contract.md
│   ├── artifact-protocol.md
│   ├── configuration.md
│   ├── engineering-discipline.md
│   ├── execution-policy.md
│   ├── handoff-and-checkpoint.md
│   ├── job-format.md
│   ├── module-resolution.md
│   ├── package-format.md
│   ├── platform-metadata.md
│   ├── publication.md
│   ├── role-protocol.md
│   └── repository-structure.md
├── skills/
│   └── engifoundry/
│       ├── SKILL.md
│       ├── agents/
│       │   ├── generic.json
│       │   └── openai.yaml
│       ├── references/
│       ├── scripts/
│       └── modules/
├── examples/
│   └── README.md
├── tests/
│   └── test_resolve_module.py
└── zh/
    └── README.md
```

The installable skill is `skills/engifoundry/`. Root-level documentation is for users and maintainers.

## Core Concepts

EngiFoundry has one public entry point and several operating modes:

| Mode | Purpose |
| --- | --- |
| `ad-hoc` | Bounded low-risk work without package ceremony |
| `package-planning` | Create or revise a structured task package |
| `package-alignment` | Review a package before execution |
| `job-execution` | Execute one or more package Jobs |
| `review-only` | Review a package, Job result, diff, or implementation |
| `package-revision` | Update package rules, Job contracts, policies, or records |
| `closeout` | Final acceptance, handoff, or delivery record |
| `audit` | Process, cost, quality, or workflow retrospective |

EngiFoundry uses the least ceremony compatible with risk. Small work may stay ad-hoc. Broad, risky, multi-step, or handoff-oriented work should use package mode.

## Artifact Root

EngiFoundry writes durable outputs to an artifact root inside the user's project.

Default:

```text
<project-root>/.engifoundry/
```

Users may choose a different path, such as:

```text
<project-root>/MyEngiFoundry/
<project-root>/docs/engifoundry/
```

The project root should contain a locator config:

```text
<project-root>/.engifoundry.config.json
```

Example:

```json
{
  "schemaVersion": 1,
  "artifactRoot": ".engifoundry",
  "packageRoot": ".engifoundry-packages",
  "recordsPolicy": "durable",
  "defaultPackagePolicy": "package-when-risky"
}
```

The artifact root is not a runtime cache. EngiFoundry must not write cache, temporary files, session dumps, downloaded modules, or other non-reviewable state into it. If an adapter needs private runtime state, it must use an explicit external cache location, not the artifact root.

The artifact root is for durable work products. The package root is for execution inputs such as task packages and Job contracts.

## Artifact Root Layout

```text
<artifact-root>/
├── execution.config.json
├── records/
│   ├── ad-hoc/
│   ├── packages/
│   ├── reviews/
│   └── audits/
└── docs/
    └── generated/
```

The artifact root should contain only durable, inspectable, useful work products.

## Package Root Layout

```text
<package-root>/
└── <package-id>/
    ├── summary.md
    ├── package.config.json
    └── jobs/
        └── JOB-001/
            ├── job.md
            └── job.config.json
```

The default package root is `.engifoundry-packages/`. It is execution input by default, not a delivery artifact.

Package-flow durable outputs, including Job records, reviews, verification evidence, handoff summaries, and closeout notes, live under `<artifact-root>/records/packages/<package-id>/`.

## Execution Config

Every artifact root should contain:

```text
execution.config.json
```

This file describes executor capabilities and selection preferences. It does not store secrets, tokens, private session IDs, or temporary state.

Example:

```json
{
  "schemaVersion": 1,
  "defaultExecutor": "multi-session",
  "executors": {
    "multi-session": {
      "type": "local-multi-session",
      "supportsStdin": true,
      "supportsStructuredOutput": true,
      "outputNoise": "low",
      "supportsParallel": true,
      "supportsReviewOnly": true
    },
    "external-cli": {
      "type": "third-party-cli",
      "command": "kimi",
      "supportsStdin": true,
      "supportsStructuredOutput": false,
      "outputNoise": "medium",
      "supportsParallel": false,
      "supportsReviewOnly": true
    }
  },
  "selectionPolicy": {
    "prefer": ["multi-session", "external-cli"],
    "fallback": "direct"
  }
}
```

Executor choice is separate from quality discipline. EngiFoundry models execution with three independent dimensions:

```text
executor   = who or what performs the work
isolation  = how separated the execution/review context is
discipline = quality preset such as quick, standard, or strict
```

## Package Format

A package is both human-readable and machine-readable.

```text
<package-root>/<package-id>/
├── summary.md
├── package.config.json
└── jobs/
    └── JOB-001/
        ├── job.md
        └── job.config.json
```

`summary.md` is for humans only. It explains purpose, scope, non-goals, target state, risks, Job overview, acceptance criteria, and closeout requirements. It is not the source of machine control.

`package.config.json` is the machine-readable package contract. It should define package status, Job order, default execution policy, acceptance gates, checkpoint references, and closeout requirements.

## Job Format

Each Job has control inputs under the package root:

```text
<package-root>/<package-id>/jobs/JOB-001/
├── job.md
└── job.config.json
```

Each Job has durable outputs under the artifact root:

```text
<artifact-root>/records/packages/<package-id>/jobs/JOB-001/
├── record.md
├── review.md
└── verification.md
```

`job.md` is for human semantic intent: background, goal, scope, non-goals, business meaning, risks, and acceptance criteria.

`job.config.json` is for stable execution: status, dependencies, allowed and forbidden areas, execution policy, verification commands, output contract, and required records.

JSON files must not duplicate long narrative content from Markdown files. Markdown explains; JSON controls.

## Roles

EngiFoundry roles are not tied to product names.

Codex may be primary/control or executor. Kimi may be primary/control or executor. A human may manually drive either. Role is session-scoped and governed by artifacts plus user intent.

Roles:

- `primary/control`: owns requirements, scope, architecture, package policy, Job ordering, review decisions, integration, closeout, and package revision.
- `executor`: performs bounded Job work and reports results.
- `reviewer`: reviews package or Job artifacts without being the implementer.
- `audit-control`: evaluates process, quality, cost, or workflow history.

New EngiFoundry work starts as `primary/control` by default.

When resuming an existing package, a session resumes as `primary/control` if ownership or continuation intent can be inferred with high confidence from conversation context, checkpoint records, handoff records, or user wording.

If role cannot be inferred, EngiFoundry asks the user to choose between control takeover and bounded executor/reviewer work.

Bounded executor/reviewer work may complete the assigned task and write outputs, but it cannot automatically drive the package forward. Its `autoDrive` capability is false.

Primary-only actions require `primary/control` authority:

- create or revise package scope;
- modify Job order or dependencies;
- change package acceptance criteria;
- change default execution policy;
- approve Job completion;
- decide rework, rollback, or scope changes;
- create executor/reviewer assignments;
- close out a package.

## Git Policy

The artifact root contains durable work products and should not be ignored by default.

EngiFoundry should not silently modify `.gitignore` for the artifact root. If users do not want artifacts in version control, they may explicitly ignore their chosen artifact root.

The package root is different. It contains execution inputs and may be automatically added to `.gitignore`. EngiFoundry should tell the user only when it first adds that ignore rule. If the user asks to version task packages, or manually edits `.gitignore` so Git reports the package root in `git status`, EngiFoundry should treat package files as versionable. Git is the source of truth; `.engifoundry.config.json` must not store Git ignore state.

## Installation

Full installation is recommended. Copy or symlink the installable skill folder:

```text
skills/engifoundry/
```

to the Codex skills directory:

```text
~/.codex/skills/engifoundry/
```

Then restart Codex so the skill metadata is rescanned.

Kernel-only installation is supported for lightweight sharing. It requires `SKILL.md`, `engifoundry.manifest.json`, and `skills/engifoundry/scripts/resolve_module.py`. Missing modules are resolved from the declared GitHub source only after explicit confirmation, and downloaded modules are cached outside any project artifact root.

## Documentation

Additional documentation:

- [Configuration](docs/configuration.md)
- [Artifact protocol](docs/artifact-protocol.md)
- [Execution policy](docs/execution-policy.md)
- [Role protocol](docs/role-protocol.md)
- [Package format](docs/package-format.md)
- [Job format](docs/job-format.md)
- [Module resolution](docs/module-resolution.md)
- [Handoff and checkpoint](docs/handoff-and-checkpoint.md)
- [Engineering discipline](docs/engineering-discipline.md)
- [Adapter contract](docs/adapter-contract.md)
- [Platform metadata](docs/platform-metadata.md)
- [Repository structure](docs/repository-structure.md)
- [Publication](docs/publication.md)
