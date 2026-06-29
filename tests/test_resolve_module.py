import json
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


def load_resolver():
    path = Path(__file__).resolve().parents[1] / "skills/engifoundry/scripts/resolve_module.py"
    spec = importlib.util.spec_from_file_location("engifoundry_resolve_module", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ResolveModuleTests(unittest.TestCase):
    def write_manifest(self, root, local_path="skills/engifoundry/references/example.md", required=True):
        manifest = {
            "remoteSource": {
                "type": "github",
                "repo": "example-org/engi-foundry-skill",
                "defaultRef": "v1.2.3",
            },
            "modules": {
                "example": {
                    "required": required,
                    "localPath": local_path,
                    "requiredFor": ["test"],
                }
            },
        }
        manifest_path = root / "engifoundry.manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        return manifest_path

    def test_resolves_existing_local_module_first(self):
        resolve_module = load_resolver().resolve_module

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            local_file = root / "skills/engifoundry/references/example.md"
            local_file.parent.mkdir(parents=True)
            local_file.write_text("# Example\n", encoding="utf-8")
            manifest_path = self.write_manifest(root)

            result = resolve_module("example", manifest_path=manifest_path, cache_dir=root / "cache")

            self.assertEqual(result.status, "local")
            self.assertEqual(result.path, local_file)

    def test_refuses_download_without_explicit_confirmation(self):
        resolver = load_resolver()

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest_path = self.write_manifest(root)

            with self.assertRaises(resolver.DownloadConfirmationRequired):
                resolver.resolve_module("example", manifest_path=manifest_path, cache_dir=root / "cache")

    def test_builds_github_raw_url_from_manifest(self):
        build_github_raw_url = load_resolver().build_github_raw_url

        url = build_github_raw_url(
            repo="example-org/engi-foundry-skill",
            ref="v1.2.3",
            path="skills/engifoundry/references/example.md",
        )

        self.assertEqual(
            url,
            "https://raw.githubusercontent.com/example-org/engi-foundry-skill/v1.2.3/skills/engifoundry/references/example.md",
        )

    def test_downloads_to_cache_and_writes_lock_when_confirmed(self):
        resolve_module = load_resolver().resolve_module

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest_path = self.write_manifest(root)
            cache_dir = root / "cache"
            downloaded = []

            def fake_downloader(url, destination):
                downloaded.append((url, destination))
                destination.write_text("# Downloaded\n", encoding="utf-8")

            result = resolve_module(
                "example",
                manifest_path=manifest_path,
                cache_dir=cache_dir,
                allow_download=True,
                downloader=fake_downloader,
            )

            self.assertEqual(result.status, "downloaded")
            self.assertTrue(result.path.exists())
            self.assertEqual(result.path.read_text(encoding="utf-8"), "# Downloaded\n")
            self.assertEqual(len(downloaded), 1)

            lock = json.loads((cache_dir / "engifoundry.lock.json").read_text(encoding="utf-8"))
            self.assertEqual(lock["modules"]["example"]["source"], downloaded[0][0])
            self.assertEqual(lock["modules"]["example"]["path"], str(result.path))

    def test_uses_cached_module_without_downloading_again(self):
        resolve_module = load_resolver().resolve_module

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest_path = self.write_manifest(root)
            cached = root / "cache/example-org__engi-foundry-skill/v1.2.3/skills/engifoundry/references/example.md"
            cached.parent.mkdir(parents=True)
            cached.write_text("# Cached\n", encoding="utf-8")

            def fail_downloader(url, destination):
                raise AssertionError("downloader should not be called")

            result = resolve_module(
                "example",
                manifest_path=manifest_path,
                cache_dir=root / "cache",
                allow_download=True,
                downloader=fail_downloader,
            )

            self.assertEqual(result.status, "cached")
            self.assertEqual(result.path, cached)


if __name__ == "__main__":
    unittest.main()
