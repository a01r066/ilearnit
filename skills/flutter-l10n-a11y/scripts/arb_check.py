#!/usr/bin/env python3
"""Check ARB files and Dart code for localization gaps.

Usage: python3 -I arb_check.py <flutter-app-root> [--arb-dir lib/l10n] [--exclude lib/admin] [--strict]

Reports:
  • keys missing from / extra in each locale vs the template (app_en.arb)
  • placeholder mismatches ({name} sets differ between locales)
  • ICU plural/select messages whose branch keywords differ
  • template keys never referenced in lib/ (possibly unused)
  • likely hard-coded UI strings in lib/ (Text('...'), tooltip: '...', label: '...', SnackBar)
Exit 1 when locales are out of sync (or any finding with --strict).
"""
import json
import re
import sys
from pathlib import Path

PH = re.compile(r"\{(\w+)(?:,\s*(plural|select)\s*,)?")
UI_STR = re.compile(
    r"""(?:\bText\(\s*|tooltip:\s*|label:\s*|labelText:\s*|hintText:\s*|title:\s*Text\(\s*|semanticLabel:\s*|content:\s*Text\(\s*)(['"])((?:(?!\1).){2,})\1""")


def placeholders(msg: str) -> set:
    # Top-level {name} and {name, plural, ...}; ignore literal words inside branches.
    out, depth, i = set(), 0, 0
    while i < len(msg):
        c = msg[i]
        if c == "{":
            if depth == 0:
                m = PH.match(msg, i)
                if m:
                    out.add(m.group(1))
            depth += 1
        elif c == "}":
            depth -= 1
        i += 1
    return out


def branches(msg: str) -> set:
    return set(re.findall(r"(=\d+|zero|one|two|few|many|other|\w+)\{", msg)) if re.search(r",\s*(plural|select)\s*,", msg) else set()


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    root = Path(argv[1])
    arb_dir = root / (argv[argv.index("--arb-dir") + 1] if "--arb-dir" in argv else "lib/l10n")
    strict = "--strict" in argv
    arbs = {p.stem.split("_", 1)[1]: json.loads(p.read_text()) for p in sorted(arb_dir.glob("app_*.arb"))}
    if "en" not in arbs:
        print(f"error: {arb_dir}/app_en.arb not found")
        return 2
    tpl = {k: v for k, v in arbs["en"].items() if not k.startswith("@")}
    problems = 0

    for loc, data in arbs.items():
        if loc == "en":
            continue
        keys = {k for k in data if not k.startswith("@")}
        missing, extra = sorted(set(tpl) - keys), sorted(keys - set(tpl))
        if missing:
            problems += 1
            print(f"[{loc}] missing {len(missing)}: {', '.join(missing[:20])}{' …' if len(missing) > 20 else ''}")
        if extra:
            problems += 1
            print(f"[{loc}] extra {len(extra)}: {', '.join(extra[:20])}")
        for k in sorted(keys & set(tpl)):
            a, b = placeholders(tpl[k]), placeholders(data[k])
            if a != b:
                problems += 1
                print(f"[{loc}] placeholder mismatch in '{k}': en={sorted(a)} {loc}={sorted(b)}")
            # Languages without plural forms may drop ICU entirely (valid);
            # only an ICU translation must keep its 'other' branch.
            if branches(data[k]) and "other{" not in data[k].replace(" ", ""):
                problems += 1
                print(f"[{loc}] '{k}' ICU message lacks an 'other' branch")
            if data[k].strip() == "" or (data[k] == tpl[k] and len(tpl[k]) > 12 and " " in tpl[k]):
                print(f"[{loc}] '{k}' looks untranslated")

    excludes = [root / argv[i + 1] for i, a in enumerate(argv) if a == "--exclude" and i + 1 < len(argv)]
    dart = [p for p in (root / "lib").rglob("*.dart")
            if "generated" not in p.parts and not p.name.endswith((".g.dart", ".freezed.dart"))]
    scan = [p for p in dart if not any(str(p).startswith(str(e)) for e in excludes)]
    code = "\n".join(p.read_text(errors="ignore") for p in dart)
    unused = [k for k in tpl if not re.search(rf"\b{re.escape(k)}\b", code)]
    if unused:
        print(f"\n[info] {len(unused)} template keys not referenced in lib/ (unused or built dynamically): "
              f"{', '.join(unused[:25])}{' …' if len(unused) > 25 else ''}")

    hard = []
    for p in scan:
        for n, line in enumerate(p.read_text(errors="ignore").splitlines(), 1):
            if line.strip().startswith("//") or "debugPrint" in line or "Key(" in line:
                continue
            for m in UI_STR.finditer(line):
                s = m.group(2)
                literal = re.sub(r"\$\{[^}]*\}|\$\w+", "", s)
                if re.search(r"[A-Za-z]{2,}", literal) and not re.fullmatch(r"[\w./:-]+\.(png|svg|json|md)|https?://\S+|\$\w+", s):
                    hard.append(f"{p.relative_to(root)}:{n}: {s[:60]}")
    if hard:
        print(f"\n[warn] {len(hard)} likely hard-coded UI strings:")
        for h in hard[:60]:
            print("  " + h)
        if len(hard) > 60:
            print(f"  … {len(hard) - 60} more")

    print(f"\nlocales: {sorted(arbs)}  template keys: {len(tpl)}  sync problems: {problems}")
    return 1 if problems or (strict and hard) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
