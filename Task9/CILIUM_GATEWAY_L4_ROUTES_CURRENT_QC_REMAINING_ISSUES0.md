# Cilium Gateway L4 Routes - Consolidated QC Review and Remaining Issues

## Current QC Status


The current Cilium Gateway L4 Routes revision is materially improved compared with the previously reviewed version. Several earlier blockers have been fixed, including RBAC grading, documentation grading, the earlier `git remote` integrity false positive, non-root agent execution, trusted binary checksum checks, verifier-owned handoff hash chaining, artifact declaration cleanup, and explicit RewardKit N/A handling.

However, several task-level, verifier-level, evaluation-level, calibration-level, trust and isolation, long-horizon validation, instruction quality, test alignment, and test coverage issues still remain.

The task is now closer to acceptable and needs targeted repair rather than a redesign.

---

# 1. Headroom and Frontier Failure Status

## 1.1 Stage 3 is a completed run, not an incomplete or timeout failure

The supplied Gemini Stage 3 trajectory confirms that the agent:

- read the Stage 2 handoff;
- inspected the Gateway API implementation;
- implemented substantial TCPRoute and UDPRoute model, ingestion, translation, and reconciliation changes;
- encountered intermediate compile failures and repaired them;
- ran relevant visible Go tests;
- wrote the required report and handoff;
- marked Stage 3 complete.

Therefore, Stage 3 should not be classified as an incomplete-run or timeout failure.

### Current classification

**Stage 3: VALID TRIAL, PLAUSIBLE OR PROVISIONAL BEHAVIORAL FAILURE, exact decisive hidden requirement unresolved.**

The run has `valid_trial=1`, so it is not integrity-invalid. However, the supplied evaluation package does not preserve enough detailed verifier evidence to identify the exact deterministic check that caused Stage 3 reward 0.

### Required fix

Package the full Stage 3 verifier evidence, including:

- `reward-details.json`;
- exact deterministic check IDs;
- per-check weights and outcomes;
- hidden-test raw output;
- test execution counts;
- verifier logs;
- final patch or frozen candidate identity;
- integrity result;
- relevant artifacts.

Only after this evidence is available should the Stage 3 failure be classified as a confirmed valid behavioral headroom failure.

---

## 1.2 Stage 4 must not be double-counted as independent headroom

The Stage 4 trajectory also confirms that Gemini completed the stage.

The agent:

- modified the Helm configuration;
- rendered and checked Helm output;
- updated Gateway API documentation;
- created the final report and closure proof;
- wrote the final handoff;
- marked the task complete.

Therefore, Stage 4 is not an incomplete-run failure.

However, Stage 4 is cumulative. Because Stage 3 had already failed, Stage 4 may simply be re-detecting the inherited Stage 3 defect.

### Current classification

**Stage 4: DOWNSTREAM OR CUMULATIVE FAILURE. Do not count it as a second independent headroom event unless per-check evidence proves a new Stage 4 specific failure.**

### Required fix

Preserve Stage 4 detailed verifier results and clearly distinguish:

- inherited Stage 3 failures;
- new Stage 4 Helm configuration failures;
- documentation failures;
- final closure failures;
- cumulative regression failures.

---

## 1.3 Official headroom is still not release-validated

There is now a stronger behavioral signal than in the previous revision, but official headroom is still not cleanly measurable for release.

Reasons:

1. only one frontier trajectory is supplied;
2. the exact decisive Stage 3 hidden failure is not packaged;
3. all supplied evaluations still use public network despite the no-network task contract;
4. repeated frontier stability is missing;
5. valid-alternative evidence is missing;
6. some verifier coverage gaps remain.

### Current headroom status

**PROVISIONAL BEHAVIORAL SIGNAL, NOT YET RELEASE-VALIDATED HEADROOM**

---

# 2. Evaluation Network Policy Mismatch

## Issue

The task declares an intended no-network environment, but the supplied evaluation configurations still use:

`override_network_mode = "public"`

for:

- Oracle;
- no-op;
- Gemini.

This means the submitted calibration evidence does not reflect the task's declared contamination boundary.

