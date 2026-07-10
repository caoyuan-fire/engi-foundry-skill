import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "engifoundry-init"
SCRIPT_SH = SKILL / "scripts" / "init.sh"
SCRIPT_PS1 = SKILL / "scripts" / "init.ps1"
TEMPLATES = SKILL / "references" / "templates"
WORKSPACE_TEMPLATE = SKILL / "references" / "workspace.md"


class InitScriptsTests(unittest.TestCase):
    def run_sh(self, command, project, expected=0):
        result = subprocess.run(
            ["sh", str(SCRIPT_SH), command, "--project-root", str(project)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(result.returncode, expected, result.stderr or result.stdout)
        return result

    def test_runtime_uses_native_scripts_and_static_templates(self):
        self.assertTrue(SCRIPT_SH.exists())
        self.assertTrue(SCRIPT_PS1.exists())
        self.assertFalse((SKILL / "scripts" / "init.py").exists())
        self.assertIn("param(", SCRIPT_PS1.read_text())
        for name in [
            "engifoundry.config.json",
            "initialization.json",
            "executors.json",
            "workflows.json",
        ]:
            json.loads((TEMPLATES / name).read_text())

    def test_init_creates_and_checks_complete_scaffold(self):
        with tempfile.TemporaryDirectory(prefix="engi foundry ") as tmp:
            project = Path(tmp)

            result = self.run_sh("init", project)
            self.assertIn("status: ok", result.stdout)
            self.assertFalse((project / ".engifoundry.config.json").exists())
            self.assertFalse((project / ".engifoundry-packages").exists())
            self.assertEqual(
                {path.name for path in project.iterdir() if "engifoundry" in path.name},
                {"engifoundry.config.json", ".engifoundry"},
            )
            self.assertIn(".engifoundry/packages/", (project / ".gitignore").read_text().splitlines())
            self.assertEqual(
                (project / "engifoundry.config.json").read_text(),
                (TEMPLATES / "engifoundry.config.json").read_text(),
            )
            self.assertEqual(
                (project / ".engifoundry" / "workspace.md").read_text(),
                WORKSPACE_TEMPLATE.read_text(),
            )
            root_config = json.loads((project / "engifoundry.config.json").read_text())
            self.assertNotIn("routerSkill", root_config)
            self.assertEqual(root_config["initializationConfig"], ".engifoundry/initialization.json")
            self.assertNotIn("verificationConfig", root_config)
            self.assertNotIn("riskConfig", root_config)
            self.assertFalse((project / ".engifoundry" / "verification.json").exists())
            self.assertFalse((project / ".engifoundry" / "risk.json").exists())
            self.assertTrue((project / ".engifoundry" / "artifacts" / "verification").is_dir())
            initialization = json.loads((project / ".engifoundry" / "initialization.json").read_text())
            self.assertEqual(initialization["status"], "in_progress")
            self.assertEqual(initialization["currentStep"], "executor")

            result = self.run_sh("check", project)
            self.assertIn("status: ok", result.stdout)

    def test_init_preserves_existing_gitignore_and_appends_package_rule(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            gitignore = project / ".gitignore"
            gitignore.write_text("node_modules/")

            self.run_sh("init", project)

            lines = gitignore.read_text().splitlines()
            self.assertEqual(lines[0], "node_modules/")
            self.assertEqual(lines.count(".engifoundry/packages/"), 1)

    def test_init_refuses_to_overwrite_existing_scaffold(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            (project / "engifoundry.config.json").write_text("{}\n")

            result = self.run_sh("init", project, expected=1)
            self.assertIn("status: blocked", result.stdout)
            self.assertIn("path already exists", result.stderr)

    def test_check_reports_every_missing_required_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.run_sh("init", project)
            (project / ".engifoundry" / "workflows.json").unlink()
            (project / ".engifoundry" / "artifacts" / "reviews").rmdir()
            (project / ".gitignore").write_text("node_modules/\n")

            result = self.run_sh("check", project, expected=1)
            self.assertIn("status: failed", result.stdout)
            self.assertIn("workflows.json", result.stderr)
            self.assertIn("artifacts/reviews", result.stderr)
            self.assertIn("missing .gitignore rule", result.stderr)

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell Core is not installed")
    def test_powershell_init_and_check(self):
        with tempfile.TemporaryDirectory(prefix="engi foundry ") as tmp:
            for command in ("init", "check"):
                result = subprocess.run(
                    [
                        "pwsh",
                        "-NoProfile",
                        "-File",
                        str(SCRIPT_PS1),
                        "-Command",
                        command,
                        "-ProjectRoot",
                        tmp,
                    ],
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )
                self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
                self.assertIn("status: ok", result.stdout)


if __name__ == "__main__":
    unittest.main()
