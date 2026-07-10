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

## Record Locations

```text
<artifact-root>/delivery/<phase-id>/<package-id>/DELIVERY-001.json
<artifact-root>/delivery/<phase-id>/<package-id>/DELIVERY-001.md
```

Allocate `DELIVERY-*` monotonically. Never overwrite or renumber an earlier acceptance attempt. The Markdown companion is required only for a completed delivery and shares its JSON identifier.

## Completed Delivery

```json
{
  "schemaVersion": 1,
  "phaseId": "PHASE-001",
  "packageId": "PAK-001",
  "deliveryId": "DELIVERY-001",
  "result": "completed",
  "summaryRef": ".engifoundry/artifacts/delivery/PHASE-001/PAK-001/DELIVERY-001.md",
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

## Human Summary

`DELIVERY-<NNN>.md` is the PAK's durable human handoff. Prefer readable narrative and content-appropriate tables or lists. It contains:

- PAK identity, goal, and final result;
- concise execution summary and current engineering state;
- verification and delivered artifact references;
- remaining risks labeled `critical`, `high`, `medium`, or `low`, including impact and evidence, or an explicit statement that no remaining risk was identified;
- handoff status, open actions, and the next entry point when one exists.

Reflect current records without reproducing JSON, command transcripts, or per-Job history. The JSON remains authoritative for control state.

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
