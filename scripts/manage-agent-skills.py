#!/usr/bin/env python3
"""Install and activate Gildra's pinned Codex skill catalog safely."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys


SHA_RE = re.compile(r"^[0-9a-f]{40}$")
NAME_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
FRONTMATTER_RE = re.compile(r"^---\s*\n(?P<body>.*?)\n---\s*\n", re.DOTALL)
MARKER = ".gildra-source.json"
STATE = ".gildra-managed.json"


def fail(message: str) -> "NoReturn":
    raise SystemExit(f"ERROR: {message}")


def expanded(path: str) -> Path:
    return Path(os.path.expanduser(path)).resolve()


def load_manifest(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read manifest {path}: {exc}")
    if data.get("schema_version") != 1:
        fail("unsupported manifest schema_version")
    return data


def validate_manifest(data: dict) -> dict[str, dict]:
    names: dict[str, dict] = {}
    repos: set[tuple[str, str]] = set()
    for source in data.get("sources", []):
        repo = source.get("repo", "")
        ref = source.get("ref", "")
        if repo.count("/") != 1 or not SHA_RE.fullmatch(ref):
            fail(f"invalid pinned source: {repo}@{ref}")
        repos.add((repo, ref))
        for skill in source.get("skills", []):
            name = skill.get("name", "")
            raw_path = skill.get("path", "")
            path = PurePosixPath(raw_path)
            if not NAME_RE.fullmatch(name):
                fail(f"invalid skill name: {name!r}")
            if name in names:
                fail(f"duplicate skill name: {name}")
            if path.is_absolute() or ".." in path.parts or not raw_path:
                fail(f"unsafe skill path for {name}: {raw_path!r}")
            profiles = skill.get("profiles", [])
            if not profiles or any(not NAME_RE.fullmatch(p) for p in profiles):
                fail(f"invalid profiles for {name}")
            names[name] = {"repo": repo, "ref": ref, **skill}
    if not names:
        fail("manifest contains no skills")
    default = data.get("default_profile")
    if default not in {profile for item in names.values() for profile in item["profiles"]}:
        fail(f"default profile does not exist: {default}")
    for section in ("deferred_sources", "deferred_project_tools"):
        for source in data.get(section, []):
            if source.get("repo", "").count("/") != 1 or not SHA_RE.fullmatch(source.get("ref", "")):
                fail(f"invalid deferred pin in {section}")
    return names


def validate_skill_dir(skill_dir: Path, expected: dict, require_marker: bool) -> None:
    if skill_dir.is_symlink():
        fail(f"catalog entry must be a directory, not a symlink: {skill_dir}")
    skill_file = skill_dir / "SKILL.md"
    if not skill_file.is_file():
        fail(f"missing SKILL.md: {skill_dir}")
    text = skill_file.read_text(encoding="utf-8", errors="strict")
    match = FRONTMATTER_RE.match(text)
    if not match or not re.search(r"^name:\s*\S+", match.group("body"), re.MULTILINE):
        fail(f"SKILL.md lacks frontmatter name: {skill_dir}")
    if not re.search(r"^description:\s*\S+", match.group("body"), re.MULTILINE):
        fail(f"SKILL.md lacks frontmatter description: {skill_dir}")
    root = skill_dir.resolve()
    for child in skill_dir.rglob("*"):
        if child.is_symlink() and root not in child.resolve().parents:
            fail(f"symlink escapes catalog entry: {child}")
    marker_path = skill_dir / MARKER
    if require_marker:
        if not marker_path.is_file():
            fail(f"missing source marker: {skill_dir}")
        marker = json.loads(marker_path.read_text(encoding="utf-8"))
        wanted = {key: expected[key] for key in ("name", "repo", "ref", "path")}
        if marker != wanted:
            fail(f"source marker mismatch: {skill_dir}")


def install_catalog(data: dict, skills: dict[str, dict], installer: Path, catalog: Path) -> None:
    if not installer.is_file():
        fail(f"official Codex skill installer not found: {installer}")
    catalog.mkdir(parents=True, exist_ok=True)
    for source in data["sources"]:
        missing = [item for item in source["skills"] if not (catalog / item["name"]).exists()]
        for item in source["skills"]:
            existing = catalog / item["name"]
            if existing.exists():
                validate_skill_dir(existing, skills[item["name"]], require_marker=True)
        if not missing:
            continue
        command = [
            sys.executable,
            str(installer),
            "--repo",
            source["repo"],
            "--ref",
            source["ref"],
            "--dest",
            str(catalog),
            "--method",
            "download",
            "--path",
            *[item["path"] for item in missing],
        ]
        print(f"Installing {len(missing)} skill(s) from {source['repo']}@{source['ref']}")
        subprocess.run(command, check=True)
        for item in missing:
            skill_dir = catalog / Path(item["path"]).name
            expected_dir = catalog / item["name"]
            if skill_dir != expected_dir:
                if expected_dir.exists():
                    fail(f"catalog name collision: {expected_dir}")
                skill_dir.rename(expected_dir)
            validate_skill_dir(expected_dir, skills[item["name"]], require_marker=False)
            marker = {key: skills[item["name"]][key] for key in ("name", "repo", "ref", "path")}
            (expected_dir / MARKER).write_text(json.dumps(marker, indent=2) + "\n", encoding="utf-8")


def activate_profile(profile: str, skills: dict[str, dict], catalog: Path, active: Path) -> None:
    selected = sorted(name for name, item in skills.items() if profile in item["profiles"])
    if not selected:
        fail(f"profile has no skills: {profile}")
    active.mkdir(parents=True, exist_ok=True)
    state_path = active / STATE
    old_state = {"managed": []}
    if state_path.exists():
        old_state = json.loads(state_path.read_text(encoding="utf-8"))
    for name in old_state.get("managed", []):
        link = active / name
        if link.is_symlink():
            target = link.resolve()
            if target == catalog / name and name not in selected:
                link.unlink()
        elif link.exists() and name not in selected:
            fail(f"refusing to remove non-symlink managed path: {link}")
    for name in selected:
        target = catalog / name
        validate_skill_dir(target, skills[name], require_marker=True)
        link = active / name
        if link.is_symlink():
            if link.resolve() != target:
                fail(f"active skill points outside managed catalog: {link}")
        elif link.exists():
            fail(f"unmanaged active skill collision: {link}")
        else:
            link.symlink_to(target, target_is_directory=True)
    state_path.write_text(
        json.dumps({"profile": profile, "managed": selected}, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Activated profile {profile}: {len(selected)} skill(s)")


def check_catalog(skills: dict[str, dict], catalog: Path, profile: str | None) -> None:
    selected = skills.items() if profile is None else (
        (name, item) for name, item in skills.items() if profile in item["profiles"]
    )
    count = 0
    for name, item in selected:
        validate_skill_dir(catalog / name, item, require_marker=True)
        count += 1
    print(f"Verified {count} catalog skill(s)")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--installer", type=Path)
    parser.add_argument("--catalog")
    parser.add_argument("--active")
    parser.add_argument("--install-catalog", action="store_true")
    parser.add_argument("--activate-profile")
    parser.add_argument("--check-catalog", action="store_true")
    parser.add_argument("--check-manifest", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    data = load_manifest(args.manifest.resolve())
    skills = validate_manifest(data)
    print(f"Manifest valid: {len(skills)} installable skill(s)")
    if args.check_manifest and not (args.install_catalog or args.activate_profile or args.check_catalog):
        return
    catalog = expanded(args.catalog or data["catalog_root"])
    active = expanded(args.active or data["active_root"])
    if args.install_catalog:
        if args.installer is None:
            fail("--installer is required with --install-catalog")
        install_catalog(data, skills, args.installer.resolve(), catalog)
    if args.check_catalog:
        check_catalog(skills, catalog, args.activate_profile)
    if args.activate_profile:
        activate_profile(args.activate_profile, skills, catalog, active)


if __name__ == "__main__":
    main()
