import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "engifoundry-deliver" / "SKILL.md"
CONTRACT = ROOT / "skills" / "engifoundry-deliver" / "references" / "contracts.md"


class DeliverNodeContractTests(unittest.TestCase):
    def test_deliver_uses_available_verification(self):
        content = SKILL.read_text()
        self.assertIn("latest verification result is `verified-available`", content)
        self.assertIn("Verification evidence is input", content)
        self.assertIn("does not repeat Verify or Review", content)

    def test_automation_modes_control_acceptance(self):
        content = SKILL.read_text()
        self.assertIn("`full-auto` supplies `auto-accepted`", content)
        self.assertIn("`job-approval` and `package-approval` are `acceptance-pending`", content)

    def test_rejected_acceptance_has_explicit_destinations(self):
        content = SKILL.read_text()
        self.assertIn("`rework-required` with kind `implementation`", content)
        self.assertIn("Exec the applicable correction contract", content)
        self.assertIn("`rework-required` with kind `contract`", content)
        self.assertIn("Orch the applicable correction contract", content)

    def test_delivery_record_is_terminal_and_minimal(self):
        skill = SKILL.read_text()
        contract = CONTRACT.read_text()
        self.assertIn("Never overwrite or renumber an earlier acceptance attempt", contract)
        self.assertIn("No delivery record exists yet", contract)
        self.assertIn("execution.status: completed", skill)
        for forbidden in ("raw conversation", "routine progress", "long logs"):
            self.assertIn(forbidden, contract)

    def test_completed_delivery_has_human_handoff_summary(self):
        skill = SKILL.read_text()
        contract = CONTRACT.read_text()
        self.assertIn("matching human-readable `DELIVERY-<NNN>.md`", skill)
        self.assertIn("## Human Summary", contract)
        self.assertIn('"summaryRef"', contract)
        self.assertIn("current engineering state", contract)
        self.assertIn("labeled `critical`, `high`, `medium`, or `low`", contract)
        self.assertIn("handoff status, open actions, and the next entry point", contract)


if __name__ == "__main__":
    unittest.main()
