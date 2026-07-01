---
name: engifoundry-gate
description: Use at session start to decide whether EngiFoundry is available for the current workspace. This is a lightweight autoload gate; do not apply full EngiFoundry workflow unless the main engifoundry skill is explicitly launched or the current request needs engineering governance.
---

# EngiFoundry Gate

This skill is the plugin autoload gate for EngiFoundry.

It is not the EngiFoundry workflow. It only decides whether the current workspace should make EngiFoundry available for the current request. Full workflow rules live in the main `engifoundry` skill.

## Required Behavior

1. If the user explicitly invokes `$engifoundry`, launch the main `engifoundry` skill immediately.
2. If the user explicitly invokes `$engifoundry-gate`, run this gate normally.
3. If the user invokes another skill but not `$engifoundry`, still run this gate normally; other explicit skills do not disable workspace detection.
4. Inspect only the current working directory's first-level children. Do not recurse.
5. If the current working directory is unavailable or unreadable, do not launch EngiFoundry unless the user explicitly invoked `$engifoundry`.
6. If the gate does not match, exit silently and continue normal handling of the user's request.
7. If the gate matches, treat EngiFoundry as available, but do not force package governance.

## Workspace Signals

### L1 Super Signal

If a first-level child named `.git` exists, the gate matches immediately.

### L2 Strong Engineering Signals

If any first-level child matches one of these names or patterns, the gate matches:

- `.engifoundry.config.json`
- `.engifoundry`
- `.engifoundry-packages`
- `pom.xml`
- `build.gradle`
- `build.gradle.kts`
- `settings.gradle`
- `settings.gradle.kts`
- `gradle.properties`
- `gradlew`
- `gradlew.bat`
- `package.json`
- `Cargo.toml`
- `go.mod`
- `pyproject.toml`
- `Makefile`
- `CMakeLists.txt`
- `*.xcodeproj`
- `*.xcworkspace`
- `*.sln`
- `*.csproj`
- `AndroidManifest.xml`

A standard project scaffold matches through ordinary project signals even when EngiFoundry has not been initialized. For example, a new project root with build files, package manifests, source directories, app directories, or test directories should make EngiFoundry available when it meets the L1, L2, or L3 signal rules above.

### L3 Medium Engineering Signals

If two or more first-level children match these names or patterns, the gate matches:

- `build*`
- `make*`
- `settings*`
- `*manifest*`
- `src`
- `app`
- `gradle`
- `lib`
- `tests`
- `test`
- `docs`

## Launch Rule

A gate match means only:

```text
EngiFoundry is available in this workspace.
```

It does not mean:

```text
Use package mode.
Write artifacts.
Create Jobs.
Apply package governance.
```

After a gate match, launch the main `engifoundry` skill only when the user's current request needs engineering governance, such as engineering state alignment, planning, implementation, review, verification, handoff, closeout, package work, or durable artifact handling.

For non-engineering requests, such as weather, casual questions, or general knowledge tasks, do not launch the main `engifoundry` skill even if the gate matched.

## Main Skill Boundary

The main `engifoundry` skill performs intent routing and selects the workflow mode:

- `ad-hoc`
- `package-planning`
- `package-alignment`
- `job-execution`
- `review-only`
- `package-revision`
- `closeout`
- `audit`

Gate detection is environment-driven. Main workflow selection is prompt-driven.
