#!/usr/bin/env bash
# Harbor-equivalent Oracle validation inside the built task image.
set -euo pipefail

export DOCKER_CONFIG="${DOCKER_CONFIG:-/tmp/docker-nocreds}"
mkdir -p "$DOCKER_CONFIG"
printf '{}\n' > "$DOCKER_CONFIG/config.json"

TASK="/mnt/c/Users/Momin/Documents/gdm-swe-bench-long-horizon-poc/Task10/istio-zone-aware-lb"
IMAGE="${IMAGE:-istio-zone-aware-lb:qc-v1}"
OUT="/mnt/c/Users/Momin/Documents/gdm-swe-bench-long-horizon-poc/Task10/harbor-jobs/manual-oracle-v1"
mkdir -p "$OUT"

docker run --rm \
  -v "$TASK/tests:/tests:ro" \
  -v "$TASK/steps:/task-steps:ro" \
  -v "$OUT:/logs/verifier" \
  "$IMAGE" \
  bash -lc '
set -euo pipefail
mkdir -p /app/output /logs/agent /logs/verifier
printf "oracle\n" > /logs/agent/oracle.txt

run_stage() {
  local stage="$1"
  local key="$2"
  echo "=== ${stage} (${key}) ==="
  rm -rf /solution
  mkdir -p /solution
  cp -a "/task-steps/${stage}/solution/." /solution/
  bash /solution/solve.sh
  RESULT_DIR="/logs/verifier/${stage}" \
    HIDDEN_TESTS_DIR="/tests/hidden" \
    AGENT_OUTPUT_DIR="/app/output" \
    bash /tests/stage_test.sh "${key}"
  python3 - <<PY
import json
from pathlib import Path
p = Path("/logs/verifier") / "${stage}" / "reward.json"
reward = json.loads(p.read_text(encoding="utf-8"))
print(json.dumps(reward, indent=2))
assert float(reward.get("binary_reward", 0.0)) == 1.0, reward
PY
}

run_stage "01-diagnose" diagnose
run_stage "02-self-discovery-bootstrap" bootstrap
run_stage "03-eds-loadbalancer" eds
run_stage "04-config-harden" harden
echo "Oracle manual validation: ALL STAGES PASS"
'

echo "Results under $OUT"
