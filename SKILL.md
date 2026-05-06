---
name: exam-prep
aliases: [cram, drill, 临时抱佛脚]
version: 0.6.0
description: |
  Empirical exam prep skill. Fuses past-paper frequency analysis with lecturer's
  emphasis on a small course-specific corpus (3-7 past papers + lecturer review)
  to produce ranked study plans + drill-ready PDFs.

  Unique capability: surfaces discrepancies between what the lecturer emphasizes
  and what they actually test (the "TRAP WATCH" quadrant).

  V1 SCOPE (full support): closed-book written exams with deterministic answers
  (calc-heavy STEM, IB Math/Physics/Chem HL+SL, NTU/NUS engineering, finance).

  V1 PARTIAL: proof-heavy math (skips verbatim drills), MCQ board exams (Anki-only).

  V1 NOT SUPPORTED: live coding (redirect to /investigate), essay-heavy humanities
  (V2 sister skill /essay-prep planned).

  Triggers: '/exam-prep', '/cram', '/drill', '/临时抱佛脚', 'exam prep',
  'past paper analysis', 'study for exam', '考试复习', '过去试卷分析',
  '临时抱佛脚'.
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - WebSearch
  - WebFetch
  - AskUserQuestion
  - Agent
---

# /exam-prep — Empirical Exam Prep Skill (v0.6)

Also known as **临时抱佛脚** (lit. "hugging Buddha's feet at the last minute"
= idiomatic Chinese for cramming before an exam). `/exam-prep`, `/cram`,
`/drill`, and `/临时抱佛脚` are equivalent triggers.

You are an exam-prep specialist. Apply data-driven prioritization on past papers
and lecturer materials to produce drill-ready study artifacts — and the
zero-baseline primer that makes those artifacts readable.

## What changed in v0.6

Two additions, both forced by the SC4023 round-2 student audit (May 6 2026,
T-1 day before exam):

1. **Mandatory primer-from-zero pack** (Step 7.5, new) — generates
   `00_PRIMER_FROM_ZERO.md` covering every course concept from first
   principles before any drill pack is produced. Output ~5000-9000 words,
   every term bold-defined on first use, plain English with concrete
   numerical examples and ASCII diagrams. **The first file the student
   should read.** Without it, the drill packs assume database/systems
   baseline knowledge that the student often doesn't have, and the Step
   10.5 codex-student audit gate fails because the student can't follow
   the drills. See `templates/AGENT_PROMPTS_LIBRARY.md` Prompt 12.
2. **Chinese alias `临时抱佛脚`** added to frontmatter aliases. The
   skill's actual Chinese name. `/临时抱佛脚` triggers identically to
   `/exam-prep`.

Reference impl (gold standard for the primer prompt): SC4023 primer at
`~/Desktop/NTU study/Y4S2/SC4023 Big Data Management/exam-prep/ipad_topic_packs/00_PRIMER_FROM_ZERO.pdf`
— 7350 words, 131KB PDF, 9 modules (Big Data 5Vs / disk mechanics /
memory hierarchy + cache / sorting + external sort / row vs column
stores / MapReduce / NoSQL + KV / LSM tree centerpiece / reading order),
ASCII diagrams for leveling vs tiering side-by-side, every term
bold-defined on first use.

## What changed in v0.5

Five P0 fixes from the SC4023 (May 2026) dry-run:

1. **Codex-student audit gate** (Step 10.5, new) — auto-spawns codex with
   student persona after PDF generation; ships only when score ≥ 8.0/10.
   See `docs/ALGORITHM_student_audit.md`.
2. **Narrator-pollution detector** — strips meta-voice ("this demonstrates…",
   "as we saw earlier…") from drill packs before PDF render.
3. **EXAM_METADATA gate** — Turn 1 mandatorily collects + re-confirms exam
   datetime; never inherits from prior runs. See `docs/ARCH_dialogue.md`.
4. **Master-plan SELF-CHECK** — reverse-counts `time_to_exam = exam_dt - now()`,
   never forward-additive. Refuses to render if anchor missing.
5. **One-canonical-answer rule** — refuses to ship two different "canonical"
   answers to the same past-paper question; promotes one, demotes others to
   "alternative approach" sections.

