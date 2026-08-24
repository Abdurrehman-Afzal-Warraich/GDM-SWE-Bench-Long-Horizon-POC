# Critical Review — `cilium-listenerset-integration` (`rev_3__17332`)

Review date: 2026-08-17  
Task checksum in all retained evaluations: `01becd6d6ff1ac49d262ffff8721e976a2e32597910281ca50fa704306f51e55`  
Decision: **Reject pending verifier, RewardKit, anti-cheat, coverage, documentation, and packaging repair**

## Executive conclusion

This is a credible four-stage Cilium controller task with meaningful state progression, verifier-injected Go tests, exact protected test-ID enforcement, broad Gateway API package regression execution, and useful first/late/recovery fault cases. One Oracle run passes all four stages, while both retained frontier-agent runs pass Diagnose and fail Core. Those are valuable signals, but this revision is not safe to release or use for booked rewards.

The principal blockers are structural:

- Stage 1 can receive a perfect score from an executable that merely exits zero plus canned JSON. The verifier's independent probe proves the base is missing ListenerSet integration, but never proves the submitted reproducer demonstrates anything.
- Failed behavior receives nonzero official reward: the real runs finish with `reward=0.35` and `reward=0.25` even though `binary_reward=0`. A clean no-op would receive `0.30` at Diagnose and `0.25` at later stages from pre-existing/integrity checks.
- No stage declares `min_reward`. Both real agents therefore ran Stages 3 and 4 after Stage 2 failed; the self-test explicitly forbids `min_reward`, while the guide describes strict non-final promotion.
- The integrity baseline is agent-writable in practice. Retained trajectories show a root shell, while `/opt/verifier/base_tree` and `/opt/verifier/binary_checksums.txt` are only image files/chmod `0444`; root can replace those baselines, verifier dependencies, and even the unverified `sha256sum` used to check them.
- RewardKit reads `LAMBDA`, but `task.toml` exports `NONDETERMINISTIC_LAMBDA`, so the observed blend is always zero. It also runs merge-readiness on failed final stages, accepts incomplete repeats/dimensions, uses a non-guide formula, and sent both Gemini Core repeats into HTTP 400 `INVALID_ARGUMENT`.
- `OPENAI_API_KEY` is absent from `[verifier.env]`. If OpenAI is the required provider for qualitative checks, the key cannot reach the verifier and no OpenAI qualitative check is currently configured; adding the secret without selecting an OpenAI judge would still be ineffective.
- Requirement-level coverage is not 100%. Conflict reporting, direct-Gateway/GAMMA preservation, isolated change-trigger paths, all-kind negative status, and recovery of the multi-ListenerSet late-failure case are not independently protected.
- README contains evaluation evidence and claims contradicted by the retained files, including Oracle/no-op/readiness results and measured timings.

## Attestation summary

| Area | Verdict | Critical conclusion |
|---|---|---|
| Behavioral instructions | Partial | The engineering outcomes are mostly behavioral, but artifact prose is trusted and some implementation/state expectations are underspecified. |
| Prompt–verifier alignment | Fail | Stage 1 admits a canned reproducer; several Stage 2–4 requirements lack an equivalent executable assertion. |
| Test coverage | Fail | Strong core cases exist, but the requirement matrix has material positive, negative, lifecycle, and recovery gaps. |
| Anti-cheat | Fail | Trajectory inspection fails open and is bypassable; trusted manifests and toolchain state are writable by the root agent. |
| RewardKit | Fail | Lambda wiring, applicability, complete-set handling, provider reliability, field schema, merge formula, and the required OpenAI qualitative-check credential/provider wiring do not meet policy. |
| Reward formula | Fail in implementation | The guide formula is appropriate; official partial reward, unused promotion, no-op credit, and non-guide blending must be replaced. |
| Grading integrity | Fail | A failing submission receives official positive reward and continues through every stage; canonical output omits required D/N data. |
| Verifier–Oracle coupling | Partial | Tests are largely behavioral and do not literal-match the patch, but only the exact upstream Oracle is proven and Stage 1 mirrors a verifier-owned fact rather than the submitted reproduction. |
| Harness and packaging | Fail | Retained execution works, but root trust, mutable baselines, `0600` modes, dependency pinning, and provenance drift are release blockers. |
| README evaluation evidence | Fail | Oracle results, no-op results, timing, and readiness claims are packaged in README. |

