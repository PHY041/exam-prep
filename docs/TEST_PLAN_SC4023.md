# F4 — Test Plan: SC4023 Big Data Management End-to-End Validation

**Purpose:** Validate exam-prep v0.2 (workflow D1 + algorithms B1-B4 + templates C2/C4) against
a real upcoming course where the user has actual stakes. SC4023 is the test fixture; success
is measured by whether the skill runs to completion AND produces material the student finds
exam-useful.

**Test type:** End-to-end integration test on production user input.
**Tester:** Haoyang (the user himself — he sits the exam).
**Baseline reference:** SC4003 (v0.1 first run, ~30 min, ~25 PDFs delivered).

---

## 1. Test Case Definition — SC4023 specifics

| Attribute | Value |
|---|---|
| Course code | SC4023 / CX4123 |
| Course name | Big Data Management |
| Lecturer | Asst Prof Luo Siqiang |
| Format | Flipped classroom — pre-recorded videos + Tue interactive lecture + Mon tutorial |
| Final exam weight | 50% (Quiz 20% + Project 25% + Tutorial 5% already weighted in) |
| Exam coverage | Full syllabus (Quiz only covered up to Column Stores) |
| Material location | `~/Library/Mobile Documents/com~apple~CloudDocs/Y4S2/SC4023 Big Data Management/` plus iCloud Downloads |
| Course memory file | `/Users/haoyangpang/clawd/memory/courses/SC4023-Big-Data-Management.md` |

**Topic spine (from lecture filenames + course memory):**
1. Big Data background + 5 V's (volume / velocity / variety / veracity / value)
2. Data models — Relational, Key-Value, Graph, Column-store
3. External sorting (Lecture 3.5)
4. Column-store internals — Part I + II
5. MapReduce / Hadoop (referenced in Quiz scope)
6. RocksDB / LSM trees (referenced in tutorial work)