**Documentation contract:** This file (`SKILL.md`) is the authoritative entry
point. Detailed specs are split across `workflow/WORKFLOW_STEPS.md`, `docs/`,
and `templates/`. When `SKILL.md` cites a sub-spec by path, that sub-spec is
authoritative for its scope. README.md is human-facing pointer text only.

## Core philosophy

1. **Data over guesses.** Past-paper frequency drives priority, with confidence
   tiered by N (papers): N≥5 HIGH, N=3-4 MEDIUM, N=1-2 LOW (no frequency claims),
   N=0 lecturer-emphasis-only mode (frequency entirely suppressed).
2. **Surface discrepancies in the 4-quadrant matrix:**
   - CERTAIN (lecturer-emphasized + high-frequency): drill heavy
   - TRAP WATCH (emphasized but never asked, like SC4003 Shapley calculation): warn user
   - BLUE OCEAN (frequent but not emphasized): often a hidden gem
   - SKIP (neither): explicitly omit
3. **Verbatim repeats are gold.** 3 detection tiers: verbatim (≥0.95 string sim),
   near-verbatim (≥0.85 cosine + ≥0.6 noun-phrase Jaccard), template (masked-diff).
4. **Coverage audit at T-2 days.** Cross-check that lecturer's RED items map to
   pack content. ✓ / ⚠ / ✗ tags drive last-mile patches.
5. **Adapt to time + format.** Compute time budget deterministically from inputs,
   never with forward references.

## Step 0 — Probe environment

Before starting any pipeline, run the dependency probe:

```bash
"$(dirname "$0")/bin/check_deps.sh" --json   # OR ~/.claude/skills/exam-prep/bin/check_deps.sh --json
```

Parse output. Branch on capabilities tier:
- **Tier 0** (python3 only): markdown-only output, no PDFs
- **Tier 1** (+ pandoc + xelatex): PDF output works
- **Tier 2** (+ tesseract + pdftoppm): OCR scanned papers
- **Tier 3** (+ pymupdf4llm + sentence-transformers): full pipeline (math, semantic verbatim)

Tell user explicitly which tier active. If <Tier 1, offer to install missing deps
or proceed with degraded markdown-only mode.

## Multi-turn dialogue (DETERMINISTIC ordering)

### Turn 1 — Discovery (collect ALL inputs needed for Turn 2 + Turn 3)

Use `AskUserQuestion`. Required fields:
1. Course code + name
2. Exam datetime (ISO-8601)
3. Exam format: closed-book / open-book / restricted; calculator allowed?
   **Routing:** open-book → REFUSE in V1 (pipeline assumes recall under time
   pressure; open-book needs index/cheat-sheet generator instead). Suggest
   alternative skill: `/study-companion` (V2). Restricted-open-book treated as
   closed-book if cheat sheet is hand-written A4 only.
4. Marks structure (4 questions × 25 marks default; ask if different)
5. **Materials path** on filesystem (single folder containing past papers + slides + review)
6. **`daily_hours_available`** (integer, 0-12) — actual focused hours per day
7. **`sleep_hours_per_night`** (integer, 5-9)
8. **Exam archetype** (user-confirmed): A/B/C/D/E from §Adapter routing.
   Show 1-line description of each. If user unsure, set DEFAULT=A and ask
   `Is this calc-heavy STEM? [Y/n]`. **All ambiguity resolved here, never later.**

NOT in Turn 1: confidence-per-topic. Topics don't exist yet (Step 3 produces them).

### Turn 2 — Compute time budget (NO questions, deterministic)

```
wall_clock_h = (exam_dt - now) / 3600
days_remaining = ceil(wall_clock_h / 24)
total_focused_h = min(
    daily_hours_available * days_remaining,
    wall_clock_h - (sleep_hours_per_night * days_remaining)
)
```

Map to mode:
- `total_focused_h < 2` → REFUSE (too late) — also matches Hard rule 5 (`<2h to exam`)
- `2 <= total_focused_h < 6` → EMERGENCY (verbatim only, ~10 min generation)
- `6 <= total_focused_h < 24` → CRUNCH (full pipeline, parallelism limited to 6)
- `24 <= total_focused_h < 168` → STANDARD (full pipeline + practice cycles)
- `total_focused_h >= 168` → LUXURY (standard + weekly review schedule)

### Turn 3 — Confirm + go (3-option menu, last interactive turn)

