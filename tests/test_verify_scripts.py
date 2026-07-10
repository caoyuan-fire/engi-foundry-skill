import json
import shutil
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "skills" / "engifoundry-init" / "scripts"


class VerifyScriptsTests(unittest.TestCase):
    def verify_sh(self, user_input, selection="multiple", source="1,2,3,4", expected=0):
        result = subprocess.run(
            [
                "sh",
                str(SCRIPTS / "verify.sh"),
                "--source",
                source,
                "--selection",
                selection,
                "--user-input",
                user_input,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(result.returncode, expected, result.stderr or result.stdout)
        return json.loads(result.stdout)

    def test_normalizes_supported_whitespace_and_commas(self):
        result = self.verify_sh("  1 ，   3  ")
        self.assertEqual(result["status"], "valid")
        self.assertEqual(result["normalizedInput"], "1,3")
        self.assertEqual(result["selectedIds"], [1, 3])

    def test_single_selection(self):
        result = self.verify_sh(" 2 ", selection="single")
        self.assertEqual(result["selectedIds"], [2])

    def test_rejects_compatibility_outside_contract(self):
        for value in ["一,2", "one", "first", "1、2", "1;2", "1；2", "1 2"]:
            with self.subTest(value=value):
                result = self.verify_sh(value, expected=1)
                self.assertEqual(result["reason"], "invalid-format")

    def test_rejects_unknown_duplicate_and_multiple_for_single(self):
        self.assertEqual(self.verify_sh("1,7", expected=1)["reason"], "unknown-option")
        self.assertEqual(self.verify_sh("1,1", expected=1)["reason"], "duplicate-option")
        self.assertEqual(
            self.verify_sh("1,2", selection="single", expected=1)["reason"],
            "multiple-not-allowed",
        )

    def test_rejects_invalid_source_as_script_error(self):
        result = self.verify_sh("1", source="1234", expected=2)
        self.assertEqual(result["reason"], "invalid-source-sequence")

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell Core is not installed")
    def test_powershell_matches_shell_contract(self):
        result = subprocess.run(
            [
                "pwsh",
                "-NoProfile",
                "-File",
                str(SCRIPTS / "verify.ps1"),
                "-Source",
                "1,2,3,4",
                "-Selection",
                "multiple",
                "-UserInput",
                " 1 ， 3 ",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(result.returncode, 0, result.stderr or result.stdout)
        self.assertEqual(json.loads(result.stdout)["selectedIds"], [1, 3])


if __name__ == "__main__":
    unittest.main()
