import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ROUTER = ROOT / "skills" / "engifoundry-router" / "SKILL.md"
ORCH = ROOT / "skills" / "engifoundry-orch" / "SKILL.md"
EXEC = ROOT / "skills" / "engifoundry-exec" / "SKILL.md"
VERIFY = ROOT / "skills" / "engifoundry-verify" / "SKILL.md"
DELIVER = ROOT / "skills" / "engifoundry-deliver" / "SKILL.md"


class RoutingContractTests(unittest.TestCase):
    def test_router_has_only_the_entry_load_requirement(self):
        content = ROUTER.read_text()
        self.assertIn("this Router must be loaded before runtime contract selection", content)
        self.assertIn("Agent may reread it whenever useful", content)
        self.assertIn("After a stage operation completes, the Agent may reread", content)
        self.assertNotIn("Never ", content)
        self.assertNotIn("Do not ", content)

    def test_contract_continuation_is_fact_driven(self):
        orch = ORCH.read_text()
        execution = EXEC.read_text()
        self.assertIn("a `ready` PAK is the fact", orch)
        self.assertIn("`jobs-completed` is the fact", execution)
        self.assertNotIn("routed flow", orch + execution)

    def test_destinations_can_be_loaded_when_selected(self):
        content = "\n".join(path.read_text() for path in (ORCH, EXEC, VERIFY, DELIVER))
        self.assertNotIn("loaded for this turn", content)
        self.assertNotIn("if loaded; otherwise stop", content)
        self.assertIn("read Verify", content)
        self.assertIn("read Deliver", content)

    def test_router_lists_node_record_contracts(self):
        content = ROUTER.read_text()
        for value in (
            "Project-owned inputs",
            "State Signals",
            "jobs-completed",
            "verified-available",
            "approval pause",
        ):
            self.assertIn(value, content)

    def test_destinations_are_declared_not_prescribed(self):
        content = ROUTER.read_text()
        self.assertIn("Possible next contracts", content)
        self.assertIn("declarations, not routing commands", content)
        self.assertIn("Agent selects, combines, and rereads", content)
        self.assertIn("rejected acceptance requiring implementation rework", content)

    def test_agent_prefers_complete_goal_driven_orchestration(self):
        content = ROUTER.read_text()
        self.assertIn("user's requested endpoint", content)
        self.assertIn("reasonably complete contract set for end-to-end completion", content)
        self.assertIn("rather than only the smallest immediate contract", content)
        self.assertIn("explicitly stage-bounded request remains bounded", content)

    def test_incomplete_initialization_does_not_capture_normal_work(self):
        content = ROUTER.read_text()
        self.assertIn("initialization is not `complete`", content)
        self.assertIn("does not explicitly ask for EngiFoundry proceeds normally", content)
        self.assertIn("cannot use runtime contracts", content)
        self.assertIn("explicit request to continue or complete initialization", content)

    def test_group_rules_cover_direct_work(self):
        content = ROUTER.read_text()
        self.assertIn("including a `direct` classification", content)
        for rule in ("test-first", "reproduced evidence", "fresh context", "fresh task-appropriate verification"):
            self.assertIn(rule, content)

    def test_package_repository_boundary_requires_explicit_inclusion(self):
        content = ROUTER.read_text()
        self.assertIn("`.engifoundry/packages/` is outside the scope", content)
        self.assertIn('"commit the current changes"', content)
        self.assertIn('"commit everything"', content)
        self.assertIn("Only explicit task-package inclusion authorizes overriding", content)

    def test_pause_points_have_human_readable_records(self):
        content = ROUTER.read_text()
        self.assertIn("## Pause Records", content)
        self.assertIn("PAUSE-<NNN>.md", content)
        self.assertIn("execution summary, current engineering state, or human acceptance checklist", content)
        self.assertIn("Automatic continuation and completed delivery are not pause points", content)

    def test_router_lists_docs_as_supporting_skill(self):
        content = ROUTER.read_text()
        self.assertIn("`engifoundry-docs`", content)
        self.assertIn("explicitly requests a detailed human-readable document", content)


if __name__ == "__main__":
    unittest.main()
