# Adapter Contract

Adapters map abstract isolated-context capabilities to concrete mechanisms.

An adapter must state:

- supported capability;
- isolation type;
- launch or invocation mechanism;
- prompt delivery;
- output retrieval;
- write support;
- review-only support;
- parallel support;
- sandbox and approval behavior;
- timeout or watchdog behavior;
- output noise;
- structured output support;
- heartbeat schema;
- final report schema;
- raw stream policy;
- known risks;
- fallback behavior.

Core EngiFoundry rules remain authoritative.

Adapter configuration belongs in `execution.config.json` when it is durable and non-sensitive.

Secrets, private paths, transient session IDs, and runtime cache do not belong in the artifact root.

Adapters cannot grant primary/control authority by themselves.

Adapters describe mechanism. Package and Job configs decide policy.

## Executor Contract Gate

Executor Contract Gate only applies after work enters a package flow and uses an isolated executor, isolated reviewer, external CLI, human handoff, or other bounded execution mechanism.

Before using an adapter for package work, `primary/control` must know or record invocation mechanism, prompt delivery method, stdin support, output retrieval method, write permissions, review-only support, timeout or watchdog behavior, and fallback behavior.

Do not assume stdin support. If prompt delivery or stdin behavior is unknown, discover it with a harmless command or ask the user before using the adapter for real package work.

Watchdog behavior must be explicit. The adapter contract should state how stalled, silent, timed-out, or partial executor runs are detected and reported.

The adapter contract does not override package-first rules, Job dependencies, allowed and forbidden areas, verification requirements, or primary/control-only decisions.

## Executor Liveness Contract

Primary/control must not abort a long-running executor solely because a fixed elapsed-time or wait-turn window has passed.

Silence is a reason to probe, not a reason to abort. Before treating a long-running executor as stalled, primary/control should use the adapter's output retrieval mechanism or an explicit probe to ask for current status, recent externally observable work, next action, and whether the executor is blocked.

An adapter should describe its liveness behavior with durable, non-sensitive fields such as:

- `livenessSignals`: observable evidence that the executor is still active, such as process-alive checks, progress events, structured status messages, or probe responses.
- `probeBehavior`: how primary/control asks for status when output is quiet or ambiguous.
- `stallCriteria`: behavior that means the executor is probably not making useful progress.
- `abortCriteria`: behavior that permits primary/control to stop waiting, fall back, or mark the run blocked.

Repeated generic `working` responses without changed phase, evidence, or next action are not sufficient progress evidence.

Valid abort criteria include process exit without a compliant handback, repeated failed probes, explicit blocked status, repeated non-evidential progress reports, contract violation, or a package/Job stop condition.

## Executor Output Cost Control

Adapters should help primary/control avoid accidental token loss from monitoring noise.

Primary/control should not continuously ingest raw executor streams during normal monitoring.

Monitor liveness through compact heartbeats, probe responses, and final handback. Raw executor streams should be read only for failure investigation, blocked execution, verification mismatch, strict review escalation, or explicit user request.

An adapter should describe durable, non-sensitive output-control behavior:

- `heartbeatSchema`: fields emitted for compact progress reporting.
- `finalReportSchema`: fields emitted for compact handback.
- `rawStreamPolicy`: whether raw streams are hidden, summarized, retained outside the artifact root, or available only on escalation.

If an adapter cannot suppress raw stream output, record that limitation in `knownLimitations` and prefer bounded executor prompts, targeted reads, and structured final handback.

quick: prefer direct execution or final-report-only executor handback.

standard: prefer compact heartbeats and compact final handback.

strict: keep stronger review and evidence requirements while still avoiding default raw-stream ingestion.

Common executor values:

- `direct`;
- `multi-session`;
- `external-cli`;
- `human`;
- `review-only`.

Common isolation values:

- `direct`;
- `isolated-execution`;
- `isolated-review`;
- `isolated-exec-and-review`.
