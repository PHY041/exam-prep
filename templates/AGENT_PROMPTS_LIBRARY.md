# D2: Agent Prompts Library v2 — Exam Prep Workflow

**Version:** 2.0
**Status:** Polished, dispatch-ready
**Audience:** Orchestrator agents, subagent dispatchers, manual operators

This document specifies every agent prompt in the exam-prep pipeline as a
**dispatchable unit** — with operational metadata that makes parallelization,
retry, and budget-tracking decisions mechanical rather than judgment-based.

---

## 0. Conventions

### Variable placeholder syntax

All prompts use `{{DOUBLE_BRACE}}` placeholders. Required variables are
listed in each prompt's "Input variables" section. Optional variables have
a `?` suffix in the spec table.

| Convention | Meaning |
|------------|---------|
| `{{COURSE_CODE}}` | Course identifier, e.g. `SC4003` |
| `{{PYP_DIR}}` | Absolute path to past-year-paper folder |
| `{{LECTURES_DIR}}` | Absolute path to lecture-slides folder |
| `{{OUTPUT_DIR}}` | Workflow root (analysis lives here) |
| `{{PACKS_DIR}}` | Where drill packs are written |
| `{{LECTURER_REVIEW_PATH}}?` | Optional lecturer review deck (PDF or md) |
| `{{HOURS_TO_EXAM}}` | Integer hours remaining |
| `{{EXAM_DATETIME}}` | ISO 8601 datetime |
| `{{TARGET_SCORE}}` | Integer 0–100 |
| `{{N_PAPERS}}` | Number of past papers available (drives data-quality gates) |

### Time/token budget notation

- **Time budget**: wall-clock estimate for a single dispatch, assuming
  the agent has tools (filesystem, PDF reader) ready. Does not include
  human review time.
- **Token budget**: rough order-of-magnitude estimate of input + output
  tokens combined. `N` = number of past papers, `T` = number of topics
  in controlled vocab, `P` = number of packs.

### Failure-mode taxonomy

| Code | Meaning | Default retry strategy |
|------|---------|------------------------|
| `OCR-CORRUPT` | OCR garbled numerical values or formulas | Re-run with marker-pdf instead of pymupdf4llm |
| `LOW-N` | Insufficient past papers (`N < 3`) | STOP, escalate to human; do not infer from N=1/2 |
| `VOCAB-DRIFT` | Agent invented topic labels outside controlled vocab | Re-dispatch with explicit vocab list re-pasted |
| `LENGTH-OVERRUN` | Output > 2× target length (rambling) | Re-dispatch with stricter length cap, no template change |
| `TEMPLATE-DRIFT` | Output ignores TEMPLATE_*.md schema | Re-dispatch with template inlined in prompt |
| `STALE-INPUT` | Upstream artifact missing or incomplete | Block; do not proceed until upstream rerun |
| `HALLUCINATED-CITE` | Agent fabricated a paper-year reference not in source | Re-dispatch with verbatim-only constraint |

### Composability legend

| Symbol | Meaning |
|--------|---------|
| 🟢 | Fully parallel — can run concurrently with other 🟢 prompts in the same wave |
| 🟡 | Parallel within itself (fan-out per item) but blocks the next wave |
| 🔴 | Strictly sequential — must wait for upstream to complete |

---

## 1. Pipeline overview

```
Wave 1 (data prep):       [P1: OCR papers] 🔴
                                    ↓
Wave 2 (per-paper):       [P2: Q&A breakdown] 🟡 (fan-out per paper)
                                    ↓
Wave 3 (analysis):        [P3: frequency table] 🔴 → [P4: reused templates] 🔴
                                    ↓
Wave 4 (pack generation): [P5: verbatim repeats]  🟢
                          [P6 × T: per-topic packs] 🟢 (fan-out per topic)
                          [P7 × N: PYP full answers] 🟢 (fan-out per paper)
                                    ↓
Wave 5 (audit + plan):    [P8: coverage audit] 🔴
                                    ↓
Wave 6 (deliverables):    [P9: master plan] 🟢
                          [P10: cheatsheet] 🟢
```

**Critical path:** P1 → P2 → P3 → P8 → P9. Everything else can sidecar.

---

## Prompt 1 — OCR past papers

