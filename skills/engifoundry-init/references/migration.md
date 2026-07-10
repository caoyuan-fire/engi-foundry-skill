# EngiFoundry Migration

Use this only after an explicit EngiFoundry migration or upgrade request. Normal Entry and Init behavior must not scan for legacy files.

## Legacy Signals

The previous default layout used:

```text
<project-root>/.engifoundry.config.json
<project-root>/.engifoundry/
<project-root>/.engifoundry-packages/
```

Read the exact legacy root config when present. Its `artifactRoot` and `packageRoot` may name different relative paths. Reject absolute, escaping, unreadable, or ambiguous roots rather than guessing.

Inventory the resolved roots, all non-control content, and these control files before changing anything:

- `.engifoundry.config.json`
- `execution.config.json`
- `directory.config.json`
- `phase.index.json`
- `phase.config.json`
- `package.config.json`
- `job.config.json`

Other JSON files are historical content unless project facts prove they are control files. Do not rewrite them.

## Re-init Decision

Use full Init interaction when Executor or Workflow preferences cannot be mapped confidently, legacy roots or hierarchy are inconsistent, a partial current scaffold conflicts with the legacy layout, or required configuration facts are missing. Do not ask the user to choose merely because migration exists; decide from inspected facts.

When preferences are recoverable without guessing, rebuild `executors.json` and `workflows.json` from those facts and validate them. Advance initialization through the normal state script. Never mark initialization complete from an assumption.

Full re-init changes only how current preferences are established. It does not permit loss or rewriting of legacy outputs.

## Migration

1. Preserve recoverable sources outside their current paths until the new scaffold and rebuilt files pass validation. Never overwrite or merge a conflicting target.
2. Create the current scaffold with the normal Init resources.
3. Move legacy artifact content unchanged under `.engifoundry/artifacts/legacy/artifact-root/`, preserving relative paths.
4. Preserve legacy control JSON unchanged under `.engifoundry/artifacts/legacy/control/`, preserving whether it came from the project, artifact root, or package root.
5. When the package hierarchy can be reconstructed confidently, move its non-control content unchanged under `.engifoundry/packages/`, preserving Phase, PAK, Job, Markdown, and other relative paths. Otherwise keep the complete legacy package root under `.engifoundry/artifacts/legacy/package-root/` and leave current packages empty.
6. Rebuild every active `phase.index.json`, `phase.config.json`, `package.config.json`, and `job.config.json` from the current contracts after inspecting the preserved JSON, Markdown, records, and repository state. Never copy a legacy control JSON into an active current path.
7. Remove the legacy root entry only after the new scaffold, preferences, active package hierarchy, and retained legacy content are verified. Keep preserved source JSON as migration evidence.

Directory migration moves content; it does not edit, reformat, reinterpret, or summarize historical outputs.

## Validation

Run scaffold `check` and require `initialization.json` to be `complete`. For every active migrated PAK, verify current Phase, PAK, and Job JSON exists, references the preserved non-control content correctly, and passes the current Orch structural check. Confirm the legacy root entry is gone and every retained source path has a destination before discarding temporary preservation data.

If validation fails, keep the preserved sources and report the exact incomplete or conflicting paths. Do not describe a partial migration as complete.
