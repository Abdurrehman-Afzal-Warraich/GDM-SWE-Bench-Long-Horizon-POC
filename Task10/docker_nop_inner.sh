#!/usr/bin/env bash
set -euo pipefail
export GOWORK=off GOTOOLCHAIN=local CGO_ENABLED=0 GOPROXY=off
export GOPATH=/go GOMODCACHE=/go/pkg/mod GOCACHE=/gocache
export PATH=/usr/local/go/bin:/go/bin:/usr/local/bin:/usr/bin:/bin
export TRUSTED_ORACLE=1
mkdir -p /app/output /logs/agent /logs/verifier
cd /testbed
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
assert float(reward.get("binary_reward", 0.0)) == 0.0, f"expected nop fail, got {reward}"
PY
done
echo "NOP ALL FAIL AS EXPECTED"
