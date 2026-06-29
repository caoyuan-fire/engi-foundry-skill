# Package Format

TaskForge packages separate human narrative from machine control.

Markdown explains. JSON controls.

## Directory Layout

```text
packages/<package-id>/
├── summary.md
├── package.config.json
├── jobs/
│   └── JOB-001/
│       ├── job.md
│       ├── job.config.json
│       ├── record.md
│       ├── review.md
│       └── verification.md
├── checkpoints/
├── handoffs/
└── closeout.md
```

## Package Rules

- A package is both human-readable and machine-readable.
- Markdown files carry human meaning and review context.
- JSON files carry machine-readable control data.
- JSON must not duplicate long Markdown narratives.
- Markdown must not be treated as the authoritative machine-control source.

## `summary.md`

`summary.md` is for humans only.

It should explain:

- package background;
- purpose;
- scope;
- non-goals;
- current state;
- target state;
- Job overview;
- risks;
- acceptance criteria;
- closeout requirements.

It may include a Job overview table:

```markdown
| Job | Purpose | Depends On | Discipline | Status |
| --- | --- | --- | --- | --- |
```

The table is a readable summary. It is not authoritative configuration.

## `package.config.json`

`package.config.json` is the machine-readable package contract.

It should record:

- `schemaVersion`;
- `packageId`;
- package status;
- Job list;
- Job order and dependencies;
- default execution policy;
- acceptance gates;
- checkpoint references;
- handoff references;
- closeout requirements.

Example:

```json
{
  "schemaVersion": 1,
  "packageId": "pkg-example",
  "status": "planned",
  "jobs": ["JOB-001", "JOB-002"],
  "jobOrder": [
    {
      "jobId": "JOB-001",
      "dependsOn": []
    },
    {
      "jobId": "JOB-002",
      "dependsOn": ["JOB-001"]
    }
  ],
  "defaultExecutionPolicy": {
    "executor": "multi-session",
    "isolation": "isolated-execution",
    "discipline": "standard",
    "reviewRequired": true
  },
  "acceptance": {
    "requiresAllJobsApproved": true,
    "requiresVerificationEvidence": true,
    "requiresCloseout": true
  }
}
```

## Checkpoints and Handoffs

Checkpoints record package state at a pause point.

Handoffs prepare another session, tool, or human to continue.

These files support role recovery but do not permanently bind control authority to any product.

## Closeout

`closeout.md` records final acceptance, remaining risks, verification status, and handoff notes for future work.
