# Tier-2 task preflight (before DataOS QC)

Run locally in Docker to catch package defects **before** spending DataOS QC/Oracle credits.

## Quick start (cilium task)

```powershell
# From repo root on Windows
.\Task9\run_preflight.ps1
```

```bash
# Linux / macOS / Git Bash
bash scripts/vetting/run_preflight_docker.sh Task9/cilium-gateway-l4-routes
```

## What it runs

1. **Contract suite** — `test_reward_contract.py`, `test_package_contract.py`, `test_near_miss_controls.py`, `test_oracle_hidden_alignment.py`
2. **DataOS QC mirrors** — `test_dataos_qc_preflight.py` (deterministic checks aligned to automated QC rows)
3. **Warnings** — rows DataOS LLM QC often fails anyway (`solvable`, offline-behavior probes) with Dev Defense hints

Output: `<task>/preflight_report.json` plus a human summary.

Exit code `0` = no hard local failures. Exit code `1` = fix before upload.

## Pack + preflight

```bash
docker run --rm -v "$PWD:/repo" -w /repo/Task9 python:3.12-bookworm \
  bash -lc 'pip install -q pytest==8.3.5 && python pack_cilium_gateway_l4_routes.py'
```

The pack script runs the same pytest suite on the staged zip copy.

## Oracle

Preflight does **not** replace DataOS Oracle. After preflight is green, upload and run Oracle on the platform (or Harbor locally if available).
