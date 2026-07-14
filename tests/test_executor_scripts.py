import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "skills" / "engifoundry-init" / "scripts"


class ExecutorScriptsTests(unittest.TestCase):
    def run_sh(self, project, action, *args, expected=0, env=None):
        if env is None:
            env = os.environ.copy()
            env["PATH"] = "/usr/bin:/bin"
        result = subprocess.run(
            [
                "sh",
                str(SCRIPTS / "executor.sh"),
                action,
                "--project-root",
                str(project),
                *args,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
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

    def test_multiselect_then_preferred_executor_builds_ordered_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)

            state = self.run_sh(project, "begin", "--native-subagent", "true")
            self.assertEqual(
                [option["executorId"] for option in state["options"]],
                ["native-subagent", "direct"],
            )

            state = self.run_sh(project, "select", "--user-input", " 2 ， 1 ")
            self.assertEqual(state["phase"], "prefer")
            self.assertEqual(state["selectedExecutors"], ["direct", "native-subagent"])

            repeated_begin = self.run_sh(project, "begin")
            self.assertEqual(repeated_begin["phase"], "prefer")
            self.assertEqual(repeated_begin["selectedExecutors"], ["direct", "native-subagent"])

            state = self.run_sh(project, "prefer", "--user-input", " 2 ")
            self.assertEqual(state["executorOrder"], ["native-subagent", "direct"])

            value = self.run_sh(project, "commit")
            self.assertTrue(value["configured"])
            self.assertEqual(value["executorOrder"], ["native-subagent", "direct"])
            self.assertEqual(
                list(value["executors"]),
                ["direct", "native-subagent"],
            )

    def test_single_selection_skips_preference(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            self.run_sh(project, "begin")

            state = self.run_sh(project, "select", "--user-input", "1")
            self.assertEqual(state, {"status": "ready", "executorOrder": ["direct"]})

    def test_invalid_selection_does_not_advance(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            self.run_sh(project, "begin", "--native-subagent", "true")

            invalid = self.run_sh(project, "select", "--user-input", "1;2", expected=1)
            self.assertEqual(invalid["reason"], "invalid-format")
            state = self.run_sh(project, "status")
            self.assertEqual(state["phase"], "select")

    def test_discovers_only_cli_commands_present_on_path(self):
        with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as bin_tmp:
            project = Path(tmp)
            self.init_project(project)
            bin_dir = Path(bin_tmp)
            for command in ("codex", "kimi"):
                path = bin_dir / command
                path.write_text("#!/bin/sh\nexit 0\n")
                path.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{bin_dir}:/usr/bin:/bin"

            state = self.run_sh(project, "begin", env=env)
            self.assertEqual(
                [option["executorId"] for option in state["options"]],
                ["codex-cli", "kimi-cli", "direct"],
            )

    def test_initialization_does_not_ask_for_cli_model(self):
        with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as bin_tmp:
            project = Path(tmp)
            self.init_project(project)
            bin_dir = Path(bin_tmp)
            codex = bin_dir / "codex"
            codex.write_text("#!/bin/sh\nexit 0\n")
            codex.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{bin_dir}:/usr/bin:/bin"

            state = self.run_sh(project, "begin", env=env)
            self.assertEqual(state["options"][0]["executorId"], "codex-cli")
            state = self.run_sh(project, "select", "--user-input", "1", env=env)
            self.assertEqual(state, {"status": "ready", "executorOrder": ["codex-cli"]})
            value = self.run_sh(project, "commit", env=env)
            self.assertNotIn("model", value["executors"]["codex-cli"])

    def test_hidden_probe_supports_default_model(self):
        with tempfile.TemporaryDirectory() as bin_tmp:
            bin_dir = Path(bin_tmp)
            codex = bin_dir / "codex"
            codex.write_text('#!/bin/sh\nprintf \'{"message":"hello"}\\n\'\n')
            codex.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{bin_dir}:/usr/bin:/bin"

            result = subprocess.run(
                [
                    "sh",
                    str(SCRIPTS / "executor-probe.sh"),
                    "--executor",
                    "codex-cli",
                    "--command",
                    "codex",
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env,
            )
            self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
            self.assertEqual(json.loads(result.stdout)["modelMode"], "cli-default")

    def test_hidden_probe_passes_pinned_model_explicitly(self):
        with tempfile.TemporaryDirectory() as bin_tmp:
            bin_dir = Path(bin_tmp)
            arguments = bin_dir / "arguments"
            codex = bin_dir / "codex"
            codex.write_text(
                '#!/bin/sh\nprintf "%s\\n" "$*" > "$PROBE_ARGUMENTS"\nprintf \'{"message":"hello"}\\n\'\n'
            )
            codex.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{bin_dir}:/usr/bin:/bin"
            env["PROBE_ARGUMENTS"] = str(arguments)

            result = subprocess.run(
                [
                    "sh",
                    str(SCRIPTS / "executor-probe.sh"),
                    "--executor",
                    "codex-cli",
                    "--command",
                    "codex",
                    "--model",
                    "gpt-5.3-codex-spark",
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env,
            )
            self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
            self.assertEqual(json.loads(result.stdout)["modelMode"], "pinned")
            self.assertIn("--model gpt-5.3-codex-spark", arguments.read_text())

    def test_commit_does_not_probe_cli_executor(self):
        with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as bin_tmp:
            project = Path(tmp)
            self.init_project(project)
            bin_dir = Path(bin_tmp)
            invocations = bin_dir / "invocations"
            codex = bin_dir / "codex"
            codex.write_text(
                '#!/bin/sh\nprintf "%s\\n" "$*" >> "$INVOCATIONS"\nprintf \'{"message":"hello"}\\n\'\n'
            )
            codex.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{bin_dir}:/usr/bin:/bin"
            env["INVOCATIONS"] = str(invocations)

            state = self.run_sh(project, "begin", env=env)
            self.assertEqual(state["options"][0]["executorId"], "codex-cli")
            self.run_sh(project, "select", "--user-input", "1", env=env)
            value = self.run_sh(project, "commit", env=env)
            self.assertFalse(invocations.exists())
            self.assertNotIn("usage", value["executors"]["codex-cli"])

    def test_hidden_probe_reports_cli_failure(self):
        with tempfile.TemporaryDirectory() as bin_tmp:
            bin_dir = Path(bin_tmp)
            codex = bin_dir / "codex"
            codex.write_text("#!/bin/sh\nexit 1\n")
            codex.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{bin_dir}:/usr/bin:/bin"

            result = subprocess.run(
                [
                    "sh",
                    str(SCRIPTS / "executor-probe.sh"),
                    "--executor",
                    "codex-cli",
                    "--command",
                    "codex",
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env,
            )
            self.assertEqual(result.returncode, 1, result.stderr or result.stdout)
            self.assertEqual(json.loads(result.stdout)["reason"], "executor-probe-failed")

    def test_cancel_preserves_existing_executor_config(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            config = project / ".engifoundry" / "executors.json"
            original = config.read_text()

            self.run_sh(project, "begin", "--native-subagent", "true")
            state = self.run_sh(project, "cancel")
            self.assertEqual(state["status"], "cancelled")
            self.assertEqual(config.read_text(), original)

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell Core is not installed")
    def test_powershell_selection_and_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)

            def run(action, *args):
                result = subprocess.run(
                    [
                        "pwsh",
                        "-NoProfile",
                        "-File",
                        str(SCRIPTS / "executor.ps1"),
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

            begin = run("begin", "-NativeSubagent")
            ids = {option["executorId"]: option["optionId"] for option in begin["options"]}
            state = run(
                "select",
                "-UserInput",
                f'{ids["direct"]},{ids["native-subagent"]}',
            )
            self.assertEqual(state["phase"], "prefer")
            self.assertEqual(state["selectedExecutors"], ["direct", "native-subagent"])
            state = run("begin")
            self.assertEqual(state["phase"], "prefer")
            self.assertEqual(state["selectedExecutors"], ["direct", "native-subagent"])
            state = run("prefer", "-UserInput", "2")
            self.assertEqual(state["executorOrder"], ["native-subagent", "direct"])
            value = run("commit")
            self.assertTrue(value["configured"])


if __name__ == "__main__":
    unittest.main()