A trajectory audit is not equivalent to actual network isolation.

## Why this matters

The benchmark is based on a public Cilium repository and public development history. Public network can allow:

- source PR lookup;
- upstream patch lookup;
- external implementation search;
- hidden contamination.

Even if the current trajectory does not visibly show cheating, the calibration evidence must prove the intended environment.

## Required fix

Rerun:

- Oracle;
- no-op;
- frontier agent runs;
- stability controls;

under the exact intended no-network configuration with no public override.

If verifier-side external access is required, isolate it from the agent execution environment.

---

# 3. Stage 2 Routecheck Behavioral Coverage Is Still Incomplete

## Issue

Stage 2 requires TCPRoute and UDPRoute:

- helpers;
- indexers;
- routechecks;
- RBAC.

The new revision has improved RBAC grading, and helper and indexer coverage is stronger.

However, dedicated behavioral verification of the routecheck semantics is still insufficient.

Build and vet success prove compilation, but do not prove route validation behavior.

## Missing or insufficiently proven behavior may include

- valid Gateway parent references;
- invalid or unsupported ParentRefs;
- namespace behavior;
- ReferenceGrant semantics;
- missing backend behavior;
- unsupported backend types;
- invalid backend references;
- listener compatibility;
- parent matching;
- relevant route status behavior.

## Risk

A partially correct routecheck implementation can potentially pass Stage 2.

## Required fix

Add deterministic protected routecheck tests that directly exercise the required TCPRoute and UDPRoute acceptance and rejection semantics.

---

# 4. Candidate Freeze Is a Fingerprint, Not a True Frozen Artifact

## Issue

The revision now records candidate fingerprints and tree state, which is an improvement.

However, the verifier still executes against the live mutable `/testbed` workspace.

A hash or fingerprint of the current workspace is not equivalent to freezing the complete candidate artifact and grading only that immutable copy.

## Guideline expectation

After the agent completes a stage:

1. terminate all candidate and agent processes;
2. capture the complete candidate state;
3. hash and seal the artifact;
4. materialize a verifier-owned candidate copy;
5. execute every verifier attempt against that exact frozen artifact;
6. do not use live `/testbed` for authoritative grading.

## Risk

Live workspace grading can be affected by:

- background processes;
- late filesystem mutations;
- verifier retry differences;
- race conditions;
- mutable Git state.

## Required fix

Implement a true verifier-owned frozen candidate bundle or copy and run authoritative grading against it.

---

# 5. Hidden Tests Still Touch the Persistent Agent Workspace

## Issue

The task has improved hidden-test protection:

- protected assets are not normally exposed;
- cleanup and recovery behavior is stronger;
- `/tests` and `/solution` protections are improved.

However, hidden tests are still injected into the live candidate repository during verification.

## Risk

If verifier cleanup is interrupted by:

- SIGKILL;
- container crash;
- host termination;
- unexpected verifier failure;

hidden material can remain in the persistent environment and potentially become visible in a later stage.

Cleanup should not be the primary security boundary.

## Required fix

Run hidden tests only in:

- a verifier-owned temporary candidate copy;
- a separate sandbox identity;
- a directory inaccessible to the agent.

Do not inject hidden files into persistent `/testbed`.

---

# 6. Trust and Sandbox Isolation Is Improved but Still Not Fully Guideline-Compliant

## Fixed

The new revision improves trust substantially:

- agent is unprivileged;
- verifier assets are root-owned;
- binary and toolchain integrity checks exist;
- earlier `git remote` false-positive logic was corrected.

## Remaining issue

The strict long-horizon trust model still expects stronger separation between:

- agent identity;
- candidate execution identity;
- verifier and root identity;
- hidden-test assets;
- trusted tools;
- frozen artifacts.

The authoritative verifier should not rely on the same mutable execution space that the candidate has been using.

## Required fix

Use:

- non-root agent;
- separate candidate sandbox UID;
- verifier-owned immutable tools;
- verifier-owned frozen candidate artifact;
- verifier-owned hidden tests;
- sealed reports.

---

# 7. Complete Candidate-State Capture Should Be Independent of Candidate Git Metadata

