import json
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "engifoundry.manifest.json"
ENTRY_UI = ROOT / "skills" / "engifoundry" / "agents" / "openai.yaml"


class PublicationContractTests(unittest.TestCase):
    def test_main_entry_has_human_readable_codex_ui_metadata(self):
        content = ENTRY_UI.read_text()
        self.assertIn('display_name: "EngiFoundry"', content)
        self.assertIn('short_description: "Start and route structured engineering work"', content)
        self.assertIn("$engifoundry", content)

    def test_runtime_manifest_points_only_to_current_skills(self):
        value = json.loads(MANIFEST.read_text())
        paths = [value["entrySkill"], value["routerSkill"]]
        paths += value["nodeSkills"] + value["supportingSkills"]
        self.assertEqual(len(paths), len(set(paths)))
        for path in paths:
            self.assertTrue((ROOT / path / "SKILL.md").is_file(), path)
        serialized = json.dumps(value)
        self.assertEqual(value["version"], "0.2.2")
        for stale in ("engifoundry-gate", "resolve_module", "check_version", "contract-operating-model"):
            self.assertNotIn(stale, serialized)

    def test_plugin_manifests_point_to_current_skill_root(self):
        value = json.loads(MANIFEST.read_text())
        for relative in value["pluginManifests"].values():
            manifest = ROOT / relative
            self.assertTrue(manifest.is_file(), relative)
            plugin = json.loads(manifest.read_text())
            self.assertEqual(plugin["skills"], "./skills/")
            self.assertEqual(plugin["version"], "0.2.2")

    def test_readmes_do_not_publish_legacy_runtime(self):
        for relative in ("README.md", "zh/README.md", "examples/README.md"):
            content = (ROOT / relative).read_text()
            self.assertNotIn("$engifoundry-gate", content)
            self.assertNotIn("skills/engifoundry/VERSION", content)
            self.assertNotIn("skills/engifoundry/references/", content)

    def test_readmes_publish_installation_and_update_guidance(self):
        english = (ROOT / "README.md").read_text()
        chinese = (ROOT / "zh/README.md").read_text()

        self.assertIn("中文说明见 [zh/README.md](zh/README.md)", english)
        self.assertIn("English documentation: [../README.md](../README.md)", chinese)
        self.assertIn("## Updating", english)
        self.assertIn("## 更新", chinese)
        for content in (english, chinese):
            self.assertIn("codex plugin marketplace upgrade engi-foundry-skill", content)
            self.assertIn("codex plugin add engifoundry-bundle@engi-foundry-skill", content)
            self.assertIn("codex plugin marketplace add caoyuan-fire/engi-foundry-skill", content)
            self.assertNotIn(
                "codex plugin marketplace add https://github.com/caoyuan-fire/engi-foundry-skill",
                content,
            )
            self.assertIn("### Skills-Only", content)
        self.assertIn("complete `skills/`", english)
        self.assertIn("完整的 `skills/`", chinese)

    def test_session_hook_emits_entry_context(self):
        result = subprocess.run(
            ["bash", str(ROOT / "hooks" / "session-start")],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        context = output.get("additionalContext") or output.get("additional_context")
        self.assertIsNotNone(context)
        self.assertIn("<ENGIFOUNDRY_ENTRY>", context)
        self.assertIn("engifoundry.config.json", context)


if __name__ == "__main__":
    unittest.main()
