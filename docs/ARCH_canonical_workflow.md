# A1 — Canonical Workflow + File Structure (exam-prep skill)

**Purpose:** Resolve the contradictions between `SKILL.md` and `workflow/WORKFLOW_STEPS.md`
into a single source of truth. Codex flagged that the two files defined two different
10-step workflows and used inconsistent path names (`ipad_topic_packs/` vs `topic_packs/`,
`_process/analysis/coverage_audit.md` vs `/process/coverage_audit.md`).

This file is the resolution. After applying the diffs in §3 and §4, both files will
agree.

---

## Decisions (TL;DR)

| Question | Decision | Rationale |
|---|---|---|
| Folder for user-facing PDFs | `ipad_topic_packs/` | The whole reason it exists is to be AirDropped to an iPad. The name encodes its purpose; "topic_packs" loses that signal and collides with the per-pack concept. |
| Process folder name | `_process/` (leading underscore) | The leading underscore matches the existing global rule in `feedback_deliverable_structure.md` (sort process below user-facing on `ls`, signal "internal"). |
| Sub-structure of `_process/` | `_process/analysis/` + `_process/papers/` | Matches SKILL.md and the SC4003 reference implementation. WORKFLOW_STEPS.md's flat layout was the inconsistent one. |
| `coverage_audit.md` location | `_process/analysis/coverage_audit.md` | It's an analysis artifact (cross-references RED items vs packs); belongs with the other analyses. |
| Canonical workflow | The 10 steps in §1 below | Merges the operational ordering of WORKFLOW_STEPS.md (which is what actually runs) with SKILL.md's polish steps (PDF + AirDrop). |

---

## §1 — Single canonical 10-step workflow

The pipeline runs in this exact order. Each step's output feeds the next.

### Step 1 — Inventory raw materials
- **Inputs:** course folder path provided by student in Turn 1 dialogue.
- **Outputs:** `raw/syllabus.pdf`, `raw/lectures/*.pdf`, `raw/papers/PYP_AYxxxx.pdf`,
  `raw/lecturer_review.pdf` (optional).
- **Action:** `Glob` + `Bash ls` to confirm every file opens. Stop here if <2 past papers.

### Step 2 — OCR all PDFs to markdown
- **Inputs:** all PDFs from Step 1.
- **Outputs:** `_process/papers/PYP_AYxxxx.md`, `_process/text/lectures/*.md`,
  `_process/text/lecturer_review.md`. Image dumps in `_process/papers/img_*.png` if
  scanned.
- **Tool:** `pdf-to-md` skill (pymupdf4llm default; `marker-pdf` for scans).
- **Parallelism:** one agent per PDF.

### Step 3 — Per-paper Q&A breakdown + topic tagging
- **Inputs:** `_process/papers/PYP_AYxxxx.md`.
- **Output:** `_process/analysis/01-paper-by-paper.md`. Table of every Q + sub-part
  tagged with a controlled-vocabulary topic label.
- **Why:** without consistent labels the frequency table in Step 4 is meaningless.

### Step 4 — Build empirical frequency table + tier ranking
- **Input:** `_process/analysis/01-paper-by-paper.md`.
- **Output:** `_process/analysis/frequency_analysis.md` (using
  `TEMPLATE_past_paper_analysis.md`). Per-topic hits, marks, average, stickiness
  (CERTAIN / HIGH / WATCH / IGNORE). Tier 1 (≥4/N) and Tier 4 (0/N → SKIP) lists.

### Step 5 — Extract lecturer's RED items + cross-reference vs frequency
- **Inputs:** `_process/text/lecturer_review.md` + frequency table.
- **Output:** `_process/analysis/red_items_audit.md`. Surface discrepancies (lecturer
  emphasized ≠ historically tested) so the student can choose.
- **Note:** also flags reused numerical templates (verbatim near-copies across years)
  for Step 6.

