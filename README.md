# EngiFoundry

EngiFoundry is a platform-neutral set of Agent Skills for structured engineering work. The Agent reads small contracts for task classification, orchestration, execution, clean-context review, goal verification, and delivery closeout while project-owned facts remain under `.engifoundry/`.

## Runtime

```text
Entry
Router
Init | Orch | Exec | Verify | Deliver
Audit | Review
```

- Entry checks only `./engifoundry.config.json`.
- Router declares available contracts and recorded state signals.
- The Agent selects and reads the contracts needed for the requested endpoint.
- Audit classifies new work as direct or packaged.
- Review is always performed by a fresh Reviewer Agent.
- States describe current project facts; they are not workflow events.

The usual packaged contract set is Orch, Exec, Verify, and Deliver. Direct work still follows the Router quality rules without creating a Package.

## Project Layout

Initialization creates only the root entry and `.engifoundry/` tree:

```text
engifoundry.config.json
.engifoundry/
  workspace.md
  initialization.json
  executors.json
  workflows.json
  artifacts/
  packages/
```

Legacy projects can be migrated through an explicit EngiFoundry migration request. Historical content is moved unchanged and active control JSON is rebuilt from inspected facts.

## Installation

Plugin installation is recommended because compatible hosts can inject the Entry at session start.

### Codex

```bash
codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
codex plugin add engifoundry-bundle@engi-foundry-skill
```

### Claude

```text
/plugin marketplace add caoyuan-fire/engi-foundry-skill
/plugin install engifoundry-bundle@engi-foundry-skill
```

### Kimi Code

```text
/plugins install https://github.com/caoyuan-fire/engi-foundry-skill
```

### GitHub Copilot CLI

```bash
copilot plugin marketplace add caoyuan-fire/engi-foundry-skill
copilot plugin install engifoundry-bundle@engi-foundry-skill
```

### Cursor

```text
/add-plugin https://github.com/caoyuan-fire/engi-foundry-skill
```

### Factory Droid

```bash
droid plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill
droid plugin install engifoundry-bundle@engi-foundry-skill
```

For skills-only hosts, install the complete `skills/` directory. Skills-only installation does not guarantee forced session loading; explicitly invoke `$engifoundry` when the host does not autoload the Entry. Do not install both the plugin and skills-only copies in the same host home.

## Development

The runtime lives under `skills/`. Git history remains the source for superseded implementations.

Run the current test suite with:

```bash
python3 -m unittest discover -s tests -p 'test_*.py'
```

## License

Apache-2.0