## Release-blocking findings and fixes

### F01 — P0 — Diagnose has a complete behavioral false-positive path

**Evidence.** Stage 1 requires the submitted executable to demonstrate a concrete missing behavior (`steps/01-diagnose/instruction.md:7-10`). `check_candidate_reproducer` only checks that the file is executable, runs it, accepts exit code zero, and confirms production source stayed unchanged (`tests/stage_check.py:269-306`). The separate hidden probe checks the base repository, not the submitted executable. Artifact validation only requires asserted booleans, nonempty strings/lists, five route-kind labels, and existing evidence files (`tests/verifier_lib.py:163-203`).

**Impact.** A script containing only a successful exit plus a syntactically valid, canned handoff can pass the entire stage. This is both prompt–verifier misalignment and verifier–Oracle coupling: the verifier supplies the actual behavioral fact while the candidate only attests to it.

**Fix.** Make the submitted reproducer emit a typed observation that the verifier independently parses, or compile/run verifier-owned code that imports and exercises the submitted reproducer. Require a specific absent-status/configuration observation and reject empty/no-op execution. Bind raw output hashes to the artifact. Add a canned-reproducer negative control.

### F02 — P0 — Official reward is continuous, no-op is nonzero, and promotion is not enforced

**Evidence.** `build_payload` sums passing weights and assigns that sum to official `reward`; a missing artifact merely caps it at `0.59` (`tests/stage_check.py:434-475`). A clean Diagnose no-op earns `0.20` for unchanged source plus `0.10` for missing-trajectory integrity, or `0.30`. A later clean no-op earns `0.15` repository integrity plus `0.10` trajectory, or `0.25`. The retained agents end with official `0.35` and `0.25` despite failed behavior. `promotion_eligible` is written but Harbor never reads it. `task.toml` has no `min_reward`, `stage_test.sh` always exits zero, and the local contract self-test requires that `min_reward` be absent (`test_reward_contract.py:29-37`).

**Impact.** The package violates the guide's strict official reward, the user's zero no-op policy, and stage completion semantics. Both failed Core runs proceeded through Review and Harden, proving this is not theoretical.

**Fix.** Set `reward == binary_reward` to `1` only for a valid all-required-check pass and `0` otherwise. Preserve partial work only in `deterministic_score` and `training_score`. Add `min_reward = 1.0` to Diagnose, Core, and Review. Keep full-pipeline runs as author validation jobs when desired, but make release evaluation stop before new agent work after a failed non-final gate. Add a meaningful-work/no-op rule that zeroes D numerator when required agent-produced evidence/work is absent.

### F03 — P0 — Root can rewrite the integrity sources of truth

**Evidence.** The retained agent terminal is `root@...:/testbed`. The Dockerfile stores `/opt/verifier/base_tree` and `/opt/verifier/binary_checksums.txt` in the same image (`environment/Dockerfile:46-83`). `chmod 444` does not protect a file from root. At verification, the checker trusts those paths and calls an unverified `sha256sum` (`tests/verifier_lib.py:257-280`). The Python venv and standard-library/runtime files used by the verifier are also in agent-writable image paths; only three binary files are listed.

**Impact.** A malicious root agent can replace the base-tree manifest, rewrite the binary manifest, patch RewardKit/Python dependencies, or replace `sha256sum`, then satisfy checks intended to prove immutability. Git metadata checks do not repair this trust-boundary failure.

**Fix.** Run the agent as a non-root UID with a read-only root filesystem and separately mounted writable `/testbed` and output paths. Mount manifests, verifier runtime, hidden tests, and trusted tools only for the verifier phase from a read-only external source. Compute hashes with verifier-owned code/tooling and sign or externally bind the manifest. Add root/write/tamper adversarial controls.

### F04 — P0 — Trajectory anti-cheat fails open and is easy to bypass or falsely trigger

**Evidence.** Missing non-Oracle trajectory returns success with zero commands audited (`tests/verifier_lib.py:433-445`). The regex only catches selected commands at line start (`:447-450`), so `env curl`, Python/Go HTTP, `gh`, alternative package managers, shell indirection, and many Git/network paths evade it. The scanner recursively treats generic `text` fields as commands (`:457-472`), so quoted prompt or discussion text can be misclassified. Evaluation configuration records public networking.

**Impact.** The README/task metadata call this a deterministic network boundary, but it is only incomplete detective logic. Absence of audit evidence is rewarded, while unrelated prose may invalidate a trial.

