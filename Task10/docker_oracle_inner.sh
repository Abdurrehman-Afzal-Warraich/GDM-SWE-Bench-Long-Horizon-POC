#!/usr/bin/env bash
set -euo pipefail
export GOWORK=off GOTOOLCHAIN=local CGO_ENABLED=0 GOPROXY=off
export GOPATH=/go GOMODCACHE=/go/pkg/mod GOCACHE=/gocache
export PATH=/usr/local/go/bin:/go/bin:/usr/local/bin:/usr/bin:/bin
export TRUSTED_ORACLE=1
mkdir -p /app/output /logs/agent /logs/verifier
printf "oracle\n" > /logs/agent/oracle.txt

run_stage() {
  local stage="$1"
  local key="$2"
  echo "=== ORACLE ${stage} (${key}) ==="
  rm -rf /solution
  mkdir -p /solution
  cp -a "/task-steps/${stage}/solution/." /solution/
  bash /solution/solve.sh
  RESULT_DIR="/logs/verifier/${stage}" \
    HIDDEN_TESTS_DIR="/tests/hidden" \
    AGENT_OUTPUT_DIR="/app/output" \
    TRUSTED_ORACLE=1 \
    bash /tests/stage_test.sh "${key}"
  python3 - <<PY
import json
from pathlib import Path
stage = "${stage}"
reward = json.loads((Path("/logs/verifier") / stage / "reward.json").read_text(encoding="utf-8"))
details_path = Path("/logs/verifier") / stage / "reward-details.json"
print(json.dumps(reward, indent=2))
if details_path.is_file():
    d = json.loads(details_path.read_text(encoding="utf-8"))
    print("critical_pass:", d.get("critical_pass"), "non_critical:", d.get("non_critical_checks"))
assert float(reward.get("binary_reward", 0.0)) == 1.0, reward
ctrf = json.loads((Path("/logs/verifier") / stage / "ctrf.json").read_text(encoding="utf-8"))
assert ctrf["results"]["summary"]["failed"] == 0, ctrf["results"]["summary"]
PY
}

run_stage "01-diagnose" diagnose
run_stage "02-self-discovery-bootstrap" bootstrap
run_stage "03-eds-loadbalancer" eds
run_stage "04-config-harden" harden
echo "ORACLE ALL PASS"
