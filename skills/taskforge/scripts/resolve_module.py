#!/usr/bin/env python3
"""Resolve TaskForge modules from local files, cache, or GitHub."""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional


class ModuleResolutionError(Exception):
    pass


class DownloadConfirmationRequired(ModuleResolutionError):
    pass


@dataclass(frozen=True)
class ResolutionResult:
    module: str
    status: str
    path: Path
    source: Optional[str] = None


def load_manifest(manifest_path: Path) -> dict:
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def build_github_raw_url(repo: str, ref: str, path: str) -> str:
    clean_path = path.lstrip("/")
    return f"https://raw.githubusercontent.com/{repo}/{ref}/{clean_path}"


def default_cache_dir() -> Path:
    base = os.environ.get("XDG_CACHE_HOME")
    if base:
        return Path(base) / "taskforge" / "modules"
    return Path.home() / ".cache" / "taskforge" / "modules"


def cache_path_for(cache_dir: Path, repo: str, ref: str, module_path: str) -> Path:
    repo_key = repo.replace("/", "__")
    return cache_dir / repo_key / ref / module_path


def download_url(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url, timeout=30) as response:
        destination.write_bytes(response.read())


def write_lock(cache_dir: Path, module_name: str, result: ResolutionResult, ref: str) -> None:
    lock_path = cache_dir / "taskforge.lock.json"
    if lock_path.exists():
        lock = json.loads(lock_path.read_text(encoding="utf-8"))
    else:
        lock = {"schemaVersion": 1, "modules": {}}

    lock.setdefault("modules", {})[module_name] = {
        "status": result.status,
        "path": str(result.path),
        "source": result.source,
        "ref": ref,
    }
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    lock_path.write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def resolve_module(
    module_name: str,
    *,
    manifest_path: Path,
    cache_dir: Optional[Path] = None,
    ref: Optional[str] = None,
    allow_download: bool = False,
    downloader: Callable[[str, Path], None] = download_url,
) -> ResolutionResult:
    manifest_path = Path(manifest_path).expanduser()
    manifest = load_manifest(manifest_path)
    modules = manifest.get("modules", {})
    if module_name not in modules:
        raise ModuleResolutionError(f"Unknown TaskForge module: {module_name}")

    module = modules[module_name]
    module_path = module["localPath"]
    local_path = manifest_path.parent / module_path
    if local_path.exists():
        return ResolutionResult(module=module_name, status="local", path=local_path)

    remote = manifest.get("remoteSource", {})
    if remote.get("type") != "github":
        raise ModuleResolutionError("Only GitHub remoteSource is supported")

    repo = remote["repo"]
    selected_ref = ref or remote.get("defaultRef", "main")
    cache_root = cache_dir or default_cache_dir()
    cached_path = cache_path_for(cache_root, repo, selected_ref, module_path)
    if cached_path.exists():
        return ResolutionResult(module=module_name, status="cached", path=cached_path)

    url = build_github_raw_url(repo=repo, ref=selected_ref, path=module_path)
    if not allow_download:
        raise DownloadConfirmationRequired(
            f"Module '{module_name}' is missing locally and in cache. "
            f"Confirm before downloading from {url}."
        )

    cached_path.parent.mkdir(parents=True, exist_ok=True)
    downloader(url, cached_path)
    result = ResolutionResult(module=module_name, status="downloaded", path=cached_path, source=url)
    write_lock(cache_root, module_name, result, selected_ref)
    return result


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Resolve a TaskForge module.")
    parser.add_argument("module", help="Module key from taskforge.manifest.json")
    parser.add_argument("--manifest", default="taskforge.manifest.json", help="Path to taskforge.manifest.json")
    parser.add_argument("--cache-dir", help="Cache directory outside any artifact root")
    parser.add_argument("--ref", help="Git ref to use instead of manifest remoteSource.defaultRef")
    parser.add_argument("--yes", action="store_true", help="Allow downloading missing modules")
    parser.add_argument("--json", action="store_true", help="Print machine-readable result")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        result = resolve_module(
            args.module,
            manifest_path=Path(args.manifest),
            cache_dir=Path(args.cache_dir).expanduser() if args.cache_dir else None,
            ref=args.ref,
            allow_download=args.yes,
        )
    except DownloadConfirmationRequired as exc:
        print(str(exc), file=sys.stderr)
        return 3
    except ModuleResolutionError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    if args.json:
        print(
            json.dumps(
                {
                    "module": result.module,
                    "status": result.status,
                    "path": str(result.path),
                    "source": result.source,
                },
                sort_keys=True,
            )
        )
    else:
        print(result.path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