**Fix.** Enforce agent-phase network isolation or an explicit egress allowlist at the platform boundary. Require a signed/complete structured executed-command stream and fail closed when it is absent. Parse actual tool-call records, not arbitrary text. Treat trajectory scanning as supporting evidence, not the security boundary.

### F05 — P0 — RewardKit formula, lambda wiring, and applicability do not follow the guide

**Evidence.** `task.toml` exports `NONDETERMINISTIC_LAMBDA` (`task.toml:36-39`), but the merger reads `LAMBDA` (`run_optional_judges.sh:154-158`); retained rewards therefore show `training_score_lambda=0.0`. The merger first normalizes whatever dimensions happen to exist and then uses `(training + lambda*rubric_score)/(1+lambda)` (`:159-168`), not `(D_num + lambda*N_num)/(D_den + lambda*N_den)`. It accepts any positive number of successful repeats and any subset of returned dimensions (`:92-145`). Merge-readiness is selected at every final stage and merely zeroed after deterministic failure (`:61-80`, `:149-162`), whereas the guide limits it to a final valid deterministic pass. `research_score` adds another unsupported blend.

**Impact.** Judge evidence is inert in training despite being advertised, and would be incorrectly normalized if enabled. Failed final submissions still incur an unnecessary merge-readiness call. Incomplete judge evidence can be silently treated as a complete set.

**Fix.** Read the declared `NONDETERMINISTIC_LAMBDA`. Emit D/N numerator and denominator fields and apply the exact guide formula. Require every configured repeat and every applicable dimension before blending; otherwise mark the set unavailable and use `training_score=D_score`. Run process and validity on eligible agent stages, merge-readiness only after final valid deterministic success, and move task-quality to author QC. Remove `research_score` unless a separate documented consumer requires it.

### F06 — P0 — RewardKit provider reliability is not release-attested

**Evidence.** The task pins `gemini/gemini-3.5-flash`, while the guide's supported example is Gemini 3.6 Flash or Sonnet 4.6. In the Gemini solver's Core stage, both RewardKit repeats fail with HTTP 400 `INVALID_ARGUMENT`; `judge_status.json` correctly records unavailable only after those failures. Other stages run, but one frozen input failing both repeats proves the path is not uniformly reliable. Judge inputs include trajectories up to about 749 KB and cumulative agent outputs; trajectory copying has no explicit byte bound.

**Impact.** RewardKit completion is not guaranteed for a required staged input, and failure diagnosis does not distinguish malformed/oversized request content from other bad arguments. Stage-level training evidence is incomplete.

**Fix.** Upgrade to a supported judge model, add an image-level RewardKit smoke test and fixed-fixture end-to-end test, cap every input class and total request size, and classify provider 400/request-construction failures explicitly. Re-run all stages with all required repeats after freezing the repair.

### F07 — P0 — Requirement-level test coverage is not 100%

**Evidence.** The verifier has strong tests for allowed-listener policies, five route kinds, hostname/name/section/port cases, namespace attach/detach events, invalid Gateway, Secret removal, and first/late retrieval faults. It does not independently assert Stage 2 listener-conflict reporting; generated configuration for all five baseline route kinds; direct-Gateway and GAMMA preservation; isolated ListenerSet/Route/Secret watch-trigger paths; negative disallowed-parent status for GRPC/TLS/TCP/UDP; status consistency for section/port mismatches; or recovery after the multi-ListenerSet late-failure case. The late-failure test stops after confirming CEC unchanged (`stage4_gateway_fault_test.go:161-183`) and does not retry. Failure atomicity only compares CEC configuration, not all published/status state.

**Impact.** An implementation can omit or regress disclosed behavior and still receive a perfect deterministic score. Broad repository tests are useful but are not verifier-owned proof that these ListenerSet-specific requirements run and cannot be weakened.

**Fix.** Add protected, exact-ID tests for each missing requirement and each route-kind/status combination. Add separate event/requeue tests for ListenerSet, Route, and Secret changes; targeted direct-Gateway/GAMMA regressions; explicit conflict status; full desired-state/status atomicity; and a successful retry after the multi-ListenerSet late fault. Retain mutation controls for every new check.

### F08 — P1 — Artifact truth is largely self-reported