### Step 6 — Build verbatim-repeats pack (Pack 01)
- **Input:** flagged near-verbatim items from Step 5.
- **Output:** `ipad_topic_packs/_source_md/01_VERBATIM_REPEATS_MEMORIZE.md` (using
  `TEMPLATE_verbatim_repeats.md`). 8-12 items, each <300 words.
- **Why first:** this is the single highest-ROI pack.

### Step 7 — Build per-topic drill packs
- **Input:** Tier-1 + Tier-2 topics from Step 4.
- **Output:** `ipad_topic_packs/_source_md/02_{TOPIC}_DRILL.md` ...
  `ipad_topic_packs/_source_md/N_{TOPIC}_DRILL.md` (one per topic, ~5-15 topics, using
  `TEMPLATE_topic_pack.md`). 200-400 lines each.
- **Parallelism:** one agent per topic.

### Step 8 — Build PYP full-answer packs
- **Input:** Step 3 breakdown + per-topic packs.
- **Output:** `ipad_topic_packs/_source_md/PYP_AYxxxx_FULL_ANSWERS.md` per past year
  (using `TEMPLATE_pyp_answers.md`). Verbatim Q + model answer + marking hints + time
  target + cross-ref to topic pack.
- **Parallelism:** one agent per paper.

### Step 9 — Coverage audit (the killer feature)
- **Input:** `_process/analysis/red_items_audit.md` + every file under
  `ipad_topic_packs/_source_md/`.
- **Output:** `_process/analysis/coverage_audit.md` (using
  `TEMPLATE_coverage_audit.md`). Every RED item tagged ✓ / ⚠ / ✗. Closure list:
  1-3 cheat cards (≤10 min total) that fix all ✗.
- **Hard rule:** never skip this step.

### Step 10 — Index, master plan, cheatsheet, render to PDF, deliver
- **Inputs:** all prior outputs.
- **Outputs (markdown sources, in `ipad_topic_packs/_source_md/`):**
  - `00_INDEX_AND_STUDY_ORDER.md` (using `TEMPLATE_index.md`)
  - `MASTER_PLAN.md` (using `TEMPLATE_master_plan.md`) — hour-by-hour
  - `cheatsheet.md` (using `TEMPLATE_handwritten_cheatsheet.md`) — 1-page
- **Render:** `pandoc + xelatex` every `.md` under `_source_md/` → sibling `.pdf` in
  `ipad_topic_packs/`.
- **Deliver:** tell user "AirDrop the entire `ipad_topic_packs/` folder to iPad".

---

## §2 — Single canonical file-structure tree

```
{course-folder}/exam-prep/
├── raw/                                       # Step 1 inputs (untouched originals)
│   ├── syllabus.pdf
│   ├── lectures/*.pdf
│   ├── papers/PYP_AYxxxx.pdf
│   └── lecturer_review.pdf
├── ipad_topic_packs/                          # USER-FACING — AirDrop this folder
│   ├── 00_INDEX_AND_STUDY_ORDER.pdf
│   ├── 01_VERBATIM_REPEATS_MEMORIZE.pdf
│   ├── 02_{TOPIC}_DRILL.pdf
│   ├── ...
│   ├── N_{TOPIC}_DRILL.pdf
│   ├── PYP_AYxxxx_FULL_ANSWERS.pdf            # one per past year
│   ├── ...
│   ├── MASTER_PLAN.pdf
│   ├── cheatsheet.pdf
│   └── _source_md/                            # markdown sources (re-renderable)
│       ├── 00_INDEX_AND_STUDY_ORDER.md
│       ├── 01_VERBATIM_REPEATS_MEMORIZE.md
│       ├── 02_{TOPIC}_DRILL.md
│       ├── ...
│       ├── PYP_AYxxxx_FULL_ANSWERS.md
│       ├── MASTER_PLAN.md
│       └── cheatsheet.md
└── _process/                                  # INTERNAL — don't show user by default
    ├── analysis/
    │   ├── 01-paper-by-paper.md               # Step 3
    │   ├── frequency_analysis.md              # Step 4 (★ the gold-standard analysis)
    │   ├── red_items_audit.md                 # Step 5
    │   └── coverage_audit.md                  # Step 9
    ├── papers/                                # Step 2 OCR output
    │   ├── PYP_AYxxxx.md
    │   └── img_*.png
    └── text/
        ├── lectures/*.md
        └── lecturer_review.md
```

