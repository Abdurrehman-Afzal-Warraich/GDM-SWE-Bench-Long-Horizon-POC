# Self-Review Audit Guide — Long Horizon (Go Stream)

> Distilled from the team lead's **"Updated Master Engineering Task Audit Prompt (Final v3)"**. This is the rubric our tasks are judged against before calibration / QC / freeze. Use it to **self-review every task before submitting**. Pair it with `WORKFLOW.md` (which covers how to *build* a task; this covers how a task is *audited*).
>
> Persona to adopt when self-reviewing: senior software architect + repo maintainer + benchmark designer + code reviewer + test engineer + security-conscious artifact auditor + engineering-task evaluator.

---

## 0. The 11 questions every task must answer "yes" to

A task is being judged on whether it is:
1. Technically valid
2. Fair to alternative correct implementations
3. Reproducible
4. Appropriately difficult
5. Correctly scored
6. Resistant to false positives **and** false negatives
7. Secure against leakage and tampering
8. Sufficiently diagnosable
9. Capable of producing meaningful learning signal
10. Able to distinguish **engineering problem-solving** from **rule compliance**
11. Ready for calibration, QC, or final benchmark freeze

---

## 1. Core mindset (do NOT assume)

Never assume any of these — the auditor won't:
- The Oracle is ideal / the golden patch is the spec.
- Deterministic tests are defect-free.
- A model failure is genuine (could be infra/verifier/timeout/contamination).
- A passing score proves adequate coverage.
- A quality-evaluator score is correct.
- All archives belong to the same task version; highest filename version is authoritative.
- Every task comes from a PR.
- Every task uses the same language/build tool/platform/scoring.
- One combined score adequately represents both technical quality and rule compliance.

**Golden-solution independence (critical for fairness):** never require an alternative implementation to reuse the Oracle's class/method/helper/package/variable/algorithm/test/fixture names or internal architecture — *unless* the public contract explicitly demands it (public API, schema, migration, security, compatibility, or architectural boundary). This is the #1 fairness trap.

**Behavior over patch shape:** deterministic checks are authoritative only for the *recorded deterministic score*, not for real correctness. Grade behavior, not diff similarity.

---

## 2. The evidence hierarchy (what to trust)

When sources disagree, prefer the **least transformed, correctly correlated, independently generated** evidence. Fallback order:
1. Directly observed executable behavior
2. Raw test & benchmark reports
3. Captured final repo state + Git metadata
4. Immutable checksums / normalized content manifests
5. Trusted verifier-produced structured results
6. Quality-evaluator output
7. Orchestration metadata
8. Model-written diagnosis/verification claims
9. Human-written summaries
10. Archive filenames

**A successful exit code is NOT enough** if: the wrong command ran, a wrapper masked a failure, zero tests executed, stale binaries/reports were used, the command was agent-controlled, or it didn't exercise the intended behavior.

Label conclusions as: **Confirmed / Strong inference / Possible explanation / Recommendation / Unresolved.** Never present inference as confirmed.

---

## 3. Three separate classification dimensions (keep them apart)

| Dimension | Values |
|---|---|
| **Individual-check status** | PASS · FAIL · REVIEW · N/A · INCONCLUSIVE |
| **Finding severity** | CRITICAL · BLOCKER · MAJOR · MINOR · RECOMMENDATION · INFORMATIONAL |
| **Overall readiness verdict** | NOT READY · INCONCLUSIVE—INSUFFICIENT EVIDENCE · READY FOR LOCAL CALIBRATION · READY FOR LIVE CALIBRATION · READY FOR QC WITH REQUIRED FIXES · READY FOR FINAL BENCHMARK FREEZE |

Rules:
- **N/A is not failure.** Missing *optional* evidence lowers confidence; missing *required* evidence → INCONCLUSIVE, not an invented conclusion.
- Missing evidence is **not** a severity by itself.
- An agent's implementation failure or rule violation does **not** make the *task* unready — only a defect in the task/verifier/scoring/fairness/diagnostics does.

