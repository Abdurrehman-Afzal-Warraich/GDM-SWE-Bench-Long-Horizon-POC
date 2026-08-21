# Long Horizon — Tier 1 Full-Repository Engineering Task Workflow

> Working guide distilled from **"Single Step Engineering repo Design"** (Tier 1 Full-Repository Engineering Task Guide — Generic Harbor Packaging, Prompt, Evaluation, Reward, and Training Design). Includes the full text and all 9 figures.

---

## 0. TL;DR — The Core Contract

- A **Tier 1 task** gives an agent **one protected session** in a **complete production repository** at an **exact pre-change commit**.
- The briefing reads like a **real issue**: observable behavior, compatibility constraints, and required evidence — while **diagnosis and implementation are left open**.
- Grading is done by **executable deterministic checks**. Optional LLM/human **judges explain quality but cannot rescue broken behavior**.
- The benchmark asks: *does the final repository satisfy a real engineering contract?* — **NOT** whether the diff matches a reference patch.
- **Any implementation may pass** if it satisfies: required behavior + regressions + integration contract + integrity boundary + any explicitly stated architecture requirement.
- Task identity is generic: `<benchmark>/<task-slug>` (replace with published package name). Placeholders describe the contract; they are **not** agent-facing text.

---

## 1. What a Tier 1 Task Is — Requirements Table

| Property | Tier 1 requirement | Reason |
|---|---|---|
| **Repository** | Complete, production-scale worktree at an exact pre-change commit | Preserves navigation, build, test, and integration complexity |
| **Session** | One agent context, no staged reviewer feedback | Measures full issue-to-patch execution in one run |
| **Prompt** | Natural, behavior-first engineering brief | Avoids revealing a PR, patch recipe, or hidden-test map |
| **Success** | All critical deterministic gates pass | A judge cannot rescue incorrect behavior |
| **Partial signal** | Weighted, labeled training vector | Near misses stay useful without being called "solved" |
| **Target headroom** | ~20–60% strict frontier solve rate after calibration | Avoids trivial or arbitrary tasks |

---

## 2. End-to-End Flow

A real repository change becomes a protected single-session task and a labeled result.
- The **source change** provides realism and an **author Oracle**, but it is **NOT** the verifier.
- Authors add **independent hidden variants, regression coverage, integrity checks, and near-miss patches** so that public change recall alone cannot satisfy the benchmark.

### Figure 6 — Tier 1 Full-Repository Lifecycle
1. Select real engineering change
2. Freeze exact pre-change repository
3. Sanitize history and network boundary
4. Write behavior-first prompt
5. Run one agent session
6. Run deterministic verifier
7. Run optional quality review
8. Emit eval result and training record

---

## 3. Run Procedure

Run **no-op, Oracle, and model trials as separate Harbor jobs**. Keep unique job names. **Verify the actual agent and model in `result.json`** before interpreting a score.

```bash
# Run from the directory that contains the task folder.
harbor run -p ./<task-directory> -a nop \
  --job-name <task>-nop

harbor run -p ./<task-directory> -a oracle \
  --job-name <task>-oracle

harbor run -p ./<task-directory> \
  -a terminus-2 -m <provider/model> \
  --job-name <task>-model

# Inspect the jobs in Harbor's local viewer.
harbor view ./jobs
```

### Where results appear
```
/root/harbor-jobs/<job-name>/
`-- <task-name>__<trial-id>/
    |-- result.json
    |-- agent/trajectory.json
    |-- verifier/reward.json
    |-- verifier/reward-details.json
    |-- verifier/test_output.log
    +-- artifacts/
