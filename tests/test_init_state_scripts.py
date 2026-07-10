import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "skills" / "engifoundry-init" / "scripts"


class InitStateScriptsTests(unittest.TestCase):
    def run_sh(self, script, *args, expected=0):
        result = subprocess.run(
            ["sh", str(SCRIPTS / script), *args],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(result.returncode, expected, result.stderr or result.stdout)
        return json.loads(result.stdout)

    def init_project(self, project):
        result = subprocess.run(
            ["sh", str(SCRIPTS / "init.sh"), "init", "--project-root", str(project)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(result.returncode, 0, result.stderr or result.stdout)

    def configure(self, project, name):
        path = project / ".engifoundry" / f"{name}.json"
        value = json.loads(path.read_text())
        value["configured"] = True
        path.write_text(json.dumps(value, indent=2) + "\n")

    def test_state_advances_only_in_fixed_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            args = ("--project-root", str(project))

            state = self.run_sh("state.sh", "status", *args)
            self.assertEqual((state["status"], state["currentStep"]), ("in_progress", "executor"))
            denied = self.run_sh("state.sh", "advance", *args, expected=1)
            self.assertEqual(denied["reason"], "executor-not-configured")

            self.configure(project, "executors")
            state = self.run_sh("state.sh", "advance", *args)
            self.assertEqual(state["currentStep"], "workflow")

            self.configure(project, "workflows")
            reviews = project / ".engifoundry" / "artifacts" / "reviews"
            reviews.rmdir()
            denied = self.run_sh("state.sh", "advance", *args, expected=1)
            self.assertEqual(denied["reason"], "final-validation-failed")
            reviews.mkdir()

            state = self.run_sh("state.sh", "advance", *args)
            self.assertEqual(state["status"], "complete")
            self.assertIsNone(state["currentStep"])
            self.assertEqual(state["completedSteps"], ["executor", "workflow"])
            denied = self.run_sh("state.sh", "advance", *args, expected=1)
            self.assertEqual(denied["reason"], "terminal-state")

    def test_cancel_preserves_actual_completed_steps(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            args = ("--project-root", str(project))
            self.configure(project, "executors")
            self.run_sh("state.sh", "advance", *args)

            state = self.run_sh("state.sh", "cancel", *args)
            self.assertEqual(state["status"], "cancelled")
            self.assertEqual(state["completedSteps"], ["executor"])

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell Core is not installed")
    def test_powershell_state_machine(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            result = subprocess.run(
                [
                    "pwsh",
                    "-NoProfile",
                    "-File",
                    str(SCRIPTS / "state.ps1"),
                    "-Action",
                    "status",
                    "-ProjectRoot",
                    str(project),
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
            self.assertEqual(json.loads(result.stdout)["currentStep"], "executor")


if __name__ == "__main__":
    unittest.main()
