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
├── .codex-plugin/
│   └── plugin.json
├── .claude-plugin/
│   └── plugin.json
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
│   ├── engifoundry-gate/
│   │   └── SKILL.md
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

The main manual skill entry point is `skills/engifoundry/`. The plugin autoload gate is `skills/engifoundry-gate/`. Root-level documentation is for users and maintainers.

## Core Concepts

EngiFoundry has two skill entry points and several operating modes.

Manual users should invoke the main entry point:

```text
$engifoundry
```

Plugin autoload should target the gate entry point:

```text
$engifoundry-gate
```

The gate only decides whether the current workspace makes EngiFoundry available. It inspects first-level children of the current working directory, treats `.git/` as a super signal, and does not recurse. A gate match does not force package governance; the main `engifoundry` skill still selects the actual mode from the user's prompt and project state.

| Mode | Purpose |
| --- | --- |
| `ad-hoc` | Bounded low-risk work without package ceremony |
| `package-planning` | Create or revise a structured task package |
| `package-alignment` | Review whether package planning can be marked ready |
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
├── directory.config.json
├── roadmaps/
│   ├── ROADMAP.md
│   ├── roadmap.index.json
│   └── archive/
├── records/
│   ├── ad-hoc/
│   ├── packages/
│   ├── reviews/
│   └── audits/
└── docs/
    ├── generated/
    ├── integration/
    ├── design/
    ├── reference/
    └── archive/
