---
name: engifoundry
description: "MUST be loaded at the start of every session. Check only ./engifoundry.config.json at the project root: if it exists, load engifoundry-router; if absent, stay silent unless the user explicitly names EngiFoundry and asks to initialize it."
---

# EngiFoundry Entry

Inject this entry once at the start of every session. Apply its rules to every user turn.

1. At session start, check exactly `<project-root>/engifoundry.config.json` once. Do not search for it.
2. If it exists, read `engifoundry-router/SKILL.md` in full before responding to the user.
3. If it does not exist, remain uninitialized and load `engifoundry-init/SKILL.md` only when both conditions are true:
   - The request contains `$engifoundry`, `engifoundry`, `engi`, or `foundry` as an explicit, case-insensitive identifier.
   - The request semantically asks to initialize, scaffold, create, onboard, connect, migrate, or upgrade the project for EngiFoundry.
4. Otherwise bypass EngiFoundry silently and handle the request normally.
5. After Init completes, check exactly `<project-root>/engifoundry.config.json` once again. If it now exists, immediately read `engifoundry-router/SKILL.md` in full. Do not require a new session.

Reading only Router metadata or a summary is forbidden. The Router governs every user turn after it is loaded.

Initialization matching is semantic, not a fixed command. Initialization language without an explicit EngiFoundry identifier must never activate EngiFoundry.

Never scan for configuration. Never recognize any other filename, location, or project signal. Do not validate configuration content or project records; Init and Node skills own those rules.

Do nothing else. Never route, infer, govern, plan, execute, verify, deliver, or load Node skills from this entry.
