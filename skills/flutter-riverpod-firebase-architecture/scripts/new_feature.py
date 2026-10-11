#!/usr/bin/env python3
"""Scaffold a feature-first Riverpod feature from the skill's templates.

Usage:
  python3 new_feature.py --root <flutter-app-root> --feature lesson_notes --entity LessonNote [--force]

Creates lib/features/<feature>/{data,domain,presentation}/... with names
substituted. Never overwrites existing files unless --force is passed.
Afterwards: add the l10n keys it prints, then `dart run build_runner build -d`.
"""
import argparse
import re
import sys
from pathlib import Path

TEMPLATES = Path(__file__).resolve().parent.parent / "templates" / "feature"


def snake(s: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "_", s).lower()


def pascal(s: str) -> str:
    return "".join(p[:1].upper() + p[1:] for p in s.split("_") if p)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True, help="Flutter app root (contains pubspec.yaml)")
    ap.add_argument("--feature", required=True, help="snake_case feature folder, e.g. lesson_notes")
    ap.add_argument("--entity", required=True, help="PascalCase entity, e.g. LessonNote")
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()

    root = Path(a.root)
    if not (root / "pubspec.yaml").exists():
        print(f"error: {root} has no pubspec.yaml", file=sys.stderr)
        return 2
    if not re.fullmatch(r"[a-z][a-z0-9_]*", a.feature):
        print("error: --feature must be snake_case", file=sys.stderr)
        return 2
    if not re.fullmatch(r"[A-Z][A-Za-z0-9]*", a.entity):
        print("error: --entity must be PascalCase", file=sys.stderr)
        return 2

    entity_snake = snake(a.entity)
    camel = a.entity[0].lower() + a.entity[1:]
    subs = [
        ("__entityCamel__", camel),
        ("__Feature__", pascal(a.feature)),
        ("__feature__", a.feature),
        ("__Entity__", a.entity),
        ("__entity__", entity_snake),
    ]

    def apply(text: str) -> str:
        for k, v in subs:
            text = text.replace(k, v)
        return text

    out_root = root / "lib" / "features" / a.feature
    written, skipped = [], []
    for src in sorted(TEMPLATES.rglob("*.dart")):
        rel = apply(str(src.relative_to(TEMPLATES)))
        dst = out_root / rel
        if dst.exists() and not a.force:
            skipped.append(dst)
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(apply(src.read_text()))
        written.append(dst)

    for p in written:
        print(f"wrote   {p.relative_to(root)}")
    for p in skipped:
        print(f"skipped {p.relative_to(root)} (exists; use --force)")
    print("\nAdd to lib/l10n/app_en.arb (and every other locale):")
    print(f'  "{camel}Title": "...",\n  "{camel}Empty": "...",')
    print("Shared keys used: errGeneric, actionDelete.")
    print("Then: flutter gen-l10n && dart run build_runner build -d")
    return 0


if __name__ == "__main__":
    sys.exit(main())
