import unittest
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


if __name__ == "__main__":
    unittest.main()
