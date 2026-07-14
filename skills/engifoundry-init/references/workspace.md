# EngiFoundry Workspace

This file describes the EngiFoundry-owned structure in this project. It is copied during initialization and becomes project-owned knowledge. Work sessions use it to locate configuration facts and durable outputs.

## Structure

```text
<project-root>/
|-- engifoundry.config.json
`-- .engifoundry/
    |-- workspace.md
    |-- initialization.json
    |-- executors.json
    |-- workflows.json
    |-- artifacts/
    |   |-- plans/
    |   |-- records/
    |   |-- reviews/
    |   |-- verification/
    |   `-- delivery/
    `-- packages/
```

## Directory Responsibilities

| Path | Responsibility |
| --- | --- |
| `./engifoundry.config.json` | The only project discovery entry. It points to project knowledge and configuration facts. |
| `.engifoundry/workspace.md` | Project-owned guide to EngiFoundry structure and output locations. |
| `.engifoundry/initialization.json` | Initialization progress facts maintained through the Init state scripts. |
| `.engifoundry/executors.json` | Available Executor facts, configured selection order, and preferred invocation templates for CLI executors. |
| `.engifoundry/workflows.json` | Fixed delivery workflow automation and approval policy. |
| `.engifoundry/artifacts/plans/` | Durable planning and design outputs. |
| `.engifoundry/artifacts/records/` | Durable execution and decision records, including human-readable snapshots at actual pause points. |
| `.engifoundry/artifacts/reviews/` | Review findings and decisions. |
| `.engifoundry/artifacts/verification/` | Test, lint, type-check, CI, and other verification evidence. |
| `.engifoundry/artifacts/delivery/` | Accepted delivery records and required human-readable PAK execution summaries for handoff. |
| `.engifoundry/artifacts/legacy/` | Migration fallback for unchanged content that cannot be inherited reliably and legacy control JSON retained as evidence. |
| `.engifoundry/packages/` | Task package inputs when package workflow is explicitly used. This path is excluded from repository history unless the user explicitly requests task-package inclusion. |

## Output Rule

Write durable EngiFoundry outputs only to the matching `artifacts/` directory. Keep caches, temporary files, raw session logs, credentials, and secrets outside `.engifoundry/`.

The `.gitignore` rule for `.engifoundry/packages/` remains effective for broad requests to stage, check in, commit, or push current or all changes. Only an explicit request to include task packages in repository history authorizes overriding that rule.
