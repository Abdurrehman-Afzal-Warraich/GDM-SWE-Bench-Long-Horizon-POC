# QC checklist disposition — volcano-k8s135-adaptation **v10**

Paste the **Check** and **Notes** values below into your per-task xlsx copies
(`Generic-QC-Rubric_volcano-k8s135-adaptation-v10_.xlsx`, `LH-Task-Review_…-v10_.xlsx`,
`LH-Eval_…-v10_.xlsx`). Every row Hamid marked **FAIL** on v9 is dispositioned here as
**PASS** (fixed, with evidence) or **DEFEND** (platform-provided / by-design).

**Package:** `Task8/volcano-k8s135-adaptation-v10.zip`
sha256 `48f0dde328eac254099891c1dac2d1eba5d96dc012b61c3e7c9ca267acd8d5e9`

**Evidence base (this build, Data-OS):** Oracle 296219 all 4 stages pass; no-op 296222 fails
S01; frontier terminus 296255 = **S1✅ S2✅ S3✅ S4❌(valid, integrity clean)** — first fully
clean headroom trial; plus executed controls in `tests/test_controls.py`.

---

## Generic QC Rubric tab

| Check ID | v9 | v10 | Evidence / note |
|---|---|---|---|
| FS-02 | FAIL | DEFEND | Hidden tests run from isolated `/tmp/verifier-corpus`; non-root/process-teardown/verifier-identity are Harbor sandbox guarantees (VALIDATION_EVIDENCE §G). |
| PQ-03 | FAIL | PASS | Strict terms now consistent: `allow_internet=false`, network policy uniform; Stage 04 closure behavioral (no exact-file term). |
| PQ-04 | FAIL | PASS | Honest path feasible & disclosed: `go run …/code-generator/cmd/<gen>` + `go mod tidy` (cache-backed); frontier completed S02 in 296255. |
| PQ-05 | FAIL | PASS | Difficulty is engineering, not benchmark mechanics: filename gate removed; tooling policy disclosed every stage. |
| PV-01 | FAIL | PASS | `requirement_map.json` updated; closure is implementation-neutral; strict checks trace to disclosed behavior. |
| PV-02 | FAIL | PASS | Verifier tests only disclosed behavior — exact `passive_assume_cache.go` requirement removed from `CRITICAL_IMPLEMENTATION_PATHS` and hidden test. |
| PV-04 | FAIL | DEFEND | Public network is the intended Data-OS run mode (owner-confirmed); anti-cheat is the integrity scanner + leak patterns, not network isolation. |
| PV-05 | FAIL | PASS | Prompt-required reports are explicitly non-decisive (`training_score` only), disclosed in every stage; critical set unchanged. |
| VC-03 | FAIL | PASS | Eval bundles now preserve `reward-details.json`, `reward-events.json`, `ctrf.json`, `test_output.log`, `trajectory.json` per stage. |
| VC-04 | FAIL | PASS(pending x3) | Oracle deterministic; ≥3 sealed-build Oracle replays recommended — run on `48f0dde`. |
| VC-05 | FAIL | DEFEND | Hidden corpus isolated from `/testbed`; freeze/hash is a harness guarantee (VALIDATION_EVIDENCE §G). |
| VC-06 | FAIL | PASS | Malformed/zero-test/crash paths handled; `test_reward_contract.py` covers zero-test guard + integrity edge cases. |
| TC-02 | FAIL | PASS | Implementation-neutrality proven: `test_control_valid_alternative_layout_passes_closure` (alt filename passes). |
| TC-03 | FAIL | DEFEND | Terminal stage is cumulative closure + installer Go1.25; late fault is the passiveAssumeCache wiring risk (fails in 296255). |
| TC-04 | FAIL | PASS | Closure split from source-shape; behavior vs file-presence separated (test_controls near-misses). |
| TC-05 | FAIL | PASS | Near-miss + valid-alternative matrix **executed** in `tests/test_controls.py` + Oracle/no-op/frontier controls. |
| AF-01 | FAIL | PASS | Honest capable agent can pass S01–S03 (frontier 296255 did); no filename/tool trap remains. |
| AF-02 | FAIL | PASS | Strictness proportionate: file-placement freedom honored; tooling policy disclosed. |
| AF-03 | FAIL | PASS | Verifier permits any-file implementation (behavioral symbol check only). |
| AF-04 | FAIL | PASS | Resources sufficient; codegen/reconcile path (`go run`/`go mod tidy`) available offline. |
| AF-05 | FAIL | PASS | Low frontier score is a clean valid failure (296255 S04 valid_trial=1, integrity clean). |
| RS-01 | FAIL | PASS | Reward formula correct; required deliverables explicitly non-decisive; contract tests assert critical set. |
| ER-01 | FAIL | DEFEND | Base image digest-pinned + Go SHA-pinned; apt top-up best-effort/non-fatal; RewardKit optional (judges off). |
| ER-03 | FAIL | DEFEND | Non-root agent / separate verifier identity = harness responsibility (VALIDATION_EVIDENCE §G). |
| ER-04 | FAIL | DEFEND | Public network is intended Data-OS mode (owner-confirmed); see PV-04. |
| ER-05 | FAIL | PASS | Integrity false-positives fixed (quote-aware scanner); infra vs task defects now separable in evidence. |
| VE-01 | FAIL | PASS | Controls present: Oracle, no-op, frontier, executed near-miss/valid-alternative matrix. |
| VE-02 | FAIL | PASS | All version identifiers rebound to v10; calibration bound to sha `48f0dde`. |
| VE-03 | FAIL | PASS(pending x3) | Agents/models/settings correct; run frontier + Oracle x3 on sealed build for count. |
| VE-04 | FAIL | PASS | Trajectories comprehensively reviewable — full per-stage evidence now shipped. |
| VE-05 | FAIL | PASS | Invalid/contaminated runs excluded (accidental swe-agent run identified & excluded). |
| AD-01 | FAIL | DEFEND | Hidden tests isolated; process-teardown is a harness guarantee. |
| AD-02 | FAIL | DEFEND | Trusted tool checksums pinned (`/opt/verifier-binary-checksums.txt`, 444); identity separation harness-provided. |
| AD-03 | FAIL | DEFEND | Public network is intended mode; anti-cheat via integrity scanner + leak patterns + novel hidden tests. |
| AD-04 | FAIL | DEFEND | Threat model addressed at the layers the package controls; rest harness-provided. |
| AT-02 | FAIL | PASS | Synthetic filename pass-condition removed; task reads natural. |
| DM-02 | FAIL | PASS | Revisions bumped/consistent at v10. |
| DM-03 | FAIL | PASS | Counts/status current in `calibration_summary.json`. |
| DM-05 | FAIL | PASS | `.sh` normalized to 0755, LF-only; `task.toml` at zip root; `[verifier.env]` present. |
| GX-01 | FAIL | DEFEND | Freeze/hash before verify = harness guarantee; hidden corpus already isolated. |
| GX-02 | FAIL | DEFEND | Non-root agent / separate identity = harness guarantee. |
| GX-03 | FAIL | PASS | Behaviorally-correct alt implementation passes (filename decoupled) — proven by control + Oracle. |
| GX-04 | FAIL | DEFEND | Complete submission capture = harness guarantee. |
| GX-05 | FAIL | PASS | Hidden tests execute outside persistent tree (`/tmp/verifier-corpus`). |
| GX-06 | FAIL | DEFEND | Immutable-base regression baseline = harness/platform; task ships base asserts in Dockerfile. |
| GX-07 | FAIL | PASS | Stage 01 reproducer is symbol/behavior based (implementation-neutral base-gap probe). |
| GX-08 | FAIL | DEFEND | Terminal stage adds cumulative closure + installer Go1.25 + passiveAssumeCache wiring risk. |
| GX-09 | FAIL | PASS | Only fair valid frontier failures counted; 296255 is clean valid (integrity clean all stages). |
| GX-10 | FAIL | PASS(pending x3) | Run same-artifact verifier + independent agent x3 on `48f0dde`. |
| XA-01 | FAIL | PASS | No internal contradiction: any-file freedom consistent with behavioral closure. |
| XA-02 | FAIL | PASS | Every strict check traces to disclosed, implementation-neutral requirement. |
| XA-03 | FAIL | PASS | Coverage incl. executed near-miss + valid-alternative (test_controls.py). |
| XA-04 | FAIL | PASS | Approved offline codegen/reconcile path disclosed (`go run` + `go mod tidy`). |
| XA-05 | FAIL | PASS | Volume-binding closure behavior-based (symbol, any file). |
| XA-06 | FAIL | DEFEND | Public agent network is the intended Data-OS mode (owner-confirmed). |
| XA-07 | FAIL | PASS | Clean valid fair frontier failure exists (296255). |
| XA-08 | FAIL | PASS | Calibration bound to exact v10 build `48f0dde`. |
| XA-09 | FAIL | PASS | Prompt-required deliverables explicitly non-decisive in every stage. |
| XA-10 | FAIL | DEFEND | Agent-teardown before verifier-asset creation = harness guarantee; corpus isolated. |

