---
name: engifoundry-deliver
description: Apply EngiFoundry automation preferences to verified-available PAK evidence, obtain acceptance when required, close delivery, or record rejected acceptance for rework.
---

# EngiFoundry Deliver

Read `./engifoundry.config.json`, the project-owned workspace guide, Workflow config, and [contracts.md](references/contracts.md). Then read the PAK, its `execution.verificationRef`, the referenced Verify record, required artifacts, and closeout requirements.

## Boundary

The Agent reads this contract only for a PAK whose latest verification result is `verified-available` and whose execution status is `verified-available` or `acceptance-pending`. Verification evidence is input; during this work the Agent does not repeat Verify or Review, implement rework, or revise contracts.

## Acceptance

The acceptance record and Package state describe exactly one current fact:

1. `full-auto` supplies `auto-accepted` when current verification is `verified-available`.
2. `job-approval` and `package-approval` are `acceptance-pending` until the user decides on the concise Verify result.
3. User approval supplies `user-approved`.
4. An actionable implementation rejection is `rework-required` with kind `implementation`.
5. A changed goal or contract is `rework-required` with kind `contract`.
6. A rejection without an actionable fact remains `acceptance-pending` and requires the reason.

Every `rework-required` acceptance fact has an immutable rejection record attached as `execution.deliveryRef`. Implementation rejection means the affected Jobs and Package execution are also `rework-required`; contract rejection means Package planning is also `rework-required`.

## Closeout

Confirm every required artifact is referenced and every closeout requirement is satisfied. Create only delivery outputs required by the PAK. Satisfied acceptance and closeout facts are recorded in one immutable delivery JSON, attached as `execution.deliveryRef`, with `execution.status: completed`.

Every completed PAK also has the matching human-readable `DELIVERY-<NNN>.md` defined by the reference contract. It summarizes PAK execution, current engineering state, evidence and artifacts, severity-labeled risks, and handoff facts. This summary is required even when no additional user-facing document was requested.

A missing closeout item is work to finish, not acceptance failure. `blocked` describes only an objective closeout condition the Agent cannot resolve during delivery work; it has an immutable record attached as `execution.deliveryRef`.

## Continuation

- `completed` is terminal with its delivery record.
- An `implementation` rejection makes Exec the applicable correction contract.
- A `contract` rejection makes Orch the applicable correction contract.
- `acceptance-pending` and `blocked` are terminal for the current turn while their facts remain.

The Agent never reports delivery completion without `execution.status: completed` and a durable `execution.deliveryRef`.