### Operational spec

| Field | Value |
|-------|-------|
| **When to dispatch** | Workflow start, once per course. Must precede everything. |
| **Input variables** | `{{PYP_DIR}}`, `{{OUTPUT_DIR}}` |
| **Output path** | `{{OUTPUT_DIR}}/papers/PYP_<year>.md` (one per paper) + `/tmp/ocr_issues.md` |
| **Time budget** | 2–5 min per paper (pymupdf4llm); 8–15 min if marker-pdf needed |
| **Token budget** | ~5K input + ~30K output per paper → `~35K × N` total |
| **Composability** | 🟡 — internally fan-out per PDF, but the entire P1 wave must finish before P2 |
| **Failure modes** | `OCR-CORRUPT` (scanned papers), `STALE-INPUT` (PDF dir missing) |
| **Retry** | If `OCR-CORRUPT`: re-dispatch single paper with marker-pdf. Cap at 2 retries before escalating. |

### Prompt body

```
You have a folder of past-paper PDFs at {{PYP_DIR}}.

For each PDF:
1. Convert to markdown using pymupdf4llm (fast) or marker-pdf (if scanned).
2. Save to {{OUTPUT_DIR}}/papers/PYP_AY<year>.md.
3. Verify every question stem is readable. If you spot OCR errors in
   numerical values (e.g., "U(s) = 100" rendered as "U(s) = lO0"),
   flag them in /tmp/ocr_issues.md.

Output structure:
- one .md per paper, named after the academic year
- preserve question numbering (Q1, Q1(a), Q2(b)...)
- preserve mark allocations [10 marks]
- preserve all numerical values, payoff matrices, utility tables verbatim

Report back: total papers converted, OCR error count, and a sample
of the most recent paper to confirm formatting.
```

---

## Prompt 2 — Per-paper Q&A breakdown

### Operational spec

| Field | Value |
|-------|-------|
| **When to dispatch** | After P1 reports ≥3 papers converted cleanly. |
| **Input variables** | `{{PYP_DIR}}`, `{{OUTPUT_DIR}}`, `{{CONTROLLED_VOCAB}}` |
| **Output path** | `{{OUTPUT_DIR}}/analysis/01-paper-by-paper.md` |
| **Time budget** | 3–5 min per paper if dispatched per-paper; 10–20 min combined |
| **Token budget** | ~10K input + ~5K output per paper → `~15K × N` total |
| **Composability** | 🟡 — can fan-out 1 dispatch per paper, then concatenate; the merged file blocks P3 |
| **Failure modes** | `VOCAB-DRIFT`, `STALE-INPUT` (P1 incomplete) |
| **Retry** | If `VOCAB-DRIFT`: re-dispatch with `{{CONTROLLED_VOCAB}}` re-pasted in full. Reject any topic label not in vocab. |

### Prompt body

```
Read every paper in {{OUTPUT_DIR}}/papers/*.md.

For each paper, produce a table in this exact format:

| Q | Marks | Topic | Type | Verbatim/paraphrase |
|---|-------|-------|------|---------------------|

Topic vocabulary (use these labels consistently — do NOT invent new ones):
{{CONTROLLED_VOCAB}}

Type vocabulary:
- named-list (e.g., "list 5 trends")
- definition (e.g., "explain X")
- compare-contrast (e.g., "difference between X and Y")
- compute (numerical)
- proof (e.g., "show why X is truthful")
- draw-diagram
- essay (open-ended application)

Verbatim column: copy the question text VERBATIM from the paper, in quotes.

Output: {{OUTPUT_DIR}}/analysis/01-paper-by-paper.md with one section per paper,
each containing the table + a "Numerical setups used" 1-line summary.

Report back: # of sub-parts tabulated per paper, and any sub-part you
couldn't classify cleanly.
```

---

## Prompt 3 — Topic frequency table

### Operational spec

| Field | Value |
|-------|-------|
| **When to dispatch** | After P2 produces a complete `01-paper-by-paper.md`. |
| **Input variables** | `{{OUTPUT_DIR}}`, `{{N_PAPERS}}` |
| **Output path** | `{{OUTPUT_DIR}}/analysis/06-past-paper-analysis.md` (Sections 1, 2, 8) |
| **Time budget** | 5–10 min |
| **Token budget** | ~20K input + ~8K output |
| **Composability** | 🔴 — strictly sequential; gate for Wave 4 |
| **Failure modes** | `LOW-N` (N<3 → unreliable empirical analysis), `STALE-INPUT` |
| **Retry** | If `LOW-N`: do NOT retry. STOP and surface to user; lecturer-emphasis becomes the primary signal. |