**Why SC4023 is a good v0.2 test:**
- Real exam pressure → user will actually use outputs and report what's broken.
- Mix of theory (5 V's, models) and systems (RocksDB, MapReduce) → exercises both verbatim
  detection (B2) and emphasis extraction (B3).
- Materials partially missing (see §2) → forces v0.2 fallback adapters (D4) to fire.

---

## 2. Pre-test Inventory — what exists, what's missing

**Discovered via `mdfind` and direct directory listing.** Desktop is sandbox-restricted, so
results below come from iCloud Drive paths only.

### Confirmed present
| Path | File | Notes |
|---|---|---|
| `Y4S2/SC4023 Big Data Management/` | `Lecture0-Course Overview.pdf` | Syllabus proxy |
| `Y4S2/SC4023 Big Data Management/` | `Lecture1.1-BigData Background.pdf` | |
| `Y4S2/SC4023 Big Data Management/` | `Lecture1.2-BigData 5V's.pdf` | |
| `Y4S2/SC4023 Big Data Management/` | `Lecture2_Data-Models.pdf` | |
| `Y4S2/SC4023 Big Data Management/` | `Bigdata-Tutorial1-Questions.pdf` | Only Tut 1 here |
| `iCloud/Downloads/` | `Lecture3.5-External-Sorting.pdf` | Stored separately |
| `iCloud/Downloads/` | `Lecture 4-Column-Store-PartI.pdf` | |
| `iCloud/Downloads/` | `Lecture 4-Column-store_PartII.pdf` | |
| `clawd/memory/courses/` | `SC4023-Big-Data-Management.md` | Excellent emphasis source — Quiz scope, lecturer announcements, weekly schedule |

### MISSING — blocks Step 1 validation
| Required by D1 | Present? | Impact |
|---|---|---|
| Past exam papers (≥3, AY format) | **NO** — `mdfind` returned zero `SC4023` past-exam PDFs; only SC4021 and SC4003 have past papers | Critical — Step 3/4/5 cannot run as designed (no PYP frequency, no verbatim, no master ranking) |
| Lectures 5+ (post-Column-Store: MapReduce, Hadoop, RocksDB, LSM, Graph systems) | NOT FOUND in iCloud | Topic frequency table will under-cover Quiz-onwards material |
| Tutorials 2-10 | NOT FOUND in iCloud (only Tut1 question PDF present) | Loses a strong proxy for "what lecturer will test" |
| Lecturer review / cheatsheet | NOT FOUND | Step 5 (RED extraction) has limited input — fall back to course memory file |
| `syllabus.pdf` (canonical) | Use Lecture0-Course Overview.pdf as substitute | Acceptable substitute |

**Pre-test verdict:** The skill cannot execute its happy path on SC4023 today. It can execute
in **degraded mode** to test fallback adapters (D4), but the user must sync NTULearn first
to get past papers + remaining lectures + tutorials before a true v0.2 acceptance run.

### Required actions before test execution
1. Run `/ntulearn-sync` skill scoped to SC4023 — pulls remaining lectures + tutorials.
2. Manually source past papers (NTU library exam archive, seniors, study resources).
   If zero past papers exist for SC4023 (course is new), the skill must be tested in
   "no-PYP mode" — see §4 checkpoint 4 fallback path.
3. Lecturer review: extract from `SC4023-Big-Data-Management.md` (already has Quiz scope
   and announcement quotes — feed this into Step 5 as `lecturer_review.md`).

---

## 3. Pipeline execution steps — invoke `/exam-prep` on SC4023

Execute steps sequentially. Capture each step's output to `/tmp/exam_prep_v2/quality/runs/sc4023_<timestamp>/step_<N>.log`.
Time each step with `time`. Record actual wall time vs. D1 estimate.

### Run command
```bash
mkdir -p ~/exam-prep/SC4023/{raw,process,deliverables}
cd ~/exam-prep/SC4023
/exam-prep SC4023 --exam-date 2026-05-XX
```

### Step-by-step capture

| # | Step (per D1) | Capture | Expected output artifact | Time budget |
|---|---|---|---|---|
| 1 | Acquire raw materials | `raw/MANIFEST.md`, `step_1.log` | ≥3 PYPs, ~10 lectures, syllabus, lecturer_review | 30 min |
| 2 | OCR / PDF→MD | `process/text/_ocr_log.md` | One `.md` per PDF, "Q1" string in each PYP | 30-60 min |
| 3 | Per-paper Q&A breakdown | `process/qa/*.md` | One row per question per paper | ~45 min |
| 4 | Topic frequency table | `process/topics.md` + normalised matrix | Σ(occurrences) ≥ N total questions | 20 min |
| 5 | Verbatim detection (B2) | `process/verbatim.md` | Cross-paper repeated wording flagged | 20 min |
| 6 | Emphasis extraction (B3) | `process/emphasis.md` | RED/HIGH-PRIORITY items from lecturer_review | 15 min |
| 7 | Coverage audit (B4) | `process/audit.md` | Surfaces topics with low confidence / sparse PYP | 10 min |
| 8 | Master ranking + plan | `deliverables/master_index.pdf`, `cramming_plan.pdf` | Tier-1/2/3 ranked, T-Hh schedule populated | 20 min |
| 9 | Drill PDFs | `deliverables/drills/*.pdf` | One per Tier-1/Tier-2 topic | 30-60 min |
| 10 | Final review pack | `deliverables/cheatsheet.pdf`, `last_24h.pdf` | Single-page-per-topic recap | 15 min |

**Total budget:** 4-6 hours wall (excluding user reading time). v0.2 target: < 35 min for
core pipeline (Steps 1-8) when materials are pre-synced.

---

## 4. Validation checkpoints

Each checkpoint is a **gate**. If it fails, log the failure to the bug template (§7) and
either retry with adapter (D4) or block the next step.

### CP1 — Step 1 inventory completeness
**Question:** Did the skill find all expected materials?

**Pass criteria:**
- `MANIFEST.md` lists ≥ 3 PYP PDFs (or explicitly logs "PYP_NOT_AVAILABLE" with adapter
  fallback engaged).
- ≥ 8 lecture PDFs (the visible spine: Lectures 0, 1.1, 1.2, 2, 3.5, 4-I, 4-II + at least
  one of MapReduce / RocksDB).
- Course memory file (`SC4023-Big-Data-Management.md`) recognised and copied as
  `lecturer_review.md`.

**Fail criteria:**
- < 3 PYPs AND no fallback path engaged → skill must abort with helpful message.
- Lecture count < 6 → warn but continue (degraded coverage).

### CP2 — Step 2 OCR accuracy
**Question:** Did past papers OCR cleanly (>90% accurate)?

**Pass criteria:**
- Spot-check: open 3 random questions from each PYP `.md`, compare to source PDF.
  ≥ 90% of words match exactly. Numbers must be 100% accurate (digit OCR errors are
  silent killers).
- "Question N" or "Qn" or "n." appears at line-start in each PYP `.md`.
- `_ocr_log.md` shows `pymupdf4llm` engine for ≥ 80% of files; `marker-pdf` fallback
  acceptable; `tesseract` only as last resort.

**Fail criteria:**
- > 10% word error rate on sampled questions → re-OCR with `marker-pdf --quality`.
- Any digit or formula corrupted in numerical question → manual fix + log.

### CP3 — Step 4 frequency table sanity (per B1)
**Question:** Did topic table pass the sanity inequality?

**Pass criteria:**
- For every paper P: Σ(topic_occurrences in P) ≥ N_total_questions(P) — every question
  must touch at least one topic.
- Normalised topic labels (B1) — no duplicate rows like "Column Store" + "Column-Store" +
  "ColumnStore". Use B1's canonical form.
- Top-3 frequency topics align with course memory file's emphasis (Column-Store,
  MapReduce, External Sorting based on the Quiz scope hint).

