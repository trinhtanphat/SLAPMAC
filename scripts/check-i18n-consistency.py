#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "SlapMac-Extension" / "popup" / "i18n.json"
TARGETS = [
    ROOT / "SlapMac-Android" / "app" / "src" / "main" / "assets" / "i18n.json",
    ROOT / "SlapMac-Linux" / "i18n.json",
    ROOT / "SlapMac-Windows" / "Resources" / "i18n.json",
    ROOT / "SlapMac-iOS" / "SlapMac" / "i18n.json",
    ROOT / "SlapMac" / "SlapMac" / "i18n.json",
]


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    if not SOURCE.exists():
        print(f"::error::Missing source i18n file: {SOURCE.relative_to(ROOT)}")
        return 1

    source_data = load_json(SOURCE)
    failed = False

    for target in TARGETS:
        if not target.exists():
            print(f"::error::Missing i18n target file: {target.relative_to(ROOT)}")
            failed = True
            continue

        target_data = load_json(target)
        if target_data != source_data:
            print(f"::error::i18n mismatch: {target.relative_to(ROOT)} differs from {SOURCE.relative_to(ROOT)}")
            failed = True

    if failed:
        print("::error::Run: python scripts/sync-i18n.py")
        return 1

    print("✅ All platform i18n files are consistent with source")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
