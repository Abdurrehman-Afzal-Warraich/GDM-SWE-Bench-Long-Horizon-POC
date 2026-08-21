#!/usr/bin/env python3
"""Score merged PR CSV rows for Tier-2 Go task suitability."""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

REJECT_TITLE = re.compile(
    r"(?i)(^build\(deps\)|^chore|^bump |vendor:|dependabot|modernize|release/|"
    r"merge branch|rebase master|registry\.istio|golang\.org/x/|^build:|^ci:|"
    r"^test: update|translation|i18n|renovate|update generated)",
)


def load(path: Path) -> list[dict]:
    rows: list[dict] = []
    with path.open(newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            r["Files Changed"] = int(r["Files Changed"])
            r["Additions"] = int(r["Additions"])
            r["Deletions"] = int(r["Deletions"])
            rows.append(r)
    return rows


def score_row(r: dict, repo: str) -> float | None:
    fc = r["Files Changed"]
    title = r["Title"]
    adds, dels = r["Additions"], r["Deletions"]
    if fc < 50:
        return None
    if REJECT_TITLE.search(title):
        return None
    if adds > 15000 and dels > 15000 and fc < 120:
        return None
    net = adds + dels
    s = min(fc, 120) / 4
    if 800 <= net <= 15000:
        s += 20
    elif net <= 800:
        s += 10
    elif net <= 25000:
        s += 8
    else:
        s += 2
    merged = r["Merged At"][:10]
    if merged >= "2026-05-01":
        s += 15
    elif merged >= "2026-01-01":
        s += 10
    good = (
        "implement", "add ", "support", "fix", "feature", "refactor", "introduce",
        "enable", "handle", "migrate", "plugin", "snapshot", "transfer", "cri",
        "runtime", "proxy", "ambient", "gateway", "waypoint", "xds", "auth",
        "policy", "inject", "index", "controller", "server", "client",
    )
    tl = title.lower()
    if any(g in tl for g in good):
        s += 12
    if repo == "istio" and "ambient" in tl:
        s += 8
    if repo == "containerd" and any(x in tl for x in ("cri", "snapshot", "transfer", "sandbox", "shim", "runtime", "content", "metadata")):
        s += 8
    if fc > 200:
        s -= 25
    elif fc > 150:
        s -= 10
    return s


def main() -> None:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    for repo, rel in (
        ("containerd", "containerd_containerd_merged_prs_last_6_months.csv"),
        ("istio", "istio_istio_merged_prs_last_6_months.csv"),
    ):
        rows = load(root / rel)
        scored = [(score_row(r, repo), r) for r in rows]
        scored = [(s, r) for s, r in scored if s is not None]
        scored.sort(key=lambda x: -x[0])
        print(f"\n=== {repo.upper()} top 30 (50+ files, dep/vendor filtered) ===")
        for s, r in scored[:30]:
            print(
                f"{s:5.1f} | #{r['PR Number']:>5} | {r['Files Changed']:>4} files | "
                f"+{r['Additions']}/-{r['Deletions']} | {r['Merged At'][:10]} | {r['Title'][:95]}"
            )


if __name__ == "__main__":
    main()
