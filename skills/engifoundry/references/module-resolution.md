# Module Resolution

EngiFoundry supports full installation and controlled kernel-only installation.

Full installation remains recommended. Kernel-only installation is for lightweight local sharing when only `SKILL.md`, the manifest, and the resolver are present.

## Source of Truth

The source of truth is `engifoundry.manifest.json`.

Manifest modules declare:

- `localPath`;
- `requiredFor`;
- `required`.

Full install is recommended. Kernel-only install is allowed when missing modules can be resolved from the declared remote source.

## Resolution Order

When a needed module is missing:

1. Check the declared local path from `engifoundry.manifest.json`.
2. Check the EngiFoundry module cache.
3. If still missing, ask the user before downloading.
4. Download from the manifest's GitHub `remoteSource`.
5. Record the resolved module in cache-side `engifoundry.lock.json`.

Required modules must not be silently skipped.

Optional modules may be skipped only with an explicit note.

## Cache

The default cache location is:

```text
~/.cache/engifoundry/modules/
```

If `XDG_CACHE_HOME` is set:

```text
<XDG_CACHE_HOME>/engifoundry/modules/
```

The module cache must not be inside a user's EngiFoundry artifact root. Artifact roots contain durable project work products, not downloaded runtime support files.

Do not write downloaded modules into a project artifact root.

## Resolver

Use:

```bash
python3 skills/engifoundry/scripts/resolve_module.py <module> --manifest engifoundry.manifest.json
```

This command refuses download unless `--yes` is present.

Use `--json` for machine-readable output.

Resolver output should include module name, resolved path, source URL, and resolution status.

The cache-side `engifoundry.lock.json` is cache metadata and does not belong in a project artifact root.

## Rules

- Do not download without explicit user confirmation.
- Do not downgrade required modules.
- Do not silently downgrade required modules.
- Do not treat optional modules as required.
- Keep cache and lockfile outside artifact roots.
- Do not store secrets in resolver output or lockfile.
- Do not store secrets in the module cache or lockfile.
