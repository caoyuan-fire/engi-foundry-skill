import json
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "skills" / "engifoundry" / "scripts"


class InitScriptsTests(unittest.TestCase):
    def run_script(self, script_name, *args, cwd):
        result = subprocess.run(
            ["sh", str(SCRIPTS / script_name), *args],
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def test_cross_platform_init_scripts_are_present(self):
        for stem in ["create_root_config", "create_standard_dirs", "create_directory_config", "check_version"]:
            with self.subTest(script=stem):
                self.assertTrue((SCRIPTS / f"{stem}.sh").exists())
                ps1 = SCRIPTS / f"{stem}.ps1"
                self.assertTrue(ps1.exists())
                content = ps1.read_text(encoding="utf-8")
                self.assertIn("param(", content)
                if stem != "check_version":
                    self.assertIn("ProjectRoot", content)

    def test_root_config_script_creates_empty_and_filled_formal_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)

            self.run_script("create_root_config.sh", "--mode", "empty", cwd=project)
            empty_config = json.loads((project / ".engifoundry.config.json").read_text(encoding="utf-8"))
            self.assertEqual(empty_config["schemaVersion"], 1)
            self.assertEqual(empty_config["artifactRoot"], "")
            self.assertEqual(empty_config["packageRoot"], "")

            self.run_script(
                "create_root_config.sh",
                "--mode",
                "filled",
                "--artifact-root",
                "docs",
                "--package-root",
                ".packs",
                "--force",
                cwd=project,
            )
            filled_config = json.loads((project / ".engifoundry.config.json").read_text(encoding="utf-8"))
            self.assertEqual(filled_config["artifactRoot"], "docs")
            self.assertEqual(filled_config["packageRoot"], ".packs")
            self.assertEqual(filled_config["recordsPolicy"], "durable")
            self.assertEqual(filled_config["defaultPackagePolicy"], "package-when-risky")

    def test_standard_dirs_script_uses_root_config_and_creates_layout(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)

            self.run_script(
                "create_root_config.sh",
                "--mode",
                "filled",
                "--artifact-root",
                "docs",
                "--package-root",
                ".packs",
                cwd=project,
            )
            self.run_script("create_standard_dirs.sh", cwd=project)

            for relative in [
                "docs/records/ad-hoc",
                "docs/records/packages",
                "docs/records/reviews",
                "docs/records/audits",
                "docs/docs/generated",
                "docs/docs/integration",
                "docs/docs/design",
                "docs/docs/reference",
                "docs/docs/archive",
                ".packs",
            ]:
                self.assertTrue((project / relative).is_dir(), relative)

    def test_directory_config_script_creates_empty_and_filled_formal_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)

            self.run_script(
                "create_root_config.sh",
                "--mode",
                "filled",
                "--artifact-root",
                "docs",
                "--package-root",
                ".packs",
                cwd=project,
            )
            self.run_script(
                "create_directory_config.sh",
                "--mode",
                "empty",
                cwd=project,
            )
            empty_config = json.loads((project / "docs" / "directory.config.json").read_text(encoding="utf-8"))
            self.assertEqual(empty_config["schemaVersion"], 1)
            self.assertEqual(empty_config["directories"][0]["path"], "")

            self.run_script(
                "create_directory_config.sh",
                "--mode",
                "filled",
                "--artifact-root",
                "docs",
                "--package-root",
                ".packs",
                "--force",
                cwd=project,
            )
            filled_config = json.loads((project / "docs" / "directory.config.json").read_text(encoding="utf-8"))
            paths = {entry["path"] for entry in filled_config["directories"]}
            self.assertIn("<artifact-root>/docs/integration/", paths)
            self.assertIn("<artifact-root>/records/ad-hoc/", paths)
            self.assertIn("<artifact-root>/records/packages/PHASE-001/PAK-001/", paths)
            self.assertIn("<package-root>/PHASE-001/ROADMAP.md", paths)
            self.assertIn("<package-root>/PHASE-001/PAK-001/", paths)
            self.assertIn("createdBy", filled_config)


if __name__ == "__main__":
    unittest.main()