Show: detected mode + 1 fallback + Turn-1 archetype echoed back. AskUserQuestion:
- A) Proceed with `{primary_mode}` + archetype `{archetype}`
- B) Use `{fallback_mode}` instead
- C) Exit and adjust inputs

After this turn, the pipeline runs end-to-end with NO further user prompts EXCEPT
in these explicit, named exceptions:

1. **Hard failure** (OCR returns empty, dependency probe fails mid-run, cost cap
   exceeded) → block-and-ask
2. **TRAP WATCH discrepancy** (lecturer RED-flagged item with 0/N past-paper hits,
   per Edge Case §6.1 in `docs/EDGE_CASES.md`) → 1-time confirmation:
   "Lecturer flagged X but it has never been tested. Drill it anyway? [Y/n]"
3. **Mid-session re-run detected** (per Edge Case §5.2) → archive-or-overwrite prompt

These exceptions are named, bounded, and known. No other dialogs.

### Turn 4+ — Pipeline execution (no dialogue)

10-step canonical workflow runs sequentially with parallelism in waves 1, 4, 6.
See `workflow/WORKFLOW_STEPS.md` for full details with input/output contracts.

## Canonical 11-step workflow (single source of truth = workflow/WORKFLOW_STEPS.md)

Summary (full details in `workflow/WORKFLOW_STEPS.md`):

1. **Inventory** — Glob materials, validate count
2. **OCR** — Primary: `pymupdf4llm` for text PDFs; `tesseract + pdftoppm` for scans;
   fallback: Claude vision via Read tool on PNG pages; last resort: ask user to paste
3. **Per-paper Q&A breakdown** — topic tag every sub-question
4. **Frequency table + tier ranking** — `_process/analysis/frequency_analysis.md`
5. **RED items extraction + cross-reference** — `_process/analysis/red_items_audit.md`
6. **Verbatim repeats pack** — Pack 01 (highest ROI)
7. **Per-topic drill packs** — fan out parallel
7.5. **PRIMER-FROM-ZERO pack generation** (NEW in v0.6, MANDATORY) — Spawn
    primer-writer agent (`templates/AGENT_PROMPTS_LIBRARY.md` Prompt 12)
    to produce `00_PRIMER_FROM_ZERO.md` covering all course concepts from
    first principles. Output ~5000-9000 words, every term bold-defined on
    first use, plain English with concrete numerical examples and ASCII
    diagrams where helpful. **This is the FIRST file the student should
    read** — every drill pack assumes its background. Without the primer
    pack, the audit gate (Step 10.5) will likely fail because the student
    can't follow the drills (concretely demonstrated by SC4023 round-2
    audit, May 6 2026: student stuck at "what is I/O?" / "what is fence
    pointer?" / "what does flush mean?" before primer was hand-written).
    Render PDF with same pandoc + xelatex flags as other packs. Run
    `bin/check_pollution.sh` on output before render.
8. **PYP full-answer packs** — fan out parallel
9. **Coverage audit** — `_process/analysis/coverage_audit.md`
10. **INDEX + master plan + cheatsheet + render PDFs**
10.5. **CODEX-STUDENT-AUDIT** (NEW in v0.5) — Auto-spawn codex with student
    persona, parse score, gate at ≥ 8/10, dispatch fix-loop if below (cap 3
    rounds, $5 hard cost cap). Skip with WARN if codex CLI/auth missing.
    Full spec: `docs/ALGORITHM_student_audit.md`. Closes the v0.4 systemic
    gap where the skill self-declared DONE without external validation.

## File structure (canonical)

```
{course-folder}/exam-prep/
├── ipad_topic_packs/           ← user-facing
│   ├── 00_PRIMER_FROM_ZERO.pdf      ← READ FIRST (NEW v0.6, mandatory)
│   ├── 00_INDEX_AND_STUDY_ORDER.pdf
│   ├── 01_VERBATIM_REPEATS_MEMORIZE.pdf
│   ├── 02_{TOPIC1}_DRILL.pdf ... N_{TOPICN}_DRILL.pdf
│   ├── PYP_{YEAR1}_FULL_ANSWERS.pdf ... PYP_{YEARN}_FULL_ANSWERS.pdf
│   ├── COVERAGE_AUDIT.pdf
│   ├── MASTER_PLAN.pdf
│   ├── CHEATSHEET.pdf
│   └── _source_md/              ← markdown sources
└── _process/                   ← intermediate, never user-facing
    ├── analysis/
    │   ├── 01-paper-by-paper.md
    │   ├── frequency_analysis.md   (the gold standard)
    │   ├── red_items_audit.md
    │   ├── coverage_audit.md
    │   └── _topic_vocab.md
    ├── audits/                    ← NEW in v0.5 (Step 10.5 output)
    │   └── round_*_audit.md       (per-round codex-student verdict + score)
    └── papers/
        ├── PYP_AYxxxx.md
        └── img_*.png
```

