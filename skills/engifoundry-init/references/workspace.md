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
| `.engifoundry/executors.json` | Available Executor facts and their configured selection order. |
| `.engifoundry/workflows.json` | Fixed delivery workflow automation and approval policy. |
| `.engifoundry/artifacts/plans/` | Durable planning and design outputs. |
| `.engifoundry/artifacts/records/` | Durable execution and decision records. |
| `.engifoundry/artifacts/reviews/` | Review findings and decisions. |
| `.engifoundry/artifacts/verification/` | Test, lint, type-check, CI, and other verification evidence. |
| `.engifoundry/artifacts/delivery/` | Accepted delivery, handoff, and closeout outputs. |
| `.engifoundry/artifacts/legacy/` | Migration fallback for unchanged content that cannot be inherited reliably and legacy control JSON retained as evidence. |
| `.engifoundry/packages/` | Task package inputs when package workflow is explicitly used. This path is ignored through `.gitignore`. |

## Output Rule

Write durable EngiFoundry outputs only to the matching `artifacts/` directory. Keep caches, temporary files, raw session logs, credentials, and secrets outside `.engifoundry/`.