### Prompt body

```
Read {{OUTPUT_DIR}}/analysis/01-paper-by-paper.md.

Build the empirical frequency table per TEMPLATE_past_paper_analysis.md
Section 2 format. For each topic in the controlled vocabulary, count:

- Per-year hit (1.0 if topic dominates a question ≥10 mks; 0.5 if sub-part only; 0 if absent)
- Total hits across all N years
- Total marks summed across years
- Avg marks/year
- Stickiness verdict: CERTAIN / HIGH / WATCH / RECURRING / COLD / NEVER

Sort the table by hit count descending.

After the table, produce:
- "Sorted by hit count:" 1-line summary
- "The N/N lock:" — name the topic that hit every year
- Tier ranking (Tier 1 ≥4/N, Tier 2 = 2-3/N, Tier 3 = 1/N, Tier 4 = 0/N)

Output: {{OUTPUT_DIR}}/analysis/06-past-paper-analysis.md (Sections 1, 2, 8).

Report back:
(a) Single most-frequent topic (highest empirical priority)
(b) Topics with hit-rate=0 (the SKIP list)
(c) Topics where lecturer-emphasized ≠ past-paper-frequency (gap warning)
```

---

## Prompt 4 — Reused-template detector

### Operational spec

| Field | Value |
|-------|-------|
| **When to dispatch** | After P3 completes. Appends to the same analysis file. |
| **Input variables** | `{{OUTPUT_DIR}}` |
| **Output path** | `{{OUTPUT_DIR}}/analysis/06-past-paper-analysis.md` (append Section 3) |
| **Time budget** | 5–10 min |
| **Token budget** | ~25K input + ~6K output |
| **Composability** | 🔴 — must follow P3; blocks P5 |
| **Failure modes** | `HALLUCINATED-CITE` (agent invents cross-year matches), `LOW-N` |
| **Retry** | If `HALLUCINATED-CITE`: re-dispatch with "every claimed match must include a verbatim quote pair". |

### Prompt body

```
Read all per-paper Q&A breakdowns in {{OUTPUT_DIR}}/analysis/01-paper-by-paper.md.

For each topic that appears in ≥2 past papers, compare the verbatim wording.
If 2+ years use near-identical phrasing (only changing numerical inputs),
flag it as a "reused template".

For each reused template, document:
- Years it appeared
- The constant template (problem narrative)
- The variable inputs (which numbers changed)
- The constant sub-question structure (the (a)/(b)/(c) breakdown)

Output: append Section 3 to {{OUTPUT_DIR}}/analysis/06-past-paper-analysis.md.

These reused templates are the HIGHEST-YIELD individual drills. Examples
from SC4003: coffee-robot decision network (AY1819 + AY2324, only drop
probability changed); Q4 game-theory 4-part structure (5/5 papers, only
matrix numbers change).

Report back: # of reused templates identified, and the single highest-
yield one (most years + most marks).
```

---

## Prompt 5 — Verbatim-repeats pack

### Operational spec

| Field | Value |
|-------|-------|
| **When to dispatch** | After P4 completes. Wave-4, can run alongside P6 and P7. |
| **Input variables** | `{{OUTPUT_DIR}}`, `{{PACKS_DIR}}` |
| **Output path** | `{{PACKS_DIR}}/01_VERBATIM_REPEATS_MEMORIZE.md` |
| **Time budget** | 10–15 min |
| **Token budget** | ~15K input + ~10K output |
| **Composability** | 🟢 — parallel with P6 and P7 (independent file, shared input is read-only) |
| **Failure modes** | `LENGTH-OVERRUN` (model answers >300 words), `TEMPLATE-DRIFT` |
| **Retry** | If `LENGTH-OVERRUN`: re-dispatch with hard 300-word ceiling per item; trim, don't regenerate the rest. |

### Prompt body