```

- Read **`result.json`** first: agent identity, model, completion state, aggregate rewards.
- Read **`reward-details.json`** and **`test_output.log`** for the exact failed check family.
- Inspect **`trajectory.json`** and **`patch.diff`** before deciding whether a failure is a *model miss, verifier defect, timeout, contamination, or infrastructure problem*.

### Figure 7 — What Harbor Runs
1. Load `task.toml`
2. Build protected image
3. Mount sanitized repository
4. Run agent with `instruction.md`
5. Copy protected tests to `/tests`
6. Execute `/tests/test.sh`
7. Write numeric reward files
8. Collect logs, patch, trajectory, and artifacts

---

## 4. Recommended Task Package (Figure 1)

```
<task-name>/
|-- task.toml                     # Harbor schema, metadata, limits, network, artifacts
|-- instruction.md                # ONLY the natural engineering brief shown to the agent
|-- README.md                     # optional author-facing run and maintenance notes
|-- environment/
|   +-- Dockerfile                # full repository, pinned toolchain, cached dependencies
|-- solution/
|   |-- solve.sh                  # author-only, repeatable Oracle entrypoint
|   |-- golden.patch              # optional author-only reference patch
|   +-- provenance.json           # private source PR and exact commit provenance
+-- tests/
    |-- test.sh                   # REQUIRED Harbor verifier entrypoint
    |-- reward.toml               # deterministic reward aggregation
    |-- sync_reward.py            # strict RewardKit output + training-vector merge
    |-- test_reward_contract.py   # root-level discoverable packaging smoke tests
    |-- judge_prompt.md           # bounded common prompt for optional judges
    |-- common/
    |   |-- fixtures.py           # local fixtures and hidden variants
    |   +-- evidence.py           # safe result and trajectory staging helpers
    |-- deterministic/
    |   |-- engine.py             # executable build, behavior, regression, integrity prepass
    |   |-- check.py              # RewardKit adapter over precomputed executable evidence
    |   |-- test_behavior.py      # fail-to-pass and hidden behavior cases
    |   |-- test_regression.py    # pass-to-pass and repository suites
    |   |-- test_integration.py   # cross-component, data, schema, migration checks
    |   +-- test_integrity.py     # contamination and verifier-boundary checks
    |-- process/
    |   |-- check.py              # executable artifact and process gates
    |   +-- judge.toml            # optional trajectory-quality review
    |-- merge_readiness/
    |   +-- judge.toml            # optional maintainability and repository-taste review
    |-- validity/
    |   +-- judge.toml            # optional cheating and failure-class review
    |-- task_quality/
    |   +-- judge.toml            # author-facing prompt/verifier audit
    +-- near_miss/
        |-- README.md             # expected failure labels
        +-- *.patch               # seeded partial and shortcut solutions
```

### Why this clears validator warnings
- Set `metadata.benchmark_type = "swe-bench"` for this repo-engineering family.
- Keep `tests/test.sh`, add `tests/reward.toml`, and place executable pytest cases in conventionally named `tests/deterministic/test_*.py` modules.
- Use **one** environment-level `allow_internet = false` baseline; **omit phase-level `network_mode` overrides** (avoids asking providers to change network policy after container start).

### File responsibilities

| Path | Role | Must contain | Must NOT contain |
|---|---|---|---|
| `task.toml` | Harness contract | Schema, task identity, benchmark type, timeouts, resources, network, artifacts | Secrets, source PR URL, unsupported fields |
| `instruction.md` | Agent brief | Symptom, invariant, preserved behavior, constraints, executable evidence | Golden function, exact file list, PR number, hidden test names, patch recipe |
| `environment/Dockerfile` | Reproducible runtime | Sanitized full repo, pinned toolchain, cached deps, output dirs | Reachable future history, remotes, solution, tests, scored network installs |
| `solution/` | Author Oracle | Repeatable `solve.sh`, optional patch, private provenance | Anything mounted for the solving agent |
| `tests/test.sh` | Verifier entrypoint | Absolute paths, deterministic execution, numeric fail-safe reward, bounded logs | Network installs, swallowed missing tests, non-numeric rewards |
| `tests/deterministic/test_*.py` | Executable truth | Hidden behavior, regressions, integration, robustness, integrity assertions | Golden-diff comparison, or only the public example |
| `judge.toml` | Optional semantic review | Bounded files, explicit rubric, no-binary-rescue rule | Unbounded repo access, authority over deterministic truth |

---

## 5. Harbor Metadata & Warning Fixes

Use Harbor's current **nested task schema**. `metadata.benchmark_type` is **required** by the benchmark validator. For Tier 1 repo-engineering, declare **`swe-bench`** unless it genuinely belongs to another listed family.

```toml
schema_version = "1.3"
artifacts = [
  "/app/output/reproducer.sh",
  "/app/output/diagnosis.json",
  "/app/output/verification.json",
]

