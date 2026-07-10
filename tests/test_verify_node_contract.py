import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "engifoundry-verify" / "SKILL.md"
CONTRACT = ROOT / "skills" / "engifoundry-verify" / "references" / "contracts.md"


class VerifyNodeContractTests(unittest.TestCase):
    def test_verify_is_package_goal_only(self):
        content = SKILL.read_text()
        self.assertIn("verifies the complete PAK goal rather than individual Job steps", content)
        self.assertIn("execution.status: jobs-completed", content)

    def test_success_is_available_not_accepted(self):
        skill = SKILL.read_text()
        contract = CONTRACT.read_text()
        self.assertIn("Never write `pass`", skill)
        self.assertIn("verified-available", contract)
        self.assertNotIn('"result": "pass"', contract)
        self.assertIn("This is not `pass`, approval, acceptance, or delivery", contract)

    def test_record_is_immutable_and_minimal(self):
        content = CONTRACT.read_text()
        self.assertIn("Never overwrite or renumber an earlier attempt", content)
        self.assertIn("Omit `findings` when the result is `verified-available`", content)
        for forbidden in ("raw streams", "routine progress", "approval decisions"):
            self.assertIn(forbidden, content)

    def test_continuation_is_fact_driven(self):
        content = SKILL.read_text()
        self.assertIn("`verified-available` lets the Agent read Deliver", content)
        self.assertIn("An `implementation` finding", content)
        self.assertIn("A `contract` finding", content)
        self.assertIn("`blocked` is terminal", content)

    def test_rework_reconciles_existing_states(self):
        content = SKILL.read_text()
        self.assertIn("affected Jobs and Package execution also carry `rework-required`", content)
        self.assertIn("Package planning carries `rework-required`", content)


if __name__ == "__main__":
    unittest.main()
