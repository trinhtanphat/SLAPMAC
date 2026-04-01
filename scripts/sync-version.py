#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION_FILE = ROOT / "VERSION"


def read_version() -> str:
    if not VERSION_FILE.exists():
        raise FileNotFoundError(f"Missing VERSION file: {VERSION_FILE}")

    raw = VERSION_FILE.read_text(encoding="utf-8").strip()
    version = raw[1:] if raw.startswith("v") else raw
    if not re.match(r"^\d+\.\d+\.\d+$", version):
        raise ValueError(f"VERSION must be X.Y.Z or vX.Y.Z, got: {raw}")

    # Normalize VERSION file to plain semantic version.
    VERSION_FILE.write_text(version + "\n", encoding="utf-8")
    return version


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
    try:
        version = read_version()
        sync(version)
        print(f"Done. Synced all platform versions from VERSION={version}")
        return 0
    except Exception as exc:
        print(f"ERROR: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
