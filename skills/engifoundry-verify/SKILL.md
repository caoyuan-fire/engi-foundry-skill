---
name: engifoundry-verify
description: Verify a jobs-completed EngiFoundry PAK against its complete task goal and acceptance criteria, record durable evidence, and identify the next applicable contract without accepting delivery.
---

# EngiFoundry Verify

Read `./engifoundry.config.json`, the project-owned workspace guide, and [contracts.md](references/contracts.md). Then read the Phase context, PAK summary and JSON, every Job result and Review, and every required artifact.

## Boundary

The Agent reads this contract only for a PAK with `planning.status: ready` and `execution.status: jobs-completed`, and verifies the complete PAK goal rather than individual Job steps. During this work, the Agent does not implement, revise contracts, repeat Job Review, accept verification, or deliver.

Automation preferences do not affect verification evidence. That evidence is an input fact for Deliver.

## Verification

1. Record `execution.status: verifying` while goal-level evidence is being gathered.
2. Map every PAK acceptance criterion to fresh evidence.
3. Confirm every required artifact exists and is usable.
4. Run every check required by the goal and project facts, such as build, automated tests, unit tests, lint, type checking, integration checks, or target-environment checks. Do not offer a menu or skip a required check.
5. For non-code goals, use target-appropriate inspection and evidence. Absence of a code command is not a blocker; inability to perform a required check can be.
6. Write one immutable verification record using the reference contract and attach it as `execution.verificationRef`.

The completed verification record has exactly one result whose meaning matches the evidence:

1. If every criterion is satisfied, every required artifact is usable, and every required check succeeds, write `verified-available`.
2. If evidence shows a correctable implementation or contract failure, write `rework-required` with the finding kind and facts.
3. If a required verification cannot run because of an objective external condition and no valid alternative evidence exists, write `blocked`.

Never write `pass`. `verified-available` means evidence is available; it is not acceptance or approval. A failed check is `rework-required`, not `blocked`.

When implementation evidence is `rework-required`, affected Jobs and Package execution also carry `rework-required` because their former completion facts no longer hold. When contract evidence is `rework-required`, Package planning carries `rework-required` because its former `ready` fact no longer holds. Preserve the verification record that establishes the newer fact.

## Continuation

- For an endpoint that includes delivery, `verified-available` lets the Agent read Deliver and continue with the PAK and verification record.
- An `implementation` finding makes Exec the applicable correction contract.
- A `contract` finding makes Orch the applicable correction contract.
- `blocked` is terminal while its objective fact remains.

Never continue without the required record or without loading the destination Skill first.
