#!/usr/bin/env bash
set -euo pipefail
mkdir -p /app/output /logs/agent /logs/verifier
printf 'oracle\n' > /logs/agent/oracle.txt

run_stage() {
  local stage="$1"
  local key="$2"
  echo "=== ${stage} (${key}) ==="
  rm -rf /solution
  mkdir -p /solution
  cp -a "/task-steps/${stage}/solution/." /solution/
  bash /solution/solve.sh
  mkdir -p "/logs/verifier/${stage}"
  RESULT_DIR="/logs/verifier/${stage}" \
    HIDDEN_TESTS_DIR="/tests/hidden" \
    AGENT_OUTPUT_DIR="/app/output" \
    bash /tests/stage_test.sh "${key}"
  python3 - <<PY
import json
from pathlib import Path
stage = "${stage}"
reward = json.loads((Path("/logs/verifier") / stage / "reward.json").read_text(encoding="utf-8"))
print(json.dumps(reward, indent=2))
assert float(reward.get("binary_reward", 0.0)) == 1.0, reward
PY
}

run_stage "01-diagnose" diagnose
run_stage "02-self-discovery-bootstrap" bootstrap
run_stage "03-eds-loadbalancer" eds
run_stage "04-config-harden" harden
echo "Oracle manual validation: ALL STAGES PASS"
