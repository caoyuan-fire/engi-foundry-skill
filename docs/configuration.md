# Configuration

EngiFoundry uses two durable configuration layers:

- project-level discovery config;
- artifact-root execution config.

Neither layer may store secrets, tokens, private session IDs, cache state, or transient runtime state.

## Project Config

The project root may contain:

```text
<project-root>/.engifoundry.config.json
```

This file is the discovery entry point for EngiFoundry inside a user project.

It should be safe to commit.

Example:

```json
{
  "schemaVersion": 1,
  "artifactRoot": ".engifoundry",
  "packageRoot": ".engifoundry-packages",
  "recordsPolicy": "durable",
  "defaultPackagePolicy": "package-when-risky"
}
```

Fields:

- `schemaVersion`: config schema version.
- `artifactRoot`: output directory for durable EngiFoundry artifacts. Defaults to `.engifoundry`.
- `packageRoot`: discovery path for task packages and Job contracts. Defaults to `.engifoundry-packages`.
- `recordsPolicy`: how aggressively EngiFoundry should preserve records.
- `defaultPackagePolicy`: when EngiFoundry should prefer package mode over ad-hoc mode.

`artifactRoot` and `packageRoot` may be relative paths. Absolute paths should be used only when the user explicitly requests them.

Project config is a discovery and alignment aid. It should not be treated as a mandatory read before every ad-hoc task. Read it when locating artifact or package roots, resuming package flow, writing durable records, or aligning a new session to project workflow state.

Do not store Git ignore state in project config. Whether the package root is versioned comes from Git behavior, especially `.gitignore` and `git status`.

Do not store roadmap state in project config. The project config locates the artifact root; roadmap state belongs to `<artifact-root>/roadmaps/ROADMAP.md` and `<artifact-root>/roadmaps/roadmap.index.json`.

## Initialization Scripts

EngiFoundry provides functional initialization scripts for macOS, Linux, and Windows. They do not require Python. Use POSIX shell scripts on macOS and Linux, and PowerShell scripts on Windows.

Run them in this order:

1. `create_root_config`
2. `create_standard_dirs`
3. `create_directory_config`

Templates are formal editable files. They are not examples or reference snippets; they are pre-generated standard files intended to be edited and committed when appropriate.

Script pairs:

| Purpose | macOS/Linux | Windows |
| --- | --- | --- |
| Create project root config | `skills/engifoundry/scripts/create_root_config.sh` | `skills/engifoundry/scripts/create_root_config.ps1` |
| Create standard directory structure | `skills/engifoundry/scripts/create_standard_dirs.sh` | `skills/engifoundry/scripts/create_standard_dirs.ps1` |
| Create artifact-root directory config | `skills/engifoundry/scripts/create_directory_config.sh` | `skills/engifoundry/scripts/create_directory_config.ps1` |

Configuration template scripts support `empty` and `filled` modes. Agents should map prompt context into script parameters instead of asking users to hand-write commands when the needed values are already clear.

## Artifact Root Config

The artifact root should contain:

```text
<artifact-root>/execution.config.json
```

This file describes executor registry and selection policy.

It is part of the durable EngiFoundry protocol and should be safe to commit.

Example:

```json
{
  "schemaVersion": 1,
  "executors": {
    "multi-session": {
      "type": "local-multi-session",
      "command": "codex",
      "supportsStdin": true,
      "stdinMode": "prompt-pipe",
      "bestInvocation": "codex exec --json",
      "supportsStructuredOutput": true,
      "structuredOutputFormat": "jsonl",
      "outputNoise": "low",
      "requiresOutputPreprocessing": true,
      "preprocessingNotes": "Extract the final assistant result from JSONL event output.",
      "timeoutBehavior": "long-running; do not abort solely because a fixed elapsed-time or wait-turn window passed",
      "livenessSignals": ["process-alive", "progress-event", "probe-response"],
      "probeBehavior": "on silence, request status before fallback or abort",
      "stallCriteria": "no probe response or repeated non-evidential working reports",
      "abortCriteria": "process exit without handback, explicit blocked status, repeated failed probes, contract violation, or stop condition",
      "heartbeatSchema": ["status", "phase", "last_event", "next", "needs_control", "blocked_reason"],
      "finalReportSchema": ["job_id", "status", "changed_files", "behavior_summary", "evidence_paths", "verification", "known_gaps", "recommendation"],
      "rawStreamPolicy": "do not ingest raw executor streams during normal monitoring; read only on failure, blocked execution, verification mismatch, strict review escalation, or explicit user request",
      "workingDirectoryPolicy": "invoke from project root",
      "supportsParallel": true,
      "supportsReviewOnly": true,
      "knownLimitations": ["stdout may include non-result events"],
      "agentNotes": "Use for bounded execution Jobs when structured handback is required."
    }
  },
  "selectionPolicy": {
    "prefer": ["multi-session"],
    "fallback": "direct"
  }
}
```

Fields:

- `schemaVersion`: config schema version.
- `executors`: registry of available executor mechanisms.
- `selectionPolicy`: ordered executor preference and fallback behavior.

Executor configs describe capability and preference. They do not grant package authority by themselves.

## Executor Invocation Profiles

`selectionPolicy.prefer` is ordered. The first available executor in the list is preferred. Later entries are fallback choices in order. This is the default call preference; it does not record user preference.

Job or package contracts may override the global ordered preference when they explicitly name an executor. A prompt may also specify an executor for the current turn, but that does not automatically rewrite `execution.config.json`.

Each `executors.<key>` entry may record an invocation profile:

- `type`: executor family, such as `local-cli`, `external-cli`, `local-multi-session`, or `human`.
- `command`: command or mechanism name when applicable.
- `supportsStdin`: whether prompt delivery through standard input is supported.
- `stdinMode`: known standard-input mode, such as `prompt-pipe`, `interactive-only`, or `unsupported`.
- `bestInvocation`: preferred command form or invocation mechanism.
- `supportsStructuredOutput`: whether output can be requested in a stable structured form.
- `structuredOutputFormat`: structured format name, such as `json`, `jsonl`, or `markdown`.
- `outputNoise`: `low`, `medium`, or `high`.
- `requiresOutputPreprocessing`: whether agent output must be cleaned or parsed before review.
- `preprocessingNotes`: how to clean or parse the output.
- `timeoutBehavior`: known long-running, watchdog, or polling behavior.
- `livenessSignals`: observable evidence that the executor is still active.
- `probeBehavior`: how to request status when output is quiet or ambiguous.
- `stallCriteria`: behavior that means the executor is probably not making useful progress.
- `abortCriteria`: behavior that permits fallback, blocked status, or abort.
- `heartbeatSchema`: compact progress fields used during normal monitoring.
- `finalReportSchema`: compact handback fields used for primary/control review.
- `rawStreamPolicy`: when raw executor output may be read and how it is kept out of normal monitoring context.
- `workingDirectoryPolicy`: safest directory from which to invoke the executor.
- `supportsParallel`: whether parallel executor use is supported.
- `supportsReviewOnly`: whether review-only use is supported.
- `knownLimitations`: verified limitations or hazards.
- `agentNotes`: concise operational notes for later agents.

Agents may update executor invocation profiles only after safe discovery or explicit user instruction. Do not record guesses as durable executor capability.

## Executor Bootstrap

When no package, Job, prompt, or `execution.config.json` specifies an executor, use `direct` for ad-hoc work and simple `primary/control` work.

Do not ask the user to choose an executor when a package, Job, prompt, or `execution.config.json` already names a usable executor. Apply the explicit contract first, then the ordered `selectionPolicy.prefer`, then its fallback.

If package work requires bounded or isolated execution and no usable executor config exists, `primary/control` should safely discover local executor capability and record durable non-sensitive capability before use. If safe discovery cannot establish a usable bounded executor, ask the user which executor to register or use for that package work.

Do not infer durable executor capability from product names, installed binaries, or examples alone.