---

## §3 — Diff to apply to `SKILL.md`

### 3.1 — Delete duplicate workflow blob in description (lines 11-13)

The description block already says "Workflow (10 steps): inventory → OCR → ..." which
duplicates the Turn 4-8 list and disagrees with WORKFLOW_STEPS. Replace with a
high-level summary that doesn't enumerate.

**Before (lines 11-13):**
```
  Workflow (10 steps): inventory → OCR → multi-year frequency → lecturer cross-reference →
  topic-pack generation → past-paper answer keys → cold mock + diagnostic → verbatim
  drill → handwritten cheatsheet → coverage audit.
```

**After:**
```
  Workflow: 10-step pipeline from raw materials → frequency analysis → topic-tier
  ranking → drill-ready PDFs → coverage audit. Full step-by-step in
  workflow/WORKFLOW_STEPS.md.
```

### 3.2 — Replace Turn 4-8 inline 10-step list (lines 97-110) with reference

The Turn 4-8 list disagrees with WORKFLOW_STEPS.md (mixes verbatim into "topic packs",
adds "Build INDEX" as a separate synth step, ends with "AirDrop"). Single source of
truth lives in WORKFLOW_STEPS.md after §4 changes below.

**Before (lines 97-110):**
```
### Turn 4-8 — Execute Pipeline

Run the 10-step workflow (see `workflow/WORKFLOW_STEPS.md`):

1. **OCR past papers** (parallel agents, 1 per paper)
2. **Build frequency table** (single agent reading all OCR'd text)
3. **Extract lecturer's RED items** (single agent reading review PDF)
4. **Cross-reference** (audit RED vs frequency)
5. **Generate topic packs** (parallel: 1 agent per topic, ~5-15 topics)
6. **Generate past-paper answer keys** (parallel: 1 agent per paper)
7. **Build INDEX + master plan** (synthesizer agent)
8. **Coverage audit** (verify all RED items are covered)
9. **Convert all to PDF** via pandoc + xelatex
10. **Tell user to AirDrop to iPad**
```

**After:**
```
### Turn 4-8 — Execute Pipeline

Run the canonical 10-step workflow defined in `workflow/WORKFLOW_STEPS.md`:

1. Inventory raw materials
2. OCR all PDFs to markdown
3. Per-paper Q&A breakdown + topic tagging
4. Build empirical frequency table + tier ranking
5. Extract lecturer's RED items + cross-reference vs frequency
6. Build verbatim-repeats pack (Pack 01)
7. Build per-topic drill packs
8. Build PYP full-answer packs
9. Coverage audit (the killer feature — never skip)
10. Index + master plan + cheatsheet, render to PDF, AirDrop to iPad

Steps 2, 7, 8 fan out via parallel agents (one per paper / per topic).
See `workflow/WORKFLOW_STEPS.md` for inputs/outputs/templates per step.
```

### 3.3 — Update file-structure example (lines 130-148) to match §2

Current SKILL.md tree is mostly right (`ipad_topic_packs/` + `_process/analysis/`)
but is missing `raw/`, `MASTER_PLAN.pdf`, `cheatsheet.pdf`, `01-paper-by-paper.md`,
`text/`, and uses `ocr_{YEAR}.txt` instead of the markdown-based OCR convention used
by `pdf-to-md`. Replace the entire tree with the §2 tree.

**Before (lines 130-148):** the existing block.
**After:** the tree from §2 above (verbatim).

### 3.4 — No other changes

`Hard rules`, `Output rules`, `Adaptive logic`, `Edge cases`, `Success criteria`,
`Reference implementation`, `When NOT to use this skill` are all consistent with the
canonical workflow and need no changes.

