#!/usr/bin/env bash
# Build the task image locally (same tag used by run_manual_oracle.sh).
set -euo pipefail

export DOCKER_CONFIG="${DOCKER_CONFIG:-/tmp/docker-nocreds}"
mkdir -p "$DOCKER_CONFIG"
printf '{}\n' > "$DOCKER_CONFIG/config.json"

PKG="/mnt/c/Users/Momin/Documents/gdm-swe-bench-long-horizon-poc/Task10/istio-zone-aware-lb"
TAG="${TAG:-istio-zone-aware-lb:qc-v1}"
LOG="/mnt/c/Users/Momin/Documents/gdm-swe-bench-long-horizon-poc/Task10/build.log"

echo "Building ${TAG} — log: ${LOG}"
echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

docker build \
  -f "${PKG}/environment/Dockerfile" \
  -t "${TAG}" \
  "${PKG}/environment/" 2>&1 | tee "${LOG}"

echo "Finished: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
docker images "${TAG}" --format "Image {{.Repository}}:{{.Tag}} size={{.Size}}"