**Evidence.** Command entries require a nonempty string, claimed exit code zero, and an existing output file, but are not tied to an observed command event (`verifier_lib.py:111-128`). `changed_files`, behavior claims, feedback resolutions, and risk text are primarily shape-checked (`:204-253`). Only Stage 1 requires twin JSON equality; later claims are not reconciled with actual Git diff or test events.

**Impact.** Canned artifacts earn deterministic weight and can contradict verifier observations. This is especially problematic because artifacts participate in binary completion.

**Fix.** Generate command/diff evidence from verifier observations, bind claims to event IDs and hashes, verify changed paths against the actual diff, impose cardinality/size bounds, and keep uncorroborated prose as zero-weight annotation.

### F09 — P1 — Canonical reward JSON is incomplete and Oracle N fields are wrong

**Evidence.** Canonical output contains normalized scores but no deterministic/non-deterministic numerator or denominator (`stage_check.py:365-379`). Oracle skips judges in `judge_status.json` yet writes `non_deterministic_score=1.0` because `nd_score=raw_reward` for Oracle (`:444-470`). The guide requires judge-only fields and lambda to be null/N/A for Oracle. Task metadata also omits explicit `reward_formula` and `training_score_formula` declarations.

**Fix.** Adopt one versioned canonical schema containing validity, completion, D numerator/denominator/score, N applicability/numerator/denominator/score, configured lambda, and training score. Use null judge fields/lambda for Oracle. Validate cross-file invariants before exit and declare both formulas in `task.toml`.

### F10 — P1 — README contains prohibited evaluation evidence and inaccurate assertions

**Evidence.** README reports measured Oracle timing (`README.md:42-49`), Oracle reward, no-op result, and Harbor/RewardKit readiness (`:51-55`). The only retained Oracle completes the entire run in about 5 minutes 44 seconds, not the stated aggregate 93–113 minutes. No no-op evaluation is retained, and the static formula shows a clean no-op gets positive official reward. The README also claims deterministic network audit and binary integrity that the threat model does not support (`:25-40`).

**Fix.** Remove all evaluation/control outcomes and timings from README. Move them to author-only, checksum-bound validation records outside `task_files`. Keep README to safe operator instructions and only claims proven by the packaged boundary.

### F11 — P1 — Verifier–Oracle independence is only partial

**Evidence.** Positive: hidden tests run public controller behavior through a fake client, require exact test execution, and do not compare patch hashes or source strings. Negative: Stage 2 Oracle decrypts/applies the exact 97-file upstream diff; Stages 3–4 apply exact scripted corrections; there is only one Oracle and no alternate-valid implementation. Stage 1's verifier-owned base probe supplies the behavior the submitted reproducer should prove.

**Classification.** **Partial, not a clean pass.** Direct literal coupling is low, but alternate implementation acceptance and Oracle omission sensitivity are unproven.

**Fix.** Add an independently structured correct implementation, Oracle-shaped wrong mutations, and requirement-specific mutations. Repeat Oracle at least three times under the frozen checksum. Repair Stage 1 so the candidate evidence—not the verifier's independent fact alone—must demonstrate the outcome.

### F12 — P1 — Provenance, calibration, and version metadata drift

**Evidence.** `provenance.json` names upstream head `7bff741...`, while the Dockerfile builds the encrypted diff from `833b1f8...`. The provenance checksum is a placeholder rather than a recorded author-side hash. Calibration claims Oracle/no-op/Gemini outcomes without checksum-bound artifacts. `task.toml` has no task revision field, names calibration `v2`, and estimates eight expert hours despite its own README allocating more than 90 verifier minutes plus four large engineering phases.

**Fix.** Reconcile the exact source/merge commit relationship, record immutable patch and package hashes outside agent-visible files, add a task revision, and replace prose calibration with checksum-bound control manifests. Re-estimate human effort from observed author/solver work.

### F13 — P1 — Packaging and dependency reproducibility need hardening

**Evidence.** Every shipped file is mode `0600`, including shell entrypoints. Retained Harbor execution succeeds because launchers explicitly invoke Bash, but the archive is not portable. Base images use mutable tags, APT dependencies are unversioned, and Python packages have versions but no locked transitive hashes. Only a local reward-contract script is present; it passes while encoding the defective absence of `min_reward` and does not test the installed judge end-to-end.

**Fix.** Normalize modes (`0755` entrypoints, `0644` data), pin image digests and dependency locks/hashes, test the exact packaged archive on the target Harbor version, and replace self-tests with guide-level binary/no-op/promotion/D-N/applicability invariants.

