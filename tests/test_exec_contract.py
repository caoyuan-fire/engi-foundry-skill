import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "engifoundry-exec" / "SKILL.md"
CONTRACT = ROOT / "skills" / "engifoundry-exec" / "references" / "contracts.md"


class ExecContractTests(unittest.TestCase):
    def test_skill_preserves_four_engineering_disciplines(self):
        content = SKILL.read_text()
        for rule in ("TDD", "Systematic debugging", "Review", "Verification before completion"):
            self.assertIn(rule, content)

    def test_result_contract_is_concise_and_separates_evidence(self):
        content = CONTRACT.read_text()
        for field in (
            '"executorId"',
            '"result"',
            '"changedAreas"',
            '"outputs"',
            '"reviewRef"',
            '"exceptions"',
        ):
            self.assertIn(field, content)
        for legacy_file in ("record.md", "verification.md", "review.md", "checkpoint.md", "handoff.md"):
            self.assertNotIn(legacy_file, content)

    def test_exceptions_are_conditional_and_fact_based(self):
        content = CONTRACT.read_text()
        self.assertIn("Add `exceptions` only when something exceptional occurred", content)
        self.assertIn("Each exception states an objective fact", content)

    def test_exec_cannot_complete_package_delivery(self):
        content = SKILL.read_text()
        self.assertIn("does not perform final Package verification or delivery while applying Exec", content)

    def test_job_approval_is_durable_and_rejectable(self):
        skill = SKILL.read_text()
        contract = CONTRACT.read_text()
        self.assertIn("`approval-pending`: current Review passed", skill)
        self.assertIn("User approval supplies the missing completion fact", skill)
        self.assertIn("recorded in `reworkFacts`", skill)
        self.assertIn("| `approval-pending` |", contract)
        self.assertIn("`user-rejected` exception", contract)

    def test_exec_continues_from_recorded_facts(self):
        content = SKILL.read_text()
        self.assertIn("`jobs-completed` is the fact that lets the Agent read Verify", content)
        self.assertNotIn("loaded for this turn", content)

    def test_rework_uses_existing_state_meanings(self):
        skill = SKILL.read_text()
        contract = CONTRACT.read_text()
        self.assertIn("affected Jobs; those Jobs are `rework-required`", skill)
        self.assertIn("Package planning is `rework-required`", skill)
        self.assertIn("no separate reopen state exists", contract)

    def test_executor_has_minimum_invocation_and_liveness_rules(self):
        content = SKILL.read_text()
        self.assertIn("verified invocation", content)
        self.assertIn("Run bounded work from the project root", content)
        self.assertIn("running or quiet process is not unavailable", content)

    def test_exec_reads_complete_executor_contract_and_obeys_gate(self):
        content = SKILL.read_text()
        self.assertIn("complete Executor and Workflow config files", content)
        self.assertIn("read that complete schema", content)
        self.assertIn("Do not extract only `executor`", content)
        self.assertIn("Use only the single configured `executor`", content)
        self.assertIn("Evaluate `gate.executorUnavailable`", content)
        self.assertIn("ask whether the current controlling session may take over", content)
        self.assertIn("execution failure", content)


if __name__ == "__main__":
    unittest.main()