---

## §4 — Diff to apply to `workflow/WORKFLOW_STEPS.md`

The workflow ordering in WORKFLOW_STEPS.md is correct and is the canonical operational
sequence. The only fixes are path names + adding the missing render+deliver substeps
to Step 10.

### 4.1 — Rename `topic_packs/` → `ipad_topic_packs/` everywhere

**Step 6 (line 106):**
- Before: `**Output:** `/packs/01_VERBATIM_REPEATS_MEMORIZE.md``
- After: `**Output:** `ipad_topic_packs/_source_md/01_VERBATIM_REPEATS_MEMORIZE.md``

**Step 7 (line 122):**
- Before: `**Output:** `/packs/02_*.md` through `/packs/N_*.md``
- After: `**Output:** `ipad_topic_packs/_source_md/02_{TOPIC}_DRILL.md` through `ipad_topic_packs/_source_md/N_{TOPIC}_DRILL.md``

**Step 8 (line 141):**
- Before: `**Output:** `/packs/pyp_answers/PYP_AYxxxx_FULL_ANSWERS.md` per past year`
- After: `**Output:** `ipad_topic_packs/_source_md/PYP_AYxxxx_FULL_ANSWERS.md` per past year`

**Step 10 (lines 175-178):**
- Before:
  ```
  - `/packs/00_INDEX_AND_STUDY_ORDER.md` (use TEMPLATE_index.md) — top-level TOC
  - `/MASTER_PLAN.md` (use TEMPLATE_master_plan.md) — hour-by-hour cramming schedule
  - `/cheatsheet.md` (use TEMPLATE_handwritten_cheatsheet.md) — 1-page final memo
  ```
- After:
  ```
  - `ipad_topic_packs/_source_md/00_INDEX_AND_STUDY_ORDER.md` (use TEMPLATE_index.md) — top-level TOC
  - `ipad_topic_packs/_source_md/MASTER_PLAN.md` (use TEMPLATE_master_plan.md) — hour-by-hour cramming schedule
  - `ipad_topic_packs/_source_md/cheatsheet.md` (use TEMPLATE_handwritten_cheatsheet.md) — 1-page final memo

  Then render every `.md` under `_source_md/` to a sibling `.pdf` in `ipad_topic_packs/`
  via `pandoc + xelatex`. Tell the student to AirDrop the entire `ipad_topic_packs/`
  folder to their iPad.
  ```

### 4.2 — Fix process paths

