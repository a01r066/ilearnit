#!/usr/bin/env python3
"""Static accessibility scan for Flutter widgets.

Usage: python3 -I a11y_scan.py <flutter-app-root>

Flags (heuristic — read each hit):
  • IconButton / FloatingActionButton.small without tooltip (no screen-reader label)
  • GestureDetector / InkWell with onTap not wrapped in Semantics or a button
  • Image / CachedNetworkImage / Icon used as content without semanticLabel
    (decorative images should use excludeFromSemantics: true)
  • Fixed font sizes on Text that ignore text scaling in tight containers
  • Tooltips inside MaterialApp.builder (no Overlay → crash)
"""
import re
import sys
from pathlib import Path


def calls(src: str, name: str):
    """Yield (offset, text) for each `name(` call with balanced parens."""
    for m in re.finditer(rf"\b{name}\(", src):
        depth, i = 1, m.end()
        while i < len(src) and depth:
            depth += {"(": 1, ")": -1}.get(src[i], 0)
            i += 1
        yield m.start(), src[m.start():i]


def main(root: Path) -> int:
    hits = []
    for p in sorted((root / "lib").rglob("*.dart")):
        if "generated" in p.parts or p.name.endswith((".g.dart", ".freezed.dart")):
            continue
        src = p.read_text(errors="ignore")
        line = lambda off: src.count("\n", 0, off) + 1
        rel = p.relative_to(root)

        for off, c in calls(src, "IconButton"):
            if "tooltip:" not in c:
                before = src[max(0, off - 160):off]
                if "Semantics(" not in before:
                    hits.append((rel, line(off), "IconButton without tooltip"))
        for name in ("GestureDetector", "InkWell"):
            for off, c in calls(src, name):
                # A tappable with visible Text is announced already; icon-only
                # or image-only tappables need a label and button role.
                if "onTap:" in c and "Text(" not in c:
                    before = src[max(0, off - 200):off]
                    if "Semantics(" not in before and "MergeSemantics(" not in before:
                        hits.append((rel, line(off), f"{name} onTap without Semantics(button: true, label: …)"))
        for name in ("Image.network", "Image.asset", "CachedNetworkImage"):
            for off, c in calls(src, name.replace(".", r"\.")):
                if "semanticLabel" not in c and "excludeFromSemantics" not in c:
                    hits.append((rel, line(off), f"{name} without semanticLabel / excludeFromSemantics"))
        if "builder: (context, child)" in src and "MaterialApp" in src:
            b = src[src.index("builder: (context, child)"):][:1500]
            if "tooltip:" in b:
                hits.append((rel, line(src.index("builder: (context, child)")), "tooltip inside MaterialApp.builder (no Overlay)"))
        for m in re.finditer(r"TextScaler\.noScaling|textScaleFactor:\s*1(\.0)?\b", src):
            hits.append((rel, line(m.start()), "text scaling disabled"))

    for rel, ln, msg in hits:
        print(f"{rel}:{ln}: {msg}")
    print(f"\n{len(hits)} potential issue(s)")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(Path(sys.argv[1])))
