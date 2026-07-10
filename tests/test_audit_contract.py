import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "engifoundry-audit" / "SKILL.md"
ORCH = ROOT / "skills" / "engifoundry-orch" / "SKILL.md"
ROUTER = ROOT / "skills" / "engifoundry-router" / "SKILL.md"


class AuditContractTests(unittest.TestCase):
    def test_audit_is_classification_only(self):
        content = SKILL.read_text()
        self.assertIn("only to classify new work", content)
        self.assertIn("does not execute, plan, split Jobs, edit files", content)
        self.assertIn("write durable records", content)

    def test_audit_has_three_small_results(self):
        content = SKILL.read_text()
        self.assertIn("as `direct`, `package`, or `blocked`", content)
        self.assertNotIn("Return only", content)
        self.assertNotIn('"status"', content)
        self.assertIn("Ambiguity produces `package`, not `blocked`", content)
        self.assertIn("objective inaccessible or invalid required input", content)

    def test_package_facts_override_preferences(self):
        content = SKILL.read_text()
        for fact in (
            "explicitly requests a Package",
            "dependent Jobs",
            "Executor delegation",
            "cross-session or human handoff",
            "material security, data, release, migration, destructive, or delivery risk",
        ):
            self.assertIn(fact, content)
        for preference in ("package-first", "balanced", "direct-first"):
            self.assertIn(f"`{preference}`", content)

    def test_direct_is_a_declared_non_node_destination(self):
        audit = SKILL.read_text()
        orch = ORCH.read_text()
        router = ROUTER.read_text()
        self.assertIn("Router Group Rules", audit)
        self.assertIn("continues under the Router Group Rules", orch)
        self.assertIn("Agent direct action for a `direct` Audit classification", router)
        self.assertIn("declared non-Node destination", router)


if __name__ == "__main__":
    unittest.main()