```
Read {{OUTPUT_DIR}}/analysis/06-past-paper-analysis.md (especially Section 3)
and the per-paper breakdowns.

Identify items that meet BOTH criteria:
1. Same question (verbatim or near-verbatim) in ≥2 past papers
2. Model answer can fit in ≤300 words

For each item, generate using TEMPLATE_verbatim_repeats.md format:
- Title with mark value
- History line (which papers, "verbatim" or "near-verbatim")
- Verbatim question (in quotes)
- Model answer (memorizable, ≤300 words)
- Marking hint

Target: 8-12 items totaling ~30-50 marks of expected return.

End the pack with a recall checklist (one bullet per item).

Output: {{PACKS_DIR}}/01_VERBATIM_REPEATS_MEMORIZE.md.

Report back: # of items, total expected marks, and which item has the
longest history (i.e., spans the most years).
```

---

## Prompt 6 — Per-topic drill pack

### Operational spec

| Field | Value |
|-------|-------|
| **When to dispatch** | Once per Tier-1 / Tier-2 topic. Wave-4. Fan-out: 1 dispatch per topic. |
| **Input variables** | `{{TOPIC_NAME}}`, `{{HIT_RATE}}`, `{{LIST_OF_PAPER_YEARS}}`, `{{LECTURES_DIR}}`, `{{OUTPUT_DIR}}`, `{{PACKS_DIR}}`, `{{NN_TOPIC_FILENAME}}` |
| **Output path** | `{{PACKS_DIR}}/{{NN_TOPIC_FILENAME}}.md` |
| **Time budget** | 15–25 min per topic |
| **Token budget** | ~30K input + ~15K output per topic → `~45K × T_eff` (T_eff = Tier-1+2 count, usually 4–8) |
| **Composability** | 🟢 — fully parallel across topics; no shared writes |
| **Failure modes** | `LENGTH-OVERRUN`, `TEMPLATE-DRIFT`, `STALE-INPUT` (lectures missing) |
| **Retry** | If `LENGTH-OVERRUN` (>400 lines): re-dispatch with "trim to 300 lines, keep all 3 drills". |

### Prompt body

```
Topic: {{TOPIC_NAME}}
Hit rate: {{HIT_RATE}}
Past-paper instances: {{LIST_OF_PAPER_YEARS}}

Read the relevant lecture slides at {{LECTURES_DIR}} and the past-paper
sub-parts on this topic from {{OUTPUT_DIR}}/analysis/01-paper-by-paper.md.

Produce a topic pack using TEMPLATE_topic_pack.md format:

1. "Why this pack matters" — hit rate + total marks + study time estimate
2. "The Method" — step-by-step recipe, broken into 3-5 numbered steps.
   Each step has: Definition + Method bullets + "State explicitly" phrasing
   + Common pitfall.
3. ≥3 fully worked drills, one per past-paper instance:
   - Verbatim question
   - Worked answer with EVERY algebraic step shown
   - Sanity check at end
4. Common pitfalls (3-5 bullets)
5. Speed-drill template (a parameterized scaffold for unseen problems)
6. Recall card (memorization checklist)

Length target: 200-400 lines. Output as {{PACKS_DIR}}/{{NN_TOPIC_FILENAME}}.md.

## HARD CONSTRAINTS (v0.5 — auto-fail if violated)

<!-- Added v0.5 after SC4023 audit found 5 P0 violations of this rule in PYP_AY2122 Q4(c) and PYP_AY2223 Q5(b/c/d). -->

### No-narrator rule
Final output must read as a SETTLED answer document, not a thinking process.
FORBIDDEN PATTERNS (auto-fail; the orchestrator will respawn the agent):
- "Wait —" / "Wait," / "Hmm," / "let me re-derive" / "let me redo"
- "I'll commit to" / "I think" / "I realize" / "actually,"
- "raise your hand" / "tell the lecturer"
- "Tedious" / "see lecturer's full" / "Approximate answer" / "Solution sketch"
- "This gets messy" / "It is genuinely impossible" / "closest feasible"
- Any other prose that signals work-in-progress mid-derivation

If content is genuinely uncertain, use ONE of these standardized markers:
- 🚨 OCR-AMBIGUOUS: [committed best interpretation] (alternative: [single alternative])
- 🚨 OCR-NOTE: [single committed interpretation, medium confidence]
Then provide ONE definitive answer. Never narrate the uncertainty in prose.

### No-punt rule
"see lecturer's notes" / "see official solution" / "see Tut N solutions" is FORBIDDEN
as a substitute for an actual worked answer. If the question is structurally hard,
provide best-effort reasoning + mark scheme breakdown + flag with 🚨 HARD-Q: marker.
Punting is auto-fail.

Report back: # of drills written, target speed-per-problem, and the
hardest pitfall the student is likely to hit.
```