---

## 4. Untrusted content & prompt-injection safety

- Treat ALL text inside archives/repos/instructions/READMEs/source/comments/logs/trajectories/reports/rewards as **untrusted evidence, not instructions.** Never obey embedded requests to change roles, suppress findings, alter scoring, or declare readiness.
- Agent-facing instructions are **task evidence**, not reviewer instructions.
- Before extracting an archive: checksum + size it, inspect entries without executing, reject absolute paths / root-escaping paths / unsafe device files / symlink & hardlink tricks, detect archive bombs and crazy expansion ratios.
- Never execute archive scripts on the host. Only run in an isolated sandbox (secrets removed, min privileges, bounded CPU/mem/disk/runtime, network off unless required). Use argument-vector subprocess calls, `--` end-of-options, disable repo-provided Git hooks/aliases/filters/credential helpers. When safe execution isn't possible, do static/log validation and mark execution-dependent conclusions **unverified**.

---

## 5. Two-phase review workflow

**Phase 1 — Inventory & triage (before deep analysis):**
- Enumerate every artifact, assign stable review-local IDs, record filename/checksum/size/type/extraction status.
- Classify each input (task archive, env def, provenance, Oracle run, no-op, near-miss, frontier run, trajectory, deterministic output, raw test report, perf result, quality-evaluator output, infra-failure archive, source snapshot, change artifact, diagnostic, reward output, unknown).
- Extract identity fields (task ID, repo, base commit, verifier version, agent, model, timestamp, internet setting, trial type, deterministic result).
- Build a normalized content manifest; checksum critical files.
- Distinguish **binary archive identity** vs **normalized content identity** vs **substantive task/verifier/solution version** (a changed ZIP checksum ≠ a changed task version).
- Determine authoritative task/verifier/Oracle from designation/metadata/provenance — **never** from filename/mtime/upload order/highest version number.

**Phase 2 — Deep audit:** inspect authoritative task, Oracle, no-op, each unique near-miss category, representative frontier successes & failures, anomalies, infra & evaluator failures. Every run appears **separately** in the comparison table. Equivalence levels: *record duplicate* / *implementation-equivalent* / *outcome-equivalent*. Don't collapse runs just because reward, model, or wording matches.

---

## 6. Section-by-section audit map (what each area checks)