## Issue

Git integrity controls are improved, but authoritative change capture should not depend only on candidate-controlled Git metadata.

The final artifact should independently represent:

- committed changes;
- staged changes;
- unstaged changes;
- untracked files;
- ignored files where relevant;
- deleted files;
- binaries;
- symlinks;
- mode-only changes;
- generated executables;
- repository metadata modifications.

## Risk

Git state can be manipulated in ways that normal `git diff` or `git status` based logic may not fully represent.

## Required fix

Freeze the filesystem artifact independently and create a verifier-owned manifest containing:

- relative path;
- file type;
- mode;
- size;
- SHA-256;
- symlink target where applicable.

---

# 8. Valid-Alternative Implementation Control Is Still Missing

## Issue

The task now discloses exact linking identifiers required by hidden tests, which fixes the earlier undisclosed requirement problem.

However, disclosure does not prove implementation neutrality.

The protected tests still compile against a fairly large set of specific identifiers and structures.

## Risk

A materially different but behaviorally correct architecture may still fail because the verifier is coupled to the upstream or reference design.

## Required fix

Create at least one structurally different but behaviorally correct implementation and prove that it passes all deterministic stages.

The valid-alternative control should intentionally differ from the Oracle in:

- internal file layout;
- helper organization;
- non-contract internal names;
- implementation decomposition;
- control flow where possible.

Only explicitly public compatibility contracts should remain identical.

---

# 9. Calibration Repeatability Is Still Too Thin

## Issue

The current submission still does not provide enough repeated clean calibration evidence for the exact release revision.

### Required Oracle control

At least 3 clean Oracle runs under the final exact environment.

### Required verifier stability control

The same frozen passing artifact should be graded at least 3 times from clean verifier state.

Expected outcome:

- identical required checks;
- identical test counts;
- identical binary reward;
- no unexplained flakiness.

### Required frontier control

Multiple independent frontier trajectories should be run after task and verifier fixes.

### Required no-op control

The no-op should continue to fail the first meaningful behavioral gate under the final environment.

## Required fix

Run and preserve raw evidence for all controls above.

---

# 10. Empirical Long-Horizon Validation Is Still Missing

## Structural status

The task is structurally long-horizon:

1. diagnosis;
2. L4 route foundation;
3. reconciliation and translation;
4. configuration hardening and cumulative closure.

Earlier-stage choices affect later behavior, and Stage 4 depends on accumulated state.

## Missing empirical evidence

No completed experiments currently demonstrate the effect of the horizon itself.

Still missing:

- staged versus single-briefing agent run;
- fresh-context versus resumed-context run;
- handoff-ablation run;
- optionally handoff-corruption or reconstruction control.

## Required fix

Run the long-horizon ablation matrix and document whether staged fresh context materially changes success or failure behavior.

---

# 11. Detailed Evaluation Evidence Packaging Is Still Incomplete

## Issue

The supplied evaluation package is not sufficient to independently adjudicate the exact Stage 3 deterministic failure.

Trajectories are useful, but they are not a replacement for authoritative verifier evidence.

## Required evidence per stage

Package:

- `reward.json`;
- `reward-details.json`;
- `test_output.log`;
- deterministic check IDs;
- check weights;
- check status;
- test execution count;
- hidden test result;
- integrity result;
- patch or frozen artifact digest;
- handoff digest;
- resource metrics where available;
- trajectory;
- final stage artifacts.

## Required fix

Make complete per-stage verifier evidence part of every release calibration bundle.

---

# 12. Stage 3 Failure Should Be Reproduced Before It Is Counted as Headroom

## Issue

The new trajectory shows that Gemini completed Stage 3 and believed visible tests passed.

That makes a hidden behavioral miss plausible.

However, a single hidden failure in one run is not enough for stable headroom.

## Required fix

After verifier and evaluation issues are fixed:

- rerun the exact frontier model from clean state;
- reproduce the same hidden Stage 3 failure;
- confirm the same deterministic check fails;
- verify no infrastructure or network contamination;
- verify stable test counts.

Only then count it as strong model-capability headroom.

