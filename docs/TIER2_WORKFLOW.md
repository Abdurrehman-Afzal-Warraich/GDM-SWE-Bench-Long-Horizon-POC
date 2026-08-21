# Tier 2 — Stateful Multi-Step Repo Engineering Task Workflow (Go Stream)

> Distilled from `Resources/tier2_stateful_repo_engineering_task_guide_v3.pdf` + the friend's `.cursor/rules`. **This is the CURRENT PRIORITY** (supersedes the Tier 1 single-step focus). Companion to `WORKFLOW.md` (Tier 1), `SELF_REVIEW_AUDIT.md` (audit rubric), and `PROJECT_CONTEXT.md`.

---

## 0. What a Tier 2 task is

One engineering assignment **split into ordered stages**. Each stage starts with a **fresh agent context**, but the **repository, services, and explicit handoff files persist**. It measures whether useful engineering work **survives context boundaries** — diagnose → implement → respond to feedback → recover/harden the same system over time.

| Property | Tier 2 requirement | Why |
|---|---|---|
| Repository | Complete production-scale worktree at exact pre-change commit | Real navigation/build/test/integration complexity |
| State | Repo + services persist across stages | Measures durable work, not isolated answers |
| Context | **Fresh agent context per stage** | Tests handoffs & reconstruction of engineering state |
| Feedback | Later prompts reveal review/CI/production/fault evidence | Measures response to new information |
| Evaluation | Per-stage gates + cumulative final deterministic closure | Allows recovery without weakening final correctness |
| Target headroom | **~5–20% strict frontier solve rate** after calibration | Room above current single-session systems |

**vs Tier 1:** Tier 1 = one brief, one context, one final repo. Tier 2 adds **temporal/stateful** signal across fresh contexts. **vs Senior SWE-Bench:** same real-repo quality bar, but evolves the task across stages (diagnosis → implementation → review/CI → hardening).

**Borrow from Senior SWE-Bench:** natural issue briefs, behavioral fail-to-pass/pass-to-pass (accept multiple valid impls), quality judges on bounded evidence, repeated Oracle/no-op/guided/near-miss/frontier calibration, strict internet controls + trajectory review.
**Tier 2 adds:** fresh context per stage; a **typed handoff artifact** later stages consume; new evidence revealed only after earlier work; **promotion thresholds** that let a bounded near-miss continue (to test recovery); per-stage reward events/snapshots; a **cumulative final verifier** that closes earlier gaps before strict success.

---

## 1. The 4 stages (reusable pattern — not rustls-only)

| Stage | Deterministic truth | Process / anti-cheat | Non-deterministic review |
|---|---|---|---|
| **1. Diagnose** | Reproduce real base failure; prove base state; validate typed diagnosis + executable evidence; confirm production change NOT applied | No source-history/network/verifier access; no production edit; reproducer executable, offline, can't swallow failure | Process: evidence-before-conclusion. Validity: no fabricated logs/leak. Task-quality: every strict contract disclosed |
| **2. Core change** | Fail-to-pass behavior; focused pass-to-pass; external/public contract; feature/config matrix; handoff consumed | No compatibility shim evading the boundary; no protected-test edits; exact changed-file+command audit; deferred work honestly reported | Process: handoff use, localization, verification, uncertainty. Validity: no reward gaming/hidden 2nd path/unsupported completion claim |
| **3. Review/integration** | Reviewer/CI case fixed; downstream consumers/services pass; old path removed where required; regression + migration/compat pass | Feedback not pre-revealed; project tests not weakened; integration evidence verifier-generated; persistent artifacts untampered | Process: response to feedback + cross-component reasoning. Validity: no selective test filtering / concealed debt |
| **4. Harden/final** | Hidden/property variants; fixed faults; performance budget; rollback/recovery; broad pass-to-pass; **cumulative final contract** | Recheck ALL earlier boundaries; audit final patch/history/network/tests/artifacts/trajectory; no late shortcut restoring obsolete path | Process + validity + task-quality. **Merge-readiness only after deterministic pass**: minimality, conventions, architecture, tests, operability |