[task]
name = "<benchmark>/<task-slug>"
description = "A full-repository engineering task stated as an observable issue."
keywords = ["repo-engineering", "full-repository", "tier-1", "<language>"]

[metadata]
benchmark_type = "swe-bench"
category = "software-engineering"
language = "<language>"
tier = "core-repo-engineering"
repository = "<owner/repository>"
base_commit = "<exact-pre-change-commit>"
expert_time_estimate_hours = 12.0

[agent]
timeout_sec = 21600.0

[verifier]
timeout_sec = 5400.0

[environment]
build_timeout_sec = 7200.0
allow_internet = false
cpus = 8
memory_mb = 16384
storage_mb = 65536
```

### Warning → correction table

| Warning | Cause | Minimal correction | Verification |
|---|---|---|---|
| Missing `[metadata].benchmark_type` | Metadata present but no recognized benchmark family | Add `benchmark_type = "swe-bench"` under `[metadata]` | Reload/lint task; confirm warning gone |
| No tests found under `tests/` | Only a custom `check.py`, non-discoverable filenames, or tests omitted from archive | Keep `tests/test.sh` + add ≥1 real `tests/deterministic/test_*.py` | List packaged archive; run no-op verifier |
| Agent network policy differs from baseline | `agent`/`verifier` `network_mode` overrides disagree with fixed environment | Remove phase-level `network_mode`; set `environment.allow_internet = false` once | Confirm agent & verifier inherit the same offline baseline |
| Verifier produced no reward | `test.sh` exited before writing a reward | Always write numeric `reward.json`/`reward.txt`; fall back to zero on error | Force one failure; confirm Harbor records zero |

### Package pre-flight
```bash
# Required Harbor entrypoints and discoverable deterministic tests.
test -f task.toml
test -f instruction.md
test -f environment/Dockerfile
test -f solution/solve.sh
test -f tests/test.sh
test -f tests/reward.toml
find tests/deterministic -type f -name 'test_*.py' -print -quit | grep -q .

# Metadata warning must be absent for this task family.
grep -q '^benchmark_type = "swe-bench"$' task.toml

# Use one fixed offline environment baseline (phase-level overrides trigger warnings).
grep -q '^allow_internet = false$' task.toml
! grep -q '^network_mode' task.toml

# Scripts should use Unix line endings and be executable in the packaged task.
file tests/test.sh solution/solve.sh
```

**Archive note:** Before publishing a ZIP/registry package, inspect the archive itself. Confirm `tests/test.sh`, `reward.toml`, and `test_*.py` are present, shell scripts use **LF** line endings, and **solution/verifier files are NOT copied into the agent image**.

---

## 6. Environment & Dependencies

| Dependency | Location | Pin / requirement | Purpose |
|---|---|---|---|
| Repository toolchain | Agent/environment image | Pinned compiler, package manager, native libs, build tools | Build & test the real repository |
| Locked repo dependencies | Environment image cache | Language lockfile deps + required runtime assets | Keep every scored run offline & repeatable |
| Python | Isolated verifier runtime | **Python 3.12+** for `harbor-rewardkit 0.1.7` | Keep verifier compatible with non-Python repo images |
| pytest | Verifier runtime | Pin a validated version, e.g. **8.3.5** | Discover/execute `test_*.py` behavior & regression suites |
| harbor-rewardkit | Verifier runtime | Pin tested package; use `[all]` only when judge/doc extras needed | Weighted criteria, multiple reward dimensions, optional judges |
| Git / ripgrep / jq | Environment image | Pinned OS packages where practical | Repo inspection, integrity checks, JSON handling |
| Judge provider client/key | Separate or post-hoc verifier ONLY | Runtime secret + controlled network access | Optional process, validity, merge-readiness review |

### Figure 2 — Dependency and Secret Boundary
1. Image build with temporary network
2. Pin toolchain and system packages
3. Cache locked repository dependencies
4. Install pytest and optional RewardKit
5. Remove source clone and remotes
6. Agent runs with **no network**
7. Deterministic verifier runs **offline**
8. Optional judge uses separate controlled verifier or post-hoc run

### Generic Dockerfile pattern
```dockerfile
FROM <pinned-language-image>
ARG BASE_COMMIT=<exact-pre-change-commit>
ARG PYTHON_VERSION=3.12
ARG PYTEST_VERSION=8.3.5
ARG REWARDKIT_VERSION=0.1.7