---

# 13. Stage 4 Should Distinguish New Failure From Inherited Cumulative Failure

## Issue

Because Stage 4 reruns cumulative behavior, a Stage 3 defect can automatically cause Stage 4 to fail.

Treating both reward 0 stages as two separate failures artificially inflates failure and headroom counts.

## Required fix

Stage 4 evidence and reporting should explicitly identify:

- inherited failed checks;
- newly introduced Stage 4 failed checks;
- cumulative regressions.

Headroom analysis should count the first decisive independent failure, not every downstream repeated failure.

---

# 14. ZIP Executable Permissions Are Still Incorrect

## Issue

Intended executable files are still packaged with mode `0600`, including items such as:

- `solve.sh`;
- `test.sh`;
- `stage_test.sh`;
- verifier and control scripts.

## Why this matters

This can create platform-dependent execution failures and is a recurring release-packaging QC issue.

## Required fix

Preserve executable mode, typically:

`0755`

for intended executable scripts.

Re-run package self-check after repacking.

---

# 15. Gemini Harness and Response-Parsing Noise Should Be Documented

## Observation

The Stage 3 trajectory contains repeated malformed or invalid JSON response retries and a very large interaction footprint.

The Stage 3 trajectory reports approximately:

- 128 steps;
- about 7.7 million prompt tokens;
- repeated parsing warnings and errors.

## Interpretation

This does not automatically invalidate the Stage 3 failure because the agent ultimately completed the task.

However, it is calibration noise and may affect:

- cost;
- effective reasoning budget;
- reliability;
- comparison across models and runs.

## Required fix

For final calibration:

- use a stable fixed harness;
- record malformed-response retry counts;
- compare retry rates across repeated runs;
- ensure failures are not driven by response-protocol instability.

---

# 16. Linking Contracts Still Reduce Implementation Freedom

## Fixed

The task now clearly discloses the exact names hidden tests compile against.

This resolves the earlier hidden or undisclosed requirement problem.

## Remaining concern

Some identifiers still represent internal architecture rather than unavoidable external product behavior.

Examples include exact model, reconciler, and helper names required for hidden-test compilation.

## Classification

**Implementation-freedom and reference-architecture coupling risk.**

This is no longer an undisclosed-requirement failure.

## Required fix

Keep exact-name contracts to the minimum technically necessary and validate a structurally different correct implementation.

---

# 17. Reward Semantics, Current Interpretation

The authoritative reward policy should remain:

- `reward` is the strict binary official result;
- `binary_reward` is the strict binary official result;
- `deterministic_score` is partial deterministic progress;
- judge score cannot rescue deterministic failure;
- `valid_trial=0` means the run is not a normal model-capability result;
- training score is separate from official reward.

For the current Cilium revision:

- the old integrity-invalid Gemini failure has been fixed;
- current Stage 3 has `valid_trial=1`;
- therefore it can potentially become valid headroom evidence;
- but only after exact failed deterministic evidence, offline rerun, and stability are established.

No reward-formula issue should be raised merely because a failed valid stage has a fractional deterministic or training score.

---

# 18. Instruction Ambiguity Review

## Verdict

**PARTIAL PASS, minor to moderate issues remain.**

## What is good

The main Stage 3 objective is clear:

- support TCPRoute and UDPRoute;
- create LoadBalancer Services;
- create operator-managed EndpointSlices;
- propagate backend weights;
- use Cilium service load-balancing;
- do not use Envoy for the L4 path.

The exact linking identifiers required by protected tests are also now disclosed, which resolves the earlier hidden-symbol ambiguity.

## Remaining ambiguity

Some behavior still requires substantial inference from repository code or hidden tests, including:

- exact backend selection semantics;
- normalization and interpretation of weights;
- behavior for invalid or unsupported backend references;
- parent and listener compatibility;
- namespace and ReferenceGrant behavior;
- cleanup and deletion behavior;
- update and idempotency behavior;
- status expectations.

There is also a long-horizon handoff risk. The Stage 2 agent-authored handoff suggested implementing Envoy translation for TCP and UDP listeners, while the Stage 3 authoritative requirement explicitly says the L4 path must use Cilium service load-balancing and not Envoy.

