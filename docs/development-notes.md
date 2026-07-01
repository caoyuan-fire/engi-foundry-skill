# Development Notes

EngiFoundry keeps public repository documentation separate from the installable skill body.

## Documentation Roles

- `README.md`: public introduction and quick reference.
- `zh/README.md`: Chinese public introduction.
- `docs/`: formal specification and maintainable design basis.
- `skills/engifoundry-gate/SKILL.md`: lightweight plugin autoload gate.
- `skills/engifoundry/SKILL.md`: concise main agent entry point.
- `skills/engifoundry/references/`: operational rules for agents, loaded only when needed.

## Gate Body

The gate body should stay small enough to load at session start.

It should:

- inspect only first-level current-working-directory children;
- treat `.git/` as a super signal;
- decide whether EngiFoundry is available;
- avoid loading full EngiFoundry rules for non-engineering requests.

It should not apply package governance or write artifacts.

## Main Skill Body

The main skill body should stay small enough to load frequently.

It should:

- classify the current request;
- load only the references needed for the classified mode;
- enforce non-negotiable safety and quality rules.

It should not duplicate the full human-facing specification.

## Reference Files

Reference files should be focused and one level deep from `SKILL.md`.

Each reference should cover one operational concern, such as artifact handling, role protocol, package format, or engineering discipline.

## Local State

Generated runtime state, private notes, local experiments, and non-publishable materials must stay out of publishable files.
