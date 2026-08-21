#!/usr/bin/env python3
"""Analyze GitHub PR file list JSON for Tier-2 suitability."""
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path


def analyze(path: Path, pr: str) -> None:
    files = json.loads(path.read_text(encoding="utf-8"))
    prod = test = gen = yaml = 0
    prod_add = test_add = 0
    dirs = Counter()
    pkg_tests: list[str] = []
    for f in files:
        p = f["filename"]
        a = f["additions"]
        top = p.split("/")[0]
        dirs[top] += 1
        if (
            "_test.go" in p
            or p.endswith("_test.yaml")
            or "/tests/" in p
            or "/test/" in p
            or "integration" in p.lower() and p.endswith((".yaml", ".yml"))
        ):
            test += 1
            test_add += a
        elif p.endswith(".golden") or "gen_" in p or "/generated/" in p:
            gen += 1
        elif p.endswith((".yaml", ".yml")):
            yaml += 1
        else:
            prod += 1
            prod_add += a
        if "_test.go" in p:
            pkg_tests.append(p)
    print(f"=== PR {pr} ({len(files)} files) ===")
    print(f"prod={prod} test={test} gen={gen} yaml={yaml}")
    print(f"prod_additions~={prod_add} test_additions~={test_add}")
    print("top dirs:", dirs.most_common(10))
    prod_files = [
        f
        for f in files
        if "_test.go" not in f["filename"] and not f["filename"].endswith("_test.yaml")
    ]
    print("prod files (top by additions):")
    for f in sorted(prod_files, key=lambda x: -x["additions"])[:15]:
        print(f"  {f['filename']} +{f['additions']}/-{f['deletions']}")
    print(f"unit test files: {len(pkg_tests)}")
    if pkg_tests[:8]:
        print("sample tests:", ", ".join(pkg_tests[:8]))
    print()


def main() -> None:
    for arg in sys.argv[1:]:
        pr, rel = arg.split(":", 1)
        analyze(Path(rel), pr)


if __name__ == "__main__":
    main()