This is not a benchmark prompt contradiction because the handoff was agent-authored, but it shows that a stale or incorrect prior handoff can mislead the next stage.

## Required fix

Add a compact behavioral acceptance section to each stage that explicitly covers:

- accepted and rejected ParentRefs;
- backend and ReferenceGrant behavior;
- weighting rules;
- reconciliation update and cleanup expectations;
- important status behavior;
- the rule that current-stage instructions override any conflicting prior agent-authored handoff text.

---

# 19. Test-Instruction Misalignment Review

## Verdict

**PARTIAL FAIL**

The alignment is substantially improved, but some important mismatches remain.

## Fixed or improved alignment

The following earlier issues are now improved:

- RBAC has dedicated grading;
- Stage 4 documentation has dedicated grading;
- hidden linking identifiers are disclosed;
- reports and handoff are explicitly described as scored but non-decisive for correct implementation behavior.

## Remaining misalignment 1: Stage 2 routechecks are required but not equivalently tested

Stage 2 requires routechecks as part of the L4 route foundation.

The verifier strongly covers helpers, indexers, and RBAC, but routecheck semantics are not tested with equivalent depth.

This means the instruction requires more behavior than the Stage 2 deterministic verifier currently proves.

### Required fix

Add protected routecheck behavioral tests for both TCPRoute and UDPRoute.

---

## Remaining misalignment 2: "Everything else is your design choice" is broader than actual verifier freedom

Stage 3 says that exact disclosed identifiers must match and everything else is the implementer's design choice.

However, protected tests directly compile against internal model types, functions, and reconciler structures.

Because these identifiers are disclosed, this is not an undisclosed requirement issue.

However, the wording still suggests more implementation freedom than the verifier actually allows.

### Required fix

Either:

1. reduce the exact linking surface to genuinely necessary compatibility contracts;

or:

2. change the instruction wording to clearly state that the named integration seams are mandatory compatibility contracts and implementation freedom applies outside those seams.

Then prove a materially different valid implementation can pass.

---

# 20. Test Coverage Review

## Verdict

**PARTIAL FAIL**

Stage 3 and Stage 4 have reasonably strong coverage, but Stage 2 and several edge and regression areas remain incomplete.

## Strong coverage

### Stage 3

Coverage is comparatively strong around:

- L4 model support;
- ingestion;
- translation;
- LoadBalancer Service creation;
- EndpointSlice generation;
- backend weight propagation;
- reconciliation;
- disclosed integration contracts.

### Stage 4

Coverage is reasonably strong around:

- Helm configuration forcing;
- Gateway API enabled behavior;
- Gateway API disabled behavior;
- documentation updates;
- cumulative closure.

---

## Remaining coverage gap 1: Routecheck semantics

Add direct tests for:

- valid ParentRef;
- invalid ParentRef;
- wrong Group;
- wrong Kind;
- namespace behavior;
- ReferenceGrant;
- missing backend;
- unsupported backend type;
- invalid backend port;
- listener compatibility;
- TCPRoute and UDPRoute variants.

---

## Remaining coverage gap 2: Reconciliation lifecycle

Add tests for:

- updating an existing Service;
- updating an existing EndpointSlice;
- removing a backend;
- deleting a route;
- cleanup of stale managed EndpointSlices;
- multiple routes and listeners;
- repeated reconciliation;
- idempotency.

---

## Remaining coverage gap 3: Weight edge cases

Add tests for:

- missing or default weight;
- zero weight if supported or rejected;
- unequal weights;
- multiple backends;
- normalized weights;
- deterministic ordering.

---

## Remaining coverage gap 4: Invalid and mixed combinations

Add negative and mixed-case tests for malformed or unsupported Gateway API combinations so that fail-safe behavior is proven, not inferred.

---

## Remaining coverage gap 5: Broad regression safety

Final cumulative verification should prove that existing L7 functionality remains intact, including relevant:

- HTTPRoute behavior;
- GRPCRoute behavior;
- TLSRoute behavior;
- existing Gateway reconciliation behavior.

