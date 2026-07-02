import unittest
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(relative_path):
    return (ROOT / relative_path).read_text(encoding="utf-8")


class GovernanceDocsTests(unittest.TestCase):
    def assert_contains_all(self, path, phrases):
        content = read(path)
        missing = [phrase for phrase in phrases if phrase not in content]
        self.assertEqual(missing, [], f"{path} is missing expected phrases")

    def test_ad_hoc_boundary_is_explicit_in_skill_and_intent_routing(self):
        phrases = [
            "`ad-hoc` remains a first-class mode",
            "Package-only governance must not be applied",
        ]

        self.assert_contains_all("skills/engifoundry/SKILL.md", phrases + [
            "If the user asks to start implementing a broad, risky, multi-step, cross-module, handoff-oriented, or ambiguous feature and no package exists",
            "do not ask the user to manually compile a package first and do not start direct TDD implementation",
            "Treat package planning as the next automatic `primary/control` step",
            "This is not a default user approval pause",
        ])
        self.assert_contains_all("skills/engifoundry/references/intent-routing.md", phrases + [
            "When the user asks to start implementing a feature and no package exists",
            "For bounded low-risk implementation requests with clear scope and acceptance criteria",
            "do not ask the user to manually compile a package as a separate prerequisite and do not start direct TDD implementation",
            "Treat package planning as the next automatic primary/control step",
            "Package planning for such implementation requests is not a default user approval pause",
            "continue into execution unless the user explicitly requested an approval gate",
        ])

    def test_dual_entry_plugin_gate_contract_is_documented(self):
        readme_phrases = [
            "$engifoundry-gate",
            "$engifoundry",
            "The gate only decides whether EngiFoundry is available in the current workspace",
            "It does not force package mode, create Jobs, or apply package governance by itself",
        ]
        spec_phrases = [
            "The gate only decides whether the current workspace makes EngiFoundry available",
            "`.git/` as a super signal",
            "ordinary project scaffold signals such as build files, package manifests, source directories, app directories, or test directories",
            ".engifoundry.config.json",
            ".engifoundry/",
            ".engifoundry-packages/",
            "does not force package governance",
        ]

        self.assert_contains_all("README.md", readme_phrases)
        self.assert_contains_all("docs/platform-metadata.md", spec_phrases)
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

    def test_plugin_manifests_expose_shared_skills_directory(self):
        codex = json.loads(read(".codex-plugin/plugin.json"))
        claude = json.loads(read(".claude-plugin/plugin.json"))
        kimi = json.loads(read(".kimi-plugin/plugin.json"))
        repository_manifest = json.loads(read("engifoundry.manifest.json"))

        for manifest in [codex, claude, kimi]:
            self.assertEqual(manifest["name"], "engifoundry-bundle")
            self.assertEqual(manifest["version"], repository_manifest["version"])
            self.assertEqual(manifest["skills"], "./skills/")
            self.assertIn("interface", manifest)

        self.assertEqual(kimi["sessionStart"]["skill"], "engifoundry-gate")
        self.assertEqual(repository_manifest["pluginName"], "engifoundry-bundle")
        self.assertEqual(repository_manifest["skillPath"], "skills/engifoundry")
        self.assertEqual(repository_manifest["gateSkillPath"], "skills/engifoundry-gate")
        self.assertEqual(repository_manifest["pluginManifests"]["codex"], ".codex-plugin/plugin.json")
        self.assertEqual(repository_manifest["pluginManifests"]["claude"], ".claude-plugin/plugin.json")
        self.assertEqual(repository_manifest["pluginManifests"]["kimi"], ".kimi-plugin/plugin.json")

    def test_plugin_package_name_is_distinct_from_main_skill_name(self):
        phrases = [
            "The plugin package name is `engifoundry-bundle`",
            "The main manual skill remains `$engifoundry`",
        ]

        self.assert_contains_all("README.md", phrases)
        self.assert_contains_all("docs/platform-metadata.md", [
            "The plugin package name is `engifoundry-bundle`",
            "differs from the main `$engifoundry` skill name",
        ])
        self.assert_contains_all("docs/publication.md", [
            "The plugin package name is `engifoundry-bundle`",
            "Do not rename the main manual skill",
        ])

    def test_installation_contract_is_plugin_first_for_repository_requests(self):
        readme_phrases = [
            "Plugin installation is the preferred full installation mode",
            "codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill",
            "codex plugin add engifoundry-bundle@engi-foundry-skill",
            ".agents/plugins/marketplace.json",
            ".codex-plugin/plugin.json",
            "Detailed installation and publication rules live in",
            "Update through the same installation channel you used",
        ]

        self.assert_contains_all("README.md", readme_phrases)
        self.assert_contains_all("docs/publication.md", [
            "## Installer Contract",
            "install the latest EngiFoundry skill from GitHub",
            "install this skill: <repository URL>",
            "add the hosted repository as a Git marketplace",
            "refresh the configured Git marketplace snapshot",
            "not as maintained plugin sources",
            "Skills-only installation is a fallback",
        ])
        self.assert_contains_all("docs/platform-metadata.md", [
            ".agents/plugins/marketplace.json",
            "hosted marketplace installation requests",
            "maintaining a separate local `~/plugins/` source mirror",
        ])
        self.assert_contains_all("docs/repository-structure.md", [
            ".agents/plugins/marketplace.json",
            ".claude-plugin/marketplace.json",
            ".kimi-plugin/plugin.json",
        ])
        self.assert_contains_all("docs/publication.md", [
            ".agents/plugins/marketplace.json",
            ".claude-plugin/marketplace.json",
            ".kimi-plugin/plugin.json",
        ])
        self.assert_contains_all("zh/README.md", [
            "codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill",
            "codex plugin add engifoundry-bundle@engi-foundry-skill",
            ".agents/plugins/marketplace.json",
            ".codex-plugin/plugin.json",
            "详细安装和发布规则见",
            "通过你原来的安装渠道更新",
        ])

        manifest = json.loads(read("engifoundry.manifest.json"))
        self.assertEqual(manifest["installModes"]["preference"], "plugin-first")
        self.assertEqual(manifest["installModes"]["full"]["preferred"], "plugin")
        self.assertTrue(manifest["installModes"]["plugin"]["recommended"])

    def test_repository_declares_github_marketplace_entry(self):
        marketplace = json.loads(read(".agents/plugins/marketplace.json"))
        self.assertEqual(marketplace["name"], "engi-foundry-skill")
        self.assertEqual(marketplace["plugins"][0]["name"], "engifoundry-bundle")
        self.assertEqual(marketplace["plugins"][0]["source"]["source"], "local")
        self.assertEqual(marketplace["plugins"][0]["source"]["path"], ".")

    def test_claude_and_kimi_installation_contracts_are_explicit(self):
        marketplace = json.loads(read(".claude-plugin/marketplace.json"))
        kimi = json.loads(read(".kimi-plugin/plugin.json"))
        self.assertEqual(marketplace["name"], "engi-foundry-skill")
        self.assertEqual(marketplace["plugins"][0]["name"], "engifoundry-bundle")
        self.assertEqual(marketplace["plugins"][0]["source"], ".")
        self.assertEqual(kimi["name"], "engifoundry-bundle")
        self.assertEqual(kimi["skills"], "./skills/")
        self.assertEqual(kimi["sessionStart"]["skill"], "engifoundry-gate")

        self.assert_contains_all("README.md", [
            "/plugin marketplace add caoyuan-fire/engi-foundry-skill",
            "/plugin install engifoundry-bundle@engi-foundry-skill",
            ".claude-plugin/marketplace.json",
            "/plugins install https://github.com/caoyuan-fire/engi-foundry-skill",
            ".kimi-plugin/plugin.json",
        ])
        self.assert_contains_all("docs/platform-metadata.md", [
            "Claude does not use Codex's `.agents/plugins/marketplace.json`",
            ".kimi-plugin/plugin.json",
            "/plugins install https://github.com/caoyuan-fire/engi-foundry-skill",
            "Official Kimi marketplace search visibility is separate from repository compatibility",
        ])
        self.assert_contains_all("docs/publication.md", [
            "`.claude-plugin/marketplace.json` makes the GitHub repository a Claude plugin marketplace",
            "`.kimi-plugin/plugin.json` makes the GitHub repository directly installable",
            "Official Kimi marketplace search visibility is a separate publication channel",
        ])
        self.assert_contains_all("skills/engifoundry/agents/generic.json", [
            ".claude-plugin/marketplace.json",
            ".kimi-plugin/plugin.json",
            "/plugins install https://github.com/caoyuan-fire/engi-foundry-skill",
        ])

    def test_plugin_and_skills_only_installation_are_exclusive(self):
        phrases = [
            "Do not install both the plugin package and skills-only entries into the same host home",
            "duplicate `$engifoundry-gate` and `$engifoundry` entries",
        ]

        self.assert_contains_all("README.md", phrases)
        self.assert_contains_all("docs/publication.md", [
            "Plugin installation and skills-only installation are mutually exclusive within one host home",
            "duplicate `$engifoundry-gate` and `$engifoundry` entries",
        ])

        manifest = json.loads(read("engifoundry.manifest.json"))
        self.assertIn("plugin", manifest["installModes"]["skillsOnly"]["exclusiveWith"])

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
            "Detailed installation and publication rules live in",
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
            "详细安装和发布规则见",
            "根 README 应保持为面向人类的入口文档",
        ])
        self.assert_contains_all("docs/publication.md", [
            "Keep README as a human-facing project entry point, not a protocol specification",
            "Do not duplicate long rules across README, docs, and references",
        ])

        readme = read("README.md")
        forbidden_phrases = [
            "## Artifact Root",
            "## Artifact Root Layout",
            "## Execution Config",
            "## Package Format",
            "## Job Format",
            "Package Alignment Gate",
            "Executor Invocation Profiles",
            "```json",
        ]
        for phrase in forbidden_phrases:
            with self.subTest(phrase=phrase):
                self.assertNotIn(phrase, readme)

        zh_readme = read("zh/README.md")
        zh_forbidden_phrases = [
            "## 成果物根目录",
            "## 成果物目录结构",
            "## 执行配置",
            "## 任务包格式",
            "## Job 格式",
            "Package Alignment Gate",
            "```json",
        ]
        for phrase in zh_forbidden_phrases:
            with self.subTest(phrase=phrase):
                self.assertNotIn(phrase, zh_readme)

    def test_package_governance_constraints_are_synced_to_installable_references(self):
        expectations = {
            "role-protocol.md": [
                "Package-First Conflict Rule",
                "approved package or Job contract",
                "executor report is not Job approval",
                "Takeover Verification Gate",
            ],
            "package-format.md": [
                "Reader Acknowledgement",
                "Package Alignment Gate",
                "Alignment records are review records",
                "only applies after work enters a package flow",
            ],
            "adapter-contract.md": [
                "Executor Contract Gate",
                "Do not assume stdin support",
                "Watchdog behavior must be explicit",
            ],
            "engineering-discipline.md": [
                "Bounded Rework Gate",
                "failure alignment",
                "not delta-only",
            ],
        }

        for file_name, phrases in expectations.items():
            with self.subTest(file=file_name):
                self.assert_contains_all(f"docs/{file_name}", phrases)
                self.assert_contains_all(f"skills/engifoundry/references/{file_name}", phrases)

    def test_job_governance_constraints_are_available_in_docs_and_package_reference(self):
        phrases = [
            "`type`: `delegable | primary-control-only | review-only | blocked`",
            "`stopConditions`",
            "`requiredReturnFormat`",
            "Executor completion does not complete the Job",
        ]

        self.assert_contains_all("docs/job-format.md", phrases)
        self.assert_contains_all("skills/engifoundry/references/package-format.md", phrases)

    def test_manifest_maps_review_and_audit_to_engineering_discipline(self):
        manifest = json.loads(read("engifoundry.manifest.json"))
        required_for = manifest["modules"]["engineering-discipline"]["requiredFor"]

        self.assertIn("review-only", required_for)
        self.assertIn("audit", required_for)

    def test_artifact_and_package_root_git_policy_is_explicit(self):
        phrases = [
            "The artifact root is for durable work products",
            "The package root is for execution inputs",
            "<artifact-root>/records/packages/PHASE-001/PAK-001/",
            "EngiFoundry may automatically add the package root to `.gitignore`",
            "Tell the user only when the ignore rule is first added",
            "Do not store Git ignore state in `.engifoundry.config.json`",
            "Git is the source of truth",
        ]

        self.assert_contains_all("docs/artifact-protocol.md", phrases)
        self.assert_contains_all("skills/engifoundry/references/artifact-protocol.md", phrases)

    def test_roadmap_protocol_is_package_root_phase_state_not_project_config_state(self):
        phrases = [
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
        ]

        self.assert_contains_all("docs/artifact-protocol.md", phrases)
        self.assert_contains_all("skills/engifoundry/references/artifact-protocol.md", phrases)
        self.assert_contains_all(
            "skills/engifoundry/references/intent-routing.md",
            [
                "When the user asks what to do next",
                "check the relevant package-root phase for `ROADMAP.md`",
                "check `<package-root>/ROADMAP.md` for the relevant phase section",
                "If no roadmap exists",
            ],
        )

    def test_artifact_protocol_has_directory_function_table(self):
        phrases = [
            "## Directory Function Table",
            "| Path | Category | Purpose | Must Not Contain |",
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
        ]

        self.assert_contains_all("docs/artifact-protocol.md", phrases)
        self.assert_contains_all("skills/engifoundry/references/artifact-protocol.md", phrases)

    def test_initialization_scripts_are_documented(self):
        phrases = [
            "## Initialization Scripts",
            "create_root_config",
            "create_standard_dirs",
            "create_directory_config",
            "Templates are formal editable files",
            "POSIX shell",
            "PowerShell",
            "do not require Python",
        ]

        self.assert_contains_all("docs/configuration.md", phrases)
        self.assert_contains_all("README.md", [
            "without requiring a separate \"initialize\"",
            "[Configuration](docs/configuration.md)",
        ])

    def test_lazy_automatic_initialization_is_required_for_new_projects(self):
        phrases = [
            "## Automatic Initialization",
            "EngiFoundry supports lazy automatic initialization",
            "If EngiFoundry workflow starts in a project with no `.engifoundry.config.json`, artifact root, or package root",
            "initialize the default project config, artifact root, directory config, and package root automatically before the first durable EngiFoundry read or write",
            "Do not require the user to request \"initialize EngiFoundry\" as a separate step",
            "Ask before initializing only when the default paths are unsafe or ambiguous",
        ]

        self.assert_contains_all("docs/configuration.md", phrases)
        self.assert_contains_all("docs/artifact-protocol.md", phrases)
        self.assert_contains_all("skills/engifoundry/references/artifact-protocol.md", phrases)
        self.assert_contains_all("README.md", [
            "without requiring a separate \"initialize\"",
            "[Artifact protocol](docs/artifact-protocol.md)",
        ])
        self.assert_contains_all("skills/engifoundry/SKILL.md", [
            "If EngiFoundry workflow starts in a project with no `.engifoundry.config.json`, artifact root, or package root",
            "initialize the default project config, artifact root, directory config, and package root automatically before the first durable EngiFoundry read or write",
            "Do not require the user to request initialization as a separate step",
        ])
        self.assert_contains_all("zh/README.md", [
            "不要求用户单独发起“初始化”或“编制任务包”请求",
            "[Artifact protocol](../docs/artifact-protocol.md)",
        ])

    def test_skill_version_policy_is_low_noise_and_documented(self):
        phrases = [
            "Skill version is a maintenance label",
            "Check at most once per session",
            "only when network access is available",
            "must not block normal EngiFoundry work",
            "check_version",
        ]

        self.assert_contains_all("skills/engifoundry/SKILL.md", phrases)
        self.assert_contains_all("docs/publication.md", phrases)

    def test_executor_config_records_invocation_profile_and_ordered_preference(self):
        phrases = [
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
        ]

        self.assert_contains_all("docs/configuration.md", phrases)
        self.assert_contains_all("docs/execution-policy.md", phrases)
        self.assert_contains_all("skills/engifoundry/references/artifact-protocol.md", phrases)

    def test_executor_bootstrap_policy_is_explicit_in_installable_skill(self):
        phrases = [
            "When aligning a new project or new EngiFoundry session to project workflow state, prefer reading `<artifact-root>/execution.config.json`",
            "If no package, Job, prompt, or execution config specifies an executor, use `direct`",
            "If package work requires bounded or isolated execution and no usable executor config exists",
            "safely discover local executor capability or ask the user",
        ]
        self.assert_contains_all("skills/engifoundry/SKILL.md", phrases)

        reference_phrases = [
            "Executor Bootstrap",
            "When no package, Job, prompt, or `execution.config.json` specifies an executor, use `direct`",
            "Do not ask the user to choose an executor when a package, Job, prompt, or `execution.config.json` already names a usable executor",
            "If safe discovery cannot establish a usable bounded executor, ask the user which executor to register or use",
            "Do not infer durable executor capability from product names, installed binaries, or examples alone",
            "When aligning a new project or new EngiFoundry session to project workflow state, prefer reading `<artifact-root>/execution.config.json`",
            "This execution-config read is a session-alignment step, not a mandatory read before every ad-hoc task",
            "If the file is missing, continue with the executor bootstrap rules",
            "When session alignment or safe discovery reveals missing executor knowledge, suggest recording durable non-sensitive facts",
            "Do not force a write unless the user asks to persist it or package execution needs a durable executor contract",
        ]

        self.assert_contains_all("skills/engifoundry/references/artifact-protocol.md", reference_phrases)
        self.assert_contains_all("docs/configuration.md", reference_phrases)

        execution_policy_phrases = [
            phrase
            for phrase in reference_phrases
            if phrase != "If the file is missing, continue with the executor bootstrap rules"
        ]
        self.assert_contains_all("docs/execution-policy.md", execution_policy_phrases)

    def test_executor_liveness_contract_prevents_wait_window_aborts(self):
        phrases = [
            "Executor Liveness Contract",
            "must not abort a long-running executor solely because a fixed elapsed-time or wait-turn window has passed",
            "Silence is a reason to probe, not a reason to abort",
            "`livenessSignals`",
            "`probeBehavior`",
            "`stallCriteria`",
            "`abortCriteria`",
            "Repeated generic `working` responses without changed phase, evidence, or next action are not sufficient progress evidence",
        ]

        self.assert_contains_all("docs/adapter-contract.md", phrases)
        self.assert_contains_all("docs/execution-policy.md", phrases)
        self.assert_contains_all("skills/engifoundry/references/adapter-contract.md", phrases)

    def test_executor_output_cost_controls_limit_primary_stream_ingestion(self):
        phrases = [
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
        ]

        self.assert_contains_all("docs/execution-policy.md", phrases)
        self.assert_contains_all("docs/adapter-contract.md", phrases)
        self.assert_contains_all("skills/engifoundry/references/adapter-contract.md", phrases)

    def test_package_alignment_is_planning_ready_gate_not_third_status_dimension(self):
        phrases = [
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
        ]

        self.assert_contains_all("docs/package-format.md", phrases)
        self.assert_contains_all("skills/engifoundry/references/package-format.md", phrases)
        self.assert_contains_all("skills/engifoundry/SKILL.md", [
            "When the user asks to create, compile, or prepare a task package",
            "must target `planning.status=ready` in the same request",
            "do not stop at draft to ask whether alignment should run",
        ])
        self.assert_contains_all("README.md", [
            "broad, risky, multi-step, ambiguous, or handoff-oriented changes use structured task packages",
            "[Package format](docs/package-format.md)",
        ])
        self.assert_contains_all("zh/README.md", [
            "范围大、高风险、多步骤、含糊或需要交接的变更使用结构化任务包",
            "[Package format](../docs/package-format.md)",
        ])

        forbidden_phrases = [
            "Review a package before execution",
            "执行前检查任务包是否可执行",
            "required before implementation starts",
        ]
        for path in [
            "README.md",
            "zh/README.md",
            "docs/package-format.md",
            "skills/engifoundry/SKILL.md",
            "skills/engifoundry/references/package-format.md",
        ]:
            content = read(path)
            for phrase in forbidden_phrases:
                with self.subTest(path=path, phrase=phrase):
                    self.assertNotIn(phrase, content)


if __name__ == "__main__":
    unittest.main()
