# Critical review: `prometheus-search-api`

## Decision

**Reject pending repair and re-evaluation.** The task has a strong, authentic behavioral core and a substantially executable verifier, but it is not release-ready. The downloaded real-agent run proves a verifier false positive, every downloaded run used public networking, Stage 1 violates the guide's strict-gate design, requirement-level coverage is materially below 100%, RewardKit is disabled and configured for the wrong provider/model, and README contains prohibited evaluation evidence.

Reviewed scope:

- `task_files/task.toml`, README, Dockerfile, all four instructions, launchers, Oracle scripts, golden patches, provenance, hidden tests, deterministic grader, RewardKit files, score merger, self-tests, contracts, and author controls.
- Oracle `eval_140822`, no-op `eval_140823`, and Terminus/Gemini `eval_140864`, including result, reward, reward-details, judge status, patches, logs, artifacts, and trajectory where present.
- `REVIEW_CHECKLIST.md`, `swe_multi_step_long_horizon_guide.md`, and all three workbook-sheet schemas.

The package self-test reports **48 passed** under a Python environment with `tomllib` compatibility. That does not clear the findings below: several self-tests assert the defective policy itself, including Anthropic-only judging, an ungated Stage 1, and the presence of calibration claims in README.

## Attestation summary

| Area | Verdict | Critical conclusion |
|---|---|---|
| Behavioral instructions | Partial | The engineering requirements are mostly behavioral, and exact exported names are disclosed as public contracts. Some artifact requirements are shape-only and some mandatory Stage 3 behavior is deferred to Stage 4. |
| Prompt–verifier alignment | Fail | Stage 3 can pass without the prompted cap-disabled behavior; `match[]`, several parser failures, all-route feature gating, and exact matching semantics are not decisively checked. Handoff types are looser than the prompt. |
| Test coverage | Fail | Coverage is not 100%. Important positive, negative, boundary, error-aggregation, laziness, matching, routing, and concurrency cases are missing or fail open. |
| Anti-cheat | Fail | All evaluations ran with public networking. The trajectory URL scanner produced a confirmed false positive and is also bypassable. Process/mount isolation for injected tests is not demonstrated. |
| Network policy | Fail | `allow_internet=false` is correct statically, but every `[steps.agent]` omits `network_mode="no-network"`, and all downloaded results record `override_network_mode="public"`. |
| RewardKit / OpenAI Terra | Fail | The package uses Anthropic Claude, `ANTHROPIC_API_KEY`, `RUN_LLM_JUDGES=0`, and lambda `0.0`. It does not use `OPENAI_API_KEY` or `openai/gpt-5.6-terra`, and no downloaded judge run executed. |
| Reward formula | Partial/Fail in deployment | The normalized guide formula is implemented correctly in isolation and binary reward is protected. Deployment is not best: lambda is unbounded above and zero by default, incomplete judge repeats/criteria are silently blended, Oracle fields are not N/A, and the scored JSON surface contains many numeric diagnostics. |
| Grading integrity | Fail | A correct functional Stage 3 was invalidated by a license URL in source text; no-op is marked invalid for missing trajectory; timeout and skipped-race outcomes are not classified safely. |
| Verifier–Oracle coupling | Partial; release gate not attested | Candidate grading does not compare golden patches and behavioral checks dominate. However, no alternate-valid full solution was retained, several checks are literal/token or exact-public-shape based, and Oracle-only success cannot prove equivalent implementations pass. |
| Harness and packaging | Fail | All files are mode `0600`, `[task].version` is absent, image/dependencies are not fully immutable, README contradicts config/results, and exact-archive execution is not attested. |
| README evaluation evidence | Fail | README lines 240–309 contain Oracle/no-op/model outcomes, timings, mutations, calibration status, performance, and headroom evidence. |
| Evaluation evidence | Fail for release calibration | Runs are downloadable, but all are public-network runs; only one solver/model was tried, it was stopped by a verifier defect, and no Terra/repeat/alternate-valid/horizon-ablation evidence exists. |

## Release-blocking issues and fixes