**Fail criteria:**
- Σ < N → labelling missed questions, re-run B1 normalisation pass.
- Top-3 doesn't include any Column-Store variant → verbatim detector miscalibrated.

### CP4 — Step 5 verbatim detection (B2): false positive / false negative audit
**Question:** Are flagged verbatim matches real?

**Pass criteria — false positive ceiling:**
- Manually inspect every flagged "verbatim" pair. ≤ 1 in 10 should be a stopword/template
  collision (e.g. "explain how" or "with reference to" matching trivially).
- Real matches must share ≥ 4 contiguous content words OR a unique numeric/named entity.

**Pass criteria — false negative ceiling:**
- Take 5 known repeated themes (from course memory: 5 V's, External Sorting, MapReduce
  word-count). At least 4 of them should appear in `verbatim.md` if the theme actually
  recurs across PYPs.

**Fail criteria:**
- > 30% false positive rate → tighten B2 minimum match length.
- > 1 of the 5 known themes missed → loosen B2 / add semantic similarity layer.

### CP5 — Step 6 emphasis extraction (B3): RED extraction works
**Question:** Did RED / HIGH-PRIORITY markers in the lecturer review get pulled out?

**Pass criteria:**
- The course memory file contains explicit emphasis cues: "Quiz scope: from beginning to
  Column Stores (inclusive)", "5Vs and data models", lecturer announcement quotes.
  These should appear in `emphasis.md` as RED-tier items.
- Each emphasis item has source attribution (file + line range or paragraph reference).

**Fail criteria:**
- B3 misses the explicit "Quiz scope" sentence → regex/cue list incomplete.
- No source attribution → makes the item unverifiable, blocks user trust.

### CP6 — Step 7 coverage audit (B4): does it surface gaps?
**Question:** Did the audit flag the missing materials we already know about?

**Pass criteria:**
- Audit flags low PYP coverage if < 3 PYPs were available.
- Audit flags topics that appear in lectures but NOT in any PYP question (these are
  "lecture-only" risks — must drill).
- Audit flags topics in PYP but NOT in lectures (suggests missing lecture material —
  triggers manual sourcing).
- Confidence column populated per B4 sparsity rules (low N → low confidence).