---

## Prompt 7 — PYP full-answer pack

### Operational spec

| Field | Value |
|-------|-------|
| **When to dispatch** | Once per past paper, after Wave-3 (so cross-references to Section 3 work). Wave-4. |
| **Input variables** | `{{PAPER_YEAR}}`, `{{PYP_DIR}}`, `{{PACKS_DIR}}` |
| **Output path** | `{{PACKS_DIR}}/pyp_answers/PYP_{{PAPER_YEAR}}_FULL_ANSWERS.md` |
| **Time budget** | 20–30 min per paper |
| **Token budget** | ~25K input + ~20K output per paper → `~45K × N` |
| **Composability** | 🟢 — fully parallel across papers; no shared writes |
| **Failure modes** | `LENGTH-OVERRUN`, `TEMPLATE-DRIFT`, missing-algebra (skipped steps) |
| **Retry** | If a sub-part skips algebra: re-dispatch only that sub-part with "show every step" emphasis. |

### Prompt body

```
For paper {{PAPER_YEAR}}:
- Source paper: {{PYP_DIR}}/papers/PYP_{{PAPER_YEAR}}.md
- Topic packs available: {{PACKS_DIR}}/*.md

For every sub-part (Q1(a), Q1(b), ..., Q4(d)), produce per
TEMPLATE_pyp_answers.md format:
- Verbatim question text in quotes
- Model answer with full algebra and explanation
- Marking hints (point breakdown + 1-2 common mistakes)
- Time target (minutes)
- Cross-reference to the relevant topic pack ID

End the file with a self-grade table (Q | Topic | Marks attempted | Marks earned | Weak?).

Output: {{PACKS_DIR}}/pyp_answers/PYP_{{PAPER_YEAR}}_FULL_ANSWERS.md.

Quality bar: every numerical answer must show every algebraic step.
"Show your working" is what gets the partial-credit marks.

## HARD CONSTRAINTS (v0.5 — auto-fail if violated)

<!-- Added v0.5 after SC4023 audit found 5 P0 violations of this rule in PYP_AY2122 Q4(c) and PYP_AY2223 Q5(b/c/d). -->

### No-narrator rule
Final output must read as a SETTLED answer document, not a thinking process.
FORBIDDEN PATTERNS (auto-fail; the orchestrator will respawn the agent):
- "Wait —" / "Wait," / "Hmm," / "let me re-derive" / "let me redo"
- "I'll commit to" / "I think" / "I realize" / "actually,"
- "raise your hand" / "tell the lecturer"
- "Tedious" / "see lecturer's full" / "Approximate answer" / "Solution sketch"
- "This gets messy" / "It is genuinely impossible" / "closest feasible"
- Any other prose that signals work-in-progress mid-derivation

If content is genuinely uncertain, use ONE of these standardized markers:
- 🚨 OCR-AMBIGUOUS: [committed best interpretation] (alternative: [single alternative])
- 🚨 OCR-NOTE: [single committed interpretation, medium confidence]
Then provide ONE definitive answer. Never narrate the uncertainty in prose.

### No-punt rule
"see lecturer's notes" / "see official solution" / "see Tut N solutions" is FORBIDDEN
as a substitute for an actual worked answer. If the question is structurally hard,
provide best-effort reasoning + mark scheme breakdown + flag with 🚨 HARD-Q: marker.
Punting is auto-fail.

### ONE canonical answer rule (Prompt 7 specific)
Each sub-question gets exactly ONE canonical answer. If the answer requires multiple
cases (e.g., "if X then ... else ..."), that's fine — but do NOT enumerate alternative
attempts (16-insert, 17-insert, 18-insert, ...). Pick the best, present it cleanly.

If the question is structurally impossible under stated constraints:
1. State impossibility in 1 declarative sentence
2. Provide ONE closest-feasible solution
3. Wrap exam-day strategy in a `📝 EXAM-DAY SCRIPT:` callout (separate from answer body)
4. Do NOT enumerate alternatives in the answer body

Report back: total marks tabulated, # of sub-parts, and which sub-part
is the most likely to recur (cross-reference Section 3 of past-paper
analysis).
```

