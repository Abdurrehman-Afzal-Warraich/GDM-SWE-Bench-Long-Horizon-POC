#!/usr/bin/env bash
# Full local verification for istio-zone-aware-lb v2 (Oracle, no-op, headroom proxy).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PKG="${ROOT}/istio-zone-aware-lb"
IMAGE="${IMAGE:-istio-zone-aware-lb:qc-v1}"
JOBS="${ROOT}/harbor-jobs/v2-verify-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$JOBS"

echo "=== [1/4] Pack gate (45 pytest) ==="
docker run --rm -v "${ROOT}:/task" python:3.12-bookworm bash -lc \
  'pip install -q pytest==8.3.5 && python /task/pack_istio_zone_aware_lb.py'

echo "=== [2/4] Oracle (all 4 stages, mounted v2 tests) ==="
ORACLE_OUT="${JOBS}/oracle"
mkdir -p "$ORACLE_OUT"
docker run --rm \
  -v "${PKG}/tests:/tests:ro" \
  -v "${PKG}/steps:/task-steps:ro" \
  -v "${ORACLE_OUT}:/logs/verifier" \
  "$IMAGE" \
  bash -lc '
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
p = Path("/logs/verifier") / stage / "reward.json"
reward = json.loads(p.read_text(encoding="utf-8"))
details = Path("/logs/verifier") / stage / "reward-details.json"
print(json.dumps(reward, indent=2))
if details.is_file():
    d = json.loads(details.read_text(encoding="utf-8"))
    print("critical_pass:", d.get("critical_pass"), "non_critical:", d.get("non_critical_checks"))
br = float(reward.get("binary_reward", 0.0))
assert br == 1.0, reward
ctrf = json.loads((Path("/logs/verifier") / stage / "ctrf.json").read_text(encoding="utf-8"))
failed = ctrf["results"]["summary"]["failed"]
assert failed == 0, ctrf["results"]["summary"]
PY
}

run_stage "01-diagnose" diagnose
run_stage "02-self-discovery-bootstrap" bootstrap
run_stage "03-eds-loadbalancer" eds
run_stage "04-config-harden" harden
echo "ORACLE: ALL STAGES binary_reward=1.0"
'

echo "=== [3/4] No-op (pristine base, all stages must score 0) ==="
NOP_OUT="${JOBS}/nop"
mkdir -p "$NOP_OUT"
docker run --rm \
  -v "${PKG}/tests:/tests:ro" \
  -v "${NOP_OUT}:/logs/verifier" \
  "$IMAGE" \
  bash -lc '
set -euo pipefail
export GOWORK=off GOTOOLCHAIN=local CGO_ENABLED=0 GOPROXY=off
export GOPATH=/go GOMODCACHE=/go/pkg/mod GOCACHE=/gocache
export PATH=/usr/local/go/bin:/go/bin:/usr/local/bin:/usr/bin:/bin
export TRUSTED_ORACLE=1
mkdir -p /app/output /logs/agent /logs/verifier
cd /testbed
# Reset to sanitized base (oracle stages mutate the tree).
git checkout -f HEAD >/dev/null 2>&1 || true
git clean -fd >/dev/null 2>&1 || true
rm -rf /app/output/*
for spec in "01-diagnose:diagnose" "02-self-discovery-bootstrap:bootstrap" "03-eds-loadbalancer:eds" "04-config-harden:harden"; do
  stage="${spec%%:*}"
  key="${spec##*:}"
  echo "=== NOP ${stage} (${key}) ==="
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
print(json.dumps(reward, indent=2))
br = float(reward.get("binary_reward", 0.0))
assert br == 0.0, f"expected nop fail, got {reward}"
PY
done
echo "NOP: ALL STAGES binary_reward=0.0"
'

echo "=== [4/4] Headroom proxy (S01 oracle pass, S02 empty agent -> hidden fail) ==="
HEAD_OUT="${JOBS}/headroom"
mkdir -p "$HEAD_OUT"
docker run --rm \
  -v "${PKG}/tests:/tests:ro" \
  -v "${PKG}/steps:/task-steps:ro" \
  -v "${HEAD_OUT}:/logs/verifier" \
  "$IMAGE" \
  bash -lc '
set -euo pipefail
export GOWORK=off GOTOOLCHAIN=local CGO_ENABLED=0 GOPROXY=off
export GOPATH=/go GOMODCACHE=/go/pkg/mod GOCACHE=/gocache
export PATH=/usr/local/go/bin:/go/bin:/usr/local/bin:/usr/bin:/bin
export TRUSTED_ORACLE=1
mkdir -p /app/output /logs/agent /logs/verifier
git checkout -f HEAD >/dev/null 2>&1 || true
git clean -fd >/dev/null 2>&1 || true
rm -rf /app/output/* /solution
mkdir -p /solution
cp -a /task-steps/01-diagnose/solution/. /solution/
bash /solution/solve.sh
RESULT_DIR="/logs/verifier/01-diagnose" HIDDEN_TESTS_DIR="/tests/hidden" AGENT_OUTPUT_DIR="/app/output" TRUSTED_ORACLE=1 \
  bash /tests/stage_test.sh diagnose
python3 - <<PY
import json
from pathlib import Path
r = json.loads((Path("/logs/verifier/01-diagnose/reward.json")).read_text(encoding="utf-8"))
assert float(r["binary_reward"]) == 1.0, r
print("S01 frontier-style pass:", r)
PY
# S02: agent did not apply golden patch (mimics Gemini partial solve).
RESULT_DIR="/logs/verifier/02-self-discovery-bootstrap" HIDDEN_TESTS_DIR="/tests/hidden" AGENT_OUTPUT_DIR="/app/output" TRUSTED_ORACLE=1 \
  bash /tests/stage_test.sh bootstrap
python3 - <<PY
import json
from pathlib import Path
p = Path("/logs/verifier/02-self-discovery-bootstrap")
reward = json.loads((p / "reward.json").read_text(encoding="utf-8"))
details = json.loads((p / "reward-details.json").read_text(encoding="utf-8"))
checks = details.get("checks", {})
hidden = checks.get("hidden_tests_pass", {})
print("S02 partial-agent reward:", json.dumps(reward, indent=2))
print("hidden_tests_pass:", hidden)
br = float(reward.get("binary_reward", 0.0))
assert br == 0.0, "headroom probe: S02 must fail without implementation"
assert not hidden.get("passed", True), "hidden_tests_pass should fail on empty S02"
print("HEADROOM PROXY: S01=1.0 S02=0.0 (hidden_tests_pass gates partial solve)")
'

echo ""
echo "=== ALL LOCAL CHECKS PASSED ==="
echo "Artifacts: ${JOBS}"
find "$JOBS" -name reward.json -print -exec sh -c 'head -c 200 "$1"; echo' _ {} \;
