# Execution Policy

EngiFoundry separates execution mechanism from isolation and quality discipline.

## Three Dimensions

```text
executor   = who or what performs the work
isolation  = how separated the execution/review context is
discipline = quality preset
```

`quick` and `strict` are not complete execution modes. They are discipline presets.

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

## Executor Liveness Contract

Primary/control must not abort a long-running executor solely because a fixed elapsed-time or wait-turn window has passed.

Silence is a reason to probe, not a reason to abort. If an executor is quiet, primary/control should check adapter-defined `livenessSignals` or use the adapter-defined `probeBehavior` before applying `stallCriteria` or `abortCriteria`.

Repeated generic `working` responses without changed phase, evidence, or next action are not sufficient progress evidence.

## Job Override Rule

A Job may override package defaults when it needs a different executor, isolation level, discipline preset, review requirement, verification command, or output contract.

The override must be explicit in `job.config.json`.
