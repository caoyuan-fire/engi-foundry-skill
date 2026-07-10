# Deliver Contracts

## State Meanings

| Package execution status | Current fact |
| --- | --- |
| `verified-available` | Goal-level evidence is available and no acceptance decision has been recorded. |
| `acceptance-pending` | Current verification is available, but configured user acceptance is still missing. No delivery record exists yet. |
| `completed` | Acceptance and every closeout requirement are satisfied, with an immutable delivery record. |
| `rework-required` | Actionable acceptance evidence shows implementation or contract facts are unsatisfied, with an immutable rejection record. |
| `blocked` | An objective closeout requirement is unavailable and the Agent cannot resolve it while following the delivery contract, with an immutable blocker record. |

Implementation rejection also means affected Jobs and Package execution are `rework-required`. Contract rejection means Package planning is `rework-required`.

## Record Location

```text
<artifact-root>/delivery/<phase-id>/<package-id>/DELIVERY-001.json
```

Allocate `DELIVERY-*` monotonically. Never overwrite or renumber an earlier acceptance attempt.

## Completed Delivery

```json
{
  "schemaVersion": 1,
  "phaseId": "PHASE-001",
  "packageId": "PAK-001",
  "deliveryId": "DELIVERY-001",
  "result": "completed",
  "verificationRef": ".engifoundry/artifacts/verification/PHASE-001/PAK-001/VERIFY-001.json",
  "acceptance": {
    "mode": "package-approval",
    "decision": "user-approved"
  },
  "artifacts": ["dist/release.zip"],
  "closeout": [
    {
      "requirement": "Release artifact is available.",
      "status": "satisfied",
      "evidenceRefs": ["dist/release.zip"]
    }
  ]
}
```

Acceptance decision is `auto-accepted` or `user-approved`. `artifacts` contains references only. `closeout` maps every PAK closeout requirement exactly once to concise evidence.

## Rejected Acceptance

```json
{
  "schemaVersion": 1,
  "phaseId": "PHASE-001",
  "packageId": "PAK-001",
  "deliveryId": "DELIVERY-002",
  "result": "rework-required",
  "verificationRef": ".engifoundry/artifacts/verification/PHASE-001/PAK-001/VERIFY-001.json",
  "acceptance": {
    "mode": "package-approval",
    "decision": "user-rejected"
  },
  "rejection": {
    "kind": "implementation",
    "fact": "The accepted workflow still requires an extra manual step."
  }
}
```

Rejection kind is `implementation` or `contract`. Record the user's actionable fact without copying the conversation or proposing a solution.

For `blocked`, replace `rejection` with one `blocker` containing the objective fact and unavailable closeout requirement.

## Forbidden Content

Do not duplicate Verify checks, Job results, Reviews, implementation details, raw conversation, routine progress, or long logs.
