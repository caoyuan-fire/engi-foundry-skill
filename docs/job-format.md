# Job Format

Each EngiFoundry Job has human-readable intent, machine-readable control, and durable output records.

## Control Input Layout

```text
<package-root>/<package-id>/jobs/JOB-001/
├── job.md
└── job.config.json
```

## Durable Output Layout

```text
<artifact-root>/records/packages/<package-id>/jobs/JOB-001/
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
- `type`: `delegable | primary-control-only | review-only | blocked`;
- dependencies;
- allowed areas;
- forbidden areas;
- stop conditions;
- execution policy;
- verification commands;
- output contract;
- required return format;
- required outputs;
- review requirement.
- delegation reason or primary execution reason when relevant.

Example:

```json
{
  "schemaVersion": 1,
  "jobId": "JOB-001",
  "status": "planned",
  "type": "delegable",
  "dependsOn": [],
  "allowedAreas": ["src", "tests"],
  "forbiddenAreas": ["release"],
  "stopConditions": ["unexpected release-file changes", "verification cannot run"],
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
    "includeEvidenceIndex": true,
    "rawStreamPolicy": "summary-only"
  },
  "requiredReturnFormat": "record-with-verification-evidence",
  "requiredOutputs": ["record.md", "verification.md"]
}
```

## Completion Gate

Executor completion does not complete the Job.

A Job reaches a completed or approved state only after required records, verification evidence, review, and primary/control approval are consistent with the package contract.

`primary/control` owns completion approval and status updates unless it explicitly records a narrower authorization in the package contract.

## Delegability and Stop Conditions

`type` should be explicit when package work may be delegated.

Allowed values:

- `delegable`: bounded work may be assigned to an executor.
- `primary-control-only`: only `primary/control` may perform the work.
- `review-only`: review work without implementation.
- `blocked`: work cannot start until `primary/control` revises the package or records unblock evidence.

`stopConditions` define situations where executor or reviewer sessions must stop and return control instead of improvising.

`requiredReturnFormat` describes the expected handback shape so the primary/control session can review evidence efficiently.

`outputContract` carries detailed formatting and verbosity constraints. `requiredReturnFormat` is the named handback shape, `requiredOutputs` is the durable file checklist, and `outputContract` defines limits such as maximum length, evidence-index requirements, and raw stream handling.

Normal executor handback should be compact. It should include enough evidence paths and known gaps for primary/control review without copying raw command logs, full file contents, or verbose process streams.

Required outputs are durable records and should be written under `<artifact-root>/records/packages/<package-id>/jobs/<job-id>/` unless the package contract explicitly records another artifact-root path.

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