# Install the repository toolchain during image build. RewardKit 0.1.7 needs
# Python 3.12+, so do not assume the language base image is sufficient.
RUN <system-package-install> git ca-certificates ripgrep jq tmux
RUN <install-or-bootstrap-python-3.12>
RUN python3.12 -m venv /opt/verifier-venv \
 && /opt/verifier-venv/bin/python -m pip install --no-cache-dir \
      "pytest==${PYTEST_VERSION}" \
      "harbor-rewardkit[all]==${REWARDKIT_VERSION}" \
 && /opt/verifier-venv/bin/python -c "import pytest, rewardkit" \
 && /opt/verifier-venv/bin/rewardkit --help >/dev/null
ENV PATH=/opt/verifier-venv/bin:<repository-toolchain-path>:/usr/local/bin:/usr/bin:/bin

# Fetch only while building, then export a sanitized worktree without remotes,
# future commits, PR identifiers, solution files, or verifier files.
RUN git clone <repository-url> /tmp/source \
 && git -C /tmp/source checkout --detach "${BASE_COMMIT}" \
 && mkdir -p /testbed \
 && git -C /tmp/source archive "${BASE_COMMIT}" | tar -x -C /testbed \
 && rm -rf /tmp/source
WORKDIR /testbed
RUN <cache-locked-repository-dependencies-and-build-targets>
RUN git init && git add -A \
 && git -c user.name=benchmark -c user.email=benchmark@invalid \
      commit -m "sanitized benchmark base"
RUN mkdir -p /app/output /logs/agent /logs/verifier
CMD ["sleep", "infinity"]
```

**Key rules:**
- RewardKit is optional for a simple single numeric reward, but recommended for weighted criteria / multiple training dimensions / LLM judges.
- Check the interpreter requirement **before** installing RewardKit (Rust/C++/older Linux base may ship only Python 3.11).
- Create an **isolated verifier venv** and put it **first on PATH** so pytest/rewardkit use the intended interpreter without changing the repo toolchain.
- Install verifier deps at image build (or a separate verifier image). **Never** use pip/cargo/npm/Maven/apt network installs during scored verification.
- If judges need an API key, inject it **only** into a separate/post-hoc verifier and allow only the required provider host. The solving agent must NOT inherit the key or judge network.
- Pin versions that passed Oracle and no-op validation. Example versions are a starting point, not an upgrade mandate.

---

## 7. Prompt Contract

### Generic `instruction.md` template
```markdown
# <Natural issue title>

The complete repository is available at `/testbed`.

Describe the observed user or system problem in normal issue language. Include
one small example only when it helps reproduce the symptom. Do not name the
source pull request, golden commit, hidden test, exact function, or patch recipe.

## Required behavior
- State the invariant that must hold after the change.
- State legitimate behavior that must remain supported.
- State important cross-component, compatibility, data, migration, fault,
  performance, ordering, or concurrency constraints.
- Require existing unrelated behavior to remain unchanged.
- Require a coherent repository-level fix, not a hard-coded example.

## Executable engineering evidence
Create under `/app/output`:
1. `reproducer.sh`: an executable offline reproducer whose exit status reflects
   the required behavior.
2. `diagnosis.json`: subsystem, observed invariant, root cause, rejected
   alternatives, and files inspected.
3. `verification.json`: commands run, cases covered, regression suites, and
   remaining risk.

