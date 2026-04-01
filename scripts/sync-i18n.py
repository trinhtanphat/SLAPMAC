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


def normalize_json(text: str) -> str:
    data = json.loads(text)
    return json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def main() -> int:
    if not SOURCE.exists():
        print(f"ERROR: Missing source i18n file: {SOURCE}")
        return 1

    source_text = SOURCE.read_text(encoding="utf-8")
    normalized_source = normalize_json(source_text)

    # Re-write source in normalized form for deterministic diffs.
    SOURCE.write_text(normalized_source, encoding="utf-8")

    for target in TARGETS:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(normalized_source, encoding="utf-8")
        print(f"Synced: {target.relative_to(ROOT)}")

    print("Done: i18n synced from source to all platforms")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
