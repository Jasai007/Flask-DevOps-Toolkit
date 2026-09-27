#!/usr/bin/env python3
"""Check that every relative Markdown link in this repo resolves to a real file.

Broken doc links are the most common rot in hand-written documentation, so
this runs as part of `bash scripts/validate.sh` (step 7/7).

Usage:
    python3 scripts/check_links.py      # exit 0 = all good, 1 = broken links
"""

import glob
import os
import re
import sys

# Markdown link targets: ](target) - ignores images vs links on purpose.
LINK_RE = re.compile(r"\]\(([^)]+)\)")
# Anything with a scheme (http:, https:, mailto:...) is external - skipped.
SCHEME_RE = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*:")
# Vendored/agent copies are not our documentation.
SKIP_PREFIXES = (".kilo",)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root)

    broken = []
    checked = 0
    files = [p for p in glob.glob("**/*.md", recursive=True)
             if not p.startswith(SKIP_PREFIXES)]

    for path in files:
        base = os.path.dirname(path)
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as fh:
                text = fh.read()
        except OSError as exc:                     # pragma: no cover
            print("WARN: cannot read %s: %s" % (path, exc))
            continue

        for target in LINK_RE.findall(text):
            clean = target.split("#")[0].strip()   # drop #anchors
            if not clean or SCHEME_RE.match(clean):
                continue                           # external / pure-anchor
            checked += 1
            resolved = os.path.normpath(os.path.join(base, clean))
            if not os.path.exists(resolved):
                broken.append("%s -> %s" % (path, target))

    print("checked %d relative links across %d markdown files" % (checked, len(files)))
    if broken:
        print("BROKEN LINKS (%d):" % len(broken))
        for item in broken:
            print("  " + item)
        return 1
    print("all links resolve")
    return 0


if __name__ == "__main__":
    sys.exit(main())
