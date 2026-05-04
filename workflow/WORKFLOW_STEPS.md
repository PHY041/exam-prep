# Exam-Prep Workflow v2 — 10 Steps with Explicit Contracts

Each step is a self-contained unit with input contract, output contract,
required tools, fallback behavior, validation gates, and time estimate.
Steps run sequentially; outputs of step N feed step N+1.

**Total elapsed time:** 15-20 hours (one-time setup), spread across 3-5 days.
**Course size assumption:** 1 semester, 3-5 past papers, ~10 lecture topics.

---

## STEP 1 — Acquire raw materials

**Input contract:**
- Course code (e.g. `SC4003`) — provided by user.
- Access to NTULearn / Blackboard (or equivalent LMS) for the course.
- Empty workspace directory (will become the project root).

**Output contract:**
- `/raw/syllabus.pdf` — single PDF, opens without errors.
- `/raw/lectures/<NN>_<topic>.pdf` — one PDF per lecture, prefixed with index.
- `/raw/papers/PYP_AY<earliest>.pdf` … `PYP_AY<latest>.pdf` — one per past year, ≥3.
- `/raw/lecturer_review.pdf` — optional but recommended (high-signal).
- `/raw/MANIFEST.md` — table listing every file, size in KB, page count.

**Tools required:**
- `curl` or browser download.
- `ntulearn-sync` skill (preferred — does discovery + diff + download).
- `pdfinfo` or `mdls -name kMDItemNumberOfPages` for page count.

**Fallback if tool missing:**
- Without `ntulearn-sync`: manual download via Chrome AppleScript control,
  files placed by hand into `/raw/` subfolders.
- Without `pdfinfo`: skip page count column in MANIFEST, keep file size only.

**Validation:**
1. Every PDF in `/raw/` opens (`pdfinfo $f >/dev/null 2>&1` returns 0).
2. `ls /raw/papers/*.pdf | wc -l` ≥ 3, otherwise abort with "insufficient PYPs".

**Time estimate:** 30 min.

---

## STEP 2 — OCR / convert PDFs to markdown

**Input contract:**
- All PDFs from Step 1 present and readable.
- `/raw/MANIFEST.md` exists.

**Output contract:**
- `/process/text/syllabus.md`
- `/process/text/lectures/<NN>_<topic>.md` (one per source PDF, same basename).
- `/process/text/papers/PYP_AY<year>.md`
- `/process/text/lecturer_review.md` (if source existed).
- `/process/text/_ocr_log.md` — per-file engine used + warnings count.

**Schema for each `.md`:** plain text, headings preserved, math in LaTeX where
detected, tables in GFM. No images required (figures may be placeholders).

**Tools required:**
- `pdf-to-md` skill (default: `pymupdf4llm`).
- `marker-pdf` for scanned papers (auto-fallback).
- `tesseract` only if both above fail.

**Fallback if tool missing:**
- No `pymupdf4llm` → use `marker-pdf` for everything (slower).
- No `marker-pdf` → use `pdftotext` (loses layout, acceptable for question text).
- No OCR at all → manual transcription of question stems only (block exam-day items).

**Validation:**
1. Every PDF in `/raw/` has a corresponding `.md` (basename match).
2. Every PYP `.md` contains the strings "Question 1" or "Q1" or "1." at start of line
   — sanity check that question structure was preserved.
3. Hand-spot 1 numerical value per paper against the source PDF (catch OCR digit errors).

**Time estimate:** 30-60 min.

---

## STEP 3 — Per-paper Q&A breakdown