**Fail criteria:**
- Audit silently passes despite < 3 PYPs.
- No "lecture-only" or "PYP-only" cross-reference produced.

### CP7 — Step 8-10 PDF rendering
**Question:** Are all PDFs valid and readable?

**Pass criteria:**
- Every PDF in `deliverables/` opens with `pdfinfo` exit-code 0.
- Every PDF in `deliverables/` opens visually in Preview.app — no blank pages, no
  truncated tables, no LaTeX render failures.
- File count: 25-30 PDFs (master index + cramming plan + cheatsheet + last_24h + per-topic
  drills).
- Page count per drill: 2-6 pages (single topic, drillable in 20-40 min).
- Cheatsheet: ≤ 4 pages total.

**Fail criteria:**
- Any PDF fails `pdfinfo` → re-render with backup template.
- Drill PDF > 10 pages → split (violates drill format).
- Cheatsheet > 4 pages → over-broad; needs distillation pass.

---

## 5. Pass/fail criteria summary

| Checkpoint | PASS bar | FAIL behaviour |
|---|---|---|
| CP1 inventory | ≥3 PYPs OR explicit fallback log; ≥8 lectures | Abort skill or warn-and-continue |
| CP2 OCR | ≥90% word accuracy; 100% digit accuracy | Re-OCR with marker-pdf |
| CP3 frequency | Σ ≥ N per paper; normalised labels | Re-run B1 |
| CP4 verbatim | ≤10% FP; ≤1/5 known themes missed | Tune B2 thresholds |
| CP5 emphasis | RED items pulled with source attribution | Expand B3 cue list |
| CP6 audit | Gaps surfaced (low PYP, lecture-only, PYP-only) | Re-implement B4 cross-ref |
| CP7 PDFs | All open; 25-30 files; correct page budgets | Re-render fail cases |

**Overall PASS condition:** All 7 checkpoints PASS, AND user reports "I'd actually study from
this" within 24 hours of delivery (subjective gate, but the only one that matters).

**Overall FAIL condition:** Any 2+ checkpoints fail OR user reports outputs are unusable
(too generic, wrong topics ranked top, hallucinated content).

---

## 6. Comparison metrics — SC4023 vs. SC4003 baseline

| Metric | SC4003 baseline (v0.1) | SC4023 target (v0.2) | Notes |
|---|---|---|---|
| Time to complete (Steps 1-8) | ~30 min | **< 35 min** (regression budget: +5 min for B1-B4 added rigor) | Wall clock from `/exam-prep` invocation to master plan PDF rendered |
| Total deliverable PDFs | ~25 | **25-30** | Drill count scales with Tier-1 topic count |
| PYP count consumed | 5+ (well-stocked archive) | 0-3 (likely) | If 0, must run in fallback mode — different success bar |
| Lecture count consumed | ~12 | 8-10 (after NTULearn sync) | |
| Verbatim hits flagged | 8-12 cross-paper | N/A if <2 PYPs; else 5-10 | Scales with PYP count |
| Emphasis RED items | 5-8 (from review sheet) | 5-8 (from course memory file proxy) | course memory is rich enough |
| Audit gaps surfaced | 2-3 | 4-6 expected | Reflects sparser inputs |
| User satisfaction | Anchor: "actually used it for SC4003 prep" | Same gate — does the user reach for it on exam day? | Single hardest metric |

**Time regression test:** if v0.2 takes > 50% longer than v0.1 baseline, investigate which
new step (B1-B4) is the bottleneck. Expected: B2 verbatim is most expensive; should still
fit in < 10 min for ~3 PYPs.

---

## 7. Bug capture template

Use one entry per defect found. Append to `/tmp/exam_prep_v2/quality/runs/sc4023_<timestamp>/bugs.md`.

