import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "engifoundry-review" / "SKILL.md"
CONTRACT = ROOT / "skills" / "engifoundry-review" / "references" / "contracts.md"


class ReviewContractTests(unittest.TestCase):
    def test_review_requires_clean_context(self):
        content = SKILL.read_text()
        self.assertIn("genuinely fresh context", content)
        self.assertIn("did not perform the reviewed work", content)
        self.assertIn("same model as the producer is acceptable", content)

    def test_reviewer_selection_uses_complete_project_config(self):
        content = SKILL.read_text()
        self.assertIn("## Reviewer Selection", content)
        self.assertIn("complete project-owned Executor configuration", content)
        self.assertIn("complete schema referenced by its `schemaRef`", content)
        self.assertIn("Use the configured `reviewer`", content)
        self.assertIn("inspect the complete primary subject and evidence", content)
        self.assertIn("never replace it with a host-native subagent", content)

    def test_reviewer_fallback_does_not_enable_conclusion_shopping(self):
        content = SKILL.read_text()
        self.assertIn("Objective unavailability before a conclusion", content)
        self.assertIn("`pass` and `rework-required` are conclusions", content)
        self.assertIn("never repeat Review to seek a preferred result", content)
        self.assertIn("A new Review requires a changed subject", content)

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