Do not access external services, task-author files, verifier files, Git remotes,
future history, or an upstream solution. Keep the patch mergeable in the full
repository.
```

### Prompt acceptance checks
- A repo maintainer could plausibly file the brief **without mentioning benchmarks or evaluation signals**.
- The prompt clearly distinguishes behavior that **must change** vs. behavior that **must remain supported**.
- The prompt requires a **repository-level outcome** but does not list every file or implementation symbol.
- Every critical deterministic gate traces to a **stated requirement** or ordinary regression expectation.
- Required reports are **secondary evidence**; prose alone cannot rescue executable failure.

### Figure 9 — What the Prompt Reveals and Withholds
**Reveal:** (1) observable symptom → (2) required invariant → (3) legitimate behavior to preserve → (4) operational constraints and artifacts.
**Withhold:** (5) PR and future commit → (6) exact function and patch recipe → (7) hidden variants and reward weights → (8) leave diagnosis and implementation open.

---

## 8. Deterministic Tests & Optional Judges

### Check families

| Check family | Class | Recommended location | What passing proves |
|---|---|---|---|
| Build and startup | Deterministic | `tests/deterministic/test_regression.py` | Repo & target service/binary build offline |
| Fail-to-pass behavior | Deterministic | `tests/deterministic/test_behavior.py` | Original defect fixed across hidden variants |
| Pass-to-pass safety | Deterministic | `tests/deterministic/test_regression.py` | Existing relevant tests & unrelated contracts still pass |
| Integration/data contract | Deterministic | `tests/deterministic/test_integration.py` | Callers, schemas, migrations, persistence, protocols agree |
| Robustness/performance | Deterministic (when stable) | `tests/deterministic/test_integration.py` | Fault, concurrency, resource, rollback, budget behavior holds |
| Architecture requirement | Deterministic **only when prompted** | `tests/deterministic/test_integration.py` | A required obsolete path / dual model is actually removed |
| Executable evidence | Deterministic | `tests/process/check.py` | Reproducer & reports correspond to commands and outputs |
| Repository integrity | Deterministic | `tests/deterministic/test_integrity.py` | No solution/verifier/remote/history/reward tampering |
| Process quality | Non-deterministic | `tests/process/judge.toml` | Trajectory diagnosed, implemented, verified coherently |
| Merge readiness | Non-deterministic | `tests/merge_readiness/judge.toml` | Strict-passing patch is idiomatic, focused, reviewable |
| Trial validity | Non-deterministic | `tests/validity/judge.toml` | Pass/fail is genuine, not leakage or infra error |
| Task quality | Non-deterministic; author-facing | `tests/task_quality/judge.toml` | Prompt, hidden checks, artifacts, intended skill agree |

### Behavior versus patch shape
- **Do NOT** compare the candidate diff with `golden.patch`.
- **Prefer** executable behavior, repository tests, properties, metamorphic variants, fault injection, and integration checks.
- Use **source-shape checks only** when the prompt explicitly requires an architectural removal, public API, migration boundary, or security invariant that behavior alone cannot distinguish.

### Deterministic test design
- **Fail-to-pass:** reproduce the original defect **plus hidden variants** with different names, ordering, values, state, topology, or timing.
- **Pass-to-pass:** run focused existing suites + unrelated contracts most likely to regress.
- **Property/metamorphic:** change irrelevant inputs, execution order, equivalent constraints, serialization form, or retry sequence while preserving the expected result.
- **Integration:** exercise real callers, persistence, schema, migration, protocol, CLI, service, or generated artifacts — not isolated helpers only.
- **Performance/fault:** use deterministic budgets, controlled clocks, seeded schedules, fixed fault points, repeated Oracle baselines; **exclude flaky checks from strict truth**.
- **Integrity:** reject verifier edits, solution access, public remotes, future history, test replacement, reward tampering, and suspicious hard-coded hidden fixtures.

### Figure 3 — Verifier Test Architecture
1. `tests/test.sh` → 2. Build or start repository → 3. Run `test_behavior.py` → 4. Run `test_regression.py` → 5. Run `test_integration.py` → 6. Run `test_integrity.py` → 7. Run executable artifact checks → 8. Write reward and details → 9. Stage bounded evidence → 10. Run optional judges separately.

---

## 9. Reward Shape

| Output | Meaning | Use | Rule |
|---|---|---|---|
| `binary_reward` | Strict benchmark success | Leaderboard & eval pass rate | **1 only when every critical deterministic gate passes** |
| `training_score` | Weighted deterministic progress | Curriculum, credit assignment, near-miss ranking | Never reported as a solved task |
| `valid_trial` | Evaluation boundary intact | Training eligibility & quarantine | Zero for contamination or invalid harness state |
| `fail_to_pass` | Original + hidden behavior repaired | Behavioral learning signal | Derived only from executable checks |
| `pass_to_pass` | Relevant prior behavior preserved | Regression-safety signal | Separate from new behavior |
| `repo_integration` | Cross-component contract coherent | Integration & migration training | Includes real callers or repo scenarios |
| `merge_ready_score` | Quality of a strict-passing patch | Preference data & review research | Zero/unreported unless deterministic success holds |

### Non-deterministic checks
- Judges are useful for diagnosis quality, repo conventions, patch minimality, architecture taste, reviewability, and suspicious trajectory review.
- Give judges **only bounded evidence**: instruction, changed files, patch, selected logs, reward details, declared artifacts, trajectory.
- Run repeated judges or human audits when a score matters. **Judge disagreement = uncertainty, not deterministic truth.**

### Two separate reward passes
- **Pass 1 (offline, in-task):** executable checks + deterministic RewardKit suite.
- **Pass 2 (separate/post-hoc):** process, validity, task-quality, merge-readiness judges.
- **Preserve `reward` and `binary_reward` from deterministic evaluation** even when a judge is unavailable or disagrees.

### RewardKit aggregation (`reward.toml`)
```toml
# Run this aggregation only over deterministic dimensions.
[[reward]]
name = "reward"
aggregation = "threshold"
threshold = 1.0