```

The artifact root should contain only durable, inspectable, useful work products.

## Roadmaps

ROADMAP archives are durable alignment artifacts and live under `<artifact-root>/roadmaps/`.

When the user has done requirement alignment, planning, or pre-task discussion and asks to persist it, EngiFoundry writes or updates `ROADMAP.md` and `roadmap.index.json`. When the user asks what to do next or asks to confirm the next step, EngiFoundry checks for an active roadmap and uses it together with current progress. If no roadmap exists, it decides from current session context, visible project state, and the user's stated goal.

Do not store roadmap state in `.engifoundry.config.json`; the project config only locates the artifact root.

## Initialization Scripts

EngiFoundry includes functional initialization scripts for macOS, Linux, and Windows. They do not require Python.

Run them in order:

1. `create_root_config`
2. `create_standard_dirs`
3. `create_directory_config`

Templates are formal editable files, not reference examples. Use the POSIX shell `.sh` scripts on macOS/Linux and the PowerShell `.ps1` scripts on Windows. Configuration template scripts support `empty` and `filled` modes, with values supplied from prompt context when available.

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
  "executors": {
    "multi-session": {
      "type": "local-multi-session",
      "command": "codex",
      "supportsStdin": true,
      "stdinMode": "prompt-pipe",
      "bestInvocation": "codex exec --json",
      "supportsStructuredOutput": true,
      "structuredOutputFormat": "jsonl",
      "outputNoise": "low",
      "requiresOutputPreprocessing": true,
      "preprocessingNotes": "Extract the final assistant result from JSONL event output.",
      "timeoutBehavior": "long-running; do not abort solely because a fixed elapsed-time or wait-turn window passed",
      "livenessSignals": ["process-alive", "progress-event", "probe-response"],
      "probeBehavior": "on silence, request status before fallback or abort",
      "stallCriteria": "no probe response or repeated non-evidential working reports",
      "abortCriteria": "process exit without handback, explicit blocked status, repeated failed probes, contract violation, or stop condition",
      "heartbeatSchema": ["status", "phase", "last_event", "next", "needs_control", "blocked_reason"],
      "finalReportSchema": ["job_id", "status", "changed_files", "behavior_summary", "evidence_paths", "verification", "known_gaps", "recommendation"],
      "rawStreamPolicy": "read raw stream only on failure, blocked execution, verification mismatch, strict review escalation, or explicit user request",
      "supportsParallel": true,
      "supportsReviewOnly": true
    },
    "external-cli": {
      "type": "third-party-cli",
      "command": "kimi",
      "supportsStdin": false,
      "stdinMode": "interactive-only",
      "bestInvocation": "kimi",
      "supportsStructuredOutput": false,
      "outputNoise": "medium",
      "requiresOutputPreprocessing": true,
      "preprocessingNotes": "Manual summary extraction may be required.",
      "timeoutBehavior": "human-observed; do not abort solely because a fixed elapsed-time or wait-turn window passed",
      "livenessSignals": ["human-status", "probe-response"],
      "probeBehavior": "ask for current status, recent work, next action, and blockers",
      "stallCriteria": "no response or repeated non-evidential working reports",
      "abortCriteria": "explicit blocked status, repeated failed probes, contract violation, or stop condition",
      "heartbeatSchema": ["status", "phase", "last_event", "next", "needs_control", "blocked_reason"],
      "finalReportSchema": ["job_id", "status", "changed_files", "behavior_summary", "evidence_paths", "verification", "known_gaps", "recommendation"],
      "rawStreamPolicy": "human observed; summarize raw output before review context unless escalated",
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

`selectionPolicy.prefer` is ordered; the first available executor is preferred.

For a new project with no usable `execution.config.json`, EngiFoundry uses `direct` for ad-hoc and simple `primary/control` work. If package work requires bounded or isolated execution and no usable executor config exists, primary/control safely discovers local executor capability or asks the user which executor to register or use.

When aligning a new project or new EngiFoundry session, EngiFoundry should read `execution.config.json` after locating the artifact root when that file exists, so executor order, invocation methods, capability fields, and known limitations stay in current-session context. This is not required before every ad-hoc task. If alignment or safe discovery finds missing executor knowledge, EngiFoundry should suggest recording durable non-sensitive facts in the matching `execution.config.json` fields without forcing a write.

Executor choice is separate from quality discipline. EngiFoundry models execution with three independent dimensions:

```text
executor   = who or what performs the work
isolation  = how separated the execution/review context is
discipline = quality preset such as quick, standard, or strict
```

During normal monitoring, primary/control should not continuously ingest raw executor streams. `quick` prefers direct execution or final-report-only handback; `standard` prefers compact heartbeats and compact final handback; `strict` keeps stronger review and evidence requirements while still avoiding default raw-stream ingestion.

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

`package.config.json` is the machine-readable package contract. It should define package planning status, execution status, Job order, default execution policy, acceptance gates, checkpoint references, and closeout requirements.

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

The installed skill version is recorded in `skills/engifoundry/VERSION`. Version is a maintenance label. EngiFoundry may check for updates at most once per session during first alignment when network access is available; no-update and failed checks stay silent.

Plugin installation is the preferred full installation mode when the host supports plugins. Installers should choose plugin installation whenever `.codex-plugin/plugin.json` or `.claude-plugin/plugin.json` is present. Skills-only installation is a compatibility fallback, not the preferred full install.

Codex-compatible installations use:

```text
.codex-plugin/plugin.json
skills/
```

For a prompt such as "install the latest EngiFoundry skill from GitHub" or "install this skill: <repository URL>", a Codex-compatible installer should treat this repository as a plugin package because `.codex-plugin/plugin.json` is present, then install the plugin so the `engifoundry-gate` and `engifoundry` entries are discovered from the shared `skills/` directory.

Claude-compatible installations use:

```text
.claude-plugin/plugin.json
skills/
```

Kimi-compatible installations should install or symlink the `skills/` entries into a Kimi-supported skills directory. This repository does not assume a stable Kimi marketplace.

Skills-only installation is still supported when the host has no plugin support or the user explicitly requests skills-only installation. Copy or symlink both skill folders:

```text
skills/engifoundry-gate/
skills/engifoundry/
```

to the target agent's skills directory. For Codex skills-only installation:

```text
~/.codex/skills/engifoundry-gate/
~/.codex/skills/engifoundry/
```

Then restart the host so skill metadata is rescanned.

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
