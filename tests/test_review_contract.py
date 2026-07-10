import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "engifoundry-review" / "SKILL.md"
CONTRACT = ROOT / "skills" / "engifoundry-review" / "references" / "contracts.md"


class ReviewContractTests(unittest.TestCase):
    def test_review_requires_clean_context(self):
        content = SKILL.read_text()
        self.assertIn("establishes a fresh context", content)
        self.assertIn("must not have performed the reviewed work", content)
        self.assertIn("same model is acceptable", content)
        self.assertIn("independent of `executorOrder`", content)

    def test_review_is_rules_without_program_interface(self):
        self.assertFalse((SKILL.parent / "scripts").exists())
        content = SKILL.read_text()
        self.assertNotIn("apply-review", content)
        self.assertNotIn("permission", content.lower())

    def test_review_supports_all_engifoundry_subjects(self):
        content = SKILL.read_text()
        for value in ("Planning", "Job", "Other durable output"):
            self.assertIn(value, content)
        for result in ("`pass`", "`rework-required`", "`blocked`"):
            self.assertIn(result, content)

    def test_blocked_has_a_factual_floor(self):
        content = SKILL.read_text()
        self.assertIn("condition prevents Review itself", content)
        self.assertIn("is `rework-required`, not `blocked`", content)
        self.assertIn("Never use `blocked` for uncertainty", content)

    def test_attempts_are_immutable_and_minimal(self):
        content = CONTRACT.read_text()
        self.assertIn("Every attempt is immutable", content)
        self.assertIn('"kind": "subject"', content)
        self.assertIn("Finding kind is `subject` or `contract`", content)
        for forbidden in ("prompts", "reasoning", "raw streams", "long logs"):
            self.assertIn(forbidden, content)

    def test_review_defines_applicable_state_meanings(self):
        content = CONTRACT.read_text()
        self.assertIn("## State Meanings", content)
        self.assertIn("`planning.status: ready`", content)
        self.assertIn("Job `pending-review` with the pass `reviewRef`", content)
        self.assertNotIn("State Effects", content)


if __name__ == "__main__":
    unittest.main()