### F01 — P0 — Real evaluations violated the required network boundary

`task.toml:46` sets `allow_internet=false`, but none of the four `[steps.agent]` blocks sets `network_mode="no-network"`. More importantly, every downloaded `result.json` and `config.json` records `override_network_mode="public"`.

This means the Oracle, no-op, and solver results do not attest an offline agent phase. It also contradicts `task.toml:28`, README's anti-contamination claims, and the guide's isolation requirement.

**Fix:** set `network_mode="no-network"` explicitly on every agent step and every deterministic verifier step supported by Harbor; reject public overrides in a package contract test. Run Terra in a separate verifier-only network boundary with only a sanitized evidence bundle and `OPENAI_API_KEY`. Re-run all controls on the frozen package and retain the effective network mode in results.

### F02 — P0 — The anti-cheat scanner produced a confirmed verifier false positive

The Gemini solver passed every weighted Stage 3 functional check, but `integrity` failed. `command_integrity_violations()` treated a heredoc writing Apache-licensed Go source as network egress because the command contained both `https://www.apache.org/licenses/LICENSE-2.0` and the string `net/http`. The real-agent reward details show `every_weighted_check_passed=true`, `D_num=0`, `valid_trial=0`, and only `integrity` failed.

This is a **verifier false positive**, not a model implementation miss or cheating event.

The same detector is easy to bypass: it requires a literal external URL and one recognized client token in the same captured command, handles only selected trajectory shapes/fields, and misses variable expansion, encoded hosts, raw sockets, many subprocess forms, browser/MCP tools, and surviving background processes.

**Fix:** make environment isolation the primary control. Replace string co-occurrence with structured, executed-network telemetry or a denied-egress audit; never scan arbitrary source/heredoc content as a command-level offense. Add regression tests for license URLs, comments, Go imports, local URLs, variables, encoded/indirect egress, alternate trajectory schemas, browsers/MCP, and raw sockets. Reclassify `eval_140864` as verifier-defective and exclude it from model-quality training.

### F03 — P0 — Stage 1 violates strict stage gates and lets no-op continue

Stage 1 deliberately has no `min_reward`, despite the guide's rule that every non-final stage advances only after required executable checks pass. The downloaded no-op scored zero at Stage 1 and still ran Stage 2. README's Mermaid edge says `strict 1.00`, while README lines 70–71 and `task.toml` say promotion is unconditional.

This weakens long-horizon semantics and allows final-only aggregation to hide an invalid or missing diagnosis phase.

**Fix:** set Stage 1 `min_reward=1.0`; preserve partial diagnostics in unscored details, but stop canonical execution after any failed non-final stage. If diagnosis is genuinely optional, remove it as a scored stage rather than calling it a required long-horizon acceptance boundary.

### F04 — P0 — A valid no-op would receive large training progress

The current no-op files show all numeric reward fields as zero only because missing trajectory sets `integrity=false`. That is the wrong reason: an intentional no-op is a valid control, not contamination. If missing trajectory were classified correctly, the verifier's own base probes would award `0.78/1.00` deterministic progress at Stage 1 even though the agent did nothing; only the handoff fields fail.

**Fix:** keep `reward=0` and `binary_reward=0` for no-op, set `valid_trial=1` when the no-op is clean, and add a meaningful-agent-evidence gate that forces `D_num`, deterministic score, and training score to zero when the agent supplies no diagnosis/reproducer/handoff. Model-independent base-state probes should be validity prerequisites or zero-weight diagnostics, not agent progress.

### F05 — P0 — Requirement-level coverage is not 100%

The hidden corpus and live HTTP checks are useful, but material gaps remain:

