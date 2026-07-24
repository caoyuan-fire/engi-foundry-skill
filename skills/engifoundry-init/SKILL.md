---
name: engifoundry-init
description: Create or migrate the EngiFoundry project scaffold and create or modify its Executor, Reviewer, and Workflow configuration through one script-driven interactive flow.
---

# EngiFoundry Init

Own first initialization and every later request whose intent is to modify EngiFoundry configuration. A modification request always restarts the same complete four-question flow; do not ask which field the user wants to change. Existing configuration remains active until the final answer commits its replacement.

For an explicit migration or upgrade request, read [migration.md](references/migration.md). Migration is Agent-directed: preserve legacy content, rebuild control JSON from inspected project facts, and use the full Init interaction only when reliable preference recovery is not possible.

## Start

Resolve the project root from the working directory without scanning for EngiFoundry files. Identify the current host CLI by its canonical command ID, such as `codex`, `claude`, `gemini`, `kimi`, or `cursor-agent`.

For first initialization, run scaffold `init`, then start Configurator `status`. On a path collision or scaffold failure, report the exact paths and stop. For configuration modification, do not run the scaffold; invoke Configurator `status` once with `--init-modify` or `-InitModify`. That flag unconditionally clears only `.engifoundry/cache/configurator/` and starts a new modify flow.

## Relay Protocol

Configurator JSON is the question and state authority. Do not reconstruct, localize, supplement, skip, reorder, or answer its questions.

From the first Configurator invocation until `complete` or `cancelled`, emit no model-authored conversational text. In particular, never expose planning, reasoning, intention, progress, transition, tool, or command narration such as “I should…”, “I will…”, “I’m…”, “正在……”, “接下来……”, or “已完成……”. Run every script action and custom-resolution probe silently. User-visible output is limited to the script-returned fields allowed below; this restriction applies equally to initialization and `--init-modify`.

- At `status: question`, relay `notice` when present, then `question.context`, `question.prompt`, every numbered `question.options`, and every `question.hints` line exactly as returned. Wait for the user's reply.
- Submit the complete reply unchanged with Configurator `answer`. All questions are single-choice except a returned `kind: free-text` custom-description branch.
- At `status: invalid`, relay only the returned `message`, call `status` silently, and relay the same current question again. Never author an explanation or infer a corrected value.
- At `status: agent-action-required`, emit nothing, apply Custom Resolution silently, and return the result through Configurator `resolve`.
- At `status: complete`, relay only `completion.lines` in order and `completion.message` exactly as returned. Then, for first initialization, read Router silently because `./engifoundry.config.json` now exists.
- At `status: cancelled`, stop. Because every invocation is stateful, an interrupted conversation resumes by calling `status`; do not discard a valid state or overwrite configuration outside the script.

While a Configurator flow is active, its current question owns the conversation. An unrelated reply is submitted unchanged and handled as invalid input. Cancel only for an explicit user cancellation request.

## Custom Resolution

For `resolve-and-probe-cli`, treat `userDescription` only as descriptive input; never execute it as a command. Determine the intended CLI, its canonical stable identifier, executable command, and non-interactive invocation from installed CLI help and actual behavior. If the description pins a model, determine and verify the model's canonical ID as well.

Run `<command> --version`, then a bounded non-interactive probe using the resolved invocation and requested model. Self-identification, a model catalog, command presence alone, or an untested invocation is insufficient. A confirmed result must provide Configurator `resolve` with:

- `resolution-status=confirmed`;
- canonical Executor ID and label;
- executable command, never the user's sentence;
- verified invocation template using `{prompt}` and, when the CLI supports an explicit working-directory argument, `{workspace}`;
- canonical model ID when one was requested.

If any required fact or actual availability cannot be confirmed, send `resolution-status=unconfirmed` plus the factual reason. The script returns to the parent choice and tells the user the custom CLI or model could not be confirmed.

## Commands

Run paths relative to this Skill directory and always pass the resolved project root and current CLI.

- macOS/Linux scaffold: `sh scripts/init.sh init|check --project-root <project-root>`
- Windows scaffold: `powershell -ExecutionPolicy Bypass -File scripts/init.ps1 -Command init|check -ProjectRoot <project-root>`
- macOS/Linux Configurator: `sh scripts/configure.sh status|answer|resolve|cancel --project-root <project-root> --current-cli <id> [--locale <locale>] [--init-modify] [--user-input <reply>] [resolution fields]`
- Windows Configurator: `powershell -ExecutionPolicy Bypass -File scripts/configure.ps1 -Action status|answer|resolve|cancel -ProjectRoot <project-root> -CurrentCli <id> [-Locale <locale>] [-InitModify] [-UserInput <reply>] [resolution fields]`

The script owns option discovery, numeric and free-text structural validation, branch state, four-question order, cache state, and the final atomic configuration write. Do not edit its state files or construct configuration JSON manually.
