# Changelog

## v0.6.0 — May 6, 2026

### Why this release exists

SC4023 round-2 evidence (May 6 2026, 1 day before exam): student opened the v0.5 drill packs and got stuck at Get cost / fence pointer / Bloom filter mechanics. The packs assumed database/systems baseline knowledge the student didn't have. v0.5's codex-audit gate would have caught this *eventually*, but only after expensive fix-loops. v0.6 adds a primer-from-zero pack as MANDATORY first output, baking the lesson into the workflow.

The Chinese alias `临时抱佛脚` (lit. "hugging Buddha's feet at the last minute" = idiom for cramming) is now official — it captures the skill's actual use case.

### Added

- **Workflow Step 7.5** — primer pack generation, MANDATORY before any drill pack. Output: `00_PRIMER_FROM_ZERO.md` (5000-9000 words covering all course concepts from first principles).
- **AGENT_PROMPTS_LIBRARY.md Prompt 12** — primer-writer prompt template with audience profile, section structure, hard constraints, and SC4023 reference impl citation.
- **临时抱佛脚 alias** added to SKILL.md frontmatter aliases list. `/临时抱佛脚` triggers the skill identically to `/exam-prep`.
- **TEMPLATE_index.md** updated to list primer pack as FIRST entry in study order.

### Changed

- README.md badges, validation claims, changelog table updated for v0.6
- SKILL.md workflow now has 11.5 steps (was 11): Step 7.5 inserted between Step 7 (per-topic drill packs) and Step 8 (PYP full-answer packs)

### Reference implementation

SC4023 primer at `~/Desktop/NTU study/Y4S2/SC4023 Big Data Management/exam-prep/ipad_topic_packs/00_PRIMER_FROM_ZERO.pdf`:
- 7350 words, 131KB PDF, ~30-40 pages
- 9 modules: Big Data 5Vs / Disk mechanics / Memory hierarchy + cache / Sorting + external sort / Row vs Column stores / MapReduce / NoSQL + KV / LSM tree (centerpiece, ~30% of doc) / Reading order
- ASCII diagrams for leveling vs tiering side-by-side, row vs column layout
- Bold-defined every term on first use
- Pollution check: ✅ CLEAN

### Case study (SC4023 round-2)

Without primer (v0.5): student stuck at LSM Get cost section, asking "what is I/O?", "what is fence pointer?", "what does flush mean?". Manual hand-explained 4 separate concepts before student could continue.

With primer (v0.6 default): student reads 90-120 min primer first, then drill packs become readable. Eliminates the "wall" effect.

### Cost

No change from v0.5 base cost. Primer generation adds ~$0.50-$1.00 to invocation cost (one extra agent call for ~7000 words). Total still ~$1.80-$5.50 per invocation.

---

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
