import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "skills"


class AgentExecutionModelTests(unittest.TestCase):
    def markdown(self):
        return list(SKILLS.rglob("*.md"))

    def test_skills_are_not_component_calls(self):
        content = "\n".join(path.read_text() for path in self.markdown())
        for forbidden in (
            "call `engifoundry-",
            "if loaded; otherwise stop",
            "loaded for this turn",
            "apply-review",
            "submit-review",
            "return control to",
            "wait for Review",
        ):
            self.assertNotIn(forbidden, content)

    def test_runtime_contracts_do_not_encode_state_machine_arrows(self):
        for path in self.markdown():
            self.assertNotIn("->", path.read_text(), str(path))

    def test_state_contracts_define_meanings(self):
        for relative in (
            "engifoundry-orch/references/contracts.md",
            "engifoundry-exec/references/contracts.md",
            "engifoundry-review/references/contracts.md",
            "engifoundry-verify/references/contracts.md",
            "engifoundry-deliver/references/contracts.md",
        ):
            content = (SKILLS / relative).read_text()
            self.assertIn("State Meaning", content, relative)

    def test_orch_scripts_only_handle_mechanical_structure(self):
        for name in ("orch.sh", "orch.ps1"):
            content = (SKILLS / "engifoundry-orch" / "scripts" / name).read_text()
            for semantic_action in ("apply-review", "submit-review", "verified-available", "jobs-completed"):
                self.assertNotIn(semantic_action, content)

    def test_orch_contract_distinguishes_project_and_skill_roots(self):
        content = (SKILLS / "engifoundry-orch" / "SKILL.md").read_text()
        self.assertIn("`<project-root>`", content)
        self.assertIn("`<orch-skill-root>`", content)
        self.assertIn("<orch-skill-root>/scripts/orch.sh", content)
        self.assertIn("--project-root <project-root>", content)
        self.assertIn("<orch-skill-root>/scripts/orch.ps1", content)
        self.assertIn("-ProjectRoot <project-root>", content)
        self.assertNotIn("`sh scripts/orch.sh", content)
        self.assertNotIn("`./engifoundry.config.json`", content)


if __name__ == "__main__":
    unittest.main()
