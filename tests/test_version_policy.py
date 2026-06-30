import json
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "skills" / "engifoundry" / "scripts"


class VersionPolicyTests(unittest.TestCase):
    def test_manifest_version_matches_installable_version_file(self):
        manifest = json.loads((ROOT / "engifoundry.manifest.json").read_text(encoding="utf-8"))
        version = (ROOT / "skills" / "engifoundry" / "VERSION").read_text(encoding="utf-8").strip()

        self.assertRegex(version, r"^\d+\.\d+\.\d+$")
        self.assertEqual(manifest["version"], version)

    def test_shell_check_version_reports_only_newer_remote(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            local = root / "VERSION"
            remote = root / "REMOTE_VERSION"
            local.write_text("0.1.0\n", encoding="utf-8")

            remote.write_text("0.1.0\n", encoding="utf-8")
            same = subprocess.run(
                [
                    "sh",
                    str(SCRIPTS / "check_version.sh"),
                    "--local-version-file",
                    str(local),
                    "--remote-version-url",
                    remote.as_uri(),
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            self.assertEqual(same.returncode, 0, same.stderr)
            self.assertEqual(same.stdout.strip(), "")

            remote.write_text("0.2.0\n", encoding="utf-8")
            newer = subprocess.run(
                [
                    "sh",
                    str(SCRIPTS / "check_version.sh"),
                    "--local-version-file",
                    str(local),
                    "--remote-version-url",
                    remote.as_uri(),
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            self.assertEqual(newer.returncode, 0, newer.stderr)
            self.assertIn("EngiFoundry update available: local 0.1.0, latest 0.2.0", newer.stdout)


if __name__ == "__main__":
    unittest.main()
