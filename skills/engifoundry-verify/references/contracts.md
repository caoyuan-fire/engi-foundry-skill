# Verify Contracts

## State Meanings

| Package execution status | Current fact |
| --- | --- |
| `jobs-completed` | Every Job satisfies its completion facts; goal-level verification has not produced a newer conclusion. |
| `verifying` | The Agent is gathering fresh evidence for the complete PAK goal. |
| `verified-available` | Every criterion and required check is satisfied and usable evidence is available to Deliver. This is not `pass`, approval, acceptance, or delivery. |
| `rework-required` | At least one `implementation` or `contract` finding shows the current PAK goal or contract is unsatisfied. |
| `blocked` | A required goal-level check is objectively unavailable and no valid alternative evidence exists. |

Every concluded verification state attaches its immutable record path as `execution.verificationRef`. An implementation finding also means affected Jobs are `rework-required`; a contract finding means planning is `rework-required`.

## Record Location

```text
<artifact-root>/verification/<phase-id>/<package-id>/VERIFY-001.json
```

Allocate `VERIFY-*` monotonically. Never overwrite or renumber an earlier attempt.

## Available Evidence

```json
{
  "schemaVersion": 1,
  "phaseId": "PHASE-001",
  "packageId": "PAK-001",
  "verificationId": "VERIFY-001",
  "result": "verified-available",
  "criteria": [
    {
      "criterion": "The complete target workflow works as specified.",
      "status": "satisfied",
      "evidenceRefs": ["check:CHECK-001"]
    }
  ],
  "checks": [
    {
      "checkId": "CHECK-001",
      "name": "automated-tests",
      "command": "npm test",
      "status": "succeeded"
    }
  ]
}
```

Rules:

- `criteria` contains every PAK acceptance criterion exactly once.
- Criterion status is `satisfied` or `unsatisfied`.
- Check status is `succeeded`, `failed`, or `blocked`.
- `checkId` is unique within the verification record and may be referenced as `check:CHECK-001`.
- A check records a reproducible `command` or a concise `method`.
- Evidence references point to durable outputs; never copy raw or long logs.
- Omit `findings` when the result is `verified-available`.

## Rework Evidence

```json
{
  "schemaVersion": 1,
  "phaseId": "PHASE-001",
  "packageId": "PAK-001",
  "verificationId": "VERIFY-002",
  "result": "rework-required",
  "criteria": [
    {
      "criterion": "The complete target workflow works as specified.",
      "status": "unsatisfied",
      "evidenceRefs": ["check:CHECK-001"]
    }
  ],
  "checks": [
    {
      "checkId": "CHECK-001",
      "name": "automated-tests",
      "command": "npm test",
      "status": "failed"
    }
  ],
  "findings": [
    {
      "kind": "implementation",
      "fact": "The final action does not persist the submitted value.",
      "evidenceRef": "check:CHECK-001",
      "affectedJobs": ["JOB-002"]
    }
  ]
}
```

Finding kind is `implementation` or `contract`. State an observed fact, not a proposed solution. Add `evidenceRef` and `affectedJobs` only when relevant.

For `blocked`, replace `findings` with one `blocker` containing the objective fact, unavailable requirement, and any alternative evidence attempted.

## Forbidden Content

Do not store prompts, reasoning, raw streams, routine progress, complete command output, duplicated Job Reviews, approval decisions, or delivery conclusions.
