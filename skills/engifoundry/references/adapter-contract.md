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