- Stage 2 value-ordered paths are checked for output only, not the promised non-materializing/early-exit behavior.
- `NewLazySearchResultSet` may eagerly construct and still pass because the test checks `called` only after `Next()`.
- Partial-error merge uses one error; it does not prove multiple errors are joined (`errors.Is` for each), warnings survive, limits interact correctly, or all healthy sets continue draining.
- Jaro-Winkler is not semantically verified; bounded scores, identity, and a non-strict threshold-count check admit non-Jaro implementations.
- Subsequence tests do not require a true non-prefix positive subsequence or reject a plausible non-subsequence across randomized cases.
- `match[]` is never sent. Invalid/out-of-range `fuzz_threshold`, invalid booleans/times/batch sizes/sort values, empty label, and method/content-type variants are not comprehensively tested.
- Feature-off probing checks only metric-names GET, not all six GET/POST routes.
- Stage 3 mandates `--web.search.max-limit=0` behavior, but that check runs only in Stage 4, so Stage 3 can promote while violating its own prompt.
- Race checking passes when no C compiler is present. The memoizing matcher's single-goroutine assumption has no verifier-owned test.
- The performance prompt permits allocation equal to one half of the full sort, but the test fails equality (`topK*2 >= full`), silently enforcing “strictly less than half.”
- Documentation can pass by scattering literal tokens across unrelated files; `final_report.json` accepts meaningless non-empty placeholders.

**Fix:** implement the coverage matrix below, add mutation controls for each omitted behavior, and require every mandatory Stage 3 rule in Stage 3. Do not call coverage complete until independent positive, negative, exact-boundary, and failure-path probes all execute.

### F06 — P0 — RewardKit does not meet the required OpenAI Terra contract

`task.toml:29`, every judge TOML, and `run_optional_judges.sh:12` select `anthropic/claude-sonnet-4-6`. The runner checks only `ANTHROPIC_API_KEY`; `OPENAI_API_KEY` is absent. `RUN_LLM_JUDGES=0` and `NONDETERMINISTIC_LAMBDA=0.0` mean qualitative judging is disabled and has no training effect even if manually run. Every downloaded `judge_status.json` says not requested or Oracle-inapplicable.

**Fix:** configure all qualitative judge files and the runner consistently for `openai/gpt-5.6-terra`; declare `OPENAI_API_KEY="${OPENAI_API_KEY:-}"` only in verifier/judge scope; never expose it to agent steps, logs, or artifacts. Enable applicable real-agent judges in a separate egress-enabled reviewer phase. Keep Oracle and controls deterministic-only with judge fields and lambda `null`/N/A.

### F07 — P0 — RewardKit aggregation accepts incomplete evidence

The formula itself matches the guide:

```text
training_score = (D_num + lambda * N_num) / (D_den + lambda * N_den)
```

However, the runner merges when only one of multiple attempted repeats succeeds. The merger silently drops missing criteria from `N_den`, falls back to dimension totals, reports `judge_available=1`, and does not validate that the claimed successful count matches parseable run files. Disagreement is only a maximum dimension-score spread; criterion-level disagreement and missingness are not preserved. `parse_lambda` accepts values above the guide's policy maximum of 1.

**Fix:** require a complete applicable dimension/criterion set for each required repeat or mark N unavailable and use deterministic-only scoring. Validate attempted/successful/parsed counts, expose per-criterion samples and disagreement, clamp/reject lambda outside `[0,1]`, and calibrate before selecting a weight. Given the requirement that qualitative judges matter, start with `lambda=0.5` only as a documented calibration candidate—not as an unvalidated optimum.

### F08 — P0 — Canonical reward JSON is semantically noisy

`reward.json` contains seven numeric fields before judging and more after judging. `result.json` exposes the whole numeric map, while the reviewed evidence does not prove every downstream consumer selects only `reward`. `stage_complete` also means every weighted check passed, whereas `reward`/promotion use only critical checks. Thus a stage may have `reward=1` but `stage_complete=0`, which conflicts with the guide's ordinary meaning of completion. Oracle output keeps lambda at `0.0` instead of N/A.

**Fix:** prove field-selective downstream parsing. Until then, keep only the authoritative binary on the scored surface (for example `{"reward": 0.0}`) and store deterministic score, validity, stage completion, D/N components, judges, disagreement, and lambda in unscored details. Use guide-aligned names and semantics; for a promoted required stage, `stage_complete` should agree with required deterministic completion.

