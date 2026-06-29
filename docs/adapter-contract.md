# Adapter Contract

Adapters map EngiFoundry's abstract isolated-context capabilities to concrete mechanisms.

An adapter may represent a local multi-session mechanism, native sub-agent feature, external CLI, cloud task runner, or human executor.

## Required Adapter Description

An adapter must state:

- supported capability;
- isolation type;
- invocation mechanism;
- prompt delivery;
- output retrieval;
- write support;
- review-only support;
- parallel support;
- sandbox behavior;
- approval behavior;
- timeout or watchdog behavior;
- output noise;
- structured output support;
- known risks;
- fallback behavior.

## Boundaries

Adapters cannot override EngiFoundry core rules.

Adapters cannot grant primary/control authority by themselves.

Adapters cannot write runtime cache, session dumps, secrets, or private state into the artifact root.

Adapters describe mechanism. Package and Job configs decide policy.

## Executor Contract Gate

Executor Contract Gate only applies after work enters a package flow and uses an isolated executor, isolated reviewer, external CLI, human handoff, or other bounded execution mechanism.

Before using an adapter for package work, `primary/control` must know or record enough capability information to run and review the work safely:

- invocation mechanism;
- prompt delivery method;
- stdin support;
- output retrieval method;
- write permissions;
- review-only support;
- timeout or watchdog behavior;
- fallback behavior.

Do not assume stdin support. If prompt delivery or stdin behavior is unknown, discover it with a harmless command or ask the user before using the adapter for real package work.

Watchdog behavior must be explicit. The adapter contract should state how stalled, silent, timed-out, or partial executor runs are detected and reported.

The adapter contract is not an approval mechanism. It does not override package-first rules, Job dependencies, allowed and forbidden areas, verification requirements, or primary/control-only decisions.

## Configuration

Durable, non-sensitive adapter capability may be recorded in `execution.config.json`.

Sensitive values must live outside EngiFoundry artifacts.