Stage split rule: Stage 1 = executable reproducer + structured decision (not just a doc); Stage 2 = one coherent load-bearing boundary, defer broader integration; Stage 3 = reveal new reviewer/CI evidence + repo-wide integration; Stage 4 = faults/rollback/performance/migration + close all earlier gaps. Each stage leaves evidence useful to the next context + a reward-event vector useful to training.

---

## 2. Recommended Harbor package (multi-step layout)

```
<task-name>/
├── task.toml                 # shared config, ordered steps, gates, final strategy, limits
├── README.md                 # author-facing runbook (NOT an agent prompt)
├── environment/Dockerfile    # sanitized full repo + pinned verifier runtime
├── tests/                    # shared PROTECTED verifier helpers
│   ├── stage_test.sh          # runs deterministic stage check, then optional judge
│   ├── stage_check.py         # executable checks, weights, reward events, manifests
│   ├── stage_judge_inputs.py  # stages bounded evidence for RewardKit
│   ├── run_optional_judges.sh # stage-aware Gemini judge runner
│   ├── test_reward_contract.py# discoverable package + judge-selection self-tests
│   ├── hidden_<behavior>.{go,rs,py}  # verifier-owned hidden behavior cases (Stage 4)
│   ├── judge_prompt.md        # shared bounded judge instructions
│   ├── process/judge.toml     # reasoning & evidence quality
│   ├── validity/judge.toml    # leakage, shortcuts, failure classification
│   ├── task_quality/judge.toml# author-facing prompt/verifier alignment
│   └── merge_readiness/judge.toml # final code quality; cannot rescue failure
├── steps/
│   ├── 01-diagnose/
│   │   ├── instruction.md      # fresh Stage 1 brief
│   │   ├── tests/test.sh       # exec bash /tests/stage_test.sh diagnose
│   │   └── solution/solve.sh   # author-only Stage 1 Oracle
│   ├── 02-core-*/
│   │   ├── instruction.md
│   │   ├── tests/test.sh       # exec bash /tests/stage_test.sh core
│   │   └── solution/{solve.sh, golden.patch, provenance.json}
│   ├── 03-review-integration/
│   │   ├── instruction.md
│   │   ├── tests/test.sh       # exec bash /tests/stage_test.sh review
│   │   └── solution/{solve.sh, golden.patch, provenance.json}
│   └── 04-hardening-final/
│       ├── instruction.md
│       ├── tests/test.sh       # exec bash /tests/stage_test.sh harden
│       └── solution/{solve.sh, golden.patch}
└── tools/
    └── run_inline_judged_terminus.sh  # Harbor 0.8+ wrapper: agent + inline judges
```

