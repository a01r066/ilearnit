#!/usr/bin/env python3
"""Heuristic lint for firestore.rules / storage.rules.

Usage: python3 -I rules_lint.py firestore.rules [storage.rules ...]

Flags common privilege bugs. It is a regex-level scan — a clean result
does NOT prove the rules are safe; use it to direct a careful read and
emulator tests. Exit code 1 when HIGH findings exist.
"""
import re
import sys
from pathlib import Path

SERVER_HINTS = ("purchase", "subscription", "entitle", "transaction", "_iap", "intent", "payout", "ledger")


def blocks(text):
    """Yield (match_path, body, start_line) for every `match` block."""
    for m in re.finditer(r"match\s+(/\S+)\s+\{", text):
        depth, i = 1, m.end()
        while i < len(text) and depth:
            depth += {"{": 1, "}": -1}.get(text[i], 0)
            i += 1
        yield m.group(1), text[m.end():i - 1], text.count("\n", 0, m.start()) + 1


def own_body(body):
    """Body minus nested match blocks (rules that apply at this level)."""
    out, depth, i = [], 0, 0
    while i < len(body):
        nm = re.match(r"match\s+/\S+\s+\{", body[i:])
        if depth == 0 and nm:
            depth = 1
            i += nm.end()
            continue
        if depth:
            depth += {"{": 1, "}": -1}.get(body[i], 0)
        else:
            out.append(body[i])
        i += 1
    return "".join(out)


def lint(path):
    text = Path(path).read_text()
    text_nc = re.sub(r"//[^\n]*", "", text)
    is_storage = "firebase.storage" in text_nc
    findings = []

    def add(sev, line, msg):
        findings.append((sev, line, msg))

    for mpath, body, line in blocks(text_nc):
        own = own_body(body)
        allows = re.findall(r"allow\s+([a-z, ]+):\s*if\s+([^;]+);", own)
        for ops, cond in allows:
            c = " ".join(cond.split())
            writes = any(o.strip() in ("write", "create", "update", "delete") for o in ops.split(","))
            if c == "true" and writes:
                add("HIGH", line, f"{mpath}: '{ops.strip()}' allowed for everyone (if true)")
            if re.fullmatch(r"request\.auth\s*!=\s*null|isSignedIn\(\)", c) and writes:
                add("HIGH", line, f"{mpath}: any signed-in user may {ops.strip()} — scope to owner/role")
            if writes and any(h in mpath.lower() for h in SERVER_HINTS) and c != "false" and not re.fullmatch(r"isAdmin\(\)", c):
                add("HIGH", line, f"{mpath}: looks server-owned but allows client {ops.strip()}")
            if is_storage and c == "true" and "read" in ops and re.search(r"private|paid|media|content|lecture", mpath, re.I):
                add("HIGH", line, f"{mpath}: public read on what looks like paid/private content")

        if not is_storage and re.search(r"\{\w+=\*\*\}", mpath) and re.search(r"allow\s+[a-z, ]*(write|create|update)[a-z, ]*:\s*if\s+(?!false\s*;)", own):
            add("MEDIUM", line, f"{mpath}: recursive wildcard with writes — also matches sibling server-owned subcollections (rules are OR-ed)")

        if not is_storage and re.fullmatch(r"/users/\{\w+\}", mpath):
            create = re.search(r"allow\s+[a-z, ]*create[a-z, ]*:\s*if\s+([^;]+);", own)
            if create and "role" not in create.group(1):
                add("HIGH", line, "/users create rule does not pin 'role' — self-promotion to admin possible")
            upd = re.findall(r"allow\s+[a-z, ]*update[a-z, ]*:\s*if\s+([^;]+);", own)
            if upd and not any("affectedKeys" in u or "isAdmin" in u for u in upd):
                add("HIGH", line, "/users owner update does not restrict changed keys (role/subscription)")

        if not is_storage and "list" in own and "status" not in own and re.search(r"allow\s+[a-z, ]*(list|read)[a-z, ]*:\s*if\s+true", own):
            add("INFO", line, f"{mpath}: world-readable list — fine for public catalogues; drafts need a status filter")

    if is_storage and not re.search(r"match\s+/\{\w+=\*\*\}\s*\{\s*allow\s+read,\s*write:\s*if\s+false", text_nc):
        add("INFO", 0, "storage: no explicit default-deny catch-all (implicit deny still applies)")
    return findings


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    worst = 0
    for p in argv[1:]:
        fs = lint(p)
        print(f"== {p}: {len(fs)} finding(s)")
        for sev, line, msg in fs:
            print(f"  [{sev}] line {line}: {msg}")
            worst = max(worst, {"HIGH": 2, "MEDIUM": 1}.get(sev, 0))
    return 1 if worst == 2 else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
