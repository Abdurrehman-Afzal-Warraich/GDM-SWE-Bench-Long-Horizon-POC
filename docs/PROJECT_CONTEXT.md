# Project Context — Repo Engineering Long-Horizon Tasks (Go Stream)

> Operational context distilled from the team channel kick-off messages + the two benchmark inspirations. Companion to `WORKFLOW.md` (how to build) and `SELF_REVIEW_AUDIT.md` (how tasks are judged).

---

## 1. What we're doing

We are building **Repo-Engineering Long-Horizon Tasks** — realistic, single-session engineering tasks in complete production repositories, packaged for the **Harbor** harness.

**Core inspiration (two benchmarks):**
- **Scale AI — SWE-Bench Pro** ([public leaderboard](https://labs.scale.com/leaderboard/swe_bench_pro_public)) — rigorous, contamination-resistant, long-horizon tasks from real repos. Strict **Resolve Rate** = fail-to-pass tests now pass **and** pass-to-pass tests still pass. Top frontier models only ~23% on the public set (vs 70%+ on SWE-Bench Verified). Notably, **Go and Python tasks tend to have higher resolve rates** than JS/TS.
- **Snorkel — Senior SWE-Bench** ([leaderboard](https://snorkel.ai/leaderboard/senior-swe-bench/)) — senior-level work from real PRs, **natural-language / under-specified** instructions (reads like a Slack issue report, not a spec). **6 evaluation gates per task**. Two headline metrics:
  - **Basic Solve Rate** — passes all pre-written verifiers + automated validation tests (correctness only).
  - **Tasteful Solve Rate** — Basic + 4 quality gates (rubric, patch-bloat < 2× reference LOC, codebase-practice alignment > 2/5, relative code quality > 2/5). Top model only ~25–29% tasteful → correctness and taste are *different skills*.

**Our differentiator:** use a **variety of deterministic AND non-deterministic verifiers** to produce more accurate **task-based and process-based reward shapes** — something existing datasets currently lack.

---

## 2. Two design approaches

> ⚠️ **PRIORITY UPDATE (from friend's `.cursor/rules` + Tier 2 guide v3):** the lead directive has moved the **current priority to the Multi-Step / Tier 2 task**, evaluated on **data-os** (not Agentic Vet). Tier 1 single-step remains valid background and may still appear in rework, but new authoring targets Tier 2.

### 1️⃣ Single Harbor Native Task (Tier 1) — background / rework
- Like Snorkel Senior Bench: **a single verifier stage**.
- Early priority; now largely background. Rework directive (Jul 21): increase headroom/signal on existing V1 tasks (more discriminating tests, clearer instructional context, ~5–20% frontier solve rate).
- Full details in `WORKFLOW.md`.

### 2️⃣ Multi-Step Harbor Native Task (Tier 2) — CURRENT PRIORITY
- **Stateful** task split into **4 ordered stages** (diagnose → core → review → harden); fresh agent context per stage while repo + services + typed handoff files **persist**.
- Per-stage deterministic gates + **cumulative final closure**; deterministic + non-deterministic (judge) verifiers → richer temporal reward shape.
- **Harbor 0.8+ multi-step layout** (installation here 0.20+), schema 1.3, `multi_step_reward_strategy = "final"`. Evaluated on **data-os**.
- Full details in `TIER2_WORKFLOW.md`.

---

## 3. Our stream: Go

- We work the **Go stream** — target repositories are written in **Go**.
- Note: the kick-off's *initial* repo suggestion was C++/Rust (e.g., ruff) for the general team, but **our assignment is Go**. Go is well-represented in both source benchmarks (e.g., `go-gitea/gitea`, `gravitational/teleport` in Senior SWE-Bench) and tends to solve at higher rates, so tasks must be genuinely challenging.

---

## 4. Repository selection rules

**License must be one of:**
- Apache 2.0
- CC BY 4.0
- CC BY-SA 4.0
- CC BY-NC 4.0
- GNU General Public License (GPL)
- BSD 2.0 (2-Clause)
- BSD 3.0 (3-Clause)
- MIT

Other selection criteria are open for discussion, but favor **complex, production-scale, industrially-relevant** Go repos with meaningful tests and reproducible builds (per SWE-Bench Pro's "diverse, non-trivial, contamination-resistant" principles). Verify the license at repo root **and** affected dirs/files/vendored components (see `SELF_REVIEW_AUDIT.md` §E).

---

### Lead-mandated PR gates (Aug 2026; hard requirements)

- The source PR must change **50 or more files**. Fewer than 50 files is an automatic rejection even when the domain is stateful.
- The defensible **expert time estimate must exceed 30 hours**. Patch size or slow builds cannot be used to manufacture that estimate.
- The work must avoid simple, localized, or purely mechanical changes. Reject one-obvious-function/one-visible-test fixes, large renames, compiling-only changes, formatting, and generated-file inflation.
- The change must connect multiple real software contracts, such as runtime state, data, APIs, persistence, concurrency, migration, performance, or recovery.
- A capable agent must need sustained diagnosis, implementation, testing, and revision. The target remains meaningful headroom against Gemini 3.6 and more capable models; easy success makes the dataset ineffective.
- Use **at least 4–5 meaningful stages**. Earlier decisions must persist and have causal consequences in later stages; do not create arbitrary checkpoints around one local edit.
- During selection, count substantive production, test, and integration files separately from generated/configuration/documentation files. A PR passes the 50-file gate on the upstream changed-file count, but generated or repetitive spread is not evidence of headroom.

---

## 5. Task-sourcing principles (from both benchmarks)

- **Source from real PRs / commits.** Prefer recent PRs (audit rubric: ideally merged within ~6 months of task creation), ideally authored by experienced contributors / maintainers — gives an authoritative reference implementation and proves the work was genuinely needed.
- **Fail-to-pass + pass-to-pass pairs:** the change must make new tests pass (that failed before) while unrelated existing tests keep passing.
- **Under-specified, behavior-first instructions:** write like an issue report / product request — describe observed behavior and required invariants, *not* exact files, interfaces, or a patch recipe. The agent must investigate and infer.
- **Accept multiple valid implementations:** grade behavior + quality, never diff-similarity to the golden patch.
- **Contamination control:** keep a private/held-out portion; separate training from evaluation (repo, time window, variant, checksum).
- **Calibration standard (Snorkel):** run **3× on the oracle patch and 3× on no-op**; reject if oracle isn't pass³ (all 3 pass) or if no-op ever passes (pass³ > 0 on no-op). Consider a "guided" instruction variant with optional hints (no solution prescribed) for curriculum/diagnosis.

---

## 6. Reward shape (our angle)

Combine, per the source benchmarks + our differentiator:
- **Deterministic verifiers** — behavioral fail-to-pass, pass-to-pass regression, integration/data contracts, integrity/anti-cheat. Authoritative for strict `binary_reward`.
- **Non-deterministic verifiers (judges)** — process quality, merge-readiness / taste (rubric, patch-bloat vs reference, codebase-practice alignment, relative code quality), validity/anti-cheat. Secondary signal; **cannot rescue** a broken deterministic result.
- Preserve **separate engineering vs rule-compliance metrics** and labeled partial/near-miss training vectors (see `SELF_REVIEW_AUDIT.md` §V).

---

## 7. Cadence & expectations

- **Target: ~1 task per day** for the Single Harbor version.
- Team lead is still QC'ing tasks; the flow above is the general working model. Sample being made **DataOS-ready**.

---

## 8. Tooling / platform facts (from friend's rules + Tier 2 guide)

- **Platform:** data-os (replaces Agentic Vet for Tier 2).
- **Harbor:** 0.20+ installed; multi-step needs 0.8+ layout (avoid old 0.3 on the same WSL machine).
- **Verifier runtime:** Python 3.12, pytest ≥8.3.5, `harbor-rewardkit[all]` ≥0.1.7 in an isolated venv.
- **Judge:** `gemini/gemini-3.5-flash` via `GEMINI_API_KEY` (verifier env ONLY, never in task files/images/trajectories), `JUDGE_REPEATS=2`.
- **Reward files:** always write numeric `reward.json` (`reward`, `binary_reward`, `training_score`, `valid_trial`); crash → explicit invalid zero.
- **Docs are flavor, not complete** (lead guidance): internal docs only sketch what's needed — prefer workflow + Task Sheet QC patterns + SWEAP seeds; don't block on missing docs.

## 9. Role split

- **User:** pick/approve the Go PR; run/submit on platform; **fill the Task Sheet** (agent never edits the tracker/Google Sheet/ODS); own the lead QC loop.
- **Agent (me):** shortlist Go PRs; draft the Harbor package; author near-misses; draft selection-criteria text if asked; apply rework. **Never edit the Task Sheet.**
- **Lead:** Status / Rework / Rejected decisions. Tracker statuses seen: `Inprogress`, `Ready for QC`, `Rework`, `Rejected`.

## 10. Working memory — file map

| File | Purpose |
|---|---|
| `PROJECT_CONTEXT.md` | This file — program goals, benchmarks, approaches, stream, licenses, cadence, tooling, roles |
| `TIER2_WORKFLOW.md` | **CURRENT PRIORITY** — how to build a Tier 2 multi-step stateful task |
| `WORKFLOW.md` | Tier 1 single-step task build guide (background/rework) |
| `SELF_REVIEW_AUDIT.md` | Master audit rubric = pre-submission self-review checklist |
| `Resources/.cursor/rules/*.mdc` | Friend's accumulated Cursor guidelines (core context, daily workflow, Harbor standards) |
| `Resources/tier2_stateful_repo_engineering_task_guide_v3.pdf` | Authoritative Tier 2 guide (source of `TIER2_WORKFLOW.md`) |

---

### Open items / to confirm with team
- ~~Adopt friend's rules into this workspace~~ — done (`.cursor/rules/*.mdc`).
- Tier is confirmed **Tier 2** for new authoring; Tier 1 is background/rework only.
- Live blockers and resume order live in `.cursor/rules/session-state.mdc` (not here).

### Workspace task snapshot (Aug 2026)

Live status is authoritative in `.cursor/rules/session-state.mdc`. Summary:

- **Approved exemplar:** `cilium-listenerset-integration-v3.zip` (cilium ListenerSet / Gateway API).
- **Gitea** (`go-gitea/gitea` #38154): `gitea-scoped-workflows-tier2-v4.zip` shipped (Oracle stage-04 merge-tree excuse + platform-log replay); re-upload on DataOS.
- **Prometheus** (`prometheus/prometheus` #18573) v11: QC failed on `anti_cheat_robustness`, `instruction_concision`, `test_instruction_alignment`; Gemini nearly failed; queued — do not mix with Gitea work.
- **One package at a time** (see `working-agreement.mdc`).
