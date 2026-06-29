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

## Executor Capability Fields

Executor entries may describe:

- `type`;
- `command`;
- `supportsStdin`;
- `supportsStructuredOutput`;
- `outputNoise`;
- `supportsParallel`;
- `supportsReviewOnly`;
- `fallback`;
- `knownRisks`.

These fields help primary/control choose an executor. They do not authorize primary-only actions.

## Job Override Rule

A Job may override package defaults when it needs a different executor, isolation level, discipline preset, review requirement, verification command, or output contract.

The override must be explicit in `job.config.json`.