The new L4 feature should not regress existing Envoy-based L7 paths.

---

## Remaining coverage gap 6: Alternative correct implementation

The current suite still lacks proof that a structurally different correct implementation can pass.

This is both a calibration and test-quality requirement.

---

# 21. Three-Axis Summary

| Axis | Verdict | Summary |
|---|---|---|
| Instruction Ambiguity | PARTIAL PASS | Core L4 objective and exact linking identifiers are now clear, but route, backend, weighting, lifecycle, and status semantics still require too much inference. |
| Test-Instruction Misalignment | PARTIAL FAIL | RBAC, docs, and disclosed identifiers are improved, but Stage 2 routecheck behavior is under-tested and implementation freedom is narrower than the wording suggests. |
| Test Coverage | PARTIAL FAIL | Stage 3 and Stage 4 are relatively strong, but routechecks, lifecycle cleanup, invalid combinations, weight boundaries, broad L7 regression, and valid-alternative controls remain incomplete. |

---

# 22. Issues That Fixed From the Previous QC

These should not remain as stale FAIL comments if the current package is the authoritative revision.

## Fixed or materially improved

- RBAC now has dedicated grading.
- Stage 4 docs now have dedicated grading.
- Handoff is promotion-gating and verifier-owned hash chaining has been added.
- Read-only `git remote` no longer triggers the previous integrity false positive.
- Agent is explicitly unprivileged.
- Trusted binary and toolchain checksum validation exists.
- `/tests` and `/solution` access controls are improved.
- Artifact collection overlap is improved and cleaned.
- RewardKit is explicitly N/A or disabled rather than pretending to run.
- Hidden linking identifiers are disclosed.
- Package self-QC and static validation are significantly stronger.
- Current Gemini Stages 1 and 2 pass with `valid_trial=1`.

The trainer should update or remove old checklist failures corresponding to these corrected issues.

---

# 23. 

## P0: Must fix before release calibration

1. Remove public-network overrides and rerun under genuine no-network.
2. Package complete Stage 3 and Stage 4 per-check verifier evidence.
3. Add or strengthen Stage 2 routecheck behavioral tests.
4. Implement true frozen candidate artifact verification instead of live `/testbed`.
5. Keep hidden tests outside persistent candidate workspace.
6. Clarify remaining ambiguous route, backend, weighting, and lifecycle semantics.
7. Align the "design choice" wording with the actual mandatory linking contracts.
8. Rerun clean frontier evaluation after the above fixes.

## P1: Required before calling headroom and stability validated

9. Oracle x3 on the exact final revision.
10. Same-artifact verifier stability x3.
11. Valid-alternative implementation control.
12. Multiple clean frontier trajectories.
13. Distinguish inherited Stage 4 failures from new Stage 4 failures.
14. Add lifecycle, edge-case, and regression test coverage.

## P2: Long-horizon and release-quality completion

15. Staged versus single-briefing ablation.
16. Fresh versus resumed context ablation.
17. Handoff-ablation experiment.
18. Fix executable ZIP permissions.
19. Strengthen complete filesystem artifact capture.
20. Document and measure harness malformed-response noise.
21. Minimize unnecessary internal linking contracts where possible.

---



The current Cilium revision is substantially improved and resolves many of the earlier QC blockers. The new Gemini trajectories confirm that Stages 3 and 4 were fully attempted and completed by the agent, so the Stage 3 reward 0 is now a plausible hidden behavioral failure rather than an incomplete-run outcome.

However, the sample is not yet ready for final headroom calibration.

The main remaining blockers are:

- public-network evaluation mismatch;
- missing exact Stage 3 verifier evidence;
- incomplete Stage 2 routecheck behavioral coverage;
- live-workspace rather than frozen-artifact verification;
- hidden-test isolation;
- insufficient repeated calibration;
- missing valid-alternative evidence;
- missing empirical horizon ablations;
- remaining instruction ambiguity;
- remaining test-instruction misalignment;
- incomplete edge, lifecycle, regression, and alternative-path test coverage;
- incorrect executable ZIP permissions.