[[reward]]
name = "binary_reward"
aggregation = "threshold"
threshold = 1.0

[[reward]]
name = "training_score"
aggregation = "weighted_mean"
```

### Verifier entrypoint pattern (`tests/test.sh`)
```bash
#!/usr/bin/env bash
set -uo pipefail
RESULT_DIR="${RESULT_DIR:-/logs/verifier}"
TESTS_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="$TESTS_DIR/deterministic/engine.py"
SUITE_DIR="$RESULT_DIR/deterministic_suite"
REWARDKIT_OUT="$RESULT_DIR/rewardkit_deterministic"
mkdir -p "$RESULT_DIR" /app/output

# First run the real repository checks. The engine writes granular executable
# evidence; it must not fetch dependencies during a scored trial.
python3 "$ENGINE" >"$RESULT_DIR/engine_output.log" 2>&1 || true
cp "$RESULT_DIR/reward.json" "$RESULT_DIR/deterministic-engine-reward.json" 2>/dev/null || true
cp "$RESULT_DIR/reward-details.json" "$RESULT_DIR/deterministic-engine-details.json" 2>/dev/null || true

# Keep conventionally named tests visible to validators and human reviewers.
DETERMINISTIC_DETAILS_PATH="$RESULT_DIR/deterministic-engine-details.json" \
PYTHONPATH="$TESTS_DIR/deterministic${PYTHONPATH:+:$PYTHONPATH}" \
pytest -q -p no:cacheprovider "$TESTS_DIR/test_reward_contract.py" \
  "$TESTS_DIR/deterministic"/test_*.py \
  >"$RESULT_DIR/test_output.log" 2>&1 || true

# RewardKit aggregates only deterministic criteria here. Optional judges are
# deliberately excluded from this suite.
rm -rf "$SUITE_DIR" "$REWARDKIT_OUT"
mkdir -p "$SUITE_DIR/deterministic" "$REWARDKIT_OUT"
cp "$TESTS_DIR/reward.toml" "$SUITE_DIR/reward.toml"
cp "$TESTS_DIR/deterministic/check.py" "$SUITE_DIR/deterministic/check.py"

status=0
DETERMINISTIC_DETAILS_PATH="$RESULT_DIR/deterministic-engine-details.json" \
rewardkit "$SUITE_DIR" --workspace /testbed \
  --output "$REWARDKIT_OUT/reward.json" \
  >>"$RESULT_DIR/test_output.log" 2>&1 || status=$?

