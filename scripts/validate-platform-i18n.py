#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_LANGUAGE_COUNT = 20

I18N_FILES = [
    ROOT / "SlapMac-Extension" / "popup" / "i18n.json",
    ROOT / "SlapMac-Android" / "app" / "src" / "main" / "assets" / "i18n.json",
    ROOT / "SlapMac-Linux" / "i18n.json",
    ROOT / "SlapMac-Windows" / "Resources" / "i18n.json",
    ROOT / "SlapMac-iOS" / "SlapMac" / "i18n.json",
    ROOT / "SlapMac" / "SlapMac" / "i18n.json",
]


def validate_file(path: Path) -> list[str]:
    errors: list[str] = []
    if not path.exists():
        return [f"Missing i18n file: {path.relative_to(ROOT)}"]

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return [f"Invalid JSON in {path.relative_to(ROOT)}: {exc}"]

    options = data.get("languageOptions")
    translations = data.get("translations")

    if not isinstance(options, list):
        errors.append(f"{path.relative_to(ROOT)}: languageOptions must be an array")
        return errors

    if len(options) != REQUIRED_LANGUAGE_COUNT:
        errors.append(
            f"{path.relative_to(ROOT)}: expected {REQUIRED_LANGUAGE_COUNT} languageOptions, found {len(options)}"
        )

    codes = []
    for opt in options:
        if not isinstance(opt, dict):
            errors.append(f"{path.relative_to(ROOT)}: language option must be object")
            continue
        code = opt.get("code")
        label = opt.get("label")
        flag = opt.get("flag")
        if not isinstance(code, str) or not code:
            errors.append(f"{path.relative_to(ROOT)}: each language option needs non-empty string code")
        else:
            codes.append(code)
        if not isinstance(label, str) or not label:
            errors.append(f"{path.relative_to(ROOT)}: each language option needs non-empty string label")
        if not isinstance(flag, str) or len(flag) != 2:
            errors.append(f"{path.relative_to(ROOT)}: each language option needs 2-char country flag code")

    if len(set(codes)) != len(codes):
        errors.append(f"{path.relative_to(ROOT)}: duplicate language codes in languageOptions")

    if not isinstance(translations, dict):
        errors.append(f"{path.relative_to(ROOT)}: translations must be an object")
        return errors

    en = translations.get("en")
    if not isinstance(en, dict) or not en:
        errors.append(f"{path.relative_to(ROOT)}: missing translations.en block")
        return errors

    required_keys = set(en.keys())
    for code in codes:
        if code not in translations:
            errors.append(f"{path.relative_to(ROOT)}: missing translation block for code '{code}'")
            continue
        block = translations[code]
        if not isinstance(block, dict):
            errors.append(f"{path.relative_to(ROOT)}: translation block '{code}' must be object")
            continue

        unknown_keys = set(block.keys()) - required_keys
        if unknown_keys:
            errors.append(
                f"{path.relative_to(ROOT)}: language '{code}' has unknown keys: {', '.join(sorted(unknown_keys))}"
            )

    return errors


def main() -> int:
    all_errors: list[str] = []
    for file_path in I18N_FILES:
        all_errors.extend(validate_file(file_path))

    if all_errors:
        for err in all_errors:
            print(f"::error::{err}")
        return 1

    print("✅ Platform i18n validation passed for all localization resource files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
