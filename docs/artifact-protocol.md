# Artifact Protocol

TaskForge writes durable work products to an artifact root inside the user's project.

## Artifact Root

The default artifact root is:

```text
<project-root>/.taskforge/
```

Users may choose another path, such as:

```text
<project-root>/MyWorkForge/
<project-root>/docs/taskforge/
```

The selected path is recorded in `.taskforge.config.json` at the project root.

The artifact root is not a runtime workspace, cache directory, or scratch area. It exists to preserve inspectable engineering artifacts.

## Allowed Contents

The artifact root may contain:

- task packages;
- Job contracts;
- execution records;
- review records;
- verification evidence;
- closeout records;
- ad-hoc records;
- audit records;
- generated docs with review or delivery value.

## Forbidden Contents

The artifact root must not contain:

- cache files;
- temporary files;
- session dumps;
- downloaded modules;
- raw model logs;
- secrets;
- tokens;
- private runtime state;
- transient executor state.

If an adapter needs runtime state, it must use an explicit external location outside the artifact root.

## Standard Layout

```text
<artifact-root>/
├── execution.config.json
├── packages/
├── records/
│   ├── ad-hoc/
│   ├── reviews/
│   └── audits/
└── docs/
    └── generated/
```

Package-specific artifacts live under `packages/<package-id>/`.

Ad-hoc, review-only, and audit work may write records under `records/` when the output has durable value.

## Git Policy

TaskForge must not silently modify `.gitignore`.

The artifact root should not be ignored by default because it contains durable work products, not temporary files.

If users do not want TaskForge artifacts in version control, they may explicitly ignore their chosen artifact root.

TaskForge may explain the tradeoff, but it must not apply the ignore rule without user approval.