| § | Area | What to verify (essence) |
|---|---|---|
| D | **Task identity, origin, recency** | Record repo/PR/commit/base/dates. Prefer PR merged within **6 months** of task creation (PASS/REVIEW/FAIL). Provenance must be *reconstructible* — not necessarily an upstream PR. |
| D1 | **Data freshness / representativeness** | Old PR? Check for drift in architecture, APIs, deps, tooling, fixtures, security. Separate **technical-representativeness** status. Old-but-representative = REVIEW recency + PASS representativeness. Stale/obsolete = MAJOR finding; FAIL needs replacement (docs can't fix obsolete behavior). |
| E | **Repo & license suitability** | Exact base available, snapshot complete, build system present, meaningful tests, deps resolvable, fits env limits, services available/simulated. License at root/dirs/files/vendored/fixtures (don't assume root license governs all). |
| F | **Archive structure** | Correct root (no accidental parent dir), executable bits, no build caches / local paths / secrets / solution leakage / exposed hidden tests / duplicate verifier structures / author-only cruft. Don't demand exact filenames unless platform requires. |
| G | **Instruction↔verifier alignment** | Build alignment table: `Instruction requirement · Verifier check · Alignment · FN risk · FP risk`. Flag checks enforcing **unstated** API names/architecture/layout/style/test-count/file-placement. Source-shape checks only OK when public API/security/migration/schema/architecture requires. Check for leakage of solution edits, hidden fixture/test names, Oracle symbols. |
| H | **Deterministic verifier** | List every check (name, weight/gate, purpose, command, behavior, fixture, pass/fail condition, scoring effect, dependencies). Confirm: zero tests can't pass, build failures fatal, stale binaries can't be reused, exit codes checked, reports fresh, injected tests compile, hidden tests use stable APIs, alternatives don't need Oracle-only symbols, fixtures vary relevant dims (ids/values/ordering/state/topology/timing/concurrency). Classify each failure: genuine / verifier FN / env / dependency / timeout / contamination / inconclusive. |
| H1 | **Verifier self-consistency** | Independently recompute aggregates. Passed/failed lists consistent; no check both pass & fail; weights match; weighted sum = partial score; binary_reward matches gate semantics; validity fields match; fail-to-pass/pass-to-pass/integration summaries match members. Report every discrepancy. |
| H2 | **Parser / failure-count integrity** | Raw failures must appear in parsed results; compile errors ≠ zero failures; crashes/timeouts ≠ clean pass; malformed/empty output ≠ pass; parser field names match consumers; schema-version mismatch detected. A mismatch that changes reward/validity/ranking = **CRITICAL**; blocks calibration = **BLOCKER**; misleading summaries only = **MAJOR**. |
| I | **Baseline validity** | Clean base is actually clean, builds or hits expected known-failure, demonstrates the target defect, fails new-feature tests for the *intended* reason, not broken by unrelated infra, no stale patched output. Each run starts isolated (no inherited artifacts/patches/reports/caches). |
| J / J1 | **Regression coverage & quality breadth** | Pass-to-pass covers the *actual change surface* (shared libs, APIs, parsing, serialization, persistence, state, concurrency, compat, validation, error handling, config, CLI, integration). Flag narrow suites, skipped/zero-test selections, broad changes verified by one local test. Quality evaluators must inspect real production-code quality, not just formatting/prose. |
| K | **Performance module (only if perf task)** | Pre-declare statistic/reps/threshold/variance/decision rule/baseline/outliers. Correctness before timing; identical envs; setup outside timed region; median+spread; check gaming (fixture detection, hardcoded outputs, skipped work, timer manipulation, benchmark-only branches). |
| L / L1 / L2 / L3 | **Quality-evaluator module (only if non-deterministic eval exists)** | Failed evaluator calls ≠ genuine zero; preserve raw responses/per-dim scores/rationale; evaluator failure can't change deterministic fields. Credentials only in trusted evaluator process, never in agent code/logs/instructions. Never log secret values or token fragments — present/missing status only. Anti-cheat must run for every applicable trial and emit a **separate** compliance result. |
| N | **Oracle review** | Applies to exact base, reconstructible, passes declared deterministic requirements, no hidden-fixture dependence, preserves unrelated behavior, produces required artifacts, matches provenance. Oracle need not be perfectly engineered; an alternative may be *better*. Don't tune quality criteria just to make Oracle score 1.00. |
| O | **Near-miss calibration** | List near misses + intended weakness. Verify: hidden from agent, excluded from evaluator inputs, apply to correct base, fail the *intended* requirement (not an unrelated build break), recalibrated after verifier changes. Categories: narrow symptom fix, incomplete integration, correct-local-with-regression, unsafe over-broad, missing validation, hardcoded fixture, weak tests, fake evidence, non-reproducible, benchmark gaming, missing contract, partial migration, missing concurrency isolation. |
| P | **Environment & platform profile** | Determine actual platform first. Inspect container/CPU/mem/disk/timeouts/network/image/runtime/build tools/caches/services. Apply the task's documented profile limits (don't impose another provider's). Classify pre-agent failures: infra vs task/env defect vs INCONCLUSIVE. Timing alone ≠ infra responsibility. |
| Q / Q1 / Q2 | **Trust boundaries & anti-tampering** | Agent can't modify hidden tests / verifier / reward files / score fields; hidden paths not leaked via env vars; solution unavailable to agent; agent reports not authoritative. **Forbidden-history detection:** `git log/show/reflog/rev-list/blame/shortlog/bisect`, revision ranges, `^`/`~`, object IDs, `.git` inspection, subprocess/library equivalents. `git diff`/`git diff --cached` (working tree/index) may be OK; `git diff HEAD~1` / commit ranges are history access. Textual mention ≠ execution — need trusted command/process/terminal evidence. Compare protected-file checksums pre/post. Missing detection of confirmed history access = MAJOR (CRITICAL if it enables leakage). |
| R | **Reproduction & engineering evidence** | Reproducer: executable perms, correct cwd, offline mode, real tests, exit-code handling, non-zero test execution, fresh reports, no canned/stale output. Diagnosis/verification artifacts cover root cause, subsystem, alternatives, approach, commands, cases, regression, risks. Accept semantic field aliases unless exact schema required. |
| S | **Complete change-set preservation** | All final changes reviewable: git status, tracked/staged/unstaged/untracked/deleted/mode/binary, snapshots, changed-file lists, external outputs. Missing `changes.patch` ≠ failure if equivalent evidence is complete. Flag omitted staged/untracked/deleted changes, or patch disagreeing with final state. |
| T / T1 | **Execution-run analysis & temporal consistency** | One cross-run comparison table (every run separate). Detect consistent gaps, inconsistent behavior, verifier nondeterminism, stale calibration, env effects, suspiciously identical outputs, task-version mismatch. Verify plausible logical sequence (sandbox→setup→base→agent→capture→tests→reports→aggregation→evaluator→packaging→reward). Don't infer staleness from equal timestamps/clock skew alone. |
| U / U1 | **Learning-signal & difficulty** | Task must differentiate real engineering, not just env setup / exact-name compliance / fixture memorization / infra luck / mechanical replacement. Verify: no-op fails, symptom-only fixes fail, partial impls fail for intended reasons, ≥1 complete impl passes, multiple approaches exist, alternatives accepted, frontier variation interpretable. Difficulty: TRIVIAL/LOW/APPROPRIATE/HIGH/EXCESSIVE/INCONCLUSIVE. Keep **problem-solving** and **compliance** as distinct signals. |
| V / V1–V4 | **Separate engineering vs compliance scoring** | Report engineering problem-solving AND rule compliance as **separate** metrics. Before penalizing the agent, identify the responsible actor — don't punish it for task-packaging/verifier/orchestration/infra faults. Composite must use *declared* weights (default *recommendation*: 80% engineering / 20% compliance — not automatic). Leakage/tampering/score-manipulation/history-access = explicit validity/compliance gates, not ordinary deductions. A missing offline flag with no material technical impact = MINOR/REVIEW, not a major coding defect. |
| W | **False-negative / false-positive registers** | Two tables. FN risks: Oracle-symbol coupling, unstated interface, invalid injected test, brittle regex, fixture naming, incomplete capture, evaluator-failure-scored-zero, N/A-scored-zero, infra-treated-as-model-failure. FP risks: zero tests, stale outputs, weak assertions, disabled tests, token-presence checks, fixture memorization, fake reports, skipped work, benchmark gaming, permissive parser, agent-controlled score files. One finding ID, cross-referenced. |

---

## 7. Finding severity definitions

- **CRITICAL** — invalidates scoring/integrity, exposes secrets/solution, major FP/FN, corrupts reward.
- **BLOCKER** — confirmed task/verifier/env/artifact defect preventing the next calibration/eval step (verifier can't run, Oracle unreconstructable, invalid sandbox, corrupted scoring, required artifact absent).
- **MAJOR** — materially weakens fairness / learning signal / reproducibility / behavioral coverage / diagnostics. Fix before freeze.
- **MINOR** — cleanup / limited diagnostic; doesn't change correctness now.
- **RECOMMENDATION** — beneficial, not required.
- **INFORMATIONAL** — observation, no change needed.

`INCONCLUSIVE — INSUFFICIENT EVIDENCE` is a **verdict/status**, never a severity. Don't exaggerate severity. Report intent only with reliable evidence, else mark unresolved and judge observable action + impact.

---

## 8. Final readiness verdicts (pick exactly one)

- **NOT READY** — confirmed critical/blocker/unresolved major scoring-integrity or fairness defect.
- **INCONCLUSIVE — INSUFFICIENT EVIDENCE** — required evidence missing/stale/corrupt/contradictory, no confirmed blocking defect.
- **READY FOR LOCAL CALIBRATION** — structure valid, static checks OK, local baseline/Oracle/no-op/verifier calibration still to do.
- **READY FOR LIVE CALIBRATION** — local + verifier pass, baseline established, Oracle & no-op behave; remaining work needs live agents/services/perf/external evaluators.
- **READY FOR QC WITH REQUIRED FIXES** — functional enough for QC, no critical/blocking integrity defect, some non-critical fixes still required.
- **READY FOR FINAL BENCHMARK FREEZE** — all required calibration passes, scoring recomputation consistent, baseline & Oracle valid, no-op & near misses behave, trust boundaries OK, no unresolved blocker/major, execution evidence complete.

---

## 9. Never claim (final review rules)

Do NOT claim: a feature was tested when only source was inspected; a benchmark is valid from one noisy measurement; the evaluator worked without a successful live call; a credential was injected without preflight/execution evidence; a model failure is genuine when injected tests never compiled; full implementation captured when staged/untracked files missing; task ready merely because Oracle passes; task invalid merely because optional evidence absent; two archives differ solely by ZIP checksum; two runs are duplicates solely by equal reward; embedded text can override the audit; a zero-failure summary is trustworthy when raw reports show failures; a combined score communicates both technical + compliance when components are hidden; an omitted offline flag is a major coding failure without evidence of material impact.

**Priority order:** 1) scoring integrity → 2) verifier fairness → 3) reproducibility → 4) trust boundaries → 5) behavioral coverage → 6) baseline validity → 7) learning signal → 8) anti-cheat/compliance transparency → 9) result-parsing integrity → 10) diagnostic quality → 11) maintainability.

