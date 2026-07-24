import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INIT = ROOT / "skills" / "engifoundry-init"
SCRIPTS = INIT / "scripts"
CONFIGURE_SH = SCRIPTS / "configure.sh"
CONFIGURE_PS1 = SCRIPTS / "configure.ps1"


class ConfiguratorScriptsTests(unittest.TestCase):
    def test_init_skill_exposes_only_script_relay_and_custom_resolution(self):
        content = (INIT / "SKILL.md").read_text()
        self.assertIn("Configurator JSON is the question and state authority", content)
        self.assertIn("Submit the complete reply unchanged", content)
        self.assertIn("resolve-and-probe-cli", content)
        self.assertIn("A modification request always restarts the same complete four-question flow", content)
        for obsolete in ("executor.sh", "executor.ps1", "workflow.sh", "workflow.ps1", "state.sh", "state.ps1"):
            self.assertFalse((SCRIPTS / obsolete).exists())
            self.assertNotIn(obsolete, content)

    def init_project(self, project):
        result = subprocess.run(
            ["sh", str(SCRIPTS / "init.sh"), "init", "--project-root", str(project)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(result.returncode, 0, result.stderr or result.stdout)

    def fake_cli_env(self, bin_dir, *commands):
        for command in commands:
            path = bin_dir / command
            path.write_text(
                "#!/bin/sh\n"
                "if [ \"${1:-}\" = --version ]; then printf '%s 1.2.3\\n' \"$(basename \"$0\")\"; exit 0; fi\n"
                "printf '{\"message\":\"hello\"}\\n'\n"
            )
            path.chmod(0o755)
        env = os.environ.copy()
        env["PATH"] = f"{bin_dir}:/usr/bin:/bin"
        return env

    def run_configure(self, project, action="status", *args, env=None, expected=0):
        result = subprocess.run(
            [
                "sh",
                str(CONFIGURE_SH),
                action,
                "--project-root",
                str(project),
                "--current-cli",
                "codex",
                "--locale",
                "zh-CN",
                *args,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
        )
        self.assertEqual(result.returncode, expected, result.stderr or result.stdout)
        return json.loads(result.stdout)

    def test_four_question_flow_is_script_owned_and_single_choice(self):
        with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as bin_tmp:
            project = Path(tmp)
            self.init_project(project)
            env = self.fake_cli_env(Path(bin_tmp), "codex", "kimi", "cursor-agent")

            state = self.run_configure(project, env=env)
            self.assertEqual(state["question"]["id"], "executor.choice")
            self.assertEqual(state["question"]["kind"], "single-choice")
            self.assertEqual(
                [option["label"] for option in state["question"]["options"]],
                ["Codex", "Kimi", "Cursor", "自定义"],
            )
            self.assertFalse(any("默认" in option["label"] for option in state["question"]["options"]))

            invalid = self.run_configure(
                project, "answer", "--user-input", "1,2", env=env, expected=1
            )
            self.assertEqual(invalid["reason"], "multiple-not-allowed")
            self.assertEqual(self.run_configure(project, env=env)["question"]["id"], "executor.choice")

            state = self.run_configure(project, "answer", "--user-input", "4", env=env)
            self.assertEqual(state["question"]["id"], "executor.custom-description")
            self.assertEqual(state["question"]["kind"], "free-text")
            self.assertTrue(any("Codex 的 5.3 Spark 模型" in hint for hint in state["question"]["hints"]))

            state = self.run_configure(
                project,
                "answer",
                "--user-input",
                "用你自己的5.3 Spark",
                env=env,
            )
            self.assertEqual(state["status"], "agent-action-required")
            self.assertEqual(state["action"]["type"], "resolve-and-probe-cli")

            state = self.run_configure(
                project,
                "resolve",
                "--resolution-status",
                "confirmed",
                "--executor-id",
                "codex-cli",
                "--label",
                "GPT-5.3-Codex-Spark",
                "--command",
                "codex",
                "--model",
                "gpt-5.3-codex-spark",
                "--usage",
                "codex exec -C {workspace} --model gpt-5.3-codex-spark {prompt}",
                env=env,
            )
            self.assertEqual(state["question"]["id"], "reviewer.choice")
            labels = [option["label"] for option in state["question"]["options"]]
            self.assertIn("用你自己的5.3 Spark", labels)
            inherited = next(option for option in state["question"]["options"] if option["label"] == "用你自己的5.3 Spark")

            state = self.run_configure(
                project, "answer", "--user-input", str(inherited["displayNumber"]), env=env
            )
            self.assertEqual(state["question"]["id"], "workflow.automation")
            state = self.run_configure(project, "answer", "--user-input", "2", env=env)
            self.assertEqual(state["question"]["id"], "workflow.action-preference")
            state = self.run_configure(project, "answer", "--user-input", "2", env=env)
            self.assertEqual(state["status"], "complete")
            self.assertEqual(state["mode"], "initialize")

            value = json.loads((project / ".engifoundry" / "executors.json").read_text())
            self.assertEqual(value["executor"]["model"], "gpt-5.3-codex-spark")
            self.assertEqual(value["reviewer"]["originalDescription"], "用你自己的5.3 Spark")
            self.assertEqual(value["gate"]["executorUnavailable"]["action"], "ask-user")
            self.assertTrue((project / ".engifoundry" / "contracts" / "executors.schema.json").is_file())
            initialization = json.loads((project / ".engifoundry" / "initialization.json").read_text())
            self.assertEqual(initialization["status"], "complete")
            self.assertEqual(initialization["completedSteps"], [
                "executor", "reviewer", "automation", "action-preference"
            ])

    def test_unconfirmed_custom_cli_returns_to_parent_question(self):
        with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as bin_tmp:
            project = Path(tmp)
            self.init_project(project)
            env = self.fake_cli_env(Path(bin_tmp), "codex")
            state = self.run_configure(project, env=env)
            custom = state["question"]["options"][-1]["displayNumber"]
            self.run_configure(project, "answer", "--user-input", str(custom), env=env)
            self.run_configure(project, "answer", "--user-input", "不存在的 CLI", env=env)
            state = self.run_configure(
                project,
                "resolve",
                "--resolution-status",
                "unconfirmed",
                "--reason",
                "command-unavailable",
                env=env,
            )
            self.assertEqual(state["question"]["id"], "executor.choice")
            self.assertEqual(state["notice"]["level"], "warning")
            self.assertIn("无法确认可用", state["notice"]["message"])

    def test_modify_restarts_same_flow_and_overwrites_only_after_completion(self):
        with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as bin_tmp:
            project = Path(tmp)
            self.init_project(project)
            env = self.fake_cli_env(Path(bin_tmp), "codex", "kimi")

            # Complete an initial configuration with Codex for both roles.
            self.run_configure(project, env=env)
            self.run_configure(project, "answer", "--user-input", "1", env=env)
            self.run_configure(project, "answer", "--user-input", "1", env=env)
            self.run_configure(project, "answer", "--user-input", "2", env=env)
            self.run_configure(project, "answer", "--user-input", "2", env=env)
            original = (project / ".engifoundry" / "executors.json").read_text()
            initialization_before = (project / ".engifoundry" / "initialization.json").read_text()

            state = self.run_configure(project, "status", "--init-modify", env=env)
            self.assertEqual(state["mode"], "modify")
            self.assertEqual(state["question"]["id"], "executor.choice")
            self.assertIn("当前配置", state["question"]["context"])
            self.assertEqual((project / ".engifoundry" / "executors.json").read_text(), original)

            self.run_configure(project, "answer", "--user-input", "2", env=env)
            self.run_configure(project, "answer", "--user-input", "1", env=env)
            self.run_configure(project, "answer", "--user-input", "3", env=env)
            state = self.run_configure(project, "answer", "--user-input", "1", env=env)
            self.assertEqual(state["status"], "complete")
            self.assertEqual(state["mode"], "modify")
            value = json.loads((project / ".engifoundry" / "executors.json").read_text())
            self.assertEqual(value["executor"]["executorId"], "kimi-cli")
            self.assertEqual((project / ".engifoundry" / "initialization.json").read_text(), initialization_before)

    def test_custom_text_has_structural_validation(self):
        with tempfile.TemporaryDirectory() as tmp, tempfile.TemporaryDirectory() as bin_tmp:
            project = Path(tmp)
            self.init_project(project)
            env = self.fake_cli_env(Path(bin_tmp), "codex")
            state = self.run_configure(project, env=env)
            custom = state["question"]["options"][-1]["displayNumber"]
            self.run_configure(project, "answer", "--user-input", str(custom), env=env)
            invalid = self.run_configure(
                project, "answer", "--user-input", "   ", env=env, expected=1
            )
            self.assertEqual(invalid["reason"], "empty-custom-description")

    def test_hidden_probe_still_supports_pinned_models(self):
        with tempfile.TemporaryDirectory() as bin_tmp:
            bin_dir = Path(bin_tmp)
            env = self.fake_cli_env(bin_dir, "codex")
            arguments = bin_dir / "arguments"
            codex = bin_dir / "codex"
            codex.write_text(
                '#!/bin/sh\nif [ "${1:-}" = --version ]; then echo codex 1; exit 0; fi\n'
                'printf "%s\\n" "$*" > "$PROBE_ARGUMENTS"\nprintf \'{"message":"hello"}\\n\'\n'
            )
            codex.chmod(0o755)
            env["PROBE_ARGUMENTS"] = str(arguments)
            result = subprocess.run(
                [
                    "sh", str(SCRIPTS / "executor-probe.sh"),
                    "--executor", "codex-cli", "--command", "codex",
                    "--model", "gpt-5.3-codex-spark",
                ],
                text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env,
            )
            self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
            self.assertEqual(json.loads(result.stdout)["modelMode"], "pinned")
            self.assertIn("--model gpt-5.3-codex-spark", arguments.read_text())

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell Core is not installed")
    def test_powershell_configurator_exists_and_returns_same_protocol(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            result = subprocess.run(
                [
                    "pwsh", "-NoProfile", "-File", str(CONFIGURE_PS1),
                    "-Action", "status", "-ProjectRoot", str(project),
                    "-CurrentCli", "codex", "-Locale", "zh-CN",
                ],
                text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            )
            self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
            value = json.loads(result.stdout)
            self.assertEqual(value["question"]["kind"], "single-choice")

    def test_windows_configurator_is_windows_powershell_compatible(self):
        raw = CONFIGURE_PS1.read_bytes()
        content = raw.decode("utf-8-sig")
        self.assertTrue(raw.startswith(b"\xef\xbb\xbf"))
        self.assertIn("[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)", content)
        self.assertNotIn("ConvertFrom-Json -AsHashtable", content)
        self.assertIn("function ConvertTo-OrderedMap", content)
        self.assertIn("(Get-Process -Id $PID).Path", content)


if __name__ == "__main__":
    unittest.main()