```markdown
### BUG-<NNN>: <one-line summary>

**Date:** YYYY-MM-DD HH:MM
**Step:** <D1 step number, e.g. Step 4 — Topic frequency table>
**Checkpoint failed:** <CP1-CP7>
**Severity:** P0 (blocks completion) | P1 (degrades output) | P2 (cosmetic) | P3 (nice-to-have)

**Expected:**
<What the contract / D1 / B*.md says should happen>

**Actual:**
<What actually happened — stdout/stderr excerpt, file content, missing artifact>

**Repro:**
1. <minimal steps>
2. ...

**Input that triggered it:**
- File: <path>
- Snippet: <relevant 5-line excerpt or input args>

**Hypothesis (root cause guess):**
<Which algorithm / template / adapter is the suspect>

**Workaround:**
<What the user can do right now to keep going — empty if blocking>

**Fix proposal:**
<Concrete change to D1 / B* / C* / D4. Include filename and rough diff.>

**Status:** OPEN | IN-PROGRESS | FIXED-PENDING-VERIFY | CLOSED
```

### Pre-seeded suspect bugs (predict before run)

These are issues I expect based on inventory analysis. Logging them in advance lets us
verify whether the skill handles them gracefully or surprises us.

1. **BUG-001 (predicted, P0):** SC4023 has zero past papers in iCloud. Skill should detect
   this in CP1 and either prompt user to source PYPs or run no-PYP fallback. If it silently
   produces a "topic frequency" table from N=0 PYPs, that's a critical failure.

2. **BUG-002 (predicted, P1):** Lectures split across two iCloud locations
   (`Y4S2/SC4023.../` and `iCloud/Downloads/`). Step 1 must walk both, otherwise
   External-Sorting + Column-Store lectures are missed and topic table under-counts.

3. **BUG-003 (predicted, P2):** Course memory file `SC4023-Big-Data-Management.md` is in
   `clawd/memory/courses/`, not in `/raw/`. The skill needs to know to look there as a
   `lecturer_review` substitute. If it doesn't, RED emphasis extraction (CP5) starves.

4. **BUG-004 (predicted, P1):** Tutorial PDFs from a different course family
   (`Tutorial 1-Question.pdf` etc. in `iCloud/Downloads/`) may get falsely picked up as
   SC4023 tutorials. Path-based scoping must filter by parent folder name, not just
   filename pattern.

---

## Appendix A — Readiness verdict for SC4023

**Can the skill run today on SC4023? — Partial.**

The user has roughly **60% of the inputs needed** for a clean v0.2 acceptance run:
- Lectures 0, 1.1, 1.2, 2, 3.5, 4-I, 4-II → present (7 of likely 10-12).
- Tutorial 1 questions → present.
- Course memory file with rich lecturer emphasis → present.
- Past exam papers → **0 found**.
- Tutorials 2-10 → **0 found**.
- Post-Column-Store lectures (MapReduce, Hadoop, RocksDB, LSM) → **0 found** despite being
  in scope.

**Recommended path before v0.2 acceptance run:**
1. Run `/ntulearn-sync` for SC4023 to pull missing lectures + tutorials. **Blocking.**
2. Source past papers — three options:
   - NTU exam archive (library) — primary.
   - Senior students / shared drives — secondary.
   - If the course is genuinely new (CX4123 was historically separate), accept that
     v0.2 SC4023 test runs in "no-PYP fallback mode" and explicitly document this as
     a fallback-adapter (D4) test rather than a happy-path test.
3. Symlink or copy `clawd/memory/courses/SC4023-Big-Data-Management.md` into the run
   workspace as `raw/lecturer_review.md` so Step 5 has rich input.

**If the user runs the test today as-is:**
- It will exercise the fallback adapters, which is good.
- It will NOT validate the verbatim cross-paper logic (B2) since there's nothing to
  cross-reference.
- Topic frequency (CP3) and verbatim (CP4) checkpoints will be skipped or marked N/A.
- The other 5 checkpoints (CP1, CP2, CP5, CP6, CP7) remain meaningful.

So: **a partial test is possible immediately and useful for the fallback path; a full v0.2
acceptance test needs ~30 min of `/ntulearn-sync` + PYP sourcing first.**
