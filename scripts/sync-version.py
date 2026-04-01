#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION_FILE = ROOT / "VERSION"


def normalize_semver(raw: str) -> str:
    value = raw.strip()
    version = value[1:] if value.startswith("v") else value
    if not re.match(r"^\d+\.\d+\.\d+$", version):
        raise ValueError(f"Version must be X.Y.Z or vX.Y.Z, got: {raw}")
    return version


def resolve_version(cli_version: str | None, cli_tag: str | None) -> str:
    if cli_version and cli_tag:
        raise ValueError("Use only one of --version or --tag")

    if cli_tag:
        return normalize_semver(cli_tag)

    if cli_version:
        return normalize_semver(cli_version)

    if not VERSION_FILE.exists():
        raise FileNotFoundError(f"Missing VERSION file: {VERSION_FILE}")

    return normalize_semver(VERSION_FILE.read_text(encoding="utf-8").strip())


def write_version_file(version: str) -> None:
    # Keep VERSION normalized even when source is a tag.
    VERSION_FILE.write_text(version + "\n", encoding="utf-8")


def replace_regex(path: Path, pattern: str, replacement: str, label: str) -> None:
    original = path.read_text(encoding="utf-8")
    updated, count = re.subn(pattern, replacement, original)
    if count == 0:
        raise RuntimeError(f"Pattern not found for {label} in {path.relative_to(ROOT)}")

    if updated != original:
        path.write_text(updated, encoding="utf-8")
        print(f"Updated {label}: {path.relative_to(ROOT)}")
    else:
        print(f"No change for {label}: {path.relative_to(ROOT)}")


def sync(version: str) -> None:
    manifest_path = ROOT / "SlapMac-Extension" / "manifest.json"
    manifest_data = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest_data.get("version") != version:
        manifest_data["version"] = version
        manifest_path.write_text(json.dumps(manifest_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Updated Extension version: {manifest_path.relative_to(ROOT)}")
    else:
        print(f"No change for Extension version: {manifest_path.relative_to(ROOT)}")

    replace_regex(
        ROOT / "SlapMac-Android" / "app" / "build.gradle.kts",
        r'versionName\s*=\s*"[^"]+"',
        f'versionName = "{version}"',
        "Android versionName",
    )

    replace_regex(
        ROOT / "SlapMac-Windows" / "SlapMac.csproj",
        r"<Version>[^<]+</Version>",
        f"<Version>{version}</Version>",
        "Windows Version",
    )

    replace_regex(
        ROOT / "SlapMac-iOS" / "project.yml",
        r'MARKETING_VERSION:\s*"[^"]+"',
        f'MARKETING_VERSION: "{version}"',
        "iOS MARKETING_VERSION",
    )

    replace_regex(
        ROOT / "SlapMac" / "SlapMac.xcodeproj" / "project.pbxproj",
        r"MARKETING_VERSION = [^;]+;",
        f"MARKETING_VERSION = {version};",
        "macOS MARKETING_VERSION",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync app versions from VERSION, tag, or explicit version")
    parser.add_argument("--version", help="Semantic version (X.Y.Z or vX.Y.Z)")
    parser.add_argument("--tag", help="Git tag to use as source (vX.Y.Z)")
    args = parser.parse_args()

    try:
        version = resolve_version(args.version, args.tag)
        write_version_file(version)
        sync(version)
        source = "tag" if args.tag else ("--version" if args.version else "VERSION")
        print(f"Done. Synced all platform versions from {source}={version}")
        return 0
    except Exception as exc:
        print(f"ERROR: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
