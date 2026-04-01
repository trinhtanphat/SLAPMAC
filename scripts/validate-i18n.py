#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
I18N_PATH = ROOT / "SlapMac-Extension" / "popup" / "i18n.json"

REQUIRED_LANGUAGE_COUNT = 20


def main() -> int:
    data = json.loads(I18N_PATH.read_text(encoding="utf-8"))

    options = data.get("languageOptions", [])
    translations = data.get("translations", {})

    if len(options) != REQUIRED_LANGUAGE_COUNT:
        print(f"::error::Expected {REQUIRED_LANGUAGE_COUNT} language options, found {len(options)}")
        return 1

    option_codes = [o.get("code") for o in options]
    if len(set(option_codes)) != len(option_codes):
        print("::error::Duplicate language code detected in languageOptions")
        return 1

    en = translations.get("en", {})
    if not en:
        print("::error::Missing translations.en")
        return 1

    required_keys = set(en.keys())
    missing_langs = [code for code in option_codes if code not in translations]
    if missing_langs:
        print(f"::error::Missing translation blocks for language codes: {', '.join(missing_langs)}")
        return 1

    for code, values in translations.items():
        if not isinstance(values, dict):
            print(f"::error::Translation block '{code}' must be an object")
            return 1

        missing = required_keys - set(values.keys())
        if missing:
            print(f"::error::Language '{code}' is missing keys: {', '.join(sorted(missing))}")
            return 1

        unknown = set(values.keys()) - required_keys
        if unknown:
            print(f"::error::Language '{code}' contains unknown keys: {', '.join(sorted(unknown))}")
            return 1

    print("✅ i18n validation passed (20 languages + full key coverage)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
