# Module Resolution

TaskForge supports full installation and controlled kernel-only installation.

Full installation remains recommended. Kernel-only installation is for lightweight local sharing when only `SKILL.md`, the manifest, and the resolver are present.

## Source of Truth

Module metadata lives in:

```text
taskforge.manifest.json
```

Each module entry declares:

- `localPath`;
- `requiredFor`;
- `required`.

Remote source metadata lives in:

```json
{
  "remoteSource": {
    "type": "github",
    "repo": "caoyuan-fire/task-forge-skill",
    "defaultRef": "main"
  }
}
```

## Resolution Order

When a module is needed:

1. Check the declared local path.
2. Check the TaskForge module cache.
3. If still missing, require explicit user confirmation before download.
4. Download from the declared GitHub raw URL.
5. Record the resolved module in `taskforge.lock.json` inside the cache directory.

Required modules must not be silently skipped.

Optional modules may be skipped only with an explicit note.

## Cache Location

The default cache location is:

```text
~/.cache/taskforge/modules/
```

If `XDG_CACHE_HOME` is set, the default is:

```text
<XDG_CACHE_HOME>/taskforge/modules/
```

The module cache must not be inside a user's TaskForge artifact root. Artifact roots contain durable project work products, not downloaded runtime support files.

## Resolver Script

The resolver script is:

```text
skills/taskforge/scripts/resolve_module.py
```

Example:

```bash
python3 skills/taskforge/scripts/resolve_module.py role-protocol \
  --manifest taskforge.manifest.json
```

If the module is missing and not cached, the command exits without downloading.

To allow download:

```bash
python3 skills/taskforge/scripts/resolve_module.py role-protocol \
  --manifest taskforge.manifest.json \
  --yes
```

Machine-readable output:

```bash
python3 skills/taskforge/scripts/resolve_module.py role-protocol \
  --manifest taskforge.manifest.json \
  --yes \
  --json
```

## Lockfile

The resolver writes:

```text
<cache-dir>/taskforge.lock.json
```

The lockfile records:

- module name;
- resolved path;
- source URL;
- Git ref;
- resolution status.

It is cache metadata and does not belong in a project artifact root.

## Safety Rules

- Do not download without explicit user confirmation.
- Do not write downloaded modules into artifact roots.
- Do not silently downgrade required modules.
- Do not treat optional modules as required.
- Do not store secrets in the module cache or lockfile.
