#!/usr/bin/env python3
"""Pack cilium-gateway-l4-routes for data-os upload."""
from __future__ import annotations

import hashlib
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PKG = ROOT / "cilium-gateway-l4-routes"
OUT_ZIP = ROOT / "cilium-gateway-l4-routes.zip"

SKIP_DIRS = {".build", "__pycache__", ".pytest_cache", ".git", ".cursor"}
SKIP_FILES = {
    "SELF_REVIEW.md",
    "DESIGN.md",
    ".DS_Store",
    "preflight_report.json",
    "golden_full.patch",
    "VALIDATION_EVIDENCE.md",
    "calibration_summary.json",
    "QC_FULL_AUDIT_REVIEW.md",
}
SKIP_SUFFIXES = (".pyc", ".pyo")
EXECUTABLE_SUFFIXES = {".sh"}


def scrub_tree(path: Path) -> None:
    for child in sorted(path.rglob("*"), key=lambda p: len(p.parts), reverse=True):
        if any(part in SKIP_DIRS for part in child.parts):
            if child.is_dir():
                shutil.rmtree(child, ignore_errors=True)
            elif child.is_file():
                child.unlink(missing_ok=True)


def normalize_shell_lf(stage: Path) -> None:
    for script in stage.rglob("*.sh"):
        data = script.read_bytes()
        if b"\r\n" in data:
            script.write_bytes(data.replace(b"\r\n", b"\n"))


def assert_no_junk_in_stage(stage: Path) -> None:
    for child in stage.rglob("*"):
        rel = child.relative_to(stage).as_posix()
        if any(part in SKIP_DIRS for part in child.parts):
            raise SystemExit(f"FATAL: junk path still present before zip: {rel}")
        if child.is_file() and child.suffix in SKIP_SUFFIXES:
            raise SystemExit(f"FATAL: junk file still present before zip: {rel}")


def assert_clean_zip(zf: zipfile.ZipFile) -> None:
    for name in zf.namelist():
        parts = name.split("/")
        if any(part in SKIP_DIRS for part in parts):
            raise SystemExit(f"FATAL: zip contains junk path: {name}")
        if name.endswith(SKIP_SUFFIXES):
            raise SystemExit(f"FATAL: zip contains junk file: {name}")
        if name.endswith(".sh"):
            info = zf.getinfo(name)
            mode = (info.external_attr >> 16) & 0o777
            if mode != 0o755:
                raise SystemExit(f"FATAL: {name} packaged as {oct(mode)}, expected 0755")


def zip_write(path: Path, arcname: str, zf: zipfile.ZipFile) -> None:
    if path.suffix in EXECUTABLE_SUFFIXES:
        info = zipfile.ZipInfo(arcname)
        info.external_attr = (stat.S_IFREG | 0o755) << 16
        zf.writestr(info, path.read_bytes())
    else:
        zf.write(path, arcname)


def run_contract_tests(stage: Path) -> None:
    tests = stage / "tests"
    env = {**os.environ, "PYTHONPATH": str(tests)}
    subprocess.run(
        [
            sys.executable,
            "-m",
            "pytest",
            "test_reward_contract.py",
            "test_package_contract.py",
            "test_oracle_hidden_alignment.py",
            "test_near_miss_controls.py",
            "test_dataos_qc_preflight.py",
            "-q",
        ],
        cwd=tests,
        check=True,
        env=env,
    )

    packed_toml = (stage / "task.toml").read_text(encoding="utf-8")
    if "allow_internet = true" in packed_toml:
        raise SystemExit("FATAL: shipped task.toml still has allow_internet=true")
    if "[verifier.env]" not in packed_toml:
        raise SystemExit("FATAL: missing [verifier.env] block in task.toml")
    if "OPENAI_API_KEY" not in packed_toml:
        raise SystemExit("FATAL: shipped task.toml missing OPENAI_API_KEY in [verifier.env]")
    core = (stage / "tests" / "score_formula.py").read_text(encoding="utf-8")
    block = core.split("REWARD_JSON_CORE_KEYS", 1)[1].split(")", 1)[0]
    if '"valid_trial"' in block or '"stage_complete"' in block:
        raise SystemExit("FATAL: valid_trial/stage_complete still in REWARD_JSON_CORE_KEYS")
    for path in stage.glob("tests/*/judge.toml"):
        if "gpt-5.6-terra" not in path.read_text(encoding="utf-8"):
            raise SystemExit(f"FATAL: judge.toml must use openai/gpt-5.6-terra: {path.name}")


def main() -> None:
    if not PKG.is_dir():
        raise SystemExit(f"missing package dir {PKG}")

    scrub_tree(PKG)

    with tempfile.TemporaryDirectory() as tmp:
        stage = Path(tmp) / "stage"
        shutil.copytree(PKG, stage, ignore=shutil.ignore_patterns(*SKIP_DIRS, "*.pyc", "*.pyo"))
        scrub_tree(stage)
        normalize_shell_lf(stage)
        run_contract_tests(stage)
        scrub_tree(stage)
        assert_no_junk_in_stage(stage)

        with zipfile.ZipFile(OUT_ZIP, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for path in sorted(stage.rglob("*")):
                if path.is_file():
                    zip_write(path, path.relative_to(stage).as_posix(), zf)
            assert_clean_zip(zf)

    digest = hashlib.sha256(OUT_ZIP.read_bytes()).hexdigest()
    print(f"packed {OUT_ZIP} sha256={digest}")


if __name__ == "__main__":
    main()