### F14 — P1 — `OPENAI_API_KEY` is missing for OpenAI qualitative checks

**Evidence.** `[verifier.env]` declares only `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, and `NONDETERMINISTIC_LAMBDA` (`task.toml:36-39`). The selected judge is currently `gemini/gemini-3.5-flash`, and `run_optional_judges.sh` explicitly requires `GEMINI_API_KEY`; there is no OpenAI judge selection or `OPENAI_API_KEY` verifier passthrough.

**Impact.** Under the requested policy that qualitative checks use OpenAI, those checks cannot authenticate or execute. Merely adding an OpenAI secret while leaving every judge configured for Gemini would not fix the qualitative path and would unnecessarily expand secret exposure.

**Fix.** Add the key only to the verifier environment, never the agent environment:

```toml
[verifier.env]
OPENAI_API_KEY = "${OPENAI_API_KEY:-}"
```

Select one supported OpenAI judge model consistently in every qualitative `judge.toml`, make the runner validate `OPENAI_API_KEY` for that provider, record provider/model/key-availability status without exposing the secret, and add an end-to-end qualitative smoke test. Oracle and no-op/control paths must not invoke the qualitative provider. If Gemini remains the intended judge, do not add an unused OpenAI credential; instead document that OpenAI qualitative checks are not part of this task.

## Prompt–verifier requirement matrix

| Prompt requirement | Current independent evidence | Verdict |
|---|---|---|
| Submitted Stage 1 reproducer demonstrates missing behavior | Executable + exit zero only; independent verifier probe proves base limitation separately | **Gap / false positive** |
| Stage 1 production source unchanged | Tree comparison before/after reproducer | Covered |
| ListenerSet extends Gateway and status/config work | Stage 2 baseline reconciliation checks Gateway, ListenerSet, HTTPRoute, CEC | Covered |
| `allowedListeners` None/All/Same/Selector | Six positive/negative policy cases | Covered |
| Listener conflict reporting | No targeted hidden assertion | Gap |
| Five route kinds use ListenerSet parents | Stage 2 checks Accepted status for all; Stage 3 checks generated config for section/port cases | Partial |
| Reconcile after ListenerSet/Route/Secret changes | Manual reconcile after combined ListenerSet+HTTPRoute edit and Secret deletion | Partial; isolated watch/event paths absent |
| Invalid Gateway remains invalid | Explicit Accepted/Programmed negative test | Covered |
| Direct-Gateway and GAMMA preserved | Broad repository suites only; no exact protected regression ID | Partial |
| ListenerSet-only hostname | Generated CEC contains ListenerSet-only route | Covered |
| Same-name Gateway and ListenerSet stay distinct | ListenerSet status and generated configuration | Covered |
| Section and port across all route kinds | Positive and negative generated-config cases for five kinds | Covered for config; status not checked |
| Namespace label attach/detach event requeue | Both transitions plus unrelated namespace negative | Covered |
| Disallowed ListenerSet route gets negative status | HTTPRoute only | Gap for GRPC/TLS/TCP/UDP |
| First retrieval failure, all five kinds, identity, atomicity, retry | Errors-Is, identifiers, CEC unchanged, successful retry | Covered for one ListenerSet |
| Late failure with multiple ListenerSets | Error/identifiers and CEC unchanged | Partial; no successful retry and no full-state/status comparison |
| Preserve all earlier behavior in final | Stage 4 cumulatively injects Stage 2/3 tests and broad packages | Covered subject to earlier gaps |

**Coverage conclusion:** 100% coverage is not established and is false at the stated requirement level. Edge and negative testing is meaningful but incomplete.

## Reward calculation and `reward.json` decision

The formula in `swe_multi_step_long_horizon_guide.md` is the best fit:

```text
D_num   = sum(u_i * w_i)
D_den   = sum(applicable deterministic weights)
D_score = D_num / D_den

reward = binary_reward = 1 only if valid_trial=1 and every required deterministic check passes;
otherwise reward = binary_reward = 0.

N_num   = sum(r_j * v_j)
N_den   = sum(applicable judge weights)
N_score = N_num / N_den

