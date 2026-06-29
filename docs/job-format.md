# Job Format

Each EngiFoundry Job is a directory with human-readable intent and machine-readable control.

## Directory Layout

```text
jobs/JOB-001/
├── job.md
├── job.config.json
├── record.md
├── review.md
└── verification.md
```

## `job.md`

`job.md` is human-facing.

It should describe:

- background;
- goal;
- scope;
- non-goals;
- business meaning;
- risks;
- acceptance criteria;
- implementation notes.

`job.md` may include nuance and narrative. It should not be parsed as the authoritative execution contract.

## `job.config.json`

`job.config.json` is machine-facing.

It should record:

- `schemaVersion`;
- `jobId`;
- status;
- dependencies;
- allowed areas;
- forbidden areas;
- execution policy;
- verification commands;
- output contract;
- required outputs;
- review requirement.

Example:

```json
{
  "schemaVersion": 1,
  "jobId": "JOB-001",
  "status": "planned",
  "dependsOn": [],
  "allowedAreas": ["src", "tests"],
  "forbiddenAreas": ["release"],
  "executionPolicy": {
    "executor": "multi-session",
    "isolation": "isolated-execution",
    "discipline": "standard",
    "reviewRequired": true
  },
  "verification": {
    "commands": ["npm test"],
    "evidenceRequired": true
  },
  "outputContract": {
    "format": "markdown-summary",
    "maxLines": 120,
    "includeEvidenceIndex": true
  },
  "requiredOutputs": ["record.md", "verification.md"]
}
```

## `record.md`

`record.md` is the executor's execution record.

It should include:

- actual work summary;
- changed areas;
- verification evidence;
- deviations from the Job contract;
- remaining risks;
- follow-up recommendations.

It should not dump raw long logs. Prefer concise evidence indexes.

## `review.md`

`review.md` is the reviewer output.

It should include:

- result: `pass`, `blocked`, or `needs-rework`;
- findings;
- evidence;
- affected acceptance criteria;
- required rework;
- follow-up review requirements.

## `verification.md`

`verification.md` records validation.

It should include:

- commands run;
- execution context;
- pass/fail result;
- failure details;
- reason if verification cannot be run;
- alternative evidence when verification is non-runnable.