**Step 2 outputs (lines 33-36):**
- Before:
  ```
  - `/process/text/syllabus.md`
  - `/process/text/lectures/*.md`
  - `/process/text/papers/PYP_AYxxxx.md`
  ```
- After:
  ```
  - `_process/text/syllabus.md`
  - `_process/text/lectures/*.md`
  - `_process/papers/PYP_AYxxxx.md`
  ```

**Step 3 (lines 48, 50):**
- Before: `**Input:** `/process/text/papers/PYP_AYxxxx.md` for each year.`
- After: `**Input:** `_process/papers/PYP_AYxxxx.md` for each year.`
- Before: `**Output:** `/process/analysis/01-paper-by-paper.md``
- After: `**Output:** `_process/analysis/01-paper-by-paper.md``

**Step 4 (lines 66, 68):**
- Before: `**Input:** `/process/analysis/01-paper-by-paper.md``
- After: `**Input:** `_process/analysis/01-paper-by-paper.md``
- Before: `**Output:** `/process/analysis/06-past-paper-analysis.md` (use TEMPLATE_past_paper_analysis.md)`
- After: `**Output:** `_process/analysis/frequency_analysis.md` (use TEMPLATE_past_paper_analysis.md)`

  *(Rename: `06-past-paper-analysis.md` → `frequency_analysis.md` for consistency
  with the SKILL.md tree and the actual semantic content.)*

**Step 9 (line 159):**
- Before: `**Output:** `/process/coverage_audit.md` (use TEMPLATE_coverage_audit.md)`
- After: `**Output:** `_process/analysis/coverage_audit.md` (use TEMPLATE_coverage_audit.md)`

### 4.3 — Insert new Step 5 entry: "Extract lecturer's RED items"

The current WORKFLOW_STEPS.md jumps from frequency table (Step 4) to "reused numerical
templates" (Step 5) — but it never explicitly extracts the lecturer's RED items, which
is one of the core inputs to the coverage audit and is called out as a separate step
in SKILL.md's Turn 4-8 and §1 above.

**Action:** rename current Step 5 to fold the "reused templates" detection into the
RED-items extraction step (they share the lecturer review PDF as input).

**Before (lines 86-99) — current Step 5:**
```
## STEP 5 — Identify reused numerical templates

**Input:** Section 3 of past-paper analysis.

**Output:** annotated list of "examiner reuse patterns" within the analysis.

The key insight: examiners reuse problem TEMPLATES (only changing numbers),
not just topics. SC4003's coffee-robot decision network appeared verbatim in
AY1819 + AY2324 with only the drop-probability changed. These reused templates
become the highest-yield individual drills.

**Action:** for each topic, look at its verbatim wording across years. If 2+
years use near-identical phrasing, flag it.
```

**After:**
```
## STEP 5 — Extract lecturer's RED items + flag reused templates

**Inputs:**
- `_process/text/lecturer_review.md` (lecturer's review/revision deck)
- `_process/analysis/frequency_analysis.md` (Section 3, verbatim wording)

**Output:** `_process/analysis/red_items_audit.md`

Two passes:

1. **RED-items extraction.** From the lecturer review PDF, extract every
   highlighted / red-flagged / "make sure you know" item into a flat list with
   the lecturer's verbatim phrasing. Cross-reference each against the frequency
   table — surface discrepancies (lecturer emphasized but ≠ historically tested,
   or historically tested but lecturer skipped).

2. **Reused-template flagging.** Examiners reuse problem TEMPLATES (only changing
   numbers), not just topics. SC4003's coffee-robot decision network appeared
   verbatim in AY1819 + AY2324 with only the drop-probability changed. For each
   topic, compare verbatim wording across years. If 2+ years use near-identical
   phrasing, flag it inline in `red_items_audit.md`. These flagged items feed
   directly into Step 6.

If no lecturer review PDF was provided, do pass 2 only and use frequency-only
heuristics in Step 9 (coverage audit becomes self-referential).
```

### 4.4 — Update final structure tree (lines 187-208)

**Before:** flat-with-typos tree.
**After:** the §2 tree (verbatim).

### 4.5 — Update validation checklist (line 217)

- Before: `- [ ] Verbatim-repeats pack has ≥8 items, all from ≥2-year repeats`

  This bullet is correct but the file path it references is now
  `ipad_topic_packs/_source_md/01_VERBATIM_REPEATS_MEMORIZE.md` (no change to bullet
  text, just be aware).

- Add new bullet:
  `- [ ] All `_source_md/*.md` files have rendered to sibling `*.pdf` in `ipad_topic_packs/`.`

### 4.6 — No changes to time-estimate table

The hours per step are still accurate after the merge.

---

## Acceptance test for this resolution

After applying §3 and §4:

1. `grep -rn "topic_packs/" /Users/haoyangpang/.claude/skills/exam-prep/` returns
   zero hits without the `ipad_` prefix.
2. `grep -rn "/process/" /Users/haoyangpang/.claude/skills/exam-prep/` returns zero
   hits — only `_process/` (with leading underscore) remains.
3. `coverage_audit.md` is referenced in exactly one location:
   `_process/analysis/coverage_audit.md`.
4. Both files describe the same 10 steps in the same order with the same names.
5. The SC4003 reference implementation at
   `/Users/haoyangpang/Desktop/NTU study/Y4S2/SC4003 Intelligent Agents/exam-prep/`
   matches the canonical tree (spot-check; if it predates the convention, document
   the drift but don't retroactively rename).
