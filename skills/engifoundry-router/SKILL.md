---
name: engifoundry-router
description: Declare EngiFoundry Node Skill contracts, their project-state signals, records, responsibilities, and possible navigation destinations so the Agent can assemble the contracts needed for a request.
---

# EngiFoundry Router

## Entry

When `./engifoundry.config.json` exists, this Router must be loaded before runtime contract selection on every user turn. It remains in session context, and the Agent may reread it whenever useful. After a stage operation completes, the Agent may reread this Router against current records before selecting more contracts.

Read the configured Initialization record before applying runtime contracts. An Init interaction already active in the current conversation continues under the Init Lock. Otherwise, when initialization is not `complete`, an explicit request to use EngiFoundry for other work receives the incomplete fact and cannot use runtime contracts; only an explicit request to continue or complete initialization makes the Agent read Init. A request that does not explicitly ask for EngiFoundry proceeds normally without EngiFoundry runtime contracts.

## Node Contracts

| Contract | Responsibility | Project-owned inputs | Recorded result facts | Possible next contracts |
| --- | --- | --- | --- | --- |
| `engifoundry-init` | Create, migrate, or modify the EngiFoundry scaffold and preferences. | Current or legacy scaffold, Initialization, Executor, and Workflow configs. | `complete` or `cancelled`. | Any runtime contract selected by the Agent after completion. |
| `engifoundry-orch` | Create or revise Phase, PAK, and Job execution contracts. | Phase index, Roadmaps, PAK and Job contracts. | `direct`, `ready`, explicit draft, `discarded`, or factual `blocked`. | Agent direct action for a `direct` Audit classification; `engifoundry-exec` for a ready PAK. |
| `engifoundry-exec` | Execute and Review ordered Job steps. | PAK and Job contracts, Executor and Workflow configs, Job results and Reviews. | `jobs-completed` or factual `blocked`. | `engifoundry-verify`; `engifoundry-orch` for contract revision. |
| `engifoundry-verify` | Verify the completed PAK goal without accepting it. | PAK acceptance criteria, required artifacts, Job results and Reviews. | `verified-available`, `rework-required`, or factual `blocked`. | `engifoundry-deliver`; `engifoundry-exec` for implementation rework; `engifoundry-orch` for contract rework. |
| `engifoundry-deliver` | Apply automation preferences to available verification and close delivery. | Verify evidence and Workflow config. | Delivery complete, approval pause, rejection, or factual `blocked`. | `engifoundry-exec` for rejected acceptance requiring implementation rework; `engifoundry-orch` when rejection changes the contract; terminal. |

## State Signals

| Recorded signal | Candidate contract |
| --- | --- |
| Initialization is incomplete or preferences are being changed. | `engifoundry-init` |
| No applicable ready PAK exists, or contracts need revision. | `engifoundry-orch` |
| A ready PAK has incomplete or rework Jobs. | `engifoundry-exec` |
| A Job is `approval-pending`. | `engifoundry-exec` |
| PAK execution is `jobs-completed`. | `engifoundry-verify` |
| Current verification evidence is `verified-available`. | `engifoundry-deliver` |
| Delivery is `acceptance-pending`. | `engifoundry-deliver` |
| Current verification evidence identifies implementation rework. | `engifoundry-exec` |
| Current verification evidence identifies contract rework. | `engifoundry-orch` |
| Delivery acceptance is rejected for implementation reasons. | `engifoundry-exec` |
| Delivery acceptance changes the contract. | `engifoundry-orch` |

## Typical Sequence

```text
Orch, Exec, Verify, Deliver
```

This is the usual contract order for an end-to-end packaged goal, not control logic. State signals and destinations are declarations, not routing commands.

The Agent should use the user's requested endpoint, current records, the typical sequence, and possible destinations to select a reasonably complete contract set for end-to-end completion rather than only the smallest immediate contract. Completed stages need not be selected again unless they are relevant rework destinations. An explicitly stage-bounded request remains bounded to that stage.

The Agent selects, combines, and rereads the Skill contracts needed to complete the user's request from project configuration, records, and conversation intent.

## Repository Boundary

`.engifoundry/packages/` is outside the scope of every stage, check-in, commit, and push request unless the user explicitly states that task packages are to be included in repository history. Broad requests such as "commit the current changes", "commit everything", or their equivalents leave this boundary unchanged. Only explicit task-package inclusion authorizes overriding the configured `.gitignore` rule for this directory.

## Pause Records

When packaged work pauses before completion because user or external input is required, the Agent writes one concise human-readable `<artifact-root>/records/<phase-id>/<package-id>/PAUSE-<NNN>.md` before ending the turn. Allocate the identifier monotonically and keep each file immutable. Its content matches the pause fact: an execution summary, current engineering state, or human acceptance checklist as applicable. Include the reason, relevant evidence, required input, and next entry point without duplicating machine records. Automatic continuation and completed delivery are not pause points.

## Group Rules

Whenever the Agent applies EngiFoundry to engineering work, including a `direct` classification, it uses test-first development for behavior changes when feasible, debugs from reproduced evidence, reviews durable outputs in fresh context when applicable, and obtains fresh task-appropriate verification before claiming completion. Package records add structure; they do not create these quality requirements.

When locally installed Superpowers discipline Skills are discoverable in the current host's available Skills list, the Agent may apply them as optional discipline enhancers and pass their applicable instructions through to the selected Executor; they strengthen but never replace or relax the four rules, and their absence changes nothing.

Use Superpowers only for discipline-aligned TDD, systematic debugging, review, and verification practices. Treat every other Superpowers workflow as outside EngiFoundry selection unless the user explicitly requests it. If the host loads another Superpowers workflow independently, preserve EngiFoundry contracts and leave any conflicting workflow unapplied.

## Supporting Skills

`engifoundry-audit`, `engifoundry-review`, and `engifoundry-docs` are reusable EngiFoundry rules rather than Nodes. Docs applies only when the user explicitly requests a detailed human-readable document from project records. Runtime contracts state when supporting rules apply and how the Agent continues from recorded facts. Agent direct action is a declared non-Node destination and does not create Package records.

## External Skill Routes

External Skills are optional integrations, not Nodes or supporting rules in this bundle.

| External Skill | Match intent | Outcome |
| --- | --- | --- |
| `engi-design` | An explicit `$engifoundry` product visual-design request to create, resume, review, revise, extend, or finalize a design; for example, `$engifoundry 帮我设计一个运营后台`. | Accepted project-root `DESIGN.md`, with intermediate state owned by the external contract under `.engifoundry/design/`. |

1. Consider only external Skills discoverable in the current host's available Skills list.
2. Match explicit user intent, then read and apply only the selected external Skill contract.
3. Omit an unavailable route silently, without mentioning the missing Skill, suggesting installation, or creating a blocker. Continue selecting from the available EngiFoundry contracts using the remaining request intent and project facts.
4. Resolve multiple matching external routes from the requested outcome and boundaries; ask only when a material ambiguity remains.
5. Keep external routes outside the Node sequence, State Signals, supporting-rule membership, and Package records unless the request independently includes packaged engineering work.