### F09 — P0 — Grading validity and correctness are conflated

Missing trajectory makes no-op `valid_trial=0`; a source-text scanner makes an otherwise correct real-agent stage `valid_trial=0`; all deterministic and training progress is then erased. Timeouts become return code 124 and ordinary check failures. `race_clean` can report success with a skipped test. `training_export_manifest.json` simultaneously says `eligible_for_training=false` and `training_candidate=integrity_ok`, an undefined contradiction.

**Fix:** separate model correctness, process validity, verifier defects, environment faults, and timeout origin. A clean no-op can be valid but incorrect. A verifier false positive must be invalid/inconclusive for training, not a model zero. Fail closed on required race tooling in the packaged image, emit explicit timeout phase/origin, and define one consistent training eligibility policy.

### F10 — P1 — Anti-cheat remains vulnerable despite strong local controls

The immutable-base diff, random failing canary, PATH hardening, root/ELF checks, and kernel ctime anchor are positive. They are insufficient as a complete boundary:

- the agent runs as root and the review does not prove a separate process/mount namespace;
- hidden tests are copied into the writable worktree, where a surviving watcher can read or alter them;
- the canary parser still trusts textual per-test lines and can be targeted after observing injected files;
- ctime covers three executable inodes, not Python libraries, the verifier venv, libc, loader state, or other dependencies;
- trajectory auditing is both the source of the false positive and not a reliable security boundary.

**Fix:** use a separate verifier container/user/process namespace, read-only protected mounts, teardown of all agent processes before verifier upload, and a clean copy of the candidate tree. Add read/watch/symlink/background-daemon/tool-library tamper controls. Keep trajectory review supplemental.

### F11 — P1 — Handoffs and reports are weakly validated and unbounded

The prompt requires arrays, but `handoff_contract()` accepts arrays or objects and multiple undocumented synonyms. Any non-empty strings/collections pass without tying evidence to commands, logs, checks, or changed files. Arrays, JSON files, `/app/output`, and copied judge output have no complete total-size/cardinality policy; `stage_judge_inputs.py` bounds changed source but copies the entire output tree.

**Fix:** publish schema/version, exact field types, cardinality and byte limits, normalized relative paths, and immutability/digests between stages. Generate command/evidence records in the verifier and cross-check report claims against named checks and Git changes. Bound the total judge bundle, including agent output and trajectory.

### F12 — P1 — README is prohibited evaluation evidence and is internally inaccurate

README lines 240–309 contain prior Oracle/no-op/model outcomes, exact stage timings, mutation results, tamper behavior, performance measurements, calibration status, and headroom plans/results. This directly violates the required release policy that README must not contain evaluation evidence.

Additional contradictions include:

- line 42 says Stage 1 promotes on `strict 1.00`, while lines 70–71/config make it unconditional;
- lines 20–21 claim the solver is not shown the PR while the packaged README/task metadata name it, without a verified visibility matrix;
- line 190 claims runtime installs are rejected, while the contract explicitly allows `pip install`, `apt-get install`, and `go install`;
- line 205 says tool digests are in `reward.json`; they are in `reward-details.json`;
- line 235 says the package has exactly five top-level entries, but `tools/` is a sixth;
- line 17 says the source changed 24 files, while the shipped proof lists 25 across the three patches;
- lines 250–291 mix explicitly superseded calibration with current release assertions.

**Fix:** remove all evaluation/calibration/headroom/mutation/timing evidence from README and keep checksum-bound evidence outside `task_files`. Correct operational facts and add a README hygiene test that rejects run IDs, scores, model outcomes, timings, and calibration tables.

### F13 — P1 — Harness and package are not portable or immutable enough

All reviewed files, including `test.sh` and `solve.sh`, are mode `0600`; `[task].version` is absent. The base image uses a mutable tag rather than a digest. APT packages float; PyPI packages are version-pinned without hashes; RewardKit installation is allowed to fail; source is fetched during image build. Stage artifacts have overlapping persistent paths and no declared size ceilings.

