# Module Resolution

EngiFoundry supports full install and controlled kernel-only install.

Full install is recommended. Kernel-only install is allowed when missing modules can be resolved from the declared remote source.

## Resolution Order

When a needed module is missing:

1. Check the declared local path from `engifoundry.manifest.json`.
2. Check the EngiFoundry module cache.
3. If still missing, ask the user before downloading.
4. Download from the manifest's GitHub `remoteSource`.
5. Record the resolved module in cache-side `engifoundry.lock.json`.

Required modules must not be silently skipped.

Optional modules may be skipped with an explicit note.

## Cache

Default cache:

```text
~/.cache/engifoundry/modules/
```

If `XDG_CACHE_HOME` is set:

```text
<XDG_CACHE_HOME>/engifoundry/modules/
```

Do not write downloaded modules into a project artifact root.

## Resolver

Use:

```bash
python3 skills/engifoundry/scripts/resolve_module.py <module> --manifest engifoundry.manifest.json
```

This command refuses download unless `--yes` is present.

Use `--json` for machine-readable output.

## Rules

- Ask before downloading.
- Do not downgrade required modules.
- Keep cache and lockfile outside artifact roots.
- Do not store secrets in resolver output or lockfile.
