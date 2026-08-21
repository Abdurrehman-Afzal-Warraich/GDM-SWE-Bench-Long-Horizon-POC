# Tier 2 Multi-Step Long-Horizon Task — Authoring Reference (authoritative)

Source of truth distilled from:
- `more resources/swe_multi_step_long_horizon_guide.pdf` (29-page guide)
- Official Harbor multi-step docs (`more resources/Multi-step Tasks.txt` / harborframework.com/docs/tasks/multi-step)
- Working sample `more resources/sample-duckdb-tier2/` (duckdb-index-vacuum-tier2, based on DuckDB PR #23653)
- `more resources/SWE_multistep_long_horizon_task_review_checklist.xlsx` (Task Review + Final Review)

This file is the checklist I author and self-review every Go task against.

---

## 1. What a Tier 2 task is

One **real** software change carried out over several **stages** in the **complete repository**. Code/services/artifacts **persist** between stages; the agent gets a **fresh briefing** (and typed handoff) each stage. Phases feel like real engineering: **diagnose → implement → review/integration → harden/close**.

**Long horizon ≠ big patch or slow build.** It means: earlier decisions have later consequences, new evidence appears after work is done, and the final result must stay correct as difficulty grows (cumulative closure).

**The simple rule:** code must pass **executable deterministic checks at every stage**. LLM (RewardKit) judges only score process/quality/validity — they can **never** turn broken behavior into a pass.

---

## 2. Hard rules (non-negotiable)

- **Repo language:** C/C++, Rust, **Go**, TypeScript/JavaScript, or Java/Kotlin. **No Python repository tasks.** (The verifier/harness itself may be Python — that's fine.)
- **License must be one of:** Apache 2.0, CC BY 4.0, CC BY-SA 4.0, CC BY-NC 4.0, GNU GPL, BSD 2.0, BSD 3.0, MIT.
- **Recent, real merged PR / issue / incident** with an exact **pre-change base commit** that still builds and shows the old behavior.
- **Contamination control:** agent must NOT see PR number/title/URL, golden patch, hidden tests, solution files, future git history. Repo image = one synthetic commit, no origin/remotes/tags/useful reflog.
- **Deterministic-first:** required behavior decides promotion. Real commands/APIs/files/outputs — no exact patch/AST/filename/prose matching (unless that exact form is itself a public requirement).
- **Reward is strict binary:** `reward = binary_reward = 1` **only if** every required deterministic check passes **AND** `valid_trial = 1` (integrity ok); else `0`.
- **Headroom target:** ~**5–20% strict solve rate** on the fixed solving-agent runs.
- **Offline:** verifier may use internet only for the RewardKit provider; solving-agent network use is prohibited and trajectory-audited. Tests must run without public internet/private services.
- **Go strong domains** (from guide): controllers, networking, cloud/distributed systems, reconciliation loops, retry policy, API compatibility, concurrent workers, service recovery. Strong Go checks: fake clocks, local control planes, bounded race tests, retry/failure injection, API regressions. **Reject** a Go change that is one isolated handler condition with no system consequence.

---

## 3. Exact package structure (from the working sample)

```
<task-name>/
|-- task.toml                      # Harbor metadata, steps, limits, verifier.env, reward strategy
|-- README.md                      # author/operator notes (may reference PR — author-only)
|-- environment/
|   `-- Dockerfile                 # full sanitized repo at base commit + pinned tools + verifier venv
|-- steps/
|   |-- 01-diagnose/
|   |   |-- instruction.md         # stage briefing (behavior + evidence, NOT implementation)
|   |   |-- tests/test.sh          # thin launcher: `bash /tests/stage_test.sh <stage>`
|   |   `-- solution/solve.sh      # author-only Oracle for this stage
|   |-- 02-<core>/
|   |   |-- instruction.md
|   |   |-- tests/test.sh
|   |   `-- solution/
|   |       |-- solve.sh           # applies /solution/golden.patch + writes artifacts
|   |       |-- golden.patch       # stage-scoped patch (disjoint file set per stage)
|   |       `-- provenance.json    # repo, PR, base/head/merge commits, patch_sha256
|   |-- 03-<review>/ ...
|   `-- 04-<harden>/ ...
`-- tests/                         # PROTECTED — never visible during agent work
    |-- stage_test.sh              # single verifier entrypoint for all stages
    |-- stage_check.py             # all deterministic stage checks + reward emission
    |-- score_formula.py           # shared scoring primitives (D/N, lambda, binary)
    |-- stage_judge_inputs.py      # builds bounded evidence bundle for judges
    |-- run_optional_judges.sh     # runs RewardKit judges (agent trials only)
    |-- merge_rewardkit_scores.py  # folds judge scores into training_score only
    |-- test_reward_contract.py    # pytest self-tests of the whole package (discovery/fairness)
    |-- <fixtures>.test            # protected hidden test fixtures (behavior, novel values)
    |-- judge_prompt.md            # shared judge authority rules
    |-- process/judge.toml         # process-quality rubric
    |-- validity/judge.toml        # leakage / anti-cheating rubric
    |-- merge_readiness/judge.toml # final patch quality (only after strict final pass)
    `-- task_quality/judge.toml    # author-side audit (excluded from agent training score)
```
Optional `tools/run_inline_judged_terminus.sh` — convenience runner (Harbor >= 0.8).

---

## 4. task.toml contract (from sample + guide)

```toml
schema_version = "1.3"                 # sample uses 1.3; official docs describe 1.4 (per-step healthcheck etc.)
multi_step_reward_strategy = "final"   # final stage's reward dict is the trial reward

[task]
name = "long-horizon/<slug>"
description = "..."
keywords = [...]

[metadata]
benchmark_type = "swe-bench"
category = "software-engineering"
language = "go"                        # our stream
tier = "stateful-long-horizon-engineering"
repository = "<owner/repo>"
base_commit = "<exact pre-change SHA>"
source_pull_request = "<author-only URL>"   # NEVER exposed to agent
judge_model = "anthropic/claude-sonnet-4-6" # or gemini/gemini-3.6-flash — ONE choice everywhere
reward_formula = "strict deterministic binary reward"
training_score_formula = "(D_num + lambda*N_num)/(D_den + lambda*N_den)"

[verifier.env]                         # declare BOTH provider keys + lambda
ANTHROPIC_API_KEY = "${ANTHROPIC_API_KEY:-}"
GEMINI_API_KEY = "${GEMINI_API_KEY:-}"
NONDETERMINISTIC_LAMBDA = "${NONDETERMINISTIC_LAMBDA:-0.0}"

[environment]
build_timeout_sec = 7200.0             # sample used 14400 for DuckDB; size to measured build
allow_internet = true                  # verifier needs it for RewardKit; audit agent traffic
cpus = 8
memory_mb = 16384
storage_mb = 65536
env = { ..., RUN_LLM_JUDGES = "1", JUDGE_MODEL = "...", JUDGE_REPEATS = "2", JUDGE_TIMEOUT_SEC = "300" }

[[steps]]
name = "01-diagnose"
min_reward = 1.0                       # promotion gate: abort trial if below
artifacts = ["/app/output/handoff.json", "/app/output/01-diagnose"]
[steps.agent]
timeout_sec = 7200.0
[steps.verifier]
timeout_sec = 1800.0
# ... repeat for 02/03/04. Final stage usually has no min_reward.
```

- **Promotion gates (`min_reward`):** use `1.0` when all required checks are strict binary; sample used `1.0` for diagnose then `0.85` for core/review (still strict-binary reward internally, but the training-score gate tolerates partial). Below threshold → trial aborts; partial progress still retained for training.
- **Artifacts** are snapshotted per step into `steps/{name}/artifacts/`.
- **`--resume-trajectory`** is a run-level flag, not a task field: default is fresh context per stage (which is what long-horizon wants, forcing typed handoffs).

---

## 5. Dockerfile pattern (sanitized base + verifier venv)

1. Base image with build toolchain (for Go: `golang:<pinned>` + git, jq, ripgrep, etc.).
2. `git clone --filter=blob:none --no-tags`, `checkout --detach <BASE_COMMIT>`, `git archive | tar -x` into `/testbed`, then **delete the clone** (removes remotes/history).
3. Pre-build the test target(s) so the environment ships warm (for Go: `go build ./...` / `go test -c` of target packages, or prime the module cache).
4. `git init && git add -A && git commit -m "sanitized benchmark base"` → single synthetic commit, no origin.
5. Separate **verifier venv** (`/opt/verifier-venv`) with `pytest` + `harbor-rewardkit[all]` pinned; put it first on PATH.
6. `mkdir -p /app/output /logs/agent /logs/verifier`; assert build artifacts + tools exist. `CMD ["sleep","infinity"]`.

---

## 6. Verifier engine (`stage_check.py`) mechanics

- One function per stage (`diagnose/core/review/harden`) fills a `checks` dict `{name: {passed, detail}}` and returns that stage's **weight map** (weights sum to 1.0).
- `CRITICAL_CHECKS[stage]` = the subset that must pass for `critical_pass` (excludes prose/handoff artifacts).
- **`required_checks_pass`** = all weighted checks passed. `binary_outcome(required_checks_pass, integrity_ok)` → 0/1.
- **Integrity is a hard gate:** if integrity fails, `D_num` forced to 0, `training_score` = 0, `valid_trial` = 0.
- Emits: `reward.json` (reward, binary_reward, training_score, valid_trial, stage_complete, critical_pass, promotion_ready, + stage-specific dims), `reward-details.json` (per-check detail, weights, scoring breakdown, changed_files), `reward-events.json` (granular events), `reward.txt` (1D reward), `training_export_manifest.json`.
- **Protected/generated tests are injected ephemerally:** copy fixture into a `tempfile.TemporaryDirectory` under `test/<group>/`, run the language's test runner pointed at it, delete after. Agent never sees them on disk.
- **`require_discovered_test`:** treat "No tests ran / No test cases matched" as a **deterministic failure** (returncode≠0), so an empty run can't pass.
- **Seeded generated variants:** `random.Random(seed)` produces novel cases (different sizes/keys/targets than the public PR). Same seed → reproducible; different seed → different cases. This is the anti-overfit layer.
- **Behavior, not symbols:** verifier must NOT reference the golden patch's class/function/variable names (there's an explicit self-test enforcing this).
- **Typed handoff checks:** JSON artifacts validated by alias contract (accept historical field-name aliases) and by exact typed decision values where disclosed (e.g. strategy enums, booleans).

---

## 7. Scoring (`score_formula.py`) + judges

```
D_num = sum(weight_i for passed deterministic checks)   # 0 if integrity fails
D_den = sum(all applicable deterministic weights)
D_score = D_num / D_den

N_num/N_den = weighted RewardKit rubric scores (agent trials only)
training_score = (D_num + lambda*N_num) / (D_den + lambda*N_den)   # clamped [0,1]
  - lambda = 0 (default) OR no judge applicable  => training_score = D_score
reward = binary_reward = 1 iff required_checks_pass AND integrity_ok, else 0
```
- `lambda` **never** changes reward/binary_reward/stage_complete/promotion/validity.
- **RewardKit judges** (one model choice, used in every judge.toml):
  - `process` — investigation/evidence/verification discipline (stage-scoped; don't demand later-stage work early).
  - `validity` — leakage/cheating/fabrication/prompt-mismatch **flags** (cannot invalidate alone; needs independent evidence).
  - `merge_readiness` — only on the **final valid agent pass**; conventions/maintainability/scope/bloat.
  - `task_quality` — **author audit only**, excluded from agent training score.
- Judges run after deterministic truth, twice (`JUDGE_REPEATS`), and cannot gate. Oracle runs **skip** all judges (judge-only fields = N/A / null).

---

## 8. Integrity / anti-cheating gate

Repository check: no changes under `.git/`, `solution/`, `tests/`; no `[remote "..."]` or `url =` in `.git/config`; `/testbed/solution` and `/testbed/tests` must not exist.
Process check (trajectory command audit) flags: `curl`/`wget`, network clients (`nc`,`ssh`,`scp`,`gh api|repo|pr|issue`), reads of `/tests` or `/solution`, verifier temp paths, `git remote|reflog|fetch|pull|clone|ls-remote`, runtime package installs (`apt/pip/npm/cargo/brew install`). Missing agent trajectory (non-Oracle) = not compliant.
Allowed: read-only `git log`/`git show` (sanitized base only), reading supplied repo + prior-stage output + normal local test failures.

---

## 9. Stage design (typical 4 stages)

- **01 diagnose:** no production changes. Build an **executable reproducer** that proves the old behavior is missing/broken (real result mismatch, not parser/catalog error, not "no tests ran"). Emit a **typed handoff.json** (invariant, evidence, boundaries, risks, next-stage checks + disclosed typed decisions). Weights: reproduction dominant (~0.65), base-behavior observed (~0.25), handoffs small (~0.10). All checks critical.
- **02 core:** implement the main behavior + focused repo tests. Checks: primary behavior (largest weight), hidden variants/properties, focused pass-to-pass, incremental build, handoff-consumed + implementation report (small, non-critical). Golden patch for this stage covers the core files.
- **03 review/integration:** introduce **new evidence** (review/CI/concurrency/compat/downstream). Verifier reruns important earlier behavior **plus** the new case. Prose review response earns credit only if it matches actual changes + executable output.
- **04 harden/close:** faults, concurrency (bounded/seeded, not flaky stress), performance (fixed threshold + warmup), migration/rollback on real fixtures, plus **agent-authored visible regression tests** (bounded count), patch hygiene (no build artifacts, bounded changed-file count), and a **cumulative re-run of all critical earlier behavior**. Final success needs every deterministic check + integrity.

Instruction.md style: state **behavior + success condition + artifact contracts + evidence**, never the implementation, class/function names, or the patch shape. Explicitly say equivalent designs pass and Oracle symbols are not required.

---

## 10. Oracle & golden patches

- Each stage's `solution/solve.sh` applies `/solution/golden.patch` (mounted only in trusted Oracle runs) and writes that stage's required artifacts.
- Golden patches are **stage-scoped and disjoint** (no file appears in two stages); together they cover **all** upstream changed files. `provenance.json` records repo/PR/commits and `patch_sha256` (self-test verifies the hash and disjointness and total file count).
- Oracle must pass every stage **legitimately** without touching tests/verifier/reward files.

---

## 11. Release controls (run before shipping)

| Control | Expected |
|---|---|
| Oracle × ≥3 | Every deterministic stage + final closure passes each time |
| Clean no-op | Fails the first real behavior gate (not on infra) |
| Compile-only patch | Fails runtime behavior |
| Partial patch | Fails the exact missing requirement |
| Visible-fixture hard-code | Fails hidden/generated variants (≥90% of near-misses fail intended family) |
| Regression patch | Fails pass-to-pass / integration |
| Valid alternative patch | **Passes** all behavior (else it's golden-patch matching) |
| Package discovery | Harbor finds every stage test; RewardKit discovery + parser + `test_reward_contract.py` pass |

Split training vs eval by repository, time window, variant, and checksum.

---

## 12. CHECKLIST — Task Review (use BEFORE agent runs)

Criticality in parentheses. Each must be satisfied with evidence.

**Authenticity & Value**
- (Critical) Based on real expert work — real issue/latest PR/incident/research/ops need; meaningful, not synthetic scaffolding.
- (High) Credible difficulty & headroom — a capable expert needs sustained diagnosis/impl/test/revision; not hard only because build is slow.
- (Critical) Contamination controlled — public solutions, old benchmark tasks, future git, PR ids, reference code, memorable answers unavailable to agent.

**Prompt & Stage Design**
- (Critical) Overall objective clear — required behavior/scope/constraints/success stated without revealing implementation.
- (High) Stage count matches real workflow (≥3 meaningful; add/merge by real work, not fixed count).
- (Critical) Every stage adds new work/evidence — removing it removes signal.
- (Critical) Every stage prompt sufficient & fair — enough context, no hidden requirements, no exposed answer.
- (Critical) State, context, handoffs defined — repo/services persist; fresh context each stage; next stage can verify+use a bounded handoff.
- (Critical) Final stage closes the whole task — reruns critical earlier behavior, regressions, integration, integrity, required hardening.

**Package & Configuration**
- (Critical) task.toml complete & consistent — metadata, benchmark type, ordered steps, timeouts, resources, network policy, artifacts, verifier env, reward settings agree.
- (Critical) Full repo pinned & resettable — exact base commit, deps, services, data, build tools reproduce from clean env.
- (High) Time/resource limits usable — measured build/test fit CPU/mem/storage/timeout with headroom.
- (Critical) Protected boundary effective — hidden tests, verifier code, Oracle, solution patches, git history, remotes, keys, reward internals outside agent access.
- (Critical) Harbor & RewardKit discover everything — stage tests, entrypoints, reward fields, judge config, provider keys, lambda load without warnings/parser errors.

**Oracle & Controls**
- (Critical) Oracle solves every stage legitimately (no test/verifier/reward edits).
- (Critical) Oracle & no-op repeatable — repeated clean Oracle passes; unchanged repo fails at intended functional gate, not infra.
- (High) Plausible near-misses/shortcuts fail (partial fixes, hard-codes, fake wrappers, mocks, shortcut patches fail what they missed).

**Deterministic Tests**
- (Critical) Each stage tests its requested behavior via executable behavior (not text/patch/filename/AST/wording).
- (High) Normal, edge, invalid, fault cases covered.
- (Critical) Integration & regressions covered across real boundaries; existing behavior preserved.
- (Critical) Every major requirement mapped to a deterministic test or explicitly judge-only.
- (Critical) Cheating & fixture-specific fixes rejected (hidden variants + integrity).
- (Critical) Tests stable & independent — reproducible, order-independent, bounded, no stale state/flaky timing.

**Reward & Judge**
- (Critical) Deterministic gates control pass/fail — required functional checks alone control promotion & binary reward.
- (High) Weights reflect meaningful progress — main behavior most weight; build/files/prose proportionate.
- (High) LLM judge limited to suitable criteria (process/validity/merge-readiness from bounded evidence; not a functional gate).
- (Critical) Lambda & Oracle fields correct — training_score in [0,1]; lambda never changes binary reward; judge/lambda fields N/A for Oracle.

---

## 13. CHECKLIST — Final Review (use AFTER Oracle/agent runs)

**Run Validity** (Critical/High): intended task+models used; environment initialized & stayed usable; every required verifier & judge ran (no silent skips); evidence package complete & consistent (trajectory, patch, stage snapshots, handoffs, logs, reward events, final result).

**Stage & Trajectory Evidence**: real long-horizon work (distinct phases); each stage completed its asked work before promotion (Critical); persistent state & handoffs worked; agent responded correctly to new evidence without breaking earlier work; final closure reran the accumulated contract (Critical).

**Deterministic Result**: decisive failures are functional & reproducible (Critical); stage checks based only on stated requirements — no failure for unstated behavior/wording/name/path/format/method (Critical); partial credit proportional; result fields (reward, binary_reward, deterministic_score, stage_complete, valid_trial, terminal stage, failure reason) agree with logs (Critical).

**LLM Judge Result**: applicability handled correctly (Oracle/merge-readiness/lambda N/A when not applicable); judge used fair bounded evidence; judge output non-gating & parseable.

**Fairness & Root Cause** (Critical): rule out unstated/brittle requirement causing failure; rule out infra/flakiness via control/repeat evidence; failure classified (Agent / Task-design / Grader / Environment-runner / Mixed-Uncertain) only after decisive cause.

**False Positive & Cheating** (Critical): agent avoided hard-coding/fake execution (works on hidden variants, real deps); avoided protected/public answer sources (no test/grader edits, hidden-artifact reads, future git, solution access, suspicious public-patch reuse); trajectory technically credible.

**Final Decision** (Critical/High): evidence-based verdict (valid pass / valid agent failure / invalid run / task issue / grader issue / infra issue / uncertain) with decisive evidence; clear next action (keep / rerun / repair task / repair grader / change infra / reject); confirm task still provides useful model headroom for substantive reasons.

---

## 14. Run commands (reference)

```bash
# Oracle (deterministic control; RewardKit skipped; judge fields N/A)
harbor run -p ./<task-name> -a oracle --jobs-dir /root/harbor-jobs --job-name <task>-oracle-v1 --yes

# No-op control (must fail first real gate)
harbor run -p ./<task-name> -a nop  --jobs-dir /root/harbor-jobs --job-name <task>-nop-v1 --yes

# Solving agent = gemini/gemini-3.6-flash (terminus-2); judge = one chosen model in every judge.toml
export GEMINI_API_KEY=...; export ANTHROPIC_API_KEY=...; export NONDETERMINISTIC_LAMBDA=0.0
harbor run -p ./<task-name> -a terminus-2 -m gemini/gemini-3.6-flash \
  --jobs-dir /root/harbor-jobs --job-name <task>-agent-v1 \
  --ve GEMINI_API_KEY="$GEMINI_API_KEY" --ve ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  --ve NONDETERMINISTIC_LAMBDA="$NONDETERMINISTIC_LAMBDA" --yes
```
Read results: `result.json` → `steps/*/verifier/reward.json` → `reward-details.json` → `test_output.log` → `reward-events.json` → `judge_status.json` → `trajectory.json`/`patch.diff`.

---

## 15. Implications for our current Go pick (k8s #140000)

- Go is an allowed repo language; Kubernetes is Apache-2.0 (allowed). ✅
- The sample's own PR was **31 files / +1303** — so the "25+ files" bar is a *floor*, comfortably met by #140000 (85 files). Substance/headroom matter more than raw count.
- k8s scheduler/kubelet **unit tests are offline & deterministic** → good fit for `stage_check.py`-style executable checks; the PR's integration/e2e tests (need etcd) are excluded from deterministic gates.
- Main risk to manage: **build weight** (k8s checkout ~1 GB). Scope compile/tests to `pkg/scheduler/...` + `pkg/kubelet/preemption`; size `build_timeout_sec`/resources to measured values (sample allowed up to 4h build).
- Must produce: seeded/novel hidden scheduler scenarios (not copied from the PR's tests), 4-stage split with disjoint golden patches, typed handoffs, Oracle ×3 + no-op + partial + valid-alternative controls, and pass `test_reward_contract.py`-style packaging self-tests.
- **Gate reminder:** do not begin authoring any task package until the user explicitly confirms the specific PR.
