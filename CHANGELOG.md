# Changelog

## v0.5.0 — May 4, 2026

### Why this release exists

Ran v0.4 end-to-end on **NTU SC4023 Big Data Management** (May 7 2026 exam). After delivering 13 "ready-to-study" PDFs and declaring DONE, we ran an independent codex-as-student cold-read audit. Result: **6.2/10 score, 6 P0 defects flagged**.

The defects weren't bugs in the input materials. They were systemic gaps in the skill's own quality gates:
- Wrong exam time silently inherited from prior SC4003 run (would have caused student to miss the exam)
- Worked answers punted with "see lecturer's full solution" (Q4 LSM, 30 marks/year)
- Narrator commentary like "Wait — re-reading" leaked into final PDFs (5 instances)
- Self-contradicting answers (Q4(c) said "best=h" then later "best=1")
- MapReduce pseudocode used undefined variable `j_col`
- Multiple alternative answer attempts in single sub-Q (Q5(d) had 4 versions)

Three rounds of automated fix-and-re-audit pushed the score 6.2 → 7.5 → 8.1+/10. Pass probability went 78% → 84%. **All 6 fix-categories are now baked into v0.5 as automated gates.**

The lesson: shipping ≠ validation. Without the codex-audit loop, every prior "successful" run (including SC4003) likely shipped with similar latent defects we never caught.

### Added

- **`docs/ALGORITHM_student_audit.md`** — NEW Step 10.5 codex-student-audit gate spec (score gate ≥ 8.0, fix-loop cap 3 rounds, ~$1-$2.40 per invocation cost adder)
- **`bin/check_pollution.sh`** — narrator-pollution + OCR-marker syntax validator
- **`bin/check_master_plan.sh`** — master-plan self-consistency checker (subtitle vs body arithmetic, cold-mock numbering, exam-time consistency)
- **`GOTCHAS_FROM_RUNS.md`** — empirical lessons from SC4003 + SC4023 (NEVER inherit prior metadata, FORBIDDEN narrator phrases, etc.)
- **EXAM_METADATA confirmation block** in Turn 1 dialogue (`docs/ARCH_dialogue.md`) — required fields: date, start time, duration, venue, format, total marks
- **Master-plan SELF-CHECK section** in `templates/TEMPLATE_master_plan.md` — 5 consistency invariants
- **No-punt rule** in `templates/AGENT_PROMPTS_LIBRARY.md` Prompt 6/7
- **No-narrator rule** in `templates/AGENT_PROMPTS_LIBRARY.md` Prompt 6/7 with full forbidden-pattern list
- **ONE canonical answer rule** in Prompt 7 — kills multi-attempt enumeration
- **Standardized OCR markers** — `🚨 OCR-AMBIGUOUS:` (multi-interpretation) vs `🚨 OCR-NOTE:` (single committed answer, medium confidence)

### Changed

- Validation claims in `README.md` softened: "validated" now explicitly defined as "produced usable materials + student passed-or-expected-to-pass," NOT "zero defects."
- `SKILL.md` workflow now has 11 steps (was 10): Step 10.5 inserted between Step 10 (PDF generation) and DONE declaration.
- Cost estimate: ~$1.80-$5.50 per invocation (was ~$1.30-$4.00) — codex-audit adds 1-3 rounds at ~$0.30-$0.80 each.

### Case study

| Round | Score | Pass prob | Bugs FIXED | Bugs PARTIAL | Bugs STILL BROKEN |
|-------|-------|-----------|------------|--------------|-------------------|
| Initial v0.4 output (no audit) | 6.2/10 | 78% | — | — | 6 of 6 |
| After Round 1 fix-loop | 7.5/10 | 78%→? | 4 | 1 | 1 |
| After Round 2 fix-loop | 8.1/10 | 84% | 5 | 1 (Q5d cosmetic) | 0 |
| After manual micro-polish (R3) | ~8.5/10 | 84%+ | 6 | 0 | 0 |

The Q5(d) "PARTIAL" status reflects a real-world impossibility (the AY2223 Q5d question is structurally impossible under stated constraints — even a perfect agent can only document the impossibility + closest-feasible solution).

---

## v0.4.0 (2026-05-02) — initial public release

First open-source release. 4 internal review iterations completed (incl. /codex peer review).

### Added
- 5-archetype scope routing (calc-heavy STEM full / proof-math partial / live-coding refused / MCQ Anki-only / essay refused)
- 3-mode validation (Mode A N≥3 STANDARD / Mode B N=1-2 SPARSE / Mode C N=0 ZERO-PAPER)
- 4-quadrant TRAP WATCH matrix (lecturer emphasis × past-paper frequency)
- Tier-based dependency probe (`bin/check_deps.sh`) with graceful fallback
- 17 fallback adapters for missing dependencies
- Reference implementation: NTU SC4003 Intelligent Agents (AY2425)

### Known limitations (V1)
- Validated on 1 course only
- Multi-doc consistency requires careful editing (SKILL.md is authoritative)
- No grade prediction — produces study plan, not score forecast
