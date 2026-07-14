import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INIT_SKILL = ROOT / "skills" / "engifoundry-init" / "SKILL.md"
SCRIPTS = ROOT / "skills" / "engifoundry-init" / "scripts"


class InitStateScriptsTests(unittest.TestCase):
    def test_init_contract_keeps_each_turn_in_the_active_setup_phase(self):
        content = INIT_SKILL.read_text()
        self.assertIn("its current step and setup phase own the conversation", content)
        self.assertIn("read initialization state, then the matching setup `status`", content)
        self.assertIn("Start a setup only when its status is `idle`", content)
        self.assertIn("does not suspend or end an active Init interaction", content)
        self.assertIn("Treat it only as invalid input for the current prompt", content)
        self.assertIn("Run Executor setup `status`; at `idle`, run `begin` once", content)
        self.assertIn("Run Workflow setup `status`; at `idle`, run `begin` once", content)

    def test_init_question_presentation_is_quiet_and_unambiguous(self):
        content = INIT_SKILL.read_text()
        self.assertIn("user-visible output contains only the current localized question", content)
        self.assertIn("run validation and state actions silently", content)
        self.assertIn("Never announce an intention, repeat the selected input", content)
        self.assertIn("`2` for a single selection or `1,2` for multiple selections", content)
        self.assertIn("$engifoundry modify config", content)
        self.assertIn("what you want changed and how", content)
        self.assertIn("`[!NOTE]` callout", content)

    def test_init_executor_contract_requires_agent_owned_real_exploration(self):
        content = INIT_SKILL.read_text()
        self.assertIn(
            "After `commit`, explore the best invocation for each selected CLI Executor yourself",
            content,
        )
        self.assertIn(
            "Run a real, bounded, non-interactive task with the candidate invocation",
            content,
        )
        self.assertIn("Write the verified template as `usage`", content)
        self.assertIn("Scripts are optional helpers", content)
        self.assertNotIn("probe each selected Executor with `executor-probe`", content)

    def test_init_completion_uses_separate_colored_success_line(self):
        content = INIT_SKILL.read_text()
        self.assertIn("emit a blank line followed by one standalone localized green/success callout", content)
        self.assertIn('"🎉 Congratulations, EngiFoundry is ready to help you work better."', content)
        self.assertIn("The `🎉` prefix is required in every language", content)
        self.assertIn("`[!TIP]` callout", content)
        self.assertIn("Never place this sentence inline with the summary", content)

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