**Fix:** ship executable entrypoints as `0755`, data as `0644`, and directories as `0755`; add `[task].version`; digest-pin the image; snapshot/lock APT and hash-lock Python wheels/transitives; make required RewardKit installation hard-fail for judged images; verify the exact task archive as the Harbor user and publish its checksum.

### F14 — P1 — Verifier–Oracle independence is not fully attested

Positive evidence: candidate scoring does not compare patches/hashes, most important checks execute exported behavior and HTTP outcomes, and exact exported constructor names are disclosed as the public API.

Residual coupling risk: no structurally different full implementation has passed; the Oracle is sliced directly from the upstream change; docs/OpenAPI checks use literal tokens; hidden tests use exact exported forms; self-tests verify Oracle/golden evidence rather than alternate equivalence. Oracle 1.0 therefore proves reference compatibility and deterministic solvability, not the no-coupling release gate.

**Fix:** retain at least two structurally different complete passing implementations, plus Oracle-shaped-but-wrong mutations and correct implementations that relocate docs/OpenAPI internals. Ensure every literal check corresponds to a genuinely public requirement.

### F15 — P1 — Calibration and headroom evidence is insufficient

The Oracle passes all four stages and no-op returns zero, but all runs used public networking. Only one real solver/model was evaluated. It never reached Stage 4 because of the verifier defect. The shipped calibration record explicitly says it is superseded; the horizon-ablation contract says `NOT RUN`; no Terra success/outage/malformed/repeat evidence exists.

**Fix:** after repair, freeze a new checksum and retain Oracle at least three times, clean valid no-op with zero progress, compile/interface-only, lazy-eager, value-full-materialization, false Jaro/subsequence, all-routes gate, cap-disabled-in-Stage-3, hardcode, Oracle-shaped-wrong, alternate-valid, protected-read/tamper, license-URL false-positive regression, and Terra success/outage/partial/malformed/disagreement trials. Evaluate multiple fixed solver models/attempts and run the horizon ablation.

## Prompt–verifier coverage matrix

| Stage | Requirement | Current evidence | Verdict |
|---|---|---|---|
| 01 | Search routes/flag/storage APIs absent at base | Real binary, `go doc`, hidden base tests | Covered |
| 01 | Agent actually investigates and records evidence | Non-empty handoff shapes; verifier itself reproduces gaps | **Gap / no-op progress** |
| 02 | Score-desc top-K equivalence and allocation advantage | Seeded equivalence plus Stage 4 allocation guard | Covered |
| 02 | Asc/desc value limit without materializing full set | Output first-K only | **Gap** |
| 02 | Lazy constructor defers until first use | Checks only that it has run after `Next()` | **False-positive gap** |
| 02 | Partial results, all healthy drains, joined errors/warnings | One healthy set + one error string | Partial |
| 02 | Duplicate collapse/higher score | Value order and score-tie cases | Covered |
| 03 | Substring rune decay and AND chain | Verifier-owned hidden tests | Covered |
| 03 | Actual Jaro-Winkler and subsequence semantics | Mostly score bounds/self-consistency | **Gap** |
| 03 | Six GET/POST NDJSON endpoints | Basic success on all routes; content/framing depth uneven | Partial |
| 03 | Full query parameter behavior including `match[]` | `match[]` absent; parser-negative matrix incomplete | **Gap** |
| 03 | All routes unavailable with flag off | Metric-names GET only | **Gap** |
| 03 | Max-limit zero disables cap | Only executed in Stage 4 | **Stage misalignment** |
| 03/04 | Metadata concurrency/race and memo assumption | Concurrent HTTP plus package `-race`; fail-open skip; no direct memo probe | Partial |
| 04 | Unicode, batch boundaries, disconnect | Runtime probes and hidden Unicode test | Mostly covered |
| 04 | Coherent adoptable docs | Cross-file token scan | **False-positive gap** |
| 04 | Truthful final report | Non-empty JSON types only | **Claim gap** |
| 04 | Cumulative regression | Major storage/filter/HTTP paths rerun | Partial because earlier gaps remain |

