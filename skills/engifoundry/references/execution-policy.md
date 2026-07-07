# Execution Policy

EngiFoundry separates execution mechanism from isolation and quality discipline.

Execution has three dimensions.

## Three Dimensions

```text
executor   = who or what performs the work
isolation  = how separated the execution/review context is
discipline = quality preset
```

`quick`, `standard`, and `strict` are discipline presets, not executor identities.

## Executors

Common executor values:

- `direct`: current session performs the work.
- `multi-session`: another local session performs bounded work.
- `external-cli`: a third-party CLI performs bounded work.
- `human`: a human performs the work and reports results.
- `review-only`: a reviewer performs review without implementation.

`execution.config.json` declares available executors and selection preferences.

## Isolation

Common isolation values:

- `direct`: no isolated execution context.
- `isolated-execution`: execution occurs outside the primary/control context.
- `isolated-review`: review occurs outside the implementing context.
- `isolated-exec-and-review`: both execution and review are isolated.

Isolation is a discipline requirement. It is not tied to any specific product feature.

## Discipline Presets

Recommended presets:

- `quick`: low-risk, local work with basic evidence.
- `standard`: default package work with explicit records and verification.
- `strict`: high-risk, cross-module, release-sensitive, architecture, data, or security-related work requiring stronger isolation and review.

Collaboration intensity should scale with the discipline preset:

- quick: prefer direct execution or final-report-only executor handback.
- standard: prefer compact heartbeats and compact final handback.
- strict: keep stronger review and evidence requirements while still avoiding default raw-stream ingestion.

## Policy Location

Package defaults belong in `package.config.json`.

Job overrides belong in `job.config.json`.

Executor capability and preference belong in `execution.config.json`.

`selectionPolicy.prefer` is ordered. The first available executor in the list is preferred. Later entries are fallback choices in order.

## Executor Capability Fields

Executor entries may describe:

- `type`;
- `command`;
- `supportsStdin`;
- `stdinMode`;
- `bestInvocation`;
- `supportsStructuredOutput`;
- `structuredOutputFormat`;
- `outputNoise`;
- `requiresOutputPreprocessing`;
- `preprocessingNotes`;
- `timeoutBehavior`;
- `livenessSignals`;
- `probeBehavior`;
- `stallCriteria`;
- `abortCriteria`;
- `heartbeatSchema`;
- `finalReportSchema`;
- `rawStreamPolicy`;
- `workingDirectoryPolicy`;
- `supportsParallel`;
- `supportsReviewOnly`;
- `knownLimitations`;
- `agentNotes`.

These fields help primary/control choose an executor. They do not authorize primary-only actions.

## Executor Invocation Profiles

Executor Invocation Profiles are durable notes about how to call each executor. They may record the best invocation, standard-input behavior, structured-output behavior, output noise, preprocessing requirements, timeout behavior, liveness and probe behavior, working directory policy, known limitations, and concise agent notes.

Agents may update executor invocation profiles only after safe discovery or explicit user instruction. Do not record guesses as durable executor capability.

When executor capability is unknown, package work must not assume support for stdin prompt delivery, unattended execution, structured output, write access, review-only mode, or watchdog behavior. Record the capability only after safe discovery or explicit user instruction, discover it safely, or ask the user before using it in a package flow.

## Executor Bootstrap

When no package, Job, prompt, or `execution.config.json` specifies an executor, use `direct` for ad-hoc work and simple `primary/control` work.

Do not ask the user to choose an executor when a package, Job, prompt, or `execution.config.json` already names a usable executor. Apply the explicit contract first, then the ordered `selectionPolicy.prefer`, then its fallback.

If package work requires bounded or isolated execution and no usable executor config exists, `primary/control` should safely discover local executor capability and record durable non-sensitive capability before use. If safe discovery cannot establish a usable bounded executor, ask the user which executor to register or use for that package work.

Do not infer durable executor capability from product names, installed binaries, or examples alone.

When aligning a new project or new EngiFoundry session to project workflow state, prefer reading `<artifact-root>/execution.config.json` after locating the artifact root, if the file exists. Use it to keep executor selection order, fallback behavior, invocation methods, capability fields, and known limitations in the current session context.

This execution-config read is a session-alignment step, not a mandatory read before every ad-hoc task.

When session alignment or safe discovery reveals missing executor knowledge, suggest recording durable non-sensitive facts in the matching `execution.config.json` fields, such as `selectionPolicy`, `bestInvocation`, `supportsStdin`, `stdinMode`, `supportsStructuredOutput`, `structuredOutputFormat`, `timeoutBehavior`, `livenessSignals`, `probeBehavior`, `rawStreamPolicy`, `workingDirectoryPolicy`, `supportsParallel`, `supportsReviewOnly`, `knownLimitations`, and `agentNotes`. Do not force a write unless the user asks to persist it or package execution needs a durable executor contract.

## Executor Liveness Contract

Primary/control must not abort a long-running executor solely because a fixed elapsed-time or wait-turn window has passed.

Silence is a reason to probe, not a reason to abort. If an executor is quiet, primary/control should check adapter-defined `livenessSignals` or use the adapter-defined `probeBehavior` before applying `stallCriteria` or `abortCriteria`.

Repeated generic `working` responses without changed phase, evidence, or next action are not sufficient progress evidence.

## Executor Output Cost Control

Executor output control reduces accidental primary/control token loss during monitoring. It must not weaken verification, review authority, durable evidence, or package-first rules.

Primary/control should not continuously ingest raw executor streams during normal monitoring.

Monitor liveness through compact heartbeats, probe responses, and final handback. Heartbeats and probes are operational signals, not audit evidence.

Raw executor streams should be read only for failure investigation, blocked execution, verification mismatch, strict review escalation, or explicit user request.

Adapters and executor profiles may declare:

- `heartbeatSchema`: compact progress fields such as status, phase, last external action, next external action, whether control is needed, and blocker reason.
- `finalReportSchema`: compact handback fields such as job id, status, changed files, behavior summary, evidence paths, verification result, known gaps, and recommendation.
- `rawStreamPolicy`: where raw executor output lives, when it may be read, and how much should enter primary/control context.

Executor prompts should prefer targeted searches, concise evidence indexes, and bounded file reads over full file dumps. Final reports should be compact enough for review while preserving evidence paths and known gaps.

Every delegated executor or reviewer prompt must request minimal-noise output. The requested final handback should contain only the target structured result: status, changed files when relevant, durable record paths, verification result, evidence paths, known gaps, recommendation, and whether primary/control is needed. Thinking, reasoning traces, raw tool streams, verbose command logs, and long logs must not be emitted as final output.

Verbose command output, raw tool streams, and long logs are not durable records by default. If they are needed for failure analysis, summarize the relevant evidence in `record.md`, `verification.md`, or `review.md` instead of copying raw long logs.

## Job Override Rule

A Job may override package defaults when it needs a different executor, isolation level, discipline preset, review requirement, verification command, or output contract.

The override must be explicit in `job.config.json`.
