#!/usr/bin/env python3
"""Run Tier-2 Harbor task preflight checks before DataOS QC upload.

Usage:
  python tier2_qc_preflight.py /path/to/task-package [--write-report PATH]

Exit codes:
  0 — all hard gates passed (warnings allowed)
  1 — one or more hard gates failed
  2 — usage / missing task path
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tomllib
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path

PYTEST_FILES = [
    "test_reward_contract.py",
    "test_package_contract.py",
    "test_near_miss_controls.py",
    "test_oracle_hidden_alignment.py",
    "test_dataos_qc_preflight.py",
]


@dataclass
class CheckResult:
    outcome: str  # pass | fail | warn | skip
    explanation: str


@dataclass
class PreflightReport:
    task_path: str
    generated_at: str
    checks: dict[str, CheckResult] = field(default_factory=dict)

    def summary(self) -> dict[str, int]:
        counts = {"pass": 0, "fail": 0, "warn": 0, "skip": 0}
        for item in self.checks.values():
            counts[item.outcome] = counts.get(item.outcome, 0) + 1
        return counts

    def to_json(self) -> dict:
        return {
            "schema": {"type": "tier2-preflight", "version": 1},
            "task_path": self.task_path,
            "generated_at": self.generated_at,
            "checks": {
                key: {"outcome": val.outcome, "explanation": val.explanation}
                for key, val in self.checks.items()
            },
            "summary": self.summary(),
            "hard_gate_pass": self.summary()["fail"] == 0,
        }


def load_task_name(task_dir: Path) -> str:
    cfg = tomllib.loads((task_dir / "task.toml").read_text(encoding="utf-8"))
    return cfg["task"]["name"]


def scrub_pycache(task_dir: Path) -> None:
    import shutil

    for cache in task_dir.rglob("__pycache__"):
        shutil.rmtree(cache, ignore_errors=True)


def run_pytest(task_dir: Path) -> tuple[int, str]:
    scrub_pycache(task_dir)
    tests_dir = task_dir / "tests"
    if not tests_dir.is_dir():
        return 2, "missing tests/ directory"

    cmd = [
        sys.executable,
        "-m",
        "pytest",
        *PYTEST_FILES,
        "-q",
        "--tb=line",
    ]
    proc = subprocess.run(
        cmd,
        cwd=tests_dir,
        env={**os.environ, "PYTHONPATH": str(tests_dir)},
        capture_output=True,
        text=True,
    )
    output = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode, output.strip()


def parse_qc_marker_results(task_dir: Path) -> dict[str, CheckResult]:
    """Import test_dataos_qc_preflight and collect QC_* registry results."""
    tests_dir = task_dir / "tests"
    sys.path.insert(0, str(tests_dir))
    try:
        import test_dataos_qc_preflight as qc  # type: ignore[import-not-found]
    except ImportError:
        return {}
    results: dict[str, CheckResult] = {}
    for check_id, meta in getattr(qc, "QC_REGISTRY", {}).items():
        fn = meta["fn"]
        severity = meta.get("severity", "fail")
        try:
            fn(task_dir)
            results[check_id] = CheckResult("pass", meta.get("pass_note", "local preflight passed"))
        except AssertionError as exc:
            outcome = "warn" if severity == "warn" else "fail"
            results[check_id] = CheckResult(outcome, str(exc) or meta.get("fail_note", "check failed"))
        except Exception as exc:  # pragma: no cover - defensive
            results[check_id] = CheckResult("fail", f"unexpected error: {exc}")
    return results


def build_report(task_dir: Path, pytest_rc: int, pytest_output: str) -> PreflightReport:
    report = PreflightReport(
        task_path=str(task_dir.resolve()),
        generated_at=datetime.now(UTC).isoformat(),
    )

    if pytest_rc == 0:
        report.checks["package_contract_suite"] = CheckResult(
            "pass",
            f"pytest contract + oracle-alignment suite green ({len(PYTEST_FILES)} files)",
        )
    else:
        report.checks["package_contract_suite"] = CheckResult(
            "fail",
            pytest_output[-4000:] or "pytest failed with no output",
        )

    for check_id, result in parse_qc_marker_results(task_dir).items():
        report.checks[check_id] = result

    try:
        sys.path.insert(0, str(task_dir / "tests"))
        import test_dataos_qc_preflight as qc_mod  # type: ignore[import-not-found]

        for check_id, defense in getattr(qc_mod, "DATAOS_LLM_LIKELY_FAIL", {}).items():
            if check_id not in report.checks or report.checks[check_id].outcome == "pass":
                report.checks[f"dataos_expected_{check_id}"] = CheckResult(
                    "warn",
                    f"DataOS QC may still fail: {defense}",
                )
    except ImportError:
        pass

    llm_only = [
        "novel",
        "interesting",
        "difficult",
        "agentic",
        "reviewable",
        "task_security",
        "typos",
    ]
    for check_id in llm_only:
        if check_id not in report.checks:
            report.checks[check_id] = CheckResult(
                "skip",
                "DataOS LLM reviewer only — not emulated locally",
            )

    return report


def print_human(report: PreflightReport) -> None:
    summary = report.summary()
    print(f"Task: {report.task_path}")
    print(f"Generated: {report.generated_at}")
    print(f"Summary: pass={summary['pass']} fail={summary['fail']} warn={summary['warn']} skip={summary['skip']}")
    print()
    for check_id in sorted(report.checks):
        item = report.checks[check_id]
        print(f"[{item.outcome.upper():4}] {check_id}")
        print(f"       {item.explanation[:240]}{'...' if len(item.explanation) > 240 else ''}")
    print()
    if summary["fail"]:
        print("PREFLIGHT FAILED — fix hard gates before DataOS QC upload.")
    elif summary["warn"]:
        print("PREFLIGHT PASSED WITH WARNINGS — review warn rows; Dev Defense may be needed on DataOS.")
    else:
        print("PREFLIGHT PASSED — safe to pack and upload for DataOS QC + Oracle.")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Tier-2 Harbor task preflight before DataOS QC")
    parser.add_argument("task_dir", type=Path, help="Path to task package directory (contains task.toml)")
    parser.add_argument(
        "--write-report",
        type=Path,
        default=None,
        help="Write JSON report to this path (default: <task>/preflight_report.json)",
    )
    args = parser.parse_args(argv)

    task_dir = args.task_dir.resolve()
    if not (task_dir / "task.toml").is_file():
        print(f"error: {task_dir} is not a Harbor task package (no task.toml)", file=sys.stderr)
        return 2

    pytest_rc, pytest_output = run_pytest(task_dir)
    report = build_report(task_dir, pytest_rc, pytest_output)

    out_path = args.write_report or (task_dir / "preflight_report.json")
    out_path.write_text(json.dumps(report.to_json(), indent=2) + "\n", encoding="utf-8")

    print_human(report)
    print(f"Report: {out_path}")
    return 1 if report.summary()["fail"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
