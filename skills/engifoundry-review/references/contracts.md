# Review Contracts

## Record Locations

```text
<artifact-root>/reviews/<phase-id>/<package-id>/planning/REVIEW-001.json
<artifact-root>/reviews/<phase-id>/<package-id>/<job-id>/REVIEW-001.json
<artifact-root>/reviews/general/REVIEW-001.json
```

Allocate `REVIEW-*` monotonically within the subject directory. Every attempt is immutable, including rework and blocked attempts.

## Pass

```json
{
  "schemaVersion": 1,
  "reviewId": "REVIEW-001",
  "context": "clean",
  "subject": {
    "kind": "planning",
    "refs": [".engifoundry/packages/PHASE-001/PAK-001/package.config.json"]
  },
  "result": "pass",
  "evidenceRefs": [".engifoundry/packages/PHASE-001/PAK-001/summary.md"]
}
```

Subject kind is `planning`, `job`, or `artifact`. A pass record omits `findings` and `blocker`.

## Rework

```json
{
  "schemaVersion": 1,
  "reviewId": "REVIEW-002",
  "context": "clean",
  "subject": {
    "kind": "job",
    "refs": [".engifoundry/packages/PHASE-001/PAK-001/jobs/JOB-001/job.config.json"]
  },
  "result": "rework-required",
  "evidenceRefs": ["src/example.ts", "test-results/unit.json"],
  "findings": [
    {
      "kind": "subject",
      "fact": "The changed behavior does not satisfy the recorded acceptance criterion.",
      "evidenceRefs": ["test-results/unit.json"],
      "affectedRefs": ["src/example.ts"]
    }
  ]
}
```

Finding kind is `subject` or `contract`. State an observed defect, not a solution. Include only relevant evidence and affected references.

## Blocked

For `blocked`, omit `findings` and add:

```json
{
  "blocker": {
    "fact": "The required encrypted subject cannot be read with the available credentials.",
    "unavailableRequirement": "Inspect the complete subject.",
    "alternativeEvidenceAttempted": []
  }
}
```

## State Meanings

| Subject fact | Recorded state |
| --- | --- |
| Current planning has a clean-context pass and no newer invalidating evidence. | `planning.status: ready` with the pass `planning.reviewRef`. |
| Current planning has an unresolved Review or downstream contract finding. | `planning.status: rework-required` with the relevant evidence retained. |
| Job output exists and awaits Review. | Job `pending-review` without a current pass record. |
| Job Review passed but Exec completion or approval facts are not yet recorded. | Job `pending-review` with the pass `reviewRef`. |
| Current Job output or contract has an unresolved finding. | Job `rework-required` with the finding `reviewRef`. |
| Review itself cannot reach a conclusion because of an objective unavailable requirement. | The applicable subject is `blocked` with the blocker evidence. |
| A durable subject has no EngiFoundry control state. | Only the immutable Review record is required. |

The subject state and `reviewRef` must describe the same current evidence before the Reviewer Agent finishes.

## Forbidden Content

Do not store prompts, reasoning, implementation discussion, intended conclusions, raw streams, routine progress, complete command output, or long logs.
