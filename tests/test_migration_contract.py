import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENTRY = ROOT / "skills" / "engifoundry" / "SKILL.md"
INIT = ROOT / "skills" / "engifoundry-init" / "SKILL.md"
MIGRATION = ROOT / "skills" / "engifoundry-init" / "references" / "migration.md"
WORKSPACE = ROOT / "skills" / "engifoundry-init" / "references" / "workspace.md"
ROUTER = ROOT / "skills" / "engifoundry-router" / "SKILL.md"


class MigrationContractTests(unittest.TestCase):
    def test_explicit_migration_can_trigger_init(self):
        entry = ENTRY.read_text()
        init = INIT.read_text()
        self.assertIn("migrate, or upgrade", entry)
        self.assertIn("explicit migration or upgrade request", init)
        self.assertIn("Create, migrate, or modify", ROUTER.read_text())

    def test_normal_init_does_not_scan_for_legacy(self):
        content = MIGRATION.read_text()
        self.assertIn("Normal Entry and Init behavior must not scan", content)
        self.assertIn("Read the exact legacy root config", content)

    def test_agent_decides_full_reinit_from_facts(self):
        content = MIGRATION.read_text()
        self.assertIn("Use full Init interaction when", content)
        self.assertIn("Do not ask the user to choose merely because migration exists", content)
        self.assertIn("preferences cannot be mapped confidently", content)

    def test_historical_content_is_moved_without_rewrite(self):
        content = MIGRATION.read_text()
        self.assertIn("artifact content unchanged", content)
        self.assertIn("non-control content unchanged", content)
        self.assertIn("does not edit, reformat, reinterpret, or summarize", content)
        self.assertIn(".engifoundry/artifacts/legacy/", WORKSPACE.read_text())

    def test_only_control_json_is_rebuilt(self):
        content = MIGRATION.read_text()
        for name in (
            "phase.index.json",
            "phase.config.json",
            "package.config.json",
            "job.config.json",
        ):
            self.assertIn(name, content)
        self.assertIn("Other JSON files are historical content", content)
        self.assertIn("Never copy a legacy control JSON into an active current path", content)

    def test_migration_has_no_program_interface(self):
        scripts = INIT.parent / "scripts"
        self.assertFalse((scripts / "migrate.sh").exists())
        self.assertFalse((scripts / "migrate.ps1").exists())
        self.assertIn("Migration is Agent-directed", INIT.read_text())


if __name__ == "__main__":
    unittest.main()
