import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INIT_SCRIPTS = ROOT / "skills" / "engifoundry-init" / "scripts"
ORCH_SCRIPTS = ROOT / "skills" / "engifoundry-orch" / "scripts"


class OrchScriptsTests(unittest.TestCase):
    def init_project(self, project):
        result = subprocess.run(
            ["sh", str(INIT_SCRIPTS / "init.sh"), "init", "--project-root", str(project)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(result.returncode, 0, result.stderr or result.stdout)

    def run_sh(self, project, action, *args, expected=0):
        result = subprocess.run(
            [
                "sh",
                str(ORCH_SCRIPTS / "orch.sh"),
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

    def create_package(self, project, jobs=2):
        self.run_sh(project, "create-phase", "--kind", "mainline")
        return self.run_sh(
            project,
            "create-package",
            "--phase-id",
            "PHASE-001",
            "--job-count",
            str(jobs),
            "--title",
            "Foundation delivery",
        )

    def complete_semantics(self, project, package_id="PAK-001"):
        package = (
            project
            / ".engifoundry"
            / "packages"
            / "PHASE-001"
            / package_id
        )
        (package / "summary.md").write_text(
            "# Foundation delivery\n\nScope and acceptance are defined.\n"
        )
        package_config = package / "package.config.json"
        value = json.loads(package_config.read_text())
        value["acceptanceCriteria"] = ["All Jobs satisfy their acceptance criteria"]
        value["requiredArtifacts"] = ["records", "verification", "review"]
        value["closeoutRequirements"] = ["Final verification and delivery record"]
        package_config.write_text(json.dumps(value, indent=2) + "\n")

        for job_dir in sorted((package / "jobs").iterdir()):
            (job_dir / "job.md").write_text(
                f"# {job_dir.name}\n\nImplement the bounded step.\n"
            )
            job_config = job_dir / "job.config.json"
            job = json.loads(job_config.read_text())
            job["allowedAreas"] = ["src", "tests"]
            job["stopConditions"] = ["Scope conflict or non-runnable verification"]
            job["acceptanceCriteria"] = ["Bounded behavior is implemented"]
            job["reviewRequirements"] = ["Relevant automated tests pass"]
            job["requiredOutputs"] = ["record", "verification"]
            job_config.write_text(json.dumps(job, indent=2) + "\n")

    def test_allocates_phase_package_and_extension_ids_monotonically(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)

            self.assertEqual(self.run_sh(project, "create-phase")["phaseId"], "PHASE-001")
            self.assertEqual(self.run_sh(project, "create-phase")["phaseId"], "PHASE-002")
            extension = self.run_sh(
                project,
                "create-phase",
                "--kind",
                "extension",
                "--base-phase-id",
                "PHASE-001",
            )
            self.assertEqual(extension["phaseId"], "PHASE-001-EX01")

            first = self.run_sh(
                project,
                "create-package",
                "--phase-id",
                "PHASE-001",
                "--job-count",
                "1",
            )
            second = self.run_sh(
                project,
                "create-package",
                "--phase-id",
                "PHASE-001",
                "--job-count",
                "1",
            )
            self.assertEqual((first["packageId"], second["packageId"]), ("PAK-001", "PAK-002"))

            root = project / ".engifoundry" / "packages"
            index = json.loads((root / "phase.index.json").read_text())
            self.assertEqual(index["mainlineOrder"], ["PHASE-001", "PHASE-002"])
            self.assertEqual(index["nextMainlinePhaseId"], "PHASE-003")
            phase = json.loads((root / "PHASE-001" / "phase.config.json").read_text())
            self.assertEqual(phase["packages"], ["PAK-001", "PAK-002"])

    def test_allocation_supports_project_paths_with_spaces(self):
        with tempfile.TemporaryDirectory(prefix="engifoundry orch ") as tmp:
            project = Path(tmp)
            self.init_project(project)

            first = self.run_sh(project, "create-phase")
            second = self.run_sh(project, "create-phase")
            package = self.run_sh(
                project,
                "create-package",
                "--phase-id",
                first["phaseId"],
                "--job-count",
                "1",
            )

            self.assertEqual(first["phaseId"], "PHASE-001")
            self.assertEqual(second["phaseId"], "PHASE-002")
            self.assertEqual(package["packageId"], "PAK-001")

    def test_incomplete_skeleton_fails_structural_check(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            self.create_package(project)

            invalid = self.run_sh(
                project,
                "check",
                "--phase-id",
                "PHASE-001",
                "--package-id",
                "PAK-001",
                expected=1,
            )
            self.assertEqual(invalid["reason"], "package-check-failed")
            self.assertIn("incomplete-summary", invalid["details"])

    def test_review_state_is_not_a_script_interface(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            self.create_package(project)
            self.complete_semantics(project)

            checked = self.run_sh(
                project,
                "check",
                "--phase-id",
                "PHASE-001",
                "--package-id",
                "PAK-001",
            )
            self.assertEqual(checked["status"], "ok")
            for script in (ORCH_SCRIPTS / "orch.sh", ORCH_SCRIPTS / "orch.ps1"):
                content = script.read_text()
                self.assertNotIn("apply-review", content)
                self.assertNotIn("submit-review", content)
                self.assertNotIn("review-result", content.lower())

    def test_generated_contracts_do_not_select_executor(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            self.create_package(project, jobs=1)
            package = project / ".engifoundry" / "packages" / "PHASE-001" / "PAK-001"
            for config in (package / "package.config.json", package / "jobs" / "JOB-001" / "job.config.json"):
                value = json.loads(config.read_text())
                self.assertNotIn("executor", json.dumps(value).lower())
                self.assertNotIn("model", json.dumps(value).lower())

    def test_contract_defines_period_goal_and_step_levels(self):
        contract = (ORCH_SCRIPTS.parent / "references" / "contracts.md").read_text()
        self.assertIn("| `PHASE-*` | Engineering period", contract)
        self.assertIn("| `PAK-*` | One complete task goal", contract)
        self.assertIn("| `JOB-*` | One ordered implementation step", contract)

    def test_generated_package_has_verify_and_delivery_refs(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)
            self.create_package(project, jobs=1)

            package = json.loads(
                (
                    project
                    / ".engifoundry"
                    / "packages"
                    / "PHASE-001"
                    / "PAK-001"
                    / "package.config.json"
                ).read_text()
            )
            self.assertIsNone(package["execution"]["verificationRef"])
            self.assertIsNone(package["execution"]["deliveryRef"])

            job = json.loads(
                (
                    project
                    / ".engifoundry"
                    / "packages"
                    / "PHASE-001"
                    / "PAK-001"
                    / "jobs"
                    / "JOB-001"
                    / "job.config.json"
                ).read_text()
            )
            self.assertIsNone(job["reviewRef"])
            self.assertEqual(job["reworkFacts"], [])

    @unittest.skipUnless(shutil.which("pwsh"), "PowerShell Core is not installed")
    def test_powershell_allocates_and_checks(self):
        with tempfile.TemporaryDirectory() as tmp:
            project = Path(tmp)
            self.init_project(project)

            def run(action, *args, expected=0):
                result = subprocess.run(
                    [
                        "pwsh",
                        "-NoProfile",
                        "-File",
                        str(ORCH_SCRIPTS / "orch.ps1"),
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
                self.assertEqual(result.returncode, expected, result.stderr or result.stdout)
                return json.loads(result.stdout)

            self.assertEqual(run("create-phase")["phaseId"], "PHASE-001")
            package = run("create-package", "-PhaseId", "PHASE-001", "-JobCount", "1")
            self.assertEqual(package["packageId"], "PAK-001")
            invalid = run("check", "-PhaseId", "PHASE-001", "-PackageId", "PAK-001", expected=1)
            self.assertEqual(invalid["reason"], "package-check-failed")


if __name__ == "__main__":
    unittest.main()