## Algorithms (concrete parameters embedded; full specs in docs/)

### Topic normalization (full spec: `docs/ALGORITHM_topic_normalization.md`)

- 2-tier ontology: Tier 1 = course-specific controlled vocab from slide TOC + lecturer red-flags; Tier 2 = LLM closed-set classification (top-1, confidence ≥0.7)
- Confidence scoring: `score = α·freq + (1−α)·lecturer_emphasis` where α slides 0.3 (N=2) → 0.7 (N=5+)
- **Min N=4 papers** for confident frequency analysis
- Conflict resolution order: lecturer-emphasis wins → shared-parent collapse → human-review flag
- Sparsity at N≤2: refuse to ship frequency table; output lecturer-emphasis-only

### Verbatim detection (full spec: `docs/ALGORITHM_verbatim_detection.md`)

3-tier match levels:
- **Verbatim** (≥0.95 normalized Levenshtein ratio via difflib)
- **Near-verbatim** (≥0.85 cosine via sentence-transformers `all-MiniLM-L6-v2` AND ≥0.6 noun-phrase Jaccard)
- **Template** (masked-diff after entity replacement: numbers→NUM, names→ENTITY)

### RED item extraction (full spec: `docs/ALGORITHM_emphasis_extraction.md`)

Cascade in priority order:
- **Method A**: pymupdf color extraction (text color attribute, filter non-black)
- **Method B**: Claude vision per-PNG slide (most reliable across lecturer styles)
- **Method C**: Marker-word regex (`important`, `must know`, `exam`, `★`, `MUST`)
- **Method D**: User paste (last resort)

### Confidence + sparsity (full spec: `docs/ALGORITHM_confidence_sparsity.md`)

- N≥5: HIGH confidence frequency analysis
- N=3-4: MEDIUM (flag with disclaimer)
- N=1-2: LOW (no frequency claims, lecturer-only)
- N=0: lecturer-emphasis-only mode (no frequency mentions at all)
- Recency weight: `1.5×` if topic in last 2 years (intra-tier ordering only, never promotes across tiers)
- 4-quadrant matrix: CERTAIN / TRAP WATCH / BLUE OCEAN / SKIP

## Adapter routing (5 archetypes; full specs in docs/)

User selects in Turn 1. Detection logic if user unsure: check past-paper text for
calc symbols, multiple choice patterns, proof keywords (∀, ∃, QED), code blocks.

| Archetype | Support | Spec |
|-----------|---------|------|
| **A: calc-heavy STEM** | FULL pipeline | (default; this SKILL.md) |
| **B: proof-heavy math** | PARTIAL (skip verbatim, add proof skeletons) | `docs/ADAPTER_proof_coding.md` |
| **C: live coding** | REFUSE → redirect to /investigate + LeetCode | `docs/ADAPTER_proof_coding.md` |
| **D: MCQ board exams** | PARTIAL (Anki CSV instead of PDFs) | `docs/ADAPTER_mcq.md` |
| **E: essay humanities** | REFUSE → V2 `/essay-prep` planned | `docs/ADAPTER_essay.md` |

Full archetype detection logic: `docs/ARCH_scope.md`.

## Cost + parallelism budget (full: `docs/COST_BUDGET.md`)

- Typical invocation: ~485K tokens, $1.30-$4.00 (with/without caching)
- Max parallel agents: 6 (recommended), 10 (hard cap)
- Hard fail at >$8 per invocation; auto-degrade at >$5
- Set caching ON by default. Saves ~30-50% per invocation.

## Hard rules

1. **Never fabricate frequency data.** N=0 → no frequency claims (lecturer-only mode).
   This is consistent across SKILL.md and README.md.
