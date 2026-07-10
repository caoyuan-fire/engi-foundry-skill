import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "skills" / "engifoundry-init" / "scripts"


class WorkflowScriptsTests(unittest.TestCase):
    def run_sh(self, project, action, *args, expected=0):
        result = subprocess.run(
            [
                "sh",
                str(SCRIPTS / "workflow.sh"),
                action,
                "--project-root",
                str(project),
                *args,
            ],
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

    def test_options_are_fixed_and_package_approval_is_recommended(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)

            state = self.run_sh(project, "begin")
            self.assertEqual(
                [option["automationMode"] for option in state["options"]],
                ["job-approval", "package-approval", "full-auto"],
            )
            self.assertTrue(state["options"][1]["recommended"])

            state = self.run_sh(project, "select", "--user-input", "2")
            self.assertEqual(state["phase"], "action-preference")
            self.assertEqual(
                [option["actionPreference"] for option in state["options"]],
                ["package-first", "balanced", "direct-first"],
            )
            self.assertTrue(state["options"][1]["recommended"])

    def test_each_mode_can_be_selected_and_committed(self):
        expected_modes = {
            "1": "job-approval",
            "2": "package-approval",
            "3": "full-auto",
        }
        for selection, expected_mode in expected_modes.items():
            with self.subTest(selection=selection), tempfile.TemporaryDirectory() as tmp:
                project = Path(tmp)
                self.init_project(project)
                self.run_sh(project, "begin")

                state = self.run_sh(project, "select", "--user-input", f" {selection} ")
                self.assertEqual(state["phase"], "action-preference")
                state = self.run_sh(project, "select", "--user-input", "2")
                self.assertEqual(
                    state,
                    {
                        "status": "ready",
                        "automationMode": expected_mode,
                        "actionPreference": "balanced",
                    },
                )
                value = self.run_sh(project, "commit")
                self.assertEqual(
                    value,
                    {
                        "schemaVersion": 1,
                        "configured": True,
                        "actionPreference": "balanced",
                        "automationMode": expected_mode,
                    },
                )

    def test_each_action_preference_can_be_selected(self):
        expected_preferences = {
            "1": "package-first",
            "2": "balanced",
            "3": "direct-first",
        }
        for selection, expected_preference in expected_preferences.items():
            with self.subTest(selection=selection), tempfile.TemporaryDirectory() as tmp:
                project = Path(tmp)
                self.init_project(project)
                self.run_sh(project, "begin")
                self.run_sh(project, "select", "--user-input", "2")

                state = self.run_sh(project, "select", "--user-input", selection)
                self.assertEqual(state["actionPreference"], expected_preference)
                self.assertEqual(self.run_sh(project, "commit")["actionPreference"], expected_preference)

    def test_rejects_multiple_selection_without_advancing(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            self.run_sh(project, "begin")

            invalid = self.run_sh(project, "select", "--user-input", "1,2", expected=1)
            self.assertEqual(invalid["reason"], "multiple-not-allowed")
            self.assertEqual(self.run_sh(project, "status")["phase"], "automation")

    def test_cancel_preserves_existing_workflow_config(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            config = project / ".engifoundry" / "workflows.json"
            original = config.read_text()

            self.run_sh(project, "begin")
            self.assertEqual(self.run_sh(project, "cancel")["status"], "cancelled")
            self.assertEqual(config.read_text(), original)

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell Core is not installed")
    def test_powershell_workflow_selection(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)

            def run(action, *args):
                result = subprocess.run(
                    [
                        "pwsh",
                        "-NoProfile",
                        "-File",
                        str(SCRIPTS / "workflow.ps1"),
                        "-Action",
                        action,
                        "-ProjectRoot",
                        str(project),
                        *args,
                    ],
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )
                self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
                return json.loads(result.stdout)

            state = run("begin")
            self.assertEqual(state["options"][1]["automationMode"], "package-approval")
            state = run("select", "-UserInput", "2")
            self.assertEqual(state["phase"], "action-preference")
            state = run("select", "-UserInput", "3")
            self.assertEqual(state["actionPreference"], "direct-first")
            value = run("commit")
            self.assertTrue(value["configured"])
            self.assertEqual(value["automationMode"], "package-approval")
            self.assertEqual(value["actionPreference"], "direct-first")


if __name__ == "__main__":
    unittest.main()
