import json
import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]


def read(relative_path):
    return (ROOT / relative_path).read_text(encoding="utf-8")


def exists(relative_path):
    return (ROOT / relative_path).exists()


def read_yaml(relative_path):
    return yaml.safe_load(read(relative_path))


class GovernanceDocsTests(unittest.TestCase):
    def assert_contains_all(self, path, phrases):
        content = read(path)
        missing = [phrase for phrase in phrases if phrase not in content]
        self.assertEqual(missing, [], f"{path} is missing expected phrases")

    def test_repository_exposes_exactly_two_runtime_skills(self):
        skill_files = sorted(
            path.relative_to(ROOT).as_posix()
            for path in (ROOT / "skills").glob("*/SKILL.md")
        )
        self.assertEqual(
            skill_files,
            [
                "skills/engifoundry-gate/SKILL.md",
                "skills/engifoundry/SKILL.md",
            ],
        )

        manifest = json.loads(read("engifoundry.manifest.json"))
        self.assertEqual(manifest["skillPath"], "skills/engifoundry")
        self.assertEqual(manifest["gateSkillPath"], "skills/engifoundry-gate")
        self.assertNotIn("reviewSkillPath", manifest)
        self.assertNotIn("packagePlanningSkillPath", manifest)

    def test_plugin_manifests_expose_shared_skills_directory(self):
        codex = json.loads(read(".codex-plugin/plugin.json"))
        claude = json.loads(read(".claude-plugin/plugin.json"))
        kimi = json.loads(read(".kimi-plugin/plugin.json"))
        github_copilot = json.loads(read(".github/plugin/plugin.json"))
        cursor = json.loads(read(".cursor-plugin/plugin.json"))
        factory_droid = json.loads(read(".factory-plugin/plugin.json"))
        repository_manifest = json.loads(read("engifoundry.manifest.json"))

        for manifest in [codex, claude, kimi, github_copilot, cursor, factory_droid]:
            self.assertEqual(manifest["name"], "engifoundry-bundle")
            self.assertEqual(manifest["version"], repository_manifest["version"])
            self.assertEqual(manifest["skills"], "./skills/")

        for manifest in [codex, claude, kimi, github_copilot]:
            self.assertIn("interface", manifest)

        self.assertEqual(kimi["sessionStart"]["skill"], "engifoundry-gate")
        self.assertEqual(repository_manifest["pluginName"], "engifoundry-bundle")
        self.assertEqual(repository_manifest["skillPath"], "skills/engifoundry")
        self.assertEqual(repository_manifest["gateSkillPath"], "skills/engifoundry-gate")
        self.assertEqual(repository_manifest["pluginManifests"]["codex"], ".codex-plugin/plugin.json")
        self.assertEqual(repository_manifest["pluginManifests"]["claude"], ".claude-plugin/plugin.json")
        self.assertEqual(repository_manifest["pluginManifests"]["kimi"], ".kimi-plugin/plugin.json")
        self.assertEqual(repository_manifest["pluginManifests"]["githubCopilot"], ".github/plugin/plugin.json")
        self.assertEqual(repository_manifest["pluginManifests"]["cursor"], ".cursor-plugin/plugin.json")
        self.assertEqual(repository_manifest["pluginManifests"]["factoryDroid"], ".factory-plugin/plugin.json")

    def test_runtime_is_self_contained_under_skill_directory(self):
        self.assertFalse(exists("docs"), "docs/ must not be a runtime or specification layer")

        manifest = json.loads(read("engifoundry.manifest.json"))
        for module_name, module in manifest["modules"].items():
            with self.subTest(module=module_name):
                self.assertNotIn("docsPath", module)
                local_path = module["localPath"]
                self.assertTrue(
                    local_path.startswith("skills/engifoundry/"),
                    f"{module_name} localPath must stay inside the self-contained skill directory",
                )
                self.assertTrue(exists(local_path), f"{module_name} localPath does not exist")

        namespaces = read("skills/engifoundry/references/namespaces.md")
        self.assertNotIn("docs/", namespaces)
        self.assert_contains_all("skills/engifoundry/SKILL.md", [
            "README is the human entry point; this skill directory is the machine entry point",
            "Read `references/contract.yaml` before mode-specific references",
            "`references/contract-invariants.yaml` defines non-negotiable invariants",
            "`references/contract-namespaces.yaml` maps workflow modes to implementation references",
        ])

    def test_public_readmes_do_not_link_to_removed_docs_layer(self):
        for path in ["README.md", "zh/README.md"]:
            content = read(path)
            self.assertNotIn("docs/", content)
            self.assertNotIn("../docs/", content)
            self.assertNotIn("Detailed installation and publication rules live in", content)

        self.assert_contains_all("README.md", [
            "Runtime protocol details live inside `skills/engifoundry/references/`",
            "The repository follows the official self-contained skill directory model",
        ])
        self.assert_contains_all("zh/README.md", [
            "运行时协议细节位于 `skills/engifoundry/references/`",
            "本仓库遵循官方的自包含 skill 目录模型",
        ])

    def test_dual_entry_plugin_gate_contract_is_preserved(self):
        self.assert_contains_all("README.md", [
            "$engifoundry-gate",
            "$engifoundry",
            "The gate only decides whether EngiFoundry is available in the current workspace",
            "It does not force package mode, create Jobs, or apply package governance by itself",
            "The main manual skill remains `$engifoundry`",
        ])
        self.assert_contains_all("skills/engifoundry/references/publication-and-platforms.md", [
            "$engifoundry-gate",
            "$engifoundry",
            "The gate only decides whether the current workspace makes EngiFoundry available",
            "`.git/` as a super signal",
            "ordinary project scaffold signals such as build files, package manifests, source directories, app directories, or test directories",
            ".engifoundry.config.json",
            ".engifoundry/",
            ".engifoundry-packages/",
            "does not force package governance",
        ])
        self.assert_contains_all("skills/engifoundry-gate/SKILL.md", [
            "If a first-level child named `.git` exists, the gate matches immediately.",
            "`gradle.properties`",
            "`gradlew`",
            "A standard project scaffold matches through ordinary project signals even when EngiFoundry has not been initialized",
            "`.engifoundry.config.json`",
            "It does not mean:",
            "Use package mode.",
            "Gate detection is environment-driven. Main workflow selection is prompt-driven.",
        ])

    def test_runtime_references_are_split_by_namespace(self):
        required_references = [
            "adapter-contract.md",
            "artifact-root.md",
            "contract-invariants.yaml",
            "contract-namespaces.yaml",
            "contract-operating-model.yaml",
            "contract.yaml",
            "contracts.md",
            "engineering-discipline.md",
            "execution-config.md",
            "execution-policy.md",
            "handoff-and-checkpoint.md",
            "intent-routing.md",
            "job-format.md",
            "module-resolution.md",
            "namespaces.md",
            "operating-model.md",
            "package-format.md",
            "package-planning.md",
            "phase-roadmap.md",
            "publication-and-platforms.md",
            "role-protocol.md",
        ]
        for name in required_references:
            self.assertTrue(exists(f"skills/engifoundry/references/{name}"), name)

        namespaces = read("skills/engifoundry/references/namespaces.md")
        for name in required_references:
            self.assertIn(f"`references/{name}`", namespaces)

        obsolete_aggregates = [
            "skills/engifoundry/references/artifact-protocol.md",
        ]
        for path in obsolete_aggregates:
            self.assertFalse(exists(path), f"{path} should be split and removed")

        for path in (ROOT / "skills" / "engifoundry" / "references").glob("*.md"):
            with self.subTest(path=path.name):
                self.assertLessEqual(
                    len(path.read_text(encoding="utf-8").splitlines()),
                    220,
                    f"{path.name} is too broad; split it further",
                )

    def test_runtime_contract_yaml_indexes_equivalent_contract_parts(self):
        contract = read_yaml("skills/engifoundry/references/contract.yaml")
        self.assertEqual(contract["schemaVersion"], 1)
        self.assertEqual(contract["kind"], "engifoundry-skill-contract")
        self.assertEqual(
            contract["loadOrder"],
            ["operatingModel", "invariants", "namespaces"],
        )
        self.assertEqual(
            contract["parts"],
            {
                "operatingModel": "references/contract-operating-model.yaml",
                "invariants": "references/contract-invariants.yaml",
                "namespaces": "references/contract-namespaces.yaml",
            },
        )
        self.assertEqual(
            contract["authoritativeSources"],
            {
                "operatingModel": "references/operating-model.md",
                "invariants": "references/contracts.md",
                "namespaces": "references/namespaces.md",
            },
        )
        manifest = json.loads(read("engifoundry.manifest.json"))
        for module_name, local_path in [
            ("contract-index", "skills/engifoundry/references/contract.yaml"),
            ("contract-operating-model", "skills/engifoundry/references/contract-operating-model.yaml"),
            ("contract-invariants", "skills/engifoundry/references/contract-invariants.yaml"),
            ("contract-namespaces", "skills/engifoundry/references/contract-namespaces.yaml"),
        ]:
            with self.subTest(module=module_name):
                self.assertEqual(manifest["modules"][module_name]["localPath"], local_path)
                self.assertTrue(manifest["modules"][module_name]["required"])
        self.assertIn(
            "Read `references/contract.yaml` before mode-specific references",
            read("skills/engifoundry/SKILL.md"),
        )

    def test_operating_model_contract_yaml_mirrors_markdown_rules(self):
        operating = read_yaml("skills/engifoundry/references/contract-operating-model.yaml")
        modes = operating["workflow"]["modes"]
        self.assertEqual(
            list(modes.keys()),
            [
                "ad-hoc",
                "package-planning",
                "package-alignment",
                "job-execution",
                "review-only",
                "package-revision",
                "closeout",
                "audit",
            ],
        )
        self.assertEqual(
            operating["controlLoop"],
            [
                "classify the request into one workflow mode",
                "establish authority and role before primary-only or bounded work",
                "locate or initialize roots when durable work is needed",
                "select the mode target state",
                "execute until the target state, an explicit user pause, or a concrete blocker",
                "verify and record the evidence required by the selected mode",
                "report only a terminal state",
            ],
        )
        self.assertEqual(operating["authority"]["default"], "primary/control")
        self.assertFalse(modes["ad-hoc"]["packageGovernance"])
        self.assertTrue(modes["package-planning"]["packageGovernance"])
        self.assertIn("planning.status=ready", modes["package-planning"]["terminalStates"])
        self.assertIn("planning.status=blocked", modes["package-planning"]["terminalStates"])
        self.assertIn("planning.status=discarded", modes["package-planning"]["terminalStates"])
        self.assertIn("user explicitly requested draft output", modes["package-planning"]["terminalStates"])
        self.assertEqual(operating["durableRoots"]["artifactRootDefault"], ".engifoundry/")
        self.assertEqual(operating["durableRoots"]["packageRootDefault"], ".engifoundry-packages/")
        self.assertTrue(operating["durableRoots"]["initializeDefaultsBeforeFirstDurableReadOrWrite"])
        self.assertTrue(operating["evidence"]["completionRequiresFreshVerificationOrNonRunnableRecord"])

    def test_invariants_contract_yaml_mirrors_markdown_rules(self):
        invariants = read_yaml("skills/engifoundry/references/contract-invariants.yaml")
        rules = invariants["invariants"]
        self.assertEqual(rules["controlSource"]["machineControl"], "json")
        self.assertEqual(rules["controlSource"]["humanNarrative"], "markdown")
        self.assertEqual(rules["controlSource"]["summaryMd"], "human-only")
        self.assertEqual(rules["roleAuthority"]["defaultAuthority"], "primary/control")
        self.assertFalse(rules["roleAuthority"]["adaptersGrantPrimaryControl"])
        self.assertIn("approve Job completion", rules["roleAuthority"]["boundedSessionsMustNot"])
        self.assertTrue(rules["packageFirstConflict"]["appliesAfterPackageFlow"])
        self.assertIn("skipped verification", rules["packageFirstConflict"]["conflictExamples"])
        self.assertEqual(rules["packagePlanning"]["target"], "planning.status=ready or formal blocker")
        self.assertFalse(rules["packagePlanning"]["draftIsCompletionState"])
        self.assertTrue(rules["packagePlanning"]["primaryControlTargetsReadyInSameRequestForCreateCompilePrepare"])
        self.assertIn("concrete blocker prevents readiness", rules["packagePlanning"]["doNotStopAtDraftUnless"])
        self.assertIn("user explicitly asks for a draft", rules["packagePlanning"]["doNotStopAtDraftUnless"])
        self.assertEqual(rules["rootBoundaries"]["artifactRootPurpose"], "durable work products only")
        self.assertEqual(rules["rootBoundaries"]["packageRootPurpose"], "execution inputs")
        self.assertTrue(rules["rootBoundaries"]["packageRootGitVisibilityDeterminedByGit"])
        self.assertFalse(rules["rootBoundaries"]["gitIgnoreStateInProjectConfig"])
        self.assertFalse(rules["rootBoundaries"]["roadmapStateInProjectConfig"])
        self.assertEqual(rules["executorAndAdapterAuthority"]["defaultExecutor"], "direct")
        self.assertTrue(rules["executorAndAdapterAuthority"]["preferArtifactRootExecutionConfigAfterLocatingArtifactRoot"])
        self.assertFalse(rules["executorAndAdapterAuthority"]["inferCapabilityFromProductNames"])
        self.assertTrue(rules["verification"]["completionRequiresFreshEvidence"])
        self.assertFalse(rules["verification"]["executorCompletionCompletesJob"])

    def test_namespaces_contract_yaml_mirrors_markdown_routing(self):
        namespaces = read_yaml("skills/engifoundry/references/contract-namespaces.yaml")
        routing = namespaces["modeRouting"]
        self.assertEqual(
            routing["ad-hoc"]["references"],
            [
                "references/intent-routing.md",
                "references/engineering-discipline.md",
            ],
        )
        self.assertEqual(
            routing["ad-hoc"]["conditionalReferences"],
            [{"when": "durable records are needed", "reference": "references/artifact-root.md"}],
        )
        self.assertIn("references/package-planning.md", routing["package-planning"]["references"])
        self.assertIn("references/job-format.md", routing["job-execution"]["references"])
        self.assertIn("references/handoff-and-checkpoint.md", routing["closeout"]["references"])
        stable = namespaces["stableDocumentNamespaces"]
        for reference_name in [
            "references/operating-model.md",
            "references/contracts.md",
            "references/namespaces.md",
            "references/package-format.md",
            "references/job-format.md",
            "references/publication-and-platforms.md",
        ]:
            self.assertIn(reference_name, stable)
        self.assertEqual(
            namespaces["runtimeReferenceBoundary"],
            "Do not point runtime rules outside skills/engifoundry/.",
        )

    def test_package_planning_ready_gate_is_preserved(self):
        self.assert_contains_all("skills/engifoundry/references/package-planning.md", [
            "draft is a transient writing state",
            "The default target for package compilation is `planning.status=ready`",
            "Do not report package planning as complete while leaving `planning.status=draft`",
            "Package alignment is required when any Job uses an executor other than `direct`",
            "primary/control self-review is not sufficient evidence",
            "automatically drive the required alignment work in the same request",
            "revise the package and rerun alignment",
            "set or keep `planning.status=blocked`",
            "Alignment evidence is recorded as review evidence",
            "Alignment records are review records, not Jobs",
            "Package execution start must check `planning.status=ready`",
        ])

    def test_package_and_job_format_constraints_are_preserved(self):
        self.assert_contains_all("skills/engifoundry/references/package-format.md", [
            "Contract anchor: `references/contract.yaml` indexes this file as the package-control detail layer",
            "this file keeps package-specific layout, identifiers, status values, and reader acknowledgement rules",
            "Markdown explains. JSON controls.",
            "Package governance only applies after work enters a package flow",
            "`summary.md` is human-only",
            "`package.config.json` is the machine-readable package contract",
            "Package planning status values",
            "`draft`: package content is being written and is not ready for execution",
            "`ready`: package content is approved as executable planning input",
            "`blocked`: package planning cannot become ready until a blocker is resolved",
            "`discarded`: package content is not approved or is no longer applicable",
            "A discarded package is retained for traceability but is not executable input",
            "do not let a discarded latest package block creation of a newer package",
            "New package allocation must continue from the highest allocated `PAK-*` id",
        ])
        self.assert_contains_all("skills/engifoundry/references/job-format.md", [
            "Contract anchor: `references/contract.yaml` indexes this file as the Job-control detail layer",
            "this file keeps Job-specific control fields, handback shape, completion gate, and durable output records",
            "`type`: `delegable | primary-control-only | review-only | blocked`",
            "`stopConditions`",
            "`requiredReturnFormat`",
            "Executor completion does not complete the Job",
            "Normal executor handback should be compact",
            "`record.md` is the executor's execution record",
            "`review.md` is reviewer output",
            "`verification.md` records validation commands",
        ])

    def test_phase_roadmap_and_artifact_constraints_are_preserved(self):
        self.assert_contains_all("skills/engifoundry/references/phase-roadmap.md", [
            "Do not mechanically create one phase directory per phase",
            "Allowed phase statuses",
            "`available`",
            "`blocked`",
            "`closed`",
            "`invalidated`",
            "do not automatically reopen",
            "PHASE-002-EX01",
            "Do not insert a mainline phase between existing phase numbers",
            "do not renumber existing phases",
            "Do not store roadmap state in `.engifoundry.config.json`",
        ])
        self.assert_contains_all("skills/engifoundry/references/artifact-root.md", [
            "The artifact root is for durable work products",
            "The package root is for execution inputs",
            "## Directory Function Table",
            "| Path | Category | Purpose | Must Not Contain |",
            "Do not write cache files",
            "Do not store Git ignore state in `.engifoundry.config.json`",
            "EngiFoundry may automatically add the package root to `.gitignore`",
            "Tell the user only when the ignore rule is first added",
        ])

    def test_execution_and_adapter_constraints_are_preserved(self):
        self.assert_contains_all("skills/engifoundry/references/execution-config.md", [
            "When aligning a new project or new EngiFoundry session to project workflow state, prefer reading `<artifact-root>/execution.config.json`",
            "`selectionPolicy.prefer` is ordered",
            "Do not infer durable executor capability from product names, installed binaries, or examples alone",
            "When no package, Job, prompt, or `execution.config.json` specifies an executor, use `direct`",
            "Do not force a write unless the user asks to persist it or package execution needs a durable executor contract",
        ])
        self.assert_contains_all("skills/engifoundry/references/execution-policy.md", [
            "`quick`, `standard`, and `strict` are discipline presets, not executor identities",
            "Execution has three dimensions",
            "Package defaults belong in `package.config.json`",
            "Job overrides belong in `job.config.json`",
        ])
        self.assert_contains_all("skills/engifoundry/references/adapter-contract.md", [
            "Required Adapter Description",
            "Adapters cannot override EngiFoundry core rules",
            "Before using an adapter for package work, `primary/control` must know or record enough capability information",
            "Executor Contract Gate",
            "Do not assume stdin support",
            "Watchdog behavior must be explicit",
            "The adapter contract is not an approval mechanism",
            "must not abort a long-running executor solely because a fixed elapsed-time or wait-turn window has passed",
            "Primary/control should not continuously ingest raw executor streams during normal monitoring",
            "Raw executor streams should be read only for failure investigation, blocked execution, verification mismatch, strict review escalation, or explicit user request",
        ])

    def test_module_resolution_and_publication_constraints_are_preserved(self):
        self.assert_contains_all("skills/engifoundry/references/module-resolution.md", [
            "Full installation remains recommended",
            "Kernel-only installation is for lightweight local sharing",
            "The source of truth is `engifoundry.manifest.json`",
            "Optional modules may be skipped only with an explicit note",
            "The module cache must not be inside a user's EngiFoundry artifact root",
            "Do not download without explicit user confirmation",
            "Do not silently downgrade required modules",
            "Do not treat optional modules as required",
            "Do not store secrets in the module cache or lockfile",
        ])
        self.assert_contains_all("skills/engifoundry/references/publication-and-platforms.md", [
            "`skills/engifoundry-gate/SKILL.md` stays lightweight",
            "The plugin package name is `engifoundry-bundle`",
            "Do not rename the main manual skill to match the package",
            "Core discovery must still work from `SKILL.md`",
            "Generated runtime state, private notes, local experiments, and non-publishable materials must stay out of publishable files",
            "`$engifoundry-gate` is the plugin autoload gate",
            "does not force package governance",
            "Do not add platform-specific metadata files unless the platform has a stable schema",
            "Plugin installation and skills-only installation are mutually exclusive within one host home",
        ])

    def test_role_and_engineering_discipline_constraints_are_preserved(self):
        self.assert_contains_all("skills/engifoundry/references/role-protocol.md", [
            "Package-First Conflict Rule",
            "approved package or Job contract",
            "Later chat instructions do not override that contract",
            "executor report is not Job approval",
            "Takeover Verification Gate",
            "Primary-only actions",
        ])
        self.assert_contains_all("skills/engifoundry/references/engineering-discipline.md", [
            "For behavior changes, prefer test-first",
            "Systematic Debugging",
            "Review findings should be ordered by severity and tied to evidence",
            "Follow-up reviews after rework are not delta-only",
            "Bounded Rework Gate",
            "failure alignment",
            "Do not claim completion without fresh verification evidence or an explicit non-runnable verification record",
        ])

    def test_manifest_and_readme_keep_plugin_installation_contract(self):
        manifest = json.loads(read("engifoundry.manifest.json"))
        self.assertEqual(manifest["installModes"]["preference"], "plugin-first")
        self.assertEqual(manifest["installModes"]["full"]["preferred"], "plugin")
        self.assertIn("plugin", manifest["installModes"]["skillsOnly"]["exclusiveWith"])
        self.assertEqual(manifest["pluginName"], "engifoundry-bundle")

        self.assert_contains_all("README.md", [
            "Plugin installation is the preferred full installation mode",
            "Do not install both the plugin package and skills-only entries into the same host home",
            "codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill",
            "codex plugin add engifoundry-bundle@engi-foundry-skill",
            "/plugin marketplace add caoyuan-fire/engi-foundry-skill",
            "/plugins install https://github.com/caoyuan-fire/engi-foundry-skill",
            "copilot plugin marketplace add caoyuan-fire/engi-foundry-skill",
            "/add-plugin https://github.com/caoyuan-fire/engi-foundry-skill",
            "droid plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill",
        ])

    def test_platform_installation_contracts_are_preserved(self):
        marketplace = json.loads(read(".agents/plugins/marketplace.json"))
        self.assertEqual(marketplace["name"], "engi-foundry-skill")
        self.assertEqual(marketplace["plugins"][0]["name"], "engifoundry-bundle")
        self.assertEqual(marketplace["plugins"][0]["source"]["source"], "local")
        self.assertEqual(marketplace["plugins"][0]["source"]["path"], ".")

        claude_marketplace = json.loads(read(".claude-plugin/marketplace.json"))
        kimi = json.loads(read(".kimi-plugin/plugin.json"))
        self.assertEqual(claude_marketplace["name"], "engi-foundry-skill")
        self.assertEqual(claude_marketplace["plugins"][0]["name"], "engifoundry-bundle")
        self.assertEqual(claude_marketplace["plugins"][0]["source"], ".")
        self.assertEqual(kimi["name"], "engifoundry-bundle")
        self.assertEqual(kimi["skills"], "./skills/")
        self.assertEqual(kimi["sessionStart"]["skill"], "engifoundry-gate")

        copilot_marketplace = json.loads(read(".github/plugin/marketplace.json"))
        copilot = json.loads(read(".github/plugin/plugin.json"))
        cursor = json.loads(read(".cursor-plugin/plugin.json"))
        factory_marketplace = json.loads(read(".factory-plugin/marketplace.json"))
        factory = json.loads(read(".factory-plugin/plugin.json"))
        self.assertEqual(copilot_marketplace["name"], "engi-foundry-skill")
        self.assertEqual(copilot_marketplace["plugins"][0]["name"], "engifoundry-bundle")
        self.assertEqual(copilot_marketplace["plugins"][0]["source"], ".")
        self.assertEqual(copilot["name"], "engifoundry-bundle")
        self.assertEqual(copilot["skills"], "./skills/")
        self.assertEqual(cursor["name"], "engifoundry-bundle")
        self.assertEqual(cursor["skills"], "./skills/")
        self.assertEqual(factory_marketplace["name"], "engi-foundry-skill")
        self.assertEqual(factory_marketplace["plugins"][0]["name"], "engifoundry-bundle")
        self.assertEqual(factory_marketplace["plugins"][0]["source"]["source"], "url")
        self.assertEqual(factory_marketplace["plugins"][0]["source"]["url"], "./")
        self.assertEqual(factory["name"], "engifoundry-bundle")
        self.assertEqual(factory["skills"], "./skills/")

        self.assert_contains_all("README.md", [
            "/plugin marketplace add caoyuan-fire/engi-foundry-skill",
            "/plugin install engifoundry-bundle@engi-foundry-skill",
            ".claude-plugin/marketplace.json",
            "/plugins install https://github.com/caoyuan-fire/engi-foundry-skill",
            ".kimi-plugin/plugin.json",
            "copilot plugin install engifoundry-bundle@engi-foundry-skill",
            ".github/plugin/marketplace.json",
            "/add-plugin https://github.com/caoyuan-fire/engi-foundry-skill",
            ".cursor-plugin/plugin.json",
            "Cursor IDE plugin support and Cursor Agent CLI support may not be identical",
            "droid plugin install engifoundry-bundle@engi-foundry-skill",
            ".factory-plugin/marketplace.json",
        ])
        self.assert_contains_all("skills/engifoundry/references/publication-and-platforms.md", [
            "install the latest EngiFoundry skill from GitHub",
            "install this skill: <repository URL>",
            "add the hosted repository as a Git marketplace",
            "refresh the configured Git marketplace snapshot",
            "not as maintained plugin sources",
            "Claude does not use Codex's `.agents/plugins/marketplace.json`",
            "`.kimi-plugin/plugin.json` makes the GitHub repository directly installable",
            "Official Kimi marketplace search visibility is a separate publication channel",
            "`.github/plugin/marketplace.json` makes the GitHub repository a plugin marketplace",
            "`.cursor-plugin/plugin.json` declares the repository root as the `engifoundry-bundle` plugin package",
            "`.factory-plugin/marketplace.json` makes the GitHub repository a Droid plugin marketplace",
            "Skills-only installation is a fallback",
        ])
        self.assert_contains_all("skills/engifoundry/agents/generic.json", [
            ".claude-plugin/marketplace.json",
            ".kimi-plugin/plugin.json",
            "/plugins install https://github.com/caoyuan-fire/engi-foundry-skill",
            ".github/plugin/marketplace.json",
            ".cursor-plugin/plugin.json",
            ".factory-plugin/marketplace.json",
        ])

        self.assertNotIn("You can also search the Kimi plugin UI", read("README.md"))
        self.assertNotIn("也可以在 Kimi 插件界面搜索", read("zh/README.md"))

    def test_public_readme_is_human_entrypoint_not_protocol_specification(self):
        self.assert_contains_all("README.md", [
            "# EngiFoundry",
            "## Quickstart",
            "## How It Works",
            "## Installation",
            "## Updating",
            "## What's Inside",
            "## Development",
            "## License",
            "Runtime protocol details live inside `skills/engifoundry/references/`",
            "Keep root documentation readable for humans",
        ])
        self.assert_contains_all("zh/README.md", [
            "# EngiFoundry",
            "## 快速开始",
            "## 工作方式",
            "## 安装",
            "## 更新",
            "## 包含内容",
            "## 开发",
            "## License",
            "运行时协议细节位于 `skills/engifoundry/references/`",
            "根 README 应保持为面向人类的入口文档",
        ])
        self.assert_contains_all("skills/engifoundry/references/publication-and-platforms.md", [
            "Keep README as a human-facing project entry point, not a protocol specification",
            "Do not duplicate long rules across README and references",
        ])

        readme = read("README.md")
        for phrase in [
            "## Artifact Root",
            "## Artifact Root Layout",
            "## Execution Config",
            "## Package Format",
            "## Job Format",
            "Package Alignment Gate",
            "Executor Invocation Profiles",
            "```json",
        ]:
            with self.subTest(phrase=phrase):
                self.assertNotIn(phrase, readme)

    def test_ad_hoc_boundary_is_explicit_in_skill_and_intent_routing(self):
        phrases = [
            "`ad-hoc` remains a first-class mode",
            "Package-only governance must not be applied",
        ]
        self.assert_contains_all("skills/engifoundry/SKILL.md", phrases + [
            "automatic package planning contract in `references/contract-operating-model.yaml`",
        ])
        operating = read_yaml("skills/engifoundry/references/contract-operating-model.yaml")
        self.assertEqual(
            operating["automaticPackagePlanning"]["trigger"],
            "broad, risky, multi-step, cross-module, handoff-oriented, or ambiguous feature implementation request with no package",
        )
        self.assertFalse(operating["automaticPackagePlanning"]["manualPackagePrerequisiteQuestion"])
        self.assertFalse(operating["automaticPackagePlanning"]["directTddBeforePackagePathResolved"])
        self.assertFalse(operating["automaticPackagePlanning"]["defaultApprovalPause"])
        self.assert_contains_all("skills/engifoundry/references/intent-routing.md", phrases + [
            "When the user asks to start implementing a feature and no package exists",
            "For bounded low-risk implementation requests with clear scope and acceptance criteria",
            "do not ask the user to manually compile a package as a separate prerequisite and do not start direct TDD implementation",
            "Treat package planning as the next automatic primary/control step",
            "Package planning for such implementation requests is not a default user approval pause",
            "continue into execution unless the user explicitly requested an approval gate",
        ])

    def test_roadmap_and_directory_table_constraints_are_preserved(self):
        self.assert_contains_all("skills/engifoundry/references/phase-roadmap.md", [
            "<package-root>/ROADMAP.md",
            "<package-root>/PHASE-001/ROADMAP.md",
            "master roadmap for cross-phase planning",
            "Phase roadmaps should capture the executable view",
            "Do not mechanically create one phase directory per phase",
            "Do not require the user to explicitly say whether the roadmap is master-level or phase-level",
            "Default to the package-root `ROADMAP.md` when there is no strong evidence",
            "`available`",
            "`blocked`",
            "`closed`",
            "`invalidated`",
            "do not automatically reopen",
            "PHASE-002-EX01",
            "Do not insert a mainline phase between existing phase numbers",
            "do not renumber existing phases",
            "Use the discussion content as evidence",
            "Ask the user only when local facts and conversation evidence conflict",
            "ROADMAP.md",
            "Do not store roadmap state in `.engifoundry.config.json`",
            "When the user asks what to do next",
            "If no roadmap exists",
        ])
        self.assert_contains_all("skills/engifoundry/references/intent-routing.md", [
            "When the user asks what to do next",
            "check the relevant package-root phase for `ROADMAP.md`",
            "check `<package-root>/ROADMAP.md` for the relevant phase section",
            "If no roadmap exists",
        ])
        self.assert_contains_all("skills/engifoundry/references/artifact-root.md", [
            "`<artifact-root>/records/ad-hoc/`",
            "`<artifact-root>/records/packages/PHASE-001/PAK-001/`",
            "`<artifact-root>/records/reviews/`",
            "`<artifact-root>/records/audits/`",
            "`<artifact-root>/directory.config.json`",
            "`<artifact-root>/docs/generated/`",
            "`<artifact-root>/docs/integration/`",
            "`<artifact-root>/docs/design/`",
            "`<artifact-root>/docs/reference/`",
            "`<artifact-root>/docs/archive/`",
            "`<package-root>/phase.index.json`",
            "`<package-root>/ROADMAP.md`",
            "`<package-root>/PHASE-001/phase.config.json`",
            "`<package-root>/PHASE-001/ROADMAP.md`",
            "`<package-root>/PHASE-001/PAK-001/`",
            "Execution input",
            "Durable output",
        ])

    def test_initialization_version_and_executor_controls_are_preserved(self):
        self.assert_contains_all("skills/engifoundry/references/artifact-root.md", [
            "## Automatic Initialization",
            "EngiFoundry supports lazy automatic initialization",
            "If EngiFoundry workflow starts in a project with no `.engifoundry.config.json`, artifact root, or package root",
            "initialize the default project config, artifact root, directory config, and package root automatically before the first durable EngiFoundry read or write",
            "Do not require the user to request \"initialize EngiFoundry\" as a separate step",
            "Ask before initializing only when the default paths are unsafe or ambiguous",
            "create_root_config",
            "create_standard_dirs",
            "create_directory_config",
            "Templates are formal editable files",
            "POSIX shell",
            "PowerShell",
            "do not require Python",
        ])
        self.assert_contains_all("skills/engifoundry/SKILL.md", [
            "Skill version is a maintenance label",
            "Check at most once per session",
            "only when network access is available",
            "must not block normal EngiFoundry work",
            "check_version",
        ])
        self.assert_contains_all("skills/engifoundry/references/execution-config.md", [
            "Executor Invocation Profiles",
            "`selectionPolicy.prefer` is ordered",
            "first available executor in the list is preferred",
            "`bestInvocation`",
            "`stdinMode`",
            "`structuredOutputFormat`",
            "`requiresOutputPreprocessing`",
            "`preprocessingNotes`",
            "`timeoutBehavior`",
            "`workingDirectoryPolicy`",
            "`knownLimitations`",
            "`agentNotes`",
            "only after safe discovery or explicit user instruction",
            "If the file is missing, continue with the executor bootstrap rules",
        ])
        self.assert_contains_all("skills/engifoundry/references/execution-policy.md", [
            "Executor Bootstrap",
            "When no package, Job, prompt, or `execution.config.json` specifies an executor, use `direct`",
            "Do not ask the user to choose an executor when a package, Job, prompt, or `execution.config.json` already names a usable executor",
            "If safe discovery cannot establish a usable bounded executor, ask the user which executor to register or use",
            "Do not infer durable executor capability from product names, installed binaries, or examples alone",
            "When session alignment or safe discovery reveals missing executor knowledge, suggest recording durable non-sensitive facts",
            "Do not force a write unless the user asks to persist it or package execution needs a durable executor contract",
            "Executor Liveness Contract",
            "must not abort a long-running executor solely because a fixed elapsed-time or wait-turn window has passed",
            "Silence is a reason to probe, not a reason to abort",
            "`livenessSignals`",
            "`probeBehavior`",
            "`stallCriteria`",
            "`abortCriteria`",
            "Repeated generic `working` responses without changed phase, evidence, or next action are not sufficient progress evidence",
            "Executor Output Cost Control",
            "Primary/control should not continuously ingest raw executor streams during normal monitoring",
            "Monitor liveness through compact heartbeats, probe responses, and final handback",
            "Raw executor streams should be read only for failure investigation, blocked execution, verification mismatch, strict review escalation, or explicit user request",
            "`heartbeatSchema`",
            "`finalReportSchema`",
            "`rawStreamPolicy`",
            "quick: prefer direct execution or final-report-only executor handback",
            "standard: prefer compact heartbeats and compact final handback",
            "strict: keep stronger review and evidence requirements while still avoiding default raw-stream ingestion",
        ])

    def test_package_alignment_and_discarded_package_constraints_are_preserved(self):
        self.assert_contains_all("skills/engifoundry/references/package-planning.md", [
            "A package records only two status dimensions: `planning.status` and `execution.status`",
            "Before setting or reporting `planning.status=ready`, primary/control must evaluate whether Package Alignment Gate is required",
            "When the user asks to create, compile, or prepare a task package, primary/control must treat `planning.status=ready` as the target state for the same request",
            "Do not stop at `planning.status=draft` to ask whether alignment should run",
            "Package alignment is a hard gate for reporting package planning as ready",
            "Do not add `alignmentStatus`, `alignmentRequired`, or `alignmentPassed`",
            "any Job uses an executor other than `direct`",
            "primary/control self-review is not sufficient evidence",
            "primary/control must automatically drive the required alignment work in the same turn",
            "must not write `planning.status=ready`",
            "Stopping at `draft` is only acceptable when a concrete blocker prevents a ready package",
            "report package planning as complete",
            "Alignment evidence is recorded as review evidence",
            "reviewer identity",
            "reviewed files",
            "pass/block decision",
            "A package may be reported as compiled only after `planning.status` can be set to `ready`",
            "execution start must check `planning.status=ready`",
        ])
        self.assert_contains_all("skills/engifoundry/references/package-format.md", [
            "Package identifiers are allocated monotonically within a phase",
            "If the latest allocated package in a phase is `PAK-003` and it is discarded, the next new package is `PAK-004`",
            "Package planning status values",
            "`discarded`: package content is not approved or is no longer applicable",
            "Package execution status values",
            "`discarded`: execution is intentionally abandoned or skipped",
            "A discarded package is retained for traceability but is not executable input",
            "The execution layer must ignore discarded packages",
            "do not start their Jobs",
            "do not treat their unfinished Jobs as pending work",
            "do not let a discarded latest package block creation of a newer package",
            "Discarding a package does not roll back numbering",
            "New package allocation must continue from the highest allocated `PAK-*` id in the phase",
            "independent of `planning.status` or `execution.status`",
        ])


if __name__ == "__main__":
    unittest.main()
