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

## Configuration

Durable, non-sensitive adapter capability may be recorded in `execution.config.json`.

Sensitive values must live outside EngiFoundry artifacts.