**Input contract:**
- `/process/text/papers/PYP_AY*.md` (all years, OCR'd).
- Controlled-vocabulary topic list (drafted from `/process/text/syllabus.md` +
  lecture filenames; can be expanded as you go but must be a finite set).

**Output contract:**
- `/process/analysis/01-paper-by-paper.md`
- `/process/analysis/_topic_vocab.md` — the controlled vocabulary, one topic per line.

**Schema for `01-paper-by-paper.md`:**
```
## PYP_AY<year>

| Q | Marks | Topic (from vocab) | Type | Verbatim stem |
|---|-------|--------------------|------|---------------|
| 1a | 5 | Game theory matrix | compute-NE | "Find all pure-strategy …" |
```

**Tools required:** None beyond a text editor / agent. Pure analytical step.

**Fallback if tool missing:** N/A.

**Validation:**
1. Every sub-part of every paper has exactly one row (count rows vs. paper TOC).
2. Every topic label appears in `_topic_vocab.md` (no free-form strings).
3. Marks per paper sum to the official total for that year (e.g. 100).

**Time estimate:** 2-3 h.

---

## STEP 4 — Build empirical frequency table

**Input contract:**
- `/process/analysis/01-paper-by-paper.md`
- `/process/analysis/_topic_vocab.md`

**Output contract:**
- `/process/analysis/06-past-paper-analysis.md` (use `TEMPLATE_past_paper_analysis.md`).

**Schema (key sections):**
- Section 1: Frequency table — columns `topic | hits | total_marks | avg_marks_per_yr | tier`.
- Section 2: Tier classification (CERTAIN / HIGH / WATCH / IGNORE, thresholds documented).
- Section 3: Verbatim-reuse callouts (feeds Step 5).
- Section 4: SKIP list (Tier 4, 0/N hits).
- Section 5: Drill set proposal.
- Section 6-9: Study schedule, risk notes, time budget, references.

**Tools required:** None (analytical). A spreadsheet helps but is not required.

**Fallback if tool missing:** N/A.

**Validation:**
1. Hits column sums match Step 3 row counts (no double-counting).
2. Every topic in `_topic_vocab.md` appears in the table (even if 0 hits).
3. Word count ≥ 2000 (otherwise the doc is too thin).
4. Tier 4 SKIP list is non-empty (if everything is "important", tiering failed).

**Time estimate:** 2 h.

---

## STEP 5 — Identify reused numerical templates

**Input contract:**
- `/process/analysis/06-past-paper-analysis.md` (Section 3 callouts).
- `/process/analysis/01-paper-by-paper.md` (verbatim stems).

**Output contract:**
- Annotated additions inside Section 3 of `06-past-paper-analysis.md`,
  flagging "TEMPLATE_REPEAT" markers with year-pairs.
- `/process/analysis/_template_repeats.md` — flat list, one repeat-cluster per row.

**Schema for `_template_repeats.md`:**
```
| cluster_id | topic | years | what_changed | confidence |
| TR-01 | Decision network coffee-robot | AY1819, AY2324 | drop_prob | high |
```

**Tools required:** `diff` or `git diff --no-index` for side-by-side stem comparison.

**Fallback if tool missing:** Manual visual comparison (slower but tractable for ≤5 papers).

**Validation:**
1. Every TR-XX cluster references ≥2 years.
2. Every cluster's topic exists in `_topic_vocab.md`.
3. At least one TR cluster exists (if zero, examiner reuse is genuinely absent OR
   the analyst missed it — re-check before proceeding).

**Time estimate:** 30 min.

---

## STEP 6 — Build verbatim-repeats pack (Pack 01)

**Input contract:**
- `/process/analysis/_template_repeats.md` (high-confidence clusters only).
- `/process/text/papers/*.md` (for verbatim copy).

**Output contract:**
- `/packs/01_VERBATIM_REPEATS_MEMORIZE.md` (use `TEMPLATE_verbatim_repeats.md`).

**Schema (per item):**
```
### Item N — <short title>
- Years: AYxxxx, AYyyyy
- Verbatim stem: <quoted from source>
- Model answer: <≤300 words, full algebra>
- Memorize-by: <date, T-3 days minimum>
```

**Tools required:** None.

**Fallback if tool missing:** N/A.

**Validation:**
1. Item count ≥ 8 and ≤ 12.
2. Every item references ≥2 years (drawn from a TR cluster).
3. Every model answer is ≤ 300 words (`wc -w` on the answer block).
4. Total expected return is ≥ 30 marks (sum of marks across cited years / N years).

**Time estimate:** 1-2 h.

---

## STEP 7 — Build per-topic drill packs

**Input contract:**
- Tier 1 + Tier 2 topics from `06-past-paper-analysis.md` Section 2.
- `/process/text/papers/*.md` (for past-paper drill instances).
- `/process/text/lectures/*.md` (for method recipes).

**Output contract:**
- `/packs/02_<topic>_DRILL.md` … `/packs/N_<topic>.md` (one pack per Tier-1/2 topic).
  Naming: zero-padded index, snake_case topic.

**Schema (per pack — use `TEMPLATE_topic_pack.md`):**
1. Why it matters (hit rate + marks/yr).
2. Method recipe (numbered steps).
3. 3-5 fully worked drills (one per past-paper instance).
4. Common pitfalls.
5. Speed-drill template.
6. Recall card.

**Tools required:** None.

**Fallback if tool missing:** N/A.

**Validation:**
1. One pack file exists per Tier-1 + Tier-2 topic (cross-check against `_topic_vocab.md`).
2. Each pack: 200 ≤ line count ≤ 400.
3. Each pack has ≥ 3 worked drills (`grep -c '^### Drill' $pack`).
4. Each pack ends with a "Recall card" section.

**Time estimate:** 4-6 h.

---

## STEP 8 — Build PYP full-answer packs

**Input contract:**
- `/process/analysis/01-paper-by-paper.md` (for Q-by-Q index).
- `/process/text/papers/*.md` (verbatim source).
- `/packs/02_*` … topic packs (for cross-references).

**Output contract:**
- `/packs/pyp_answers/PYP_AY<year>_FULL_ANSWERS.md` — one file per past year.

**Schema (per sub-part — use `TEMPLATE_pyp_answers.md`):**
- Verbatim question (copied from source).
- Model answer (full algebra).
- Marking hints (point breakdown).
- Time target (minutes).
- Cross-reference: `→ /packs/<topic>_DRILL.md#section`.

**Tools required:** None.

**Fallback if tool missing:** N/A.

**Validation:**
1. One `PYP_AY<year>_FULL_ANSWERS.md` per file in `/raw/papers/`.
2. Sub-part count per file equals Step 3 row count for that year.
3. Time targets per paper sum to ≤ official exam duration (e.g. 120 min).
4. Every sub-part has a cross-reference to either a topic pack or Pack 01.

**Time estimate:** 3-4 h.

---

## STEP 9 — Coverage audit

**Input contract:**
- `/process/text/lecturer_review.md` (RED-flagged items extracted).
- `/packs/*.md` — all topic packs and Pack 01.

**Output contract:**
- `/process/analysis/coverage_audit.md` (use `TEMPLATE_coverage_audit.md`).
- `/packs/99_CLOSURE_CHEAT_CARDS.md` — 1-3 cheat cards covering all `✗` items.

**Schema for `coverage_audit.md`:**
```
| RED item | Pack | Status | Action |
| <topic> | 02_X | ✓ | none |
| <topic> | —    | ✗ | add cheat card C-01 |
```
Status legend: `✓` definition + worked example, `⚠` partial, `✗` absent.

**Tools required:** `grep` for spotting topic mentions across packs.

**Fallback if tool missing:** Manual ToC scan of each pack (slower).

**Validation:**
1. Every RED-flagged item from the lecturer's deck appears as a row.
2. No row has empty Status.
3. Total closure-card reading time ≤ 10 min (`wc -w / 250` rule of thumb).

**Time estimate:** 1 h.

---

## STEP 10 — Master plan + index + cheatsheet

**Input contract:**
- All prior `/packs/*.md` files exist.
- `/process/analysis/coverage_audit.md` complete.
- Exam date known (passed by user).

**Output contract:**
- `/packs/00_INDEX_AND_STUDY_ORDER.md` (use `TEMPLATE_index.md`).
- `/MASTER_PLAN.md` (use `TEMPLATE_master_plan.md`) — hour-by-hour cramming schedule
  anchored to exam date.
- `/cheatsheet.md` (use `TEMPLATE_handwritten_cheatsheet.md`) — 1-page final memo,
  hand-copyable in <30 min.

**Schema for `MASTER_PLAN.md`:** Markdown table with columns
`date | time_block | activity | pack_ref | self_check`.

**Tools required:** `date` for relative-date math (T-N days from exam).

**Fallback if tool missing:** Hard-code calendar dates manually.

**Validation:**
1. `00_INDEX_AND_STUDY_ORDER.md` references every file under `/packs/`.
2. `MASTER_PLAN.md` is hour-by-hour (no row spans > 2 h without a self-check).
3. `MASTER_PLAN.md` schedules Pack 01 (verbatim repeats) FIRST, not last.
4. `cheatsheet.md` fits on one A4 page (`wc -l` ≤ ~80, depending on density).
5. Final pass: every item in `coverage_audit.md` with `✗` is referenced in
   `MASTER_PLAN.md` on a T-2 or T-1 study block.

**Time estimate:** 1 h.

---

# Final output structure

```
exam-prep/
├── raw/
│   ├── MANIFEST.md
│   ├── syllabus.pdf
│   ├── lectures/
│   ├── papers/
│   └── lecturer_review.pdf
├── process/
│   ├── text/                                  # Step 2 outputs
│   │   ├── syllabus.md
│   │   ├── lectures/
│   │   ├── papers/
│   │   ├── lecturer_review.md
│   │   └── _ocr_log.md
│   └── analysis/
│       ├── _topic_vocab.md
│       ├── _template_repeats.md
│       ├── 01-paper-by-paper.md
│       ├── 06-past-paper-analysis.md          ★ THE GOLD STANDARD
│       └── coverage_audit.md
├── packs/
│   ├── 00_INDEX_AND_STUDY_ORDER.md
│   ├── 01_VERBATIM_REPEATS_MEMORIZE.md
│   ├── 02_<topic>_DRILL.md
│   ├── …
│   ├── 99_CLOSURE_CHEAT_CARDS.md
│   └── pyp_answers/
│       ├── PYP_AY<earliest>_FULL_ANSWERS.md
│       └── PYP_AY<latest>_FULL_ANSWERS.md
├── MASTER_PLAN.md
└── cheatsheet.md
```

---

# Global validation checklist (run before exam)

- [ ] Step 3: every sub-part of every paper tabulated.
- [ ] Step 4: frequency table has explicit hit counts (not vibes).
- [ ] Step 4: Tier 4 SKIP list is non-empty.
- [ ] Step 6: Pack 01 has ≥8 items, all from ≥2-year repeats.
- [ ] Step 7: each topic pack has ≥3 worked drills, 200-400 lines.
- [ ] Step 8: every past paper has a full-answers file with cross-refs.
- [ ] Step 9: coverage audit reports specific ✗ items + ≤10-min closure cards.
- [ ] Step 10: MASTER_PLAN is hour-by-hour and schedules Pack 01 first.
- [ ] Step 10: INDEX references every file under `/packs/`.

---

# Time estimate summary

| Step | Time | Validations |
|------|------|-------------|
| 1 | 30 min | 2 |
| 2 | 30-60 min | 3 |
| 3 | 2-3 h | 3 |
| 4 | 2 h | 4 |
| 5 | 30 min | 3 |
| 6 | 1-2 h | 4 |
| 7 | 4-6 h | 4 |
| 8 | 3-4 h | 4 |
| 9 | 1 h | 3 |
| 10 | 1 h | 5 |
| **Total** | **15-20 h** | **35** |

Step 10 has the most validations (5) — it is the final integrity gate before
the student starts studying, so the bar is highest there.
