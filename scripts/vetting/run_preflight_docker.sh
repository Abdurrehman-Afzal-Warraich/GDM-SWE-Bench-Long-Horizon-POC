#!/usr/bin/env bash
# Run Tier-2 preflight (contract tests + DataOS QC mirrors) inside Docker.
set -euo pipefail

TASK_DIR="${1:-}"
if [[ -z "${TASK_DIR}" ]]; then
  echo "usage: $0 /path/to/task-package" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_DIR="$(cd "${TASK_DIR}" && pwd)"

docker run --rm \
  -v "${ROOT}:/repo:ro" \
  -v "${TASK_DIR}:/task" \
  -w /repo \
  python:3.12-bookworm \
  bash -lc '
    pip install -q pytest==8.3.5
    python /repo/scripts/vetting/tier2_qc_preflight.py /task --write-report /task/preflight_report.json
  '