**Coverage conclusion:** 100% behavioral, edge, negative, and adversarial coverage is statically disproven.

## Evaluation classification

| Evaluation | Observed outcome | Critical review classification |
|---|---|---|
| Oracle `eval_140822` | Four stages, all reward fields 1.0; judges correctly skipped | Deterministic solvability evidence, but not a no-network or no-coupling attestation because effective network was public and only Oracle shape passed. |
| No-op `eval_140823` | Stage 1 and 2 reward 0; `valid_trial=0`; Stage 1 still promoted | Official no-op reward is zero, but validity classification is wrong (missing trajectory) and Stage 1 continuation violates strict gating. It does not test a clean valid no-op score. |
| Terminus/Gemini `eval_140864` | Stages 1–2 pass; Stage 3 all weighted functional checks pass; integrity alone fails | **Verifier false positive / inconclusive for model quality.** Apache license URL plus `net/http` in a heredoc was misclassified as egress. Exclude from solver-failure statistics and training labels. |

All three share task checksum `c0c5847fec291946566e8466e81b79a8441dc53ccedefb2c6ff8687cfb3ecf1b`, all record public network override, and all applicable judge statuses say not requested. No CTRF file is present; `reward-details.json` is granular but does not replace a standard execution/test classification artifact.

## Reward calculation and `reward.json` decision

The guide's formula is appropriate for this task and the arithmetic helper implements it correctly:

```text
D_score = D_num / D_den

reward = binary_reward = 1
  iff valid_trial = 1 and every required deterministic gate passes;
otherwise 0.

N_score = N_num / N_den

training_score =
  (D_num + lambda * N_num) / (D_den + lambda * N_den)
```

The current **configuration and merge policy are not best**. Required changes:

1. Keep deterministic behavior and validity as the sole authority for `reward`, `binary_reward`, promotion, and `stage_complete`.
2. Use `openai/gpt-5.6-terra` with verifier-only `OPENAI_API_KEY` for process/validity and final merge-readiness; skip Oracle/controls.
3. Use only complete applicable judge evidence. Missing/partial provider output makes N unavailable, not zero and not partially renormalized.
4. Restrict lambda to `[0,1]`. Because judges are required to matter, replace the misleading default `0.0`; use `0.5` as an initial calibration candidate and justify the final value empirically.
5. Ensure a clean no-op has `reward=0`, `binary_reward=0`, `D_score=0`, and `training_score=0`, while remaining `valid_trial=1` if untampered.
6. Keep continuous diagnostics off the platform-scored numeric surface unless downstream field-selective parsing is proven.

Safest canonical scored file:

```json
{ "reward": 0.0 }
```

Store the guide-aligned detail separately, including deterministic numerator/denominator/score, valid trial, N applicability and components, process/validity/merge-readiness, disagreement, lambda, training score, and failure classification.

## Required actions from `swe_multi_step_long_horizon_guide.md`

1. Enforce strict `min_reward=1.0` on every non-final stage; stop after failure while retaining partial unscored evidence.
2. Make the final stage cumulative and close every earlier requirement, including requirements currently missing from Stage 2/3 verification.
3. Treat environment isolation—not trajectory text scanning—as the primary anti-contamination boundary.
4. Set task `allow_internet=false`, explicit per-step `network_mode="no-network"`, and reject public overrides; give only the Terra reviewer a separate bounded egress path.
5. Separate deterministic truth, trial validity, infrastructure/verifier defects, and qualitative annotations.
6. Configure and execute OpenAI Terra judges with protected key, bounded evidence, repeats, disagreement, applicability, and deterministic fallback.
7. Keep Oracle deterministic-only with N/A judge/lambda fields; run repeated exact-package Oracle and no-op controls.
8. Add requirement-to-test and prompt–verifier–Oracle matrices with positive, negative, edge, fault, mutation, and alternate-valid evidence.
9. Remove all evaluation evidence from README; freeze a new version/checksum after packaging and policy repairs.

Until these changes are made and re-evaluated under explicit no-network settings, this task should not be released or used to book model-quality or training rewards.