## LH-Task-Review tab & LH-Eval tab

These mirror the same clusters. Disposition by theme:
- **Headroom credible / clean valid failure / eligible for solve-rate** → PASS (296255 clean valid terminal failure; run frontier x3 to state a rate).
- **Contamination / network controlled** → DEFEND (public network = intended Data-OS mode).
- **Multiple valid implementation paths / final closure implementation-neutral / strict checks faithful** → PASS (filename decoupled; valid-alternative control passes).
- **Stage-2 tooling fairness / instruction ambiguity** → PASS (go run + go mod tidy disclosed every stage).
- **Near-miss/valid-alternative/adversarial controls executed** → PASS (test_controls.py).
- **Frozen/hashed candidate, non-root sandbox, hidden-test teardown, submission capture** → DEFEND (harness guarantees; corpus isolation done in-package).
- **Reward contract / required deliverables gate-or-non-decisive** → PASS (explicitly non-decisive, disclosed).
- **Release provenance / evidence bound to exact revision / version consistency** → PASS (all v10, sha `48f0dde`).
- **Stability x3 / horizon ablation** → PASS(pending): run Oracle x3 + frontier x3 on the sealed build.

## Remaining owner actions before submit
1. Frontier x3 (+ Oracle x3) on `48f0dde` to state the solve-rate and satisfy the x3 stability rows (VC-04, VE-03, GX-10).
2. Transcribe the Check/Notes above into the three xlsx copies.
3. Log Dev Defense text (VALIDATION_EVIDENCE §"Dev Defense drafts") in tracker column M.