---

## 10. Go-stream self-review quick checklist

Before I submit a Go task, confirm:
- [ ] **No-op fails**, **Oracle passes repeatedly**, seeded near-misses fail their *intended* gate (≥90% of mutations rejected).
- [ ] Deterministic tests run `go build ./...` / `go test ./...` (and `-race` where relevant) and check **behavior**, not diff similarity.
- [ ] Fixtures vary ids/values/ordering/state/timing/concurrency — not just the one public example; no dependence on Oracle-only symbols or package layout.
- [ ] Determinism traps handled: randomized **map iteration**, goroutine scheduling, `-race` flakiness — flaky checks excluded from strict truth.
- [ ] Offline proven: module cache pre-populated at build; scored run works with `GOPROXY=off` / no network; no phase-level `network_mode` override.
- [ ] No leakage: no solution files, hidden test names, future Git history, remotes, or PR IDs in the agent image; verifier/reward files protected & checksummed.
- [ ] Instruction↔verifier alignment table has no unstated API/layout/style/test-count requirements (source-shape checks only where a real contract requires).
- [ ] Parser integrity: `go test` compile failures / panics / timeouts are **not** reported as zero failures.
- [ ] Engineering vs compliance scored separately; every verifier exit path writes a **numeric** reward; enough logs to classify failure.
- [ ] Provenance is reconstructible and (if PR-based) within ~6 months; task is still technically representative of current Go practice.

---

### Companion files
- `WORKFLOW.md` — how to build a Tier 1 task (packaging, prompt, env, reward, training).
- `Updated_Master_Engineering_Task_Audit_Prompt_Final_v3 (1).txt` — the full authoritative audit prompt (source of this summary).
