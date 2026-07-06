# Execution Config

EngiFoundry uses artifact-root execution config to record durable, non-sensitive executor capability and selection policy.

The artifact root should contain:

```text
<artifact-root>/execution.config.json
```

This file describes executor registry and selection policy. It is durable configuration, not a secret store.

It is part of the durable EngiFoundry protocol and should be safe to commit.

Executor configs describe capability and preference. They do not grant package authority by themselves.

Neither project config nor execution config may store secrets, tokens, private session IDs, cache state, or transient runtime state.

## Session Alignment

When aligning a new project or new EngiFoundry session to project workflow state, prefer reading `<artifact-root>/execution.config.json` after locating the artifact root, if the file exists.

Use it to keep executor selection order, fallback behavior, invocation methods, capability fields, and known limitations in the current session context.

This execution-config read is a session-alignment step, not a mandatory read before every ad-hoc task. If the file is missing, continue with the executor bootstrap rules.

## Executor Invocation Profiles

`selectionPolicy.prefer` is ordered. The first available executor in the list is preferred. Later entries are fallback choices in order. This is the default call preference; it does not record user preference.

Job or package contracts may override the global ordered preference when they explicitly name an executor. A prompt may also specify an executor for the current turn, but that does not automatically rewrite `execution.config.json`.

Each `executors.<key>` entry may record an invocation profile:

- `type`: executor family, such as `local-cli`, `external-cli`, `local-multi-session`, or `human`;
- `command`: command or mechanism name when applicable;
- `supportsStdin`: whether prompt delivery through standard input is supported;
- `stdinMode`: known standard-input mode, such as `prompt-pipe`, `interactive-only`, or `unsupported`;
- `bestInvocation`: preferred command form or invocation mechanism;
- `supportsStructuredOutput`: whether output can be requested in a stable structured form;
- `structuredOutputFormat`: structured format name, such as `json`, `jsonl`, or `markdown`;
- `outputNoise`: `low`, `medium`, or `high`;
- `requiresOutputPreprocessing`: whether agent output must be cleaned or parsed before review;
- `preprocessingNotes`: how to clean or parse the output;
- `timeoutBehavior`: known long-running, watchdog, or polling behavior;
- `livenessSignals`: observable evidence that the executor is still active;
- `probeBehavior`: how to request status when output is quiet or ambiguous;
- `stallCriteria`: behavior that means the executor is probably not making useful progress;
- `abortCriteria`: behavior that permits fallback, blocked status, or abort;
- `heartbeatSchema`: compact progress fields used during normal monitoring;
- `finalReportSchema`: compact handback fields used for primary/control review;
- `rawStreamPolicy`: when raw executor output may be read and how it is kept out of normal monitoring context;
- `workingDirectoryPolicy`: safest directory from which to invoke the executor;
- `supportsParallel`: whether parallel executor use is supported;
- `supportsReviewOnly`: whether review-only use is supported;
- `knownLimitations`: verified limitations or hazards;
- `agentNotes`: concise operational notes for later agents.

Agents may update executor invocation profiles only after safe discovery or explicit user instruction. Do not record guesses as durable executor capability.

When executor capability is unknown, package work must not assume support for stdin prompt delivery, unattended execution, structured output, write access, review-only mode, or watchdog behavior. Record the capability only after safe discovery or explicit user instruction, discover it safely, or ask the user before using it in a package flow.

## Executor Bootstrap

When no package, Job, prompt, or `execution.config.json` specifies an executor, use `direct` for ad-hoc work and simple `primary/control` work.

Do not ask the user to choose an executor when a package, Job, prompt, or `execution.config.json` already names a usable executor. Apply the explicit contract first, then the ordered `selectionPolicy.prefer`, then its fallback.

If package work requires bounded or isolated execution and no usable executor config exists, `primary/control` should safely discover local executor capability and record durable non-sensitive capability before use. If safe discovery cannot establish a usable bounded executor, ask the user which executor to register or use for that package work.

Do not infer durable executor capability from product names, installed binaries, or examples alone.

When session alignment or safe discovery reveals missing executor knowledge, suggest recording durable non-sensitive facts in the matching `execution.config.json` fields, such as `selectionPolicy`, `bestInvocation`, `supportsStdin`, `stdinMode`, `supportsStructuredOutput`, `structuredOutputFormat`, `timeoutBehavior`, `livenessSignals`, `probeBehavior`, `rawStreamPolicy`, `workingDirectoryPolicy`, `supportsParallel`, `supportsReviewOnly`, `knownLimitations`, and `agentNotes`.

Do not force a write unless the user asks to persist it or package execution needs a durable executor contract.
