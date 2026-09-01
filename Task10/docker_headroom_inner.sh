#!/usr/bin/env bash
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
python3 - <<'PY'
import json
from pathlib import Path
r = json.loads((Path("/logs/verifier/01-diagnose/reward.json")).read_text(encoding="utf-8"))
assert float(r["binary_reward"]) == 1.0, r
print("S01 pass:", r)
PY

RESULT_DIR="/logs/verifier/02-self-discovery-bootstrap" HIDDEN_TESTS_DIR="/tests/hidden" AGENT_OUTPUT_DIR="/app/output" TRUSTED_ORACLE=1 \
  bash /tests/stage_test.sh bootstrap
python3 - <<'PY'
import json
from pathlib import Path
p = Path("/logs/verifier/02-self-discovery-bootstrap")
reward = json.loads((p / "reward.json").read_text(encoding="utf-8"))
details = json.loads((p / "reward-details.json").read_text(encoding="utf-8"))
hidden = details.get("checks", {}).get("hidden_tests_pass", {})
print("S02 fail reward:", json.dumps(reward, indent=2))
print("hidden_tests_pass:", hidden)
assert float(reward.get("binary_reward", 0.0)) == 0.0
assert not hidden.get("passed", True)
print("HEADROOM PROXY OK: S01=1.0 S02=0.0")
PY
