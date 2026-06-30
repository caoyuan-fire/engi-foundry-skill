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

        self.assert_contains_all("skills/engifoundry/SKILL.md", phrases)
        self.assert_contains_all("skills/engifoundry/references/intent-routing.md", phrases)

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
            "<artifact-root>/records/packages/<package-id>/",
            "EngiFoundry may automatically add the package root to `.gitignore`",
            "Tell the user only when the ignore rule is first added",
            "Do not store Git ignore state in `.engifoundry.config.json`",
            "Git is the source of truth",
        ]

        self.assert_contains_all("docs/artifact-protocol.md", phrases)
        self.assert_contains_all("skills/engifoundry/references/artifact-protocol.md", phrases)

    def test_roadmap_protocol_is_artifact_root_state_not_project_config_state(self):
        phrases = [
            "<artifact-root>/roadmaps/",
            "ROADMAP.md",
            "roadmap.index.json",
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
                "If no roadmap exists",
            ],
        )

    def test_artifact_protocol_has_directory_function_table(self):
        phrases = [
            "## Directory Function Table",
            "| Path | Category | Purpose | Must Not Contain |",
            "`<artifact-root>/records/ad-hoc/`",
            "`<artifact-root>/records/packages/<package-id>/`",
            "`<artifact-root>/records/reviews/`",
            "`<artifact-root>/records/audits/`",
            "`<artifact-root>/directory.config.json`",
            "`<artifact-root>/docs/generated/`",
            "`<artifact-root>/docs/integration/`",
            "`<artifact-root>/docs/design/`",
            "`<artifact-root>/docs/reference/`",
            "`<artifact-root>/docs/archive/`",
            "`<package-root>/<package-id>/`",
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
        self.assert_contains_all("README.md", phrases)

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


if __name__ == "__main__":
    unittest.main()
