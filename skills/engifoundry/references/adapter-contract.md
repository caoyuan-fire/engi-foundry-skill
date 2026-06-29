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
