---
name: engifoundry-init
description: Create or migrate the EngiFoundry project scaffold and create or modify its Executor and Workflow configuration through a controlled interactive flow.
---

# EngiFoundry Init

## Scope

Own project initialization and later configuration changes. Configuration changes reuse the matching interactive section without recreating the scaffold or changing a completed `initialization.json`.

For an explicit migration or upgrade request, read [migration.md](references/migration.md). Migration is Agent-directed: preserve legacy content, rebuild control JSON from inspected project facts, and use the full Init interaction only when reliable preference recovery is not possible.

## Lock

While initialization is `in_progress`, or a later configuration setup is active, its current step and setup phase own the conversation. At every turn, read initialization state, then the matching setup `status`. Start a setup only when its status is `idle`. Pass the complete reply unchanged to the current `select` or `prefer` action, which invokes the verifier, and repeat the localized prompt unless verification is valid. Do no unrelated work; never infer, translate, skip, reorder, or edit `initialization.json` directly. First initialization exits only at `complete` or explicit scripted `cancelled`; a later configuration setup exits only after `commit` or its matching `cancel`.

An unrelated request, topic change, refusal, malformed reply, or request to use EngiFoundry for other work does not suspend or end an active Init interaction. Treat it only as invalid input for the current prompt. Cancellation requires an explicit request: first initialization uses the state script, while a later configuration setup uses its matching setup script.

## Presentation

During the numbered question flow, user-visible output contains only the current localized question, its numbered options, and required explanatory or hint lines. After a reply, run validation and state actions silently, then show only the next question or completion output. Never announce an intention, repeat the selected input, mention the verifier or commands, or narrate state transitions. This silence rule ends when the active Init interaction exits.

## Flow

1. Resolve the project root without scanning for EngiFoundry files.
2. For first initialization, run scaffold `init`, then `check`; `status: ok` means only scaffold-ready. Migration follows its reference before entering this flow. For a later configuration change, do not run scaffold commands.
3. For `currentStep`, show every numbered option in the user's language and use only verified `selectedIds`.
4. After writing that section's preference config, run state `advance`; the script preserves the fixed order and completion facts.
5. At `complete`, show an informational summary of `executorOrder`, `automationMode`, and `actionPreference`. Then emit a blank line followed by one standalone localized green/success callout equivalent to: "Congratulations, EngiFoundry is ready to help you work better." For Markdown output, use a `[!TIP]` callout. Never place this sentence inline with the summary. Then read the Router because `./engifoundry.config.json` now exists. Do not ask for confirmation or offer rollback; later changes use the applicable Init configuration rules.

Do not overwrite an existing `./engifoundry.config.json` or `.engifoundry/`. On collision or failed validation, report the exact paths. Init validates structure and progress only; later Nodes own policy semantics.

## Executor

Run Executor setup `status`; at `idle`, run `begin` once. Set native-subagent capability to true only when the current host actually exposes it. The script discovers supported CLI commands, places current-session execution as late as possible, and returns the numbered candidates.

For `phase: select`, localize every returned option and state that the user may select one or multiple options, separated by commas. Give examples for both forms: `2` for a single selection or `1,2` for multiple selections. State that multiple-selection input order defines fallback order. Pass the complete reply unchanged to `select`.

On this first question only, add one localized blue/info callout equivalent to: "For advanced configuration, choose any one option now. After initialization completes, run `$engifoundry modify config` and describe what you want changed and how." For Markdown output, use a `[!NOTE]` callout.

For `phase: prefer`, list the returned selected options in the user's input order. State that the chosen Executor moves to the front and the others retain that order. Pass the complete reply unchanged to `prefer`. A single selection skips this phase.

At `status: ready`, run `commit`. Never construct or reorder `executorOrder` yourself. During initialization, then run state `advance`; during later configuration changes, stop after commit.

Never ask about CLI models during initialization. Model configuration is a hidden modification capability only. When an explicit configuration-change request already identifies the target Executor and desired default or model ID, read the existing Executor config, run the platform `executor-probe` with that exact request, and update only the target entry after a successful probe. Do not show a model menu, enumerate models, or start a numbered question flow. Never trust model self-identification or infer availability from a catalog.

## Workflow

The delivery workflow is fixed: Package, Execute, Verify, Deliver. Workflow configuration changes package preference and pause points; no option may remove or reorder a required stage.

Run Workflow setup `status`; at `idle`, run `begin` once. For `phase: automation`, localize all three returned options:

1. `job-approval`: require approval of every Job Review result and the final PAK Verify result before continuing.
2. `package-approval`: automatically advance through Job Review, then require approval of the final PAK Verify result before Deliver. Present this as recommended.
3. `full-auto`: automatically advance through Job Review, PAK Verify, and Deliver.

For `phase: action-preference`, localize all three returned options:

1. `package-first`: package every action except mechanical, trivial changes.
2. `balanced`: package multi-step, cross-module, unclear, delegated, or meaningfully risky work; present this as recommended.
3. `direct-first`: act directly on clear, controlled work, but still package when direct action cannot reliably control scope, risk, or delivery quality.

Every mode requires Job Review and final PAK Verify; approval controls progression but never replaces or overrides either gate. An explicit user request, Risk requirement, required Job split, Executor delegation, or cross-session handoff always requires Package even under `direct-first`. State that risk, destructive action, permission, and blocker stops apply in every automation mode. Pass each complete reply unchanged to `select`. At `status: ready`, run `commit`; during initialization, then run state `advance`.

## Commands

- macOS/Linux scaffold: `sh scripts/init.sh init|check --project-root <project-root>`
- Windows scaffold: `powershell -ExecutionPolicy Bypass -File scripts/init.ps1 -Command init|check -ProjectRoot <project-root>`
- macOS/Linux input: `sh scripts/verify.sh --source <1,2,...,N> --selection single|multiple --user-input <reply>`
- Windows input: `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -Source <1,2,...,N> -Selection single|multiple -UserInput <reply>`
- macOS/Linux Executor: `sh scripts/executor.sh begin|status|select|prefer|commit|cancel --project-root <project-root>`
- Windows Executor: `powershell -ExecutionPolicy Bypass -File scripts/executor.ps1 -Action begin|status|select|prefer|commit|cancel -ProjectRoot <project-root>`
- macOS/Linux hidden model probe: `sh scripts/executor-probe.sh --executor <id> --command <command> [--model <model-id>]`
- Windows hidden model probe: `powershell -ExecutionPolicy Bypass -File scripts/executor-probe.ps1 -Executor <id> -Command <command> [-Model <model-id>]`
- macOS/Linux Workflow: `sh scripts/workflow.sh begin|status|select|commit|cancel --project-root <project-root>`
- Windows Workflow: `powershell -ExecutionPolicy Bypass -File scripts/workflow.ps1 -Action begin|status|select|commit|cancel -ProjectRoot <project-root>`
- macOS/Linux state: `sh scripts/state.sh status|advance|cancel --project-root <project-root>`
- Windows state: `powershell -ExecutionPolicy Bypass -File scripts/state.ps1 -Action status|advance|cancel -ProjectRoot <project-root>`

`source` is exactly the option-number sequence shown for the current prompt. The verifier is the only input authority.
