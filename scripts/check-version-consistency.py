#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION_FILE = ROOT / "VERSION"


def read_version() -> str:
    if not VERSION_FILE.exists():
        raise FileNotFoundError("Missing VERSION file")

    raw = VERSION_FILE.read_text(encoding="utf-8").strip()
    version = raw[1:] if raw.startswith("v") else raw
    if not re.match(r"^\d+\.\d+\.\d+$", version):
        raise ValueError(f"VERSION must be X.Y.Z or vX.Y.Z, got: {raw}")
    return version


def extract_android_version() -> str:
    text = (ROOT / "SlapMac-Android" / "app" / "build.gradle.kts").read_text(encoding="utf-8")
    match = re.search(r'versionName\s*=\s*"([^"]+)"', text)
    return match.group(1) if match else ""


def extract_windows_version() -> str:
    text = (ROOT / "SlapMac-Windows" / "SlapMac.csproj").read_text(encoding="utf-8")
    match = re.search(r"<Version>([^<]+)</Version>", text)
    return match.group(1).strip() if match else ""


def extract_ios_version() -> str:
    text = (ROOT / "SlapMac-iOS" / "project.yml").read_text(encoding="utf-8")
    match = re.search(r'MARKETING_VERSION:\s*"([^"]+)"', text)
    return match.group(1).strip() if match else ""


def extract_mac_versions() -> list[str]:
    text = (ROOT / "SlapMac" / "SlapMac.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")
    return [v.strip() for v in re.findall(r"MARKETING_VERSION = ([^;]+);", text)]


def extract_extension_version() -> str:
    data = json.loads((ROOT / "SlapMac-Extension" / "manifest.json").read_text(encoding="utf-8"))
    return data.get("version", "")


def main() -> int:
    parser = argparse.ArgumentParser(description="Check VERSION consistency across platforms")
    parser.add_argument("--tag", help="Optional release tag, e.g. v1.0.14")
    args = parser.parse_args()

    try:
        version = read_version()
    except Exception as exc:
        print(f"::error:: {exc}")
        return 1

    expected_version = version
    if args.tag:
        tag = args.tag.strip()
        if not re.match(r"^v\d+\.\d+\.\d+$", tag):
            print(f"::error::Tag must be semantic version (vX.Y.Z). Got: {tag}")
            return 1
        expected_version = tag[1:]

    failed = False

    checks = {
        "VERSION file": version,
        "Extension manifest": extract_extension_version(),
        "Android versionName": extract_android_version(),
        "Windows csproj Version": extract_windows_version(),
        "iOS MARKETING_VERSION": extract_ios_version(),
    }

    for name, value in checks.items():
        if value != expected_version:
            print(f"::error::{name}={value} does not match expected version {expected_version}")
            failed = True

    mac_versions = extract_mac_versions()
    for idx, value in enumerate(mac_versions):
        if value != expected_version:
            print(f"::error::macOS MARKETING_VERSION[{idx}]={value} does not match expected version {expected_version}")
            failed = True

    if args.tag:
        if version != expected_version:
            print(f"::error::VERSION {version} does not match pushed tag {args.tag}")
            failed = True

    if failed:
        print("::error::Version mismatch detected. Run: python scripts/sync-version.py")
        return 1

    print(f"OK: all platform versions are consistent with {expected_version}")
    if args.tag:
        print(f"OK: tag {args.tag} matches VERSION")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