---

## Prompt 8 — Coverage audit (RED items vs packs)

### Operational spec

| Field | Value |
|-------|-------|
| **When to dispatch** | After Wave-4 finishes (all packs exist). |
| **Input variables** | `{{LECTURER_REVIEW_PATH}}`, `{{PACKS_DIR}}`, `{{OUTPUT_DIR}}` |
| **Output path** | `{{OUTPUT_DIR}}/coverage_audit.md` |
| **Time budget** | 10–15 min |
| **Token budget** | ~40K input + ~10K output |
| **Composability** | 🔴 — sequential; gate for Wave 6 |
| **Failure modes** | `STALE-INPUT` (lecturer review missing), `HALLUCINATED-CITE` (agent invents pack coverage) |
| **Retry** | If `STALE-INPUT` (no lecturer review): degrade gracefully — run audit against past-paper frequency only and flag the missing input in output header. |

### Prompt body

```
Sources:
- Lecturer review deck at {{LECTURER_REVIEW_PATH}}
- All topic packs at {{PACKS_DIR}}/*.md

Extract every RED-flagged item from the lecturer's review deck (these are
items the lecturer explicitly emphasized as exam scope).

For each RED item, search every topic pack for coverage. Tag:
- ✓ = pack has BOTH definition AND worked example
- ⚠ = pack mentions but missing drill OR definition
- ✗ = topic absent or only one passing mention

Produce {{OUTPUT_DIR}}/coverage_audit.md per TEMPLATE_coverage_audit.md format:
- Coverage table (per-module breakdown)
- Summary counts (total / ✓ / ⚠ / ✗)
- Critical gaps (✗ items) with risk + remedy + ROI
- Partial gaps (⚠) with fix bullets
- Top 3 strengths
- "Single highest-priority action (next hour)" — 1-3 cheat cards
  totaling ≤15 min that close all critical gaps
- Honest verdict (% coverage pre-fix vs post-fix)

Report back:
(a) # of ✗ items
(b) Highest-ROI cheat card (5-min memorization vs marks at risk)
(c) Whether lecturer-emphasized items align with past-paper frequency
    (warn if they diverge significantly)
```

---

## Prompt 9 — Hour-by-hour master plan

### Operational spec

| Field | Value |
|-------|-------|
| **When to dispatch** | After P8. Wave-6, parallel with P10. |
| **Input variables** | `{{OUTPUT_DIR}}`, `{{PACKS_DIR}}`, `{{HOURS_TO_EXAM}}`, `{{EXAM_DATETIME}}`, `{{TARGET_SCORE}}` |
| **Output path** | `{{OUTPUT_DIR}}/MASTER_PLAN.md` |
| **Time budget** | 10–15 min |
| **Token budget** | ~30K input + ~12K output |
| **Composability** | 🟢 — parallel with P10 (different output files, both read-only on packs) |
| **Failure modes** | mis-allocation (Tier-4 getting time), violating sleep guarantee, `STALE-INPUT` |
| **Retry** | If allocation rules violated: re-dispatch with violation explicitly flagged ("you allocated 2h to Tier-4 X — fix"). |

### Prompt body

```
Inputs:
- Frequency table at {{OUTPUT_DIR}}/analysis/06-past-paper-analysis.md
- All topic packs at {{PACKS_DIR}}/
- Hours remaining: {{HOURS_TO_EXAM}}
- Exam date/time: {{EXAM_DATETIME}}
- Target score: {{TARGET_SCORE}}

Produce a master cramming plan per TEMPLATE_master_plan.md format. Hour-
by-hour, working backwards from the exam start time.

Allocation rules:
- Tier-1 packs (≥4/N hits) get 50-60% of time
- Tier-2 packs (2-3/N) get 25-30%
- Tier-3 (1/N) gets 10-15% only if time permits
- Tier-4 (0/N) gets 0 hours
- Verbatim repeats pack first (Hour 1)
- Cold past-paper attempt at end of Day 1
- Day 2 morning is review-only (no new material)
- Stop studying ≥2 hours before exam

Include:
- Phase 0 setup (env prep, snacks, no phone)
- Per-block exit criteria
- Recovery plan if cold mock < target
- Recovery plan if cold mock ≥ stretch goal
- Pre-exam ritual (last 30 min)

Output: {{OUTPUT_DIR}}/MASTER_PLAN.md.

Report back: total hours scheduled, sleep hours guaranteed, and which
pack is the most-time-allocated (validate it's the highest-frequency one).
```