# Merge strict RewardKit truth with the executable training vector. The sync
# script writes numeric zero on infrastructure failure instead of no reward.
python3 "$TESTS_DIR/sync_reward.py" "$RESULT_DIR" "$REWARDKIT_OUT" "$status"

# Optional process, validity and merge-readiness judges run separately or
# post-hoc. They must never overwrite binary_reward or rescue deterministic
# failure.
exit 0
```

### Figure 4 — Strict Evaluation and Training Reward
1. Validate trial integrity → 2. Run critical deterministic checks → 3. Compute strict all-pass condition → 4. Set `binary_reward`: 1 only if all pass, else 0 → 5. Preserve weighted check vector → 6. Optional process & merge-readiness judges → 7. Export labeled training record.

---

## 10. Authoring and Acceptance

- Select **stateful, cross-component work** (runtime behavior, data contracts, migrations, concurrency, performance, faults, compatibility) rather than patch size alone.
- Keep the exact PR, issue, merge commit, and Oracle **private** for provenance; remove all of them from the agent-visible image and prompt.
- Require **Oracle success in repeated clean builds** and **no-op failure in every run**.
- Seed **≥3 plausible near misses**: narrow symptom patch, over-broad behavior change, incomplete integration/regression update.
- Confirm hidden verifiers **reject ≥90% of authored near-miss mutations** before accepting the task.
- Calibrate **multiple frontier agents**; investigate trajectories, not only aggregate scores.
- **Freeze** the prompt, base image, verifier, dependency versions, and task checksum together.

### Figure 8 — Task Acceptance Funnel
1. Real recent change and protected base
2. Oracle passes repeatedly
3. No-op always fails
4. Seeded partial patches fail named gates
5. Hidden variants reject shortcuts
6. Guided run proves solvability
7. Unguided frontier calibration
8. Freeze prompt, image, verifier, and checksum

---

## 11. Evaluation-to-Training Use

- Export full **trajectories, repository snapshots or patches, commands, test outputs, reward events, artifacts, failure labels, contamination labels, and optional judge reasoning**.
- Retain **valid failed trials and near misses** — they show localization, implementation, regression, or integration boundaries.
- Create **pairwise preferences only from comparable valid trials** (e.g. strict pass vs. near miss, focused patch vs. bloated strict pass).
- **Never train on an active evaluation instance.** Separate training and evaluation by **repository, time window, hidden variant, and task checksum**.

### Figure 5 — Evaluation-to-Training Handoff
1. Capture trajectory, patch, logs, artifacts
2. Attach deterministic reward events
3. Attach optional quality scores
4. Classify model, verifier, timeout, contamination failures
5. Quarantine invalid trials
6. Separate repositories, time windows, variants
7. Create SFT, preference, or RL records
8. Publish a provenance manifest

---

## 12. Worked Example (UV task — example, NOT a template)

The earlier UV task is a useful **calibration case** (based on a real Rust resolver migration). Apply the generic package/verifier rules to any suitable repo and language.

| Example fact | Observed value | Lesson |
|---|---|---|
| Source | UV PR #20302 at exact pre-change commit | Use real provenance privately; sanitize from solving env |
| Scope | Resolver behavior, repo scenarios, CLI/settings, generated schema & docs | Grade one contract across multiple repo representations |
| Oracle | Strict deterministic pass | Author solution must prove repeatable solvability |
| Frontier trial | 13/16 checks; strict 0; weighted training score 0.70 | Partial vectors explain progress without inflating pass rate |
| Failure families | Architecture cleanup, repo scenarios, doc/schema consistency | A local fix isn't enough if the full repo stays inconsistent |
| Patch identity | No comparison with `golden.patch` | Evaluate behavior & declared architecture, not line similarity |

### Fresh-container validation (example calibration record, not universal targets)

| Trial | Observed result | What it proves |
|---|---|---|
| No-op | `binary_reward` 0.0; `training_score` 0.51; `valid_trial` 1.0; `rewardkit_available` 1.0 | Untouched repo fails strict behavior but yields a valid partial vector |
| Oracle | All 16 deterministic criteria passed; binary_reward, training_score, integration, regression, process = 1.0 | Author solution solvable through full executable + RewardKit path |
| Runtime | Python 3.12.13; pytest 8.3.5; harbor-rewardkit 0.1.7; Rust 1.97 | A non-Python repo can carry a separate pinned verifier runtime |
| Network policy | One `allow_internet = false` baseline; no phase override | Agent & verifier inherit one startup policy |
| Discovery | Five `test_*.py` modules + `test.sh` + `reward.toml` | Package is validator-visible while retaining a richer engine |

---

## 13. Final Author Checklist

- [ ] `task.toml` uses `schema_version 1.3` and declares `metadata.benchmark_type = "swe-bench"`.
- [ ] `environment.allow_internet = false` and agent/verifier sections do **not** override network policy.
- [ ] `tests/test.sh`, `tests/reward.toml`, and ≥1 `tests/deterministic/test_*.py` are present in the packaged artifact.
- [ ] Verifier interpreter satisfies RewardKit's requirement; pytest/rewardkit resolve from the pinned isolated env.
- [ ] Full repo + all locked deps build **without network** during the scored run.
- [ ] Prompt states behavior, preserved contracts, constraints, and executable evidence **without revealing provenance or a patch recipe**.
- [ ] Critical deterministic checks cover fail-to-pass, pass-to-pass, integration, artifacts, and integrity.
- [ ] Source-shape checks exist only for explicitly required architecture or security boundaries.
- [ ] Optional judges are bounded, reproducible where possible, and unable to change binary truth.
- [ ] Oracle, no-op, seeded near misses, guided runs, and multiple frontier trials all reviewed.
- [ ] Every verifier exit path writes a numeric reward and enough logs to classify failure.
- [ ] Training exports separated from active evaluation repositories, windows, variants, and checksums.

---

## 14. Source Map

Harbor task & RewardKit guidance checked against official docs on **July 13, 2026**. Source-change identity belongs in private author provenance or a worked example — **not** in the protected agent instruction.

| Source | URL | Used for |
|---|---|---|
| SWE-bench | swebench.com | Issue-to-patch repo evaluation; keep executable behavior + pass-to-pass safety |
| SWE-Bench Pro | labs.scale.com | Professional repos, reproducible containers, protected splits |
| Senior SWE-Bench | senior-swe-bench.snorkel.ai | Natural briefs, runtime verification; separate correctness from merge readiness |
| Senior SWE-Bench tasks | github.com | Concrete Harbor-compatible packages; reuse package discipline + contamination controls |
| Harbor task docs | harborframework.com | Task/agent/environment/verifier/reward/artifact model |
| Harbor task structure | harborframework.com | Required instruction/env/solution/`test.sh` + numeric reward contract; absolute container paths |
| Harbor RewardKit | harborframework.com | Programmatic + judge criteria, reward dimensions, `reward.toml` aggregation |
| Harbor task tutorial | harborframework.com | Discoverable `test_*.py` convention + Oracle/no-op workflow |
| UV worked example | github.com | Real full-repo Rust resolver change; retain as example only |

---

## Quick Mental Model (memorized principles)

1. **Behavior is truth, not the diff.** Never grade against `golden.patch`.
2. **One protected session, one complete repo, exact pre-change commit.**
3. **Strict binary pass** requires *all* critical deterministic gates; **judges never rescue** a broken build.
4. **Offline by default:** one `allow_internet = false` baseline; no phase-level `network_mode`.
5. **Sanitize hard:** no remotes, future history, PR IDs, solution, or verifier files in the agent image.
6. **Always emit a numeric reward** on every verifier exit path (fall back to 0).
7. **Near misses & valid failures are gold** for training — keep them labeled and separated from eval.
8. **Prompt reveals symptom + invariants + constraints; withholds PR, function, patch recipe, hidden variants, reward weights.**
9. **Freeze everything together:** prompt, image, verifier, dep versions, checksum.
10. **Acceptance gates:** Oracle passes repeatedly, no-op always fails, hidden variants reject ≥90% of near-miss mutations, frontier headroom ~20–60%.
