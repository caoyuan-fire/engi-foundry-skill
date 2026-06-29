# Platform Metadata

EngiFoundry exposes one installable skill entry point:

```text
$engifoundry
```

The canonical runtime metadata is the YAML frontmatter in:

```text
skills/engifoundry/SKILL.md
```

That frontmatter contains the required `name` and `description` fields. Platforms that support Agent Skills should be able to discover the skill from those fields.

## OpenAI / Codex

EngiFoundry includes OpenAI/Codex-facing UI metadata:

```text
skills/engifoundry/agents/openai.yaml
```

This file provides display name, short description, and default prompt metadata for OpenAI surfaces that support it.

## Generic Metadata

EngiFoundry also includes platform-neutral metadata:

```text
skills/engifoundry/agents/generic.json
```

This file is for humans, installers, and third-party tooling. It is not required for EngiFoundry runtime behavior.

## Claude-Compatible Surfaces

Claude-compatible skill surfaces should use `SKILL.md` frontmatter as the core metadata source.

EngiFoundry does not currently include a separate Claude-specific metadata file because the stable shared contract is the skill folder plus `SKILL.md`.

## Kimi-Compatible Surfaces

EngiFoundry does not currently include a Kimi-specific metadata file because no stable Kimi-specific skill metadata schema is declared in this repository.

Kimi-compatible usage should rely on:

- `SKILL.md` frontmatter;
- `agents/generic.json`;
- public documentation in this repository.

## Rule

Do not add platform-specific metadata files unless the platform has a stable schema or the repository explicitly documents the file as non-authoritative tooling metadata.