---

## Prompt 10 — Handwritten cheatsheet

### Operational spec

| Field | Value |
|-------|-------|
| **When to dispatch** | After P8. Wave-6, parallel with P9. |
| **Input variables** | `{{PACKS_DIR}}`, `{{OUTPUT_DIR}}` |
| **Output path** | `{{OUTPUT_DIR}}/cheatsheet.md` |
| **Time budget** | 10–15 min |
| **Token budget** | ~25K input + ~6K output |
| **Composability** | 🟢 — parallel with P9 |
| **Failure modes** | `LENGTH-OVERRUN` (>1500 words → won't fit A4 by hand) |
| **Retry** | If word count >1500: re-dispatch with "compress, drop Tier-3 lines first". |

### Prompt body

```
Inputs:
- All packs at {{PACKS_DIR}}/
- Frequency table

Produce a 1-page (or 2-side) cheatsheet per TEMPLATE_handwritten_cheatsheet.md.

Compression rule: if it doesn't fit on A4, it's not memorized. Cut.

Required sections:
- Exam logistics line (date / venue / seat / format)
- Q-by-Q lock-in: one paragraph per question slot with formula/recipe
- Tier-1 must-recall items (write from memory in first 5 min of exam)
- Verbatim repeats one-liner table (5-10 rows)
- Key formulas / recipes (3-5)
- Sanity checks (4 bullets)
- Skip list (0/N hits — don't panic if you see them)
- First 5 min ritual (numbered steps)
- Last 5 min ritual

Output: {{OUTPUT_DIR}}/cheatsheet.md.

For closed-book exams: the student writes this BY HAND the night before,
then the handwritten copy is the mental model — what they should be able
to reproduce on scratch paper in the first 5 minutes.

Report back: word count of cheatsheet (target ≤1500 words to fit A4 by hand).
```

---

## Composite "do everything" prompt

### Operational spec

| Field | Value |
|-------|-------|
| **When to dispatch** | One-shot pipeline run; only when all inputs are confirmed present. |
| **Input variables** | `{{COURSE_CODE}}`, `{{PYP_DIR}}`, `{{LECTURES_DIR}}`, `{{LECTURER_REVIEW_PATH}}?`, `{{EXAM_DATETIME}}`, `{{HOURS_TO_EXAM}}`, `{{TARGET_SCORE}}` |
| **Output path** | All outputs from P1–P10 in their respective paths |
| **Time budget** | 90–180 min wall-clock if subagent waves run in parallel; 4–8 hours sequential |
| **Token budget** | sum of P1–P10 ≈ `~150K + 80K×N + 45K×T_eff` |
| **Composability** | 🔴 — exclusive (it IS the pipeline) |
| **Failure modes** | `LOW-N` (must STOP, not infer); any per-step failure should checkpoint, not blow up the whole run |
| **Retry** | Fail-fast at `LOW-N`. Otherwise checkpoint per wave so individual prompts can be re-dispatched. |

### Prompt body

```
Run the full exam-prep pipeline for {{COURSE_CODE}}.

Inputs:
- Past papers: {{PYP_DIR}}
- Lectures: {{LECTURES_DIR}}
- Lecturer review (optional): {{LECTURER_REVIEW_PATH}}
- Exam datetime: {{EXAM_DATETIME}}
- Hours remaining: {{HOURS_TO_EXAM}}
- Target score: {{TARGET_SCORE}}

Execute steps 1-10 from WORKFLOW_STEPS.md, in order. Use the templates at
/tmp/exam_prep_templates/ as the format for each output file.

Final report should include:
(a) total artifacts produced
(b) Tier-1 topics (with hit rates)
(c) SKIP list (Tier-4 topics)
(d) cold-mock recommendation (which past paper to attempt first)
(e) any RED items not yet covered (with 10-min closure plan)

If any step has insufficient input data (e.g., <3 past papers), STOP and
ask before proceeding — empirical analysis is unreliable below N=3.
```

---

## Parallelization plan

### Wave-by-wave dispatch matrix

| Wave | Prompts | Mode | Wall-clock if parallel | Wall-clock if serial |
|------|---------|------|------------------------|----------------------|
| 1 | P1 (fan-out × N) | 🟡 N parallel | 5–15 min | 10–75 min |
| 2 | P2 (fan-out × N) | 🟡 N parallel | 3–5 min | 10–25 min |
| 3 | P3 → P4 | 🔴 strict serial | 10–20 min | 10–20 min |
| 4 | P5, P6×T_eff, P7×N | 🟢 ALL parallel | 20–30 min | 60+ min |
| 5 | P8 | 🔴 | 10–15 min | 10–15 min |
| 6 | P9, P10 | 🟢 parallel | 10–15 min | 20–30 min |

### Safe-to-parallelize set

The following can run **concurrently in the same dispatch batch** with no
shared-write conflicts:

**Wave-1 batch (per-paper OCR):**
- P1 dispatched once per PDF in `{{PYP_DIR}}` (writes distinct output files)

**Wave-2 batch (per-paper Q&A):**
- P2 dispatched once per paper (each writes a distinct section, then merge)
  *Caveat:* if you fan-out P2, the orchestrator must concatenate sections
  in chronological order before P3 reads.

**Wave-4 batch (the big parallel wave):**
- P5 (one dispatch — verbatim repeats pack)
- P6 dispatched once per Tier-1 / Tier-2 topic (typically 4–8 dispatches)
- P7 dispatched once per past paper (typically 5–7 dispatches)

  Total Wave-4 parallel dispatches: **1 + T_eff + N ≈ 10–16 concurrent agents**.
  All read-only on shared inputs (`papers/*.md`, `analysis/06-*.md`); each
  writes to a distinct output file. Zero write contention.

**Wave-6 batch:**
- P9 (master plan) and P10 (cheatsheet) — distinct output files, both read-only on packs.

### Serial chokepoints (do not parallelize)

| Edge | Reason |
|------|--------|
| P1 → P2 | P2 reads P1's outputs |
| P2 → P3 | P3 needs the merged Q&A table |
| P3 → P4 | P4 appends to P3's analysis file |
| P4 → Wave-4 | Wave-4 reads Section 3 (reused templates) cross-references |
| Wave-4 → P8 | P8 audits the packs |
| P8 → Wave-6 | P9/P10 use audit's gap signals |

---

## Notes on prompt design (preserved + extended)

1. **Always specify output paths.** Agents drift if you let them.
2. **Always specify "Report back:"** with the questions you want answered.
   This forces the agent to actually verify its work, not just declare done.
3. **Always pass the relevant template.** Inline schemas beat free-form prose.
4. **Include validation rules** (e.g., "≥3 drills per pack", "≤300 words per
   verbatim item"). Without quality bars, agents over- or under-produce.
5. **Use "STOP and ask" guards** for low-data conditions (N<3 papers).
   Bad data in → bad analysis out.
6. **(v2) Specify failure modes up front.** Agents that know what can go
   wrong recover faster than agents told only what success looks like.
7. **(v2) Treat token/time budgets as contracts.** When a prompt overruns,
   that's a signal the spec is wrong, not just that the model is slow.
8. **(v2) Mark composability explicitly (🟢/🟡/🔴).** This makes
   parallelization a mechanical decision, not a per-run judgment call.

---

## Appendix: Quick-reference dispatch order

```
SEQ: P1 → P2 → P3 → P4 → [P5 ‖ P6×T ‖ P7×N] → P8 → [P9 ‖ P10]
       ↑           ↑                              ↑
      LOW-N    HALLUCINATED-CITE              LENGTH gates
      gate     gate
```

`‖` = parallel.
`→` = strict serial dependency.
`×N` = fan-out per past paper.
`×T` = fan-out per Tier-1/2 topic.
