import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "engifoundry-docs" / "SKILL.md"


class DocsContractTests(unittest.TestCase):
    def test_docs_requires_explicit_detailed_document_request(self):
        content = SKILL.read_text()
        self.assertIn("only for an explicit request for a detailed document", content)
        self.assertIn("Routine pause records and required PAK delivery summaries", content)

    def test_docs_uses_project_records_without_invention(self):
        content = SKILL.read_text()
        self.assertIn("primary records and artifacts", content)
        self.assertIn("instead of resolving it by invention", content)
        self.assertIn("do not dump records, raw logs, prompts, or reasoning", content)

    def test_docs_format_matches_content(self):
        content = SKILL.read_text()
        for value in ("tables for comparisons", "bullet lists", "numbered lists", "fenced code blocks", "blockquotes"):
            self.assertIn(value, content)
        self.assertIn("Match structure to content rather than forcing a fixed template", content)

    def test_docs_is_rules_without_program_interface(self):
        self.assertFalse((SKILL.parent / "scripts").exists())


if __name__ == "__main__":
    unittest.main()