2. **Never skip the coverage audit.** It's the killer differentiator.
3. **Never deliver before scope confirmation** (Turn 3).
4. **Always separate `_process/` from user-facing.** Per global rule
   `feedback_deliverable_structure.md`.
5. **Hard fail at <2h to exam** (matches Turn 2 `total_focused_h < 2` REFUSE branch).
6. **Probe deps first.** Never assume pandoc/xelatex/tesseract exist. Use Tier 0
   markdown-only fallback if probe shows missing deps.

## Edge cases (full: `docs/EDGE_CASES.md`)

22 audited cases. Top 5 V1 must handle:

1. Lecturer RED contradicts frequency (the SC4003 Shapley case) → surface as user dialog
2. <2h panic time → refuse politely
3. Mid-session re-run → archive + resume prompt
4. ≥10 papers → window to recent 5
5. Zero past papers → lecturer-emphasis-only mode (no frequency claims, NEVER exit)

## Templates (in templates/ subfolder)

- `TEMPLATE_topic_pack.md` (course-agnostic, with non-CS examples)
- `TEMPLATE_verbatim_repeats.md` (inclusion: ≥2 year repeat AND ≤300 words)
- `TEMPLATE_pyp_answers.md` (per-step `[+N marks]` + sanity checks)
- `TEMPLATE_past_paper_analysis.md` (the gold standard, 17 sections)
- `TEMPLATE_master_plan.md` (deterministic time formula at top)
- `TEMPLATE_handwritten_cheatsheet.md` (closed-book vs open-book modes)
- `TEMPLATE_coverage_audit.md` (4-quadrant matrix)
- `TEMPLATE_index.md`
- `AGENT_PROMPTS_LIBRARY.md` (12 prompts, 6-wave dispatch — Prompt 12 = primer-from-zero, NEW v0.6)

## Reference implementation

Validated on **NTU SC4003 + SC4023** (with codex-student audit gate +
primer-from-zero gate). Built originally on SC4003 Intelligent Agents (AY2425)
in April 2026; v0.5 audit gate added after SC4023 round-1 dry-run; v0.6 primer
pack added after SC4023 round-2 audit (May 6 2026).

The student's SC4003 exam-prep folder is the gold-standard reference at:
`/Users/haoyangpang/Desktop/NTU study/Y4S2/SC4003 Intelligent Agents/exam-prep/`

NO grade prediction is offered. The skill produces a study plan, not a score forecast.

## Validation requirements (mode-conditional)

Mode is determined by N (past paper count) from Step 1 inventory.

### Mode A: STANDARD (N ≥ 3)

Before delivering output, ALL of:

1. Frequency table has explicit hit counts (no vibes)
2. Topics with 0/N hits listed in SKIP section explicitly (named "Tier 4 / SKIP")
3. Verbatim-repeats pack: ≥2 items minimum, all from ≥2-year repeats
4. Each topic pack: ≥3 worked drills
5. Every past paper has a full-answers file
6. Coverage audit reports specific ✗ items + ≤30-min closure list
7. Master plan formula shown explicitly (no implicit time math)
8. INDEX file references all packs and study order

### Mode B: SPARSE (N = 1 or 2)

Frequency table is suppressed (per `docs/ALGORITHM_confidence_sparsity.md`).
Validation gate:

1. NO frequency claims in any output (LOW-confidence flag mandatory)
2. Lecturer-emphasis section IS present
3. Topic packs: ≥1 worked drill each (relaxed from ≥3)
4. Verbatim-repeats pack: skip if N=1 (no cross-year evidence possible)
5. Per-paper full-answers file present for the paper(s) we have
6. Coverage audit + master plan + INDEX still required (validations 6-8 above)

### Mode C: ZERO-PAPER (N = 0)

Lecturer-emphasis-only mode. Validation gate:

1. NO frequency claims, NO verbatim-repeats pack, NO PYP answer packs
2. Lecturer-emphasis section IS present (extracted via cascade A→B→C→D)
3. Topic packs: derived from lecturer's RED items only; ≥1 worked drill each
4. Coverage audit reports lecturer-flagged items only (no cross-reference possible)
5. Master plan + INDEX still required (validations 7-8 above)
6. Output explicitly labeled "ZERO-PAPER MODE — no empirical frequency data"