**Critical layout rules (from rustls sample + friend's notes):**
- **NO root `instruction.md` / root `solution/`** — adding them makes an older Harbor runner misclassify as single-step. Use **Harbor 0.8+** (installation here is 0.20+).
- Provenance lives **inside per-step** solution dirs; `golden.patch` duplicated in steps 2, 3, 4.
- Judge dirs at `tests/<dimension>/judge.toml` (NOT `tests/judges/<dimension>/`).
- `test_reward_contract.py` is **mandatory** (verifier self-validation).
- `hidden_*` test file at `tests/` level, copied by verifier at runtime.
- Step `test.sh` = `exec bash /tests/stage_test.sh <stage-name>`.
- No `export_surefire_artifacts.py` — data-os reads `reward.json` directly.

---

## 3. task.toml schema

```toml
schema_version = "1.3"                    # NOT 1.4
multi_step_reward_strategy = "final"

[task]
name = "long-horizon/<org>__<repo>-<pr_number>"
description = "Stateful full-repository work across diagnosis, implementation, review, and hardening."
keywords = ["repo-engineering", "stateful", "multi-step", "tier-2", "<language>"]

[metadata]
benchmark_type = "swe-bench"
category = "software-engineering"
language = "go"
tier = "stateful-long-horizon-engineering"
repository = "<org>/<repo>"
base_commit = "<sha>"
source_state = "complete repository worktree at the exact pre-change commit"
expert_time_estimate_hours = 24.0    # (32.0 seen in friend's sample)
judge_provider = "gemini"
judge_model = "gemini/gemini-3.5-flash"
judge_dimensions = ["process", "validity", "merge-readiness", "task-quality"]

[environment]
build_timeout_sec = 7200.0
allow_internet = true    # COMPROMISE: shared verifier calls Gemini inline; agent net forbidden by prompt+audit
cpus = 8
memory_mb = 16384
storage_mb = 65536
env = { PATH = "/opt/verifier-venv/bin:<toolchain>:...", RUN_LLM_JUDGES = "1", JUDGE_MODEL = "gemini/gemini-3.5-flash", JUDGE_REPEATS = "2", JUDGE_TIMEOUT_SEC = "300" }

[[steps]]
name = "01-diagnose"
min_reward = 1.0    # strict gate — any lower stops the trial
artifacts = ["/app/output/handoff.json", "/app/output/01-diagnose"]
[steps.agent]
timeout_sec = 7200.0
[steps.verifier]
timeout_sec = 1200.0

[[steps]]
name = "02-core-migration"
min_reward = 0.75   # allows bounded partial to continue (tests recovery)
artifacts = ["/app/output/handoff.json", "/app/output/02-core"]

[[steps]]
name = "03-review-integration"
min_reward = 0.80

[[steps]]
name = "04-hardening-final"
# no min_reward — final stage
```

**Reward strategy:** `multi_step_reward_strategy = "final"` — the final verifier rechecks the complete repo. If an early `min_reward` gate aborts, Harbor returns that aborted stage's result. Consumers must use `binary_reward` + completion state + stage identity together; a partial early reward is training signal, NOT a solved task.

---

## 4. Dockerfile pattern (multi-stage, archive+reinit)

```dockerfile
FROM python:3.12-bookworm AS verifier-python
ARG PYTEST_VERSION=8.3.5
ARG REWARDKIT_VERSION=0.1.7
RUN python -m venv /opt/verifier-venv \
 && /opt/verifier-venv/bin/pip install --no-cache-dir \
    "pytest==${PYTEST_VERSION}" "harbor-rewardkit[all]==${REWARDKIT_VERSION}"

FROM <pinned-language-toolchain>          # e.g. golang:1.xx-bookworm
ARG BASE_COMMIT=<exact-pre-change-commit>
COPY --from=verifier-python /opt/verifier-venv /opt/verifier-venv
ENV PATH=/opt/verifier-venv/bin:<language-toolchain>:/usr/local/bin:/usr/bin:/bin

# Network allowed ONLY during build. Export exact base tree — no origin, remotes,
# reflog, future commits, PR ID, author solution, or verifier files reach the agent.
RUN git clone --no-tags <repository-url> /tmp/source \
 && git -C /tmp/source checkout --detach "${BASE_COMMIT}" \
 && mkdir -p /testbed \
 && git -C /tmp/source archive "${BASE_COMMIT}" | tar -x -C /testbed \
 && rm -rf /tmp/source
WORKDIR /testbed
RUN <fetch-locked-dependencies-and-prebuild-expensive-targets>   # Go: go mod download / vendored; prebuild
RUN git init && git add -A \
 && git -c user.name=benchmark -c user.email=benchmark@invalid commit -m "sanitized benchmark base"

# Build-time sanitization assertions:
RUN set -eux; cd /testbed; \
    test "$(git rev-list --all --count)" -eq 1; \
    test -z "$(git remote)"; \
    test -z "$(git tag --list)"; \
    test ! -e .git/refs/remotes; \
    test ! -e .git/logs/refs/remotes; \
    test "$(git reflog --all --format=%H | sort -u)" = "$(git rev-parse HEAD)"

RUN mkdir -p /app/output /logs/agent /logs/verifier
CMD ["sleep", "infinity"]
```

- **Fetch deps BEFORE `git init`** (deps cached, history sanitized).
- **Never** `rm -rf .git` / `git filter-repo` / `git reset --hard` in the maintainer checkout. Export-and-reinit only, inside the disposable build. If removing a copied `/testbed/.git`, first assert `realpath /testbed` == `/testbed`.
- **Network compromise (rustls sample):** `allow_internet = true` because the shared verifier calls Gemini inline and the local provider can't change network policy after container start. Prompt + process-integrity audit forbid agent network use (weaker than technical isolation). Production-preferred: separate verifier env with provider allowlist, agent baseline no-network.
- Never place Gemini keys in task files/images/markdown/trajectories/source control. Bound judge repeats 1–3, hard timeout per call.

---

## 5. Prompt & handoff contract

```markdown
# Stage <N>: <natural engineering milestone>
The complete repository is at `/testbed`. Continue from the persistent worktree
and read only the handoff artifacts explicitly named below.

## Current evidence or feedback
Describe the symptom, new CI result, reviewer request, production observation, or
fault evidence revealed at THIS stage. Do NOT reveal the source PR, golden patch,
hidden test names, exact implementation, or reward weights.

## Work for this stage
- State the observable behavior / engineering boundary to achieve now.
- State what must remain unchanged.
- State which downstream work is intentionally deferred to a later stage.
- Require executable verification, not a prose-only claim.

## Durable handoff
Write `/app/output/<stage>/<artifact>.json` with explicit TYPED fields. Use
structured fields for any decision a strict gate must check; never search
free-form prose for one exact phrase.
```

**Typed handoff example** (avoids the "correct explanation lost credit for missing one exact phrase" failure):
```json
{"encrypted_input_owner": "caller", "input_buffer_type": "VecInput",
 "caller_populates_input": true, "connection_keeps_second_encrypted_buffer": false}
```

**Prompt-verifier FAIRNESS rule (non-negotiable):** if the verifier requires a command option, file path, schema field, timeout behavior, or artifact format, the stage prompt **must disclose it** (unless the environment enforces it behaviorally). Return exact machine-readable failure reasons like `missing_contract_requirements: ["uses_explicit_offline_mode"]` and pass them to judges. A judge must NOT invent a different cause when deterministic evidence already names the failure.
**Reveal:** symptom, invariants, preserve-behavior, constraints/artifacts, explicit paths/schemas the verifier requires. **Withhold:** PR/future commit, exact patch recipe, hidden tests/variants, reward weights, verifier test names.

---

## 6. Deterministic evaluation design

| Check family | Strict truth? | Design rule |
|---|---|---|
| Fail-to-pass (symptom + hidden variants) | Yes | Exercise behavior, not golden lines |
| Pass-to-pass (focused suites + downstream pkgs) | Yes | Run where prompt scope makes them fair |
| Property/metamorphic | Yes when seeded & stable | Vary irrelevant shape, preserve expected behavior |
| Integration (real consumers/services/schemas/protocols) | Yes | Prefer system interfaces over internal symbol checks |
| Fault injection (EOF, close, backpressure, service failure) | Yes when deterministic | Fixed fault points, bounded clocks |
| Performance | Only when stable | Repeated Oracle baselines, allow noise |
| Artifact (reproducer, rollback, typed handoff) | Yes when explicitly requested | Validate behavior/schema, not prose style |
| Source shape (no 2nd buffer / obsolete call shape) | Only for load-bearing contract | Prompt must make architecture requirement clear |
| Integrity (no verifier/solution/history/network/reward access) | **Always** | Invalid trial cannot be promoted |

**Integrity gate** = zero-weight **validity** gate (not a reward source). Records tracked+untracked files, process commands, network attempts, protected-path access, verifier checksums, artifact path resolution. Rejects symlink/hardlink escape; never trusts agent-written reward/test files. **Distinguish suspicious from confirmed** — patch similarity / fast completion alone ≠ cheating; require human or deterministic confirmation before a contamination label.

**Shared verifier entrypoint** — always writes a numeric reward, always `exit 0`:
```bash
#!/usr/bin/env bash
set -uo pipefail
stage="${1:?stage name required}"
RESULT_DIR="${RESULT_DIR:-/logs/verifier}"; mkdir -p "$RESULT_DIR"
python3 /tests/stage_check.py --stage "$stage" > "$RESULT_DIR/test_output.log" 2>&1
if [ ! -f "$RESULT_DIR/reward.json" ]; then
  printf '%s\n' '{"reward":0,"binary_reward":0,"training_score":0,"valid_trial":0}' > "$RESULT_DIR/reward.json"
fi
git -C /testbed diff --binary > "$RESULT_DIR/patch.diff" 2>/dev/null || true
python3 /tests/stage_judge_inputs.py || true
if [ "${RUN_LLM_JUDGES:-0}" = "1" ]; then
  TASK_STAGE="$stage" bash /tests/run_optional_judges.sh "$RESULT_DIR" || true
fi
exit 0
```
- **Never compare candidate patch with golden.patch.** Oracle proves solvability, it's not the acceptance matcher.
- Keep stage checks aligned with the stage prompt (work deferred to Stage 3 must NOT be a strict Stage 2 check).
- Seed near misses for: narrow local fixes, duplicate compat paths, missing callers, broken features, prose-only artifacts, fault cases.

`stage_check.py` writes: `reward.json`, `reward-details.json`, `reward.txt`, `reward-events.json`, `training_export_manifest.json`. Weights per stage **sum to 1.0**. `reward = 1.0 if strict else promotable_score`; `binary_reward = 1.0 if strict else 0.0` (strict = all checks pass + integrity).

---

## 7. Reward shape & promotion logic

| Output | Meaning | Hard rule |
|---|---|---|
| `reward` | 1.0 on strict stage pass; else weighted deterministic progress | Integrity failure forces promotable reward to 0 |
| `binary_reward` | Strict all-pass for current/final stage | **Judge cannot change it** |
| `training_score` | Weighted deterministic check completion | Never call a partial score "solved" |
| `valid_trial` | Repo + process boundary intact | Zero blocks promotion/training use |
| `stage_complete` | All deterministic stage checks passed | Separate from threshold-based advancement |
| `process_judge` | Evidence-backed engineering process | No binary authority |
| `merge_ready_score` | Final code quality | Zero unless final deterministic pass |
| `research_score` | `0.70*training + 0.20*process + 0.10*merge_readiness` | Model analysis only; not an eval pass condition |

- Deterministic stage weights sum to 1.0; most weight on executable behavior/regression/integration/data/faults/migration/performance/recovery. File creation / doc completion must NOT be a large reward source.
- Integrity stays zero-weight (eligibility only — models don't earn points for not cheating).
- Judge scores (process/validity/task-quality/merge-readiness) are **separate dimensions** with repeats + uncertainty; never blended into `binary_reward`.
- **Partial promotion** (e.g. Stage 2 at 0.80 with `min_reward=0.75`) exists only to study recovery in later stages; cumulative final all-pass prevents it inflating solve rate.

---

## 8. Non-deterministic judges

| Judge | Stages | Question | Authority |
|---|---|---|---|
| `process` | All 4 | Did reasoning follow evidence, use handoffs, verify, self-correct? | Research/training only |
| `validity` | All 4 | Leakage, shortcutting, reward hacking, infra/verifier issue? | Review flag; needs deterministic/human confirm |
| `task_quality` | Diagnose + final | Did prompt/state/checks/gates measure intended work fairly? | Author audit only |
| `merge_readiness` | Final only | Is a deterministic-passing patch focused/idiomatic/coherent/reviewable? | **Zero unless final binary pass; cannot rescue failure** |

**Judge evidence contract:** give ONLY current stage instruction, bounded trajectory, changed sources, raw deterministic outputs, typed artifacts, exact failure reasons, prior persistent handoffs. **Never** give golden patch, hidden tests, private provenance, unrestricted history, or credentials. Repeat the judge, record per-criterion outputs + disagreement, keep scores outside `binary_reward`.

Runtime: Python 3.12, pytest 8.3.5, harbor-rewardkit 0.1.7; `gemini/gemini-3.5-flash` via `GEMINI_API_KEY` at run time (verifier env only). No key → judge unavailable, deterministic result retained. 401/403 → rejected key (never print/store it). 404 → model config failure. Timeout → record uncertainty. Judge disagreement → export spread, never treat one stochastic score as truth.

---

## 9. Run & read results

```bash
harbor --version    # need 0.8+ (installation here 0.20+); NOT old 0.3 on same WSL
harbor run -p ./<tier2-task> -a oracle --jobs-dir /root/harbor-jobs --job-name <task>-oracle-v1
harbor run -p ./<tier2-task> -a nop    --jobs-dir /root/harbor-jobs --job-name <task>-nop-v1
export GEMINI_API_KEY='...'; export JUDGE_REPEATS=2
bash ./<tier2-task>/tools/run_inline_judged_terminus.sh <task>-terminus-judged-v1
```
Results tree: `/root/harbor-jobs/<job>/result.json` (+ `config.json`) then `<task>__<trial>/steps/<stage>/{agent/trajectory.json, artifacts/, verifier/{reward.json, reward-details.json, reward-events.json, judge_status.json, judge_summary.json, judge_runs/repeat-*/, training_export_manifest.json, test_output.log}}`.
**Read order:** job `result.json` (agent/model/errors/final binary_reward/ending stage) → per-stage `reward.json` (strict vs partial) → `reward-details.json` (failed checks + evidence) → `test_output.log` (compiler/test/timeout/env/script) → `judge_status.json` (provider/dims/repeats/means/disagreement) → trajectory+patch (model miss vs unfair mismatch vs contamination vs infra).

---

## 10. Acceptance calibration

| Control | Required outcome | Failure action |
|---|---|---|
| Oracle repeated clean runs | Every stage strict-passes | Fix env/prompt/verifier/Oracle before model trials |
| No-op repeated runs | Stops at earliest meaningful gate | Strengthen checks / remove unearned artifact credit |
| Seeded near misses | Each fails its intended NAMED gate | Add discriminating hidden/property/integration checks |
| Hidden mutation rejection | **≥90% of authored shortcuts rejected** | Do not accept task yet |
| Guided frontier | ≥1 strong model proves practical solvability | Investigate ambiguity/env blockers |
| Unguided frontier | **~5–20% strict solve rate** | Increase stateful difficulty / remove arbitrary strictness |
| Judge repeatability | Oracle/no-op semantic outcomes stable across repeats | Revise rubric/evidence bounds/judge role |

Seed these authored candidates (each should be rejected): no-op + prose/file-only artifact (unearned base credit) → stops at diagnosis; golden behavior missing one hidden variant → fails property/hidden event; local fix w/ downstream caller broken → fails integration/regression; compat shim keeping obsolete path → fails external contract/final closure; hardcoded marker/fake log → verifier rerun fails + validity flag; deleted/skipped/filtered project test → integrity/regression invalidates; source PR retrieved / verifier path accessed → `valid_trial=0` + quarantine; correct-but-bloated strict pass → binary pass stays, merge-readiness falls; fair alternative architecture → **passes** when observable contracts + disclosed invariants hold.

---

## 11. Data-OS QC lessons (Go stream — MUST AVOID)

These WILL be flagged by data-os reviewers:

1. **Never grep `github.com` in integrity checks** — Go imports use github.com paths. Only flag actual network commands (`curl`, `wget`, `git clone/fetch/pull/remote/reflog`).
2. **Git config check:** look for `[remote` sections specifically, NOT substring `github.com`.
3. **`|| true` checks:** strip comments first (agents write comments explaining what they DON'T do); only check code lines.
4. **Never hardcode file paths in grep checks** — search the whole package directory with fallbacks (implementation may live in different files; real code uses different names e.g. `matchesOwner`).
5. **Never use regex/source-token as a primary gate** — `go build` + `go test` must be **≥50% of each stage's weight**.
6. **Never fabricate test names** — `go test -run TestNonExistent` exits 0 silently (vacuous pass). Use real test names from the golden patch or grep patterns.
7. **Always verify API types against `vendor/`** — if vendor has `gatewayv1.ListenerSet` (from `apis/v1`), never write `v1alpha2` in instructions.
8. **Always add a verifier-owned base-state check** — don't trust the agent's reproducer output alone.
9. **Disclose everything the verifier checks** — exact marker strings, exact JSON field names, exact commands (no "e.g.").

**Required weight hierarchy per stage:** `go build` ≥0.15–0.25 · `go test` ≥0.25–0.30 · structural grep ≤0.05–0.15 each (broad search) · artifact/report ≤0.05 each.
**Integrity scanner — DO flag:** `curl`, `wget`, `git clone/fetch/pull/remote/reflog`, `pip install`, `go install`/`go get`, `apt install`. **DO NOT flag:** Go import paths, `go build` output, source references.

**Pre-upload self-validation:** (1) Oracle passes all stages 1.0; (2) no-op fails Stage 1 (< min_reward); (3) integrity doesn't flag Go imports; (4) grep checks search correct dirs (not hardcoded filenames); (5) weights sum to exactly 1.0 per stage; (6) `go test` runs & reports real pass/fail (not vacuous "no tests matched"); (7) hidden test uses types that exist in vendored packages.

---

## 12. Task selection (Go)

- Choose **genuinely stateful** work: migrations, concurrency fixes, distributed state, protocol changes, storage/transaction behavior, compatibility transitions, performance, fault recovery.
- ≥3 distinct phases a real engineer would recognize — not arbitrary checkpoints on one local edit.
- Later evidence must **causally depend** on earlier work (CI failures, review comments, prod traces, load results, migration state, fault tests).
- Keep the complete repo + real service topology (no toy extraction).
- Use a recent merged PR / maintainer patch for provenance + Oracle, then add **novel hidden variants** so PR recall alone is insufficient.
- **Go strong domains:** cloud control planes, networking, operators. **Useful signal:** fast broad tests, races, service state, fault injection. **Caution:** add real state + contracts; avoid tiny local fixes.

---

## 13. Training export (schema v2)

```json
{"schema": "repo-engineering-training-v2", "task_family": "...", "stage": "<diagnose|core|review|harden>",
 "training_candidate": true, "eligible_for_training": false,
 "split_policy": "never train on an active evaluation instance",
 "artifacts": ["trajectory.json","patch.diff","changed_files.txt","reward-details.json","reward-events.json","test_output.log","agent_output/","judge_inputs/","judge_summary.json"],
 "failure_labels": ["<failed deterministic gates>"], "contamination_label": "<clean|suspected|invalid>"}
```
Uses: Stage SFT (phase-specific behavior), temporal credit (per-check events), recovery preference (partial→recovery), merge-readiness preference (two strict passes by quality — never prefer stylish-broken over correct), failure classification. Keep training/eval separate by repo, time window, task variant, hidden cases, checksum. Quarantine confirmed contaminated/invalid; don't label fast work or golden similarity as cheating without stronger evidence.

---

## 14. Worked sample (reference only)
`rustls/rustls` @ `68771ca492c91b1084ea6d51354385aef62b5ea4`, provenance = merged rustls **PR 2940 "Externalize input buffers"** (2026-07-07). Oracle v9: all 4 stages `binary_reward=1`, ~4m20s cached. No-op: stops at Stage 1, `training_score=reward=0.15`, `valid_trial=1`. The PR is **private author provenance only** — no origin/PR#/future commit/golden patch/verifier in the solving image; hidden cases + staged feedback make memorized patch recall insufficient.

Friend's active Go task (reference): `cilium/cilium #46303 "GatewayAPI: Implement ListenerSets"` @ `7bff741409a56f1de8b693f073f24040d2989d34` (merged 2026-06-26, 97 files, +5289/-576), Tier 2 4-stage, platform data-os.