training_score = (D_num + lambda * N_num) / (D_den + lambda * N_den)
```

Required policy:

- Official `reward` is binary; partial progress lives only in D/training fields.
- A clean no-op receives zero D numerator and zero training score.
- Diagnose, Core, and Review use `min_reward = 1.0`; Final has no promotion target.
- Process and validity are the agent-stage training rubrics. Task-quality is author QC. Merge-readiness is applicable only after a final valid deterministic pass.
- Blend only a complete judge set. If unavailable/incomplete, `training_score=D_score`.
- Oracle has N applicability zero and null N/lambda fields.
- If judges are retained as trainer signals, use a documented nonzero value such as `lambda=0.5`; lambda zero is mathematically valid but misleading for a task that advertises judge-blended training.

For the retained Gemini final stage, current deterministic weights produce `D_num=0.35`, `D_den=1.0`; the correct official result is zero. If only process and validity are applicable, both retained scores are 1.0, and `lambda=0.5`, a guide-aligned record would be:

```json
{
  "reward": 0.0,
  "binary_reward": 0.0,
  "valid_trial": 1.0,
  "stage_complete": 0.0,
  "deterministic_score": 0.35,
  "deterministic_numerator": 0.35,
  "deterministic_denominator": 1.0,
  "non_deterministic_score_applicable": 1.0,
  "non_deterministic_score": 1.0,
  "non_deterministic_numerator": 0.75,
  "non_deterministic_denominator": 0.75,
  "training_score_lambda": 0.5,
  "training_score": 0.5273
}
```

This example describes scoring only; it does not validate the unexpectedly perfect validity/process judgments. After coverage repair, D weights and scores must be recalibrated.

## Retained evaluation integrity

### Oracle — `eval_111001__attempt_1__oracle`

- All four deterministic stages pass with `binary_reward=1` and `reward=1`.
- RewardKit is correctly skipped in `judge_status.json`.
- `reward.json` incorrectly records `non_deterministic_score=1.0` rather than null/N/A.
- One run proves exact-Oracle solvability only; the guide requires at least three clean repetitions.
- Total elapsed time is approximately 5m44s, contradicting README timing claims.

### Gemini — `eval_111002__attempt_1__terminus-2__gemini-3.6-flash`

- Diagnose passes.
- Core fails behavior and the required implementation artifact; deterministic fraction is `0.25` from integrity/trajectory.
- Both Core RewardKit repeats fail provider request validation with HTTP 400; this is judge unavailability, not agent invalidity.
- Review and Final still run. Final fails behavior but passes final artifact/integrity/trajectory, yielding current D `0.35` and improper official `reward=0.35`.
- Final merge-readiness is selected despite deterministic failure and zeroed afterward.

### GPT — `eval_111357__attempt_1__terminus-2__gpt-5.6-sol`

- Diagnose passes.
- Core fails behavior and artifact, yielding D `0.25`; later stages still run.
- Review and Final fail behavior and required artifacts; final current D and improper official reward are `0.25`.
- The run demonstrates credible agent-caused implementation failure, but not correct stage promotion or reward booking.

No retained clean no-op, hard-code, network attempt, root-tamper, malformed-artifact, alternate-valid, Oracle-repeat, or requirement-level near-miss run exists.

## Required release sequence

1. Repair Stage 1 so the submitted reproducer itself must prove the disclosed missing behavior; add canned/no-op controls.
2. Make official reward strict binary, zero clean no-op training, add `min_reward=1.0` to all three non-final stages, and replace the self-test's contrary invariant.
3. Move manifests/verifier/tooling outside the root agent's writable trust boundary and enforce agent network isolation.
4. Close every requirement-level hidden-test gap and add targeted mutation controls.
5. Implement the guide's D/N schema and exact lambda formula; fix the env variable and judge applicability/complete-set logic.
6. Configure the intended qualitative provider end to end: if OpenAI is required, declare verifier-only `OPENAI_API_KEY`, select the same supported OpenAI model in every judge config, and validate all repeats; otherwise explicitly document the Gemini-only policy. Keep inputs bounded.
7. Remove all evaluation evidence from README and reconcile provenance/timing/version metadata.
8. Normalize modes and lock images/dependencies.
9. Freeze a new checksum and retain Oracle×3, clean no-op, canned Stage-1 repro, targeted near-misses, hard-code/network/root-tamper/malformed-artifact controls, an alternate-valid implementation, judge outage controls, and multiple fixed-agent evaluations.

Until those steps pass, the task should not be released or used to book official or training rewards.
