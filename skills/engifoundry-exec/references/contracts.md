# Exec Contracts

## State Meanings

| Job status | Current fact |
| --- | --- |
| `planned` | A reviewed Job contract exists and implementation has not started. |
| `in-progress` | Implementation is active and no complete result is awaiting Review. |
| `pending-review` | Required output and fresh execution evidence exist, but completion facts are not yet satisfied. A pass `reviewRef` means only approval or final recording remains. |
| `approval-pending` | Current Review passed and `job-approval` still lacks the user's decision. |
| `completed` | Required outputs exist, current clean-context Review passed, and configured approval is satisfied. |
| `rework-required` | Current Review, Verify, Deliver, or user evidence shows that output or contract facts are unsatisfied. |
| `blocked` | An objective condition prevents execution or Review and cannot be resolved or routed around. |

| Package execution status | Current fact |
| --- | --- |
| `not-started` | No Job implementation has begun. |
| `in-progress` | At least one Job is active or awaiting Review or approval. |
| `jobs-completed` | Every Job currently satisfies `completed`; Package Verify has not established delivery acceptance. |
| `rework-required` | Current evidence requires implementation or contract correction before all Jobs can again be complete. |
| `blocked` | An objective execution condition remains unresolved. |

Newer evidence may make a former `completed` or `jobs-completed` record inaccurate. The Agent reconciles it to the state whose meaning matches current facts; no separate reopen state exists.

## Result Location

Write exactly one result per Job:

```text
<artifact-root>/records/<phase-id>/<package-id>/<job-id>.json
```

Write it atomically only when the Job reaches `completed` or factual `blocked`. JSON controls status; this result is concise execution evidence, never a progress log.

## Normal Result

```json
{
  "schemaVersion": 1,
  "phaseId": "PHASE-001",
  "packageId": "PAK-001",
  "jobId": "JOB-001",
  "executorId": "codex-cli",
  "result": {
    "status": "completed",
    "summary": "Implemented the bounded Job scope."
  },
  "approval": "user-approved",
  "changedAreas": ["src", "tests"],
  "outputs": ["build/report.json"],
  "reviewRef": ".engifoundry/artifacts/reviews/PHASE-001/PAK-001/JOB-001/REVIEW-001.json"
}
```

Rules:

- `result.status` is `completed` or `blocked`.
- Keep `result.summary` to one factual sentence.
- Include `approval: user-approved` only when `automationMode` is `job-approval`.
- `changedAreas` contains paths or external objects, not a prose diff.
- `outputs` contains durable result references that cannot be inferred from the workspace diff.
- Omit `changedAreas` or `outputs` when empty.
- A completed result requires `reviewRef` to a pass record.
- Do not duplicate Review content.

## Exceptions

Add `exceptions` only when something exceptional occurred:

```json
{
  "exceptions": [
    {
      "type": "executor-fallback",
      "fact": "codex-cli exited before returning a result.",
      "executorId": "codex-cli"
    },
    {
      "type": "contract-deviation",
      "fact": "The required target was unavailable.",
      "evidenceRef": ".engifoundry/artifacts/verification/target-unavailable.json"
    }
  ]
}
```

Allowed exception types are `executor-unavailable`, `executor-fallback`, `contract-deviation`, `check-non-runnable`, `user-rejected`, and `blocked`.

Each exception states an objective fact. Add `executorId` or `evidenceRef` only when relevant. Never use exceptions as a progress log.

Each fact in `job.config.json.reworkFacts` must appear as a `user-rejected` exception in the completed Job result.

Each `reworkFacts` entry has this shape:

```json
{
  "kind": "implementation",
  "fact": "The reviewed step still requires an unwanted manual action."
}
```

Kind is `implementation` or `contract`. Store the user's actionable fact, not conversation text or a proposed solution.

## Executor Handback

A delegated Executor returns only:

- Job id and result;
- changed areas;
- durable output or evidence paths;
- exceptions or control needed.

The control session writes the canonical result. Raw Executor output is transient and is never the record.
