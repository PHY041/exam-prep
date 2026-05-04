# F1 — Edge Case + Failure Mode Audit (exam-prep skill)

Audit target: `/Users/haoyangpang/.claude/skills/exam-prep/SKILL.md` (v1, 235 lines, ref impl SC4003)

Purpose: enumerate every edge case + failure mode the skill must handle, and specify
the exact behavior. Intended consumers: skill author, reviewer, V2 implementer.

Conventions:
- **Severity**: P0 (blocker, common) / P1 (likely, painful) / P2 (rare, recoverable)
- **Detection**: how the skill notices the case (which Turn / which step)
- **Behavior**: literal handling logic the agent must follow
- **Failure mode if unhandled**: what breaks if the skill doesn't catch it

---

## 1. Material edge cases

### 1.1 Zero past papers — P0

- **Trigger**: Glob in Turn 2 returns no PDFs in past-paper directory, or user
  says "我没有 past papers".
- **Detection**: `_process/papers/` empty after Turn 2 inventory.
- **Behavior**:
  1. Set `frequency_analysis = SKIPPED (no past papers)` in master plan header.
  2. Skip workflow steps 1, 2, 6 (OCR, frequency, PYP keys).
  3. Fall back to **lecturer-emphasis-only mode**: priority = RED-items × slide-frequency.
  4. Surface explicit warning in INDEX: `⚠ NO empirical frequency data — priority is
     lecturer's RED list only. Cannot identify verbatim repeats.`
  5. Replace TEMPLATE_verbatim_repeats with `01_LECTURER_RED_PRIORITY.pdf` (RED items
     ranked by emphasis count).
  6. Reduce confidence claim in success criteria from "70+ on cold mock" to "best
     effort with available signal".
- **Failure if unhandled**: skill silently fabricates frequency data, violating
  "Never fabricate frequency data" hard rule.

### 1.2 Exactly 1 past paper — P1

- **Trigger**: 1 PDF found.
- **Detection**: Turn 2.
- **Behavior**:
  1. OCR it normally.
  2. Frequency table: replace counts with raw question list, label
     `Sample size = 1 — frequency NOT meaningful, treated as topic enumeration`.
  3. **Skip verbatim-repeat detection** (mathematically impossible from N=1).
  4. Generate topic packs from the 1 paper + lecturer RED.
  5. Generate 1 PYP answer key normally.
  6. INDEX warning: `⚠ Only 1 past paper — cannot detect repeats. Treat all questions
     as Tier-1 candidates.`
- **Failure if unhandled**: skill outputs "verbatim_repeats" pack containing every
  question from the single paper, misleading student into over-memorizing.

### 1.3 2 past papers — P1 (already partially covered by SKILL.md `<3 = low confidence`)

- **Behavior**: produce frequency table but flag every count as
  `[LOW-CONFIDENCE: N=2]`. Verbatim-repeat detection runs but threshold raised
  to "exact wording match across both years" (no fuzzy match — too noisy).
- The existing SKILL.md note `<3 past papers: still produce frequency table but flag
  low-confidence` is sufficient; just enforce it.

### 1.4 10+ past papers — P1

- **Trigger**: Glob returns ≥10 PDFs.
- **Detection**: Turn 2.
- **Behavior**:
  1. **Window to most recent 5** for primary frequency analysis (course content
     drifts; old papers can be misleading — SC4003 Shapley case is precedent).
  2. Run a **second-tier "long-tail" pass** on years 6+ flagged as
     `historical_only.md` to detect topics that appeared 5+ years ago and may return.
  3. INDEX explicitly states: `Frequency = recent 5 years; historical reference
     in _process/historical_long_tail.md`.
  4. Cap parallel OCR agents at 5 to avoid context blowup; queue the rest.
- **Failure if unhandled**: 10 parallel OCR agents blow context window; or
  obsolete topics from 8 years ago dominate frequency table.

### 1.5 Past papers in different language than exam — P1

- **Trigger**: lecturer says "exam is in English" but PDFs are 中文 (or vice versa).
- **Detection**: Turn 1 — explicit ask: "Exam language?" — and OCR-step language
  detection (heuristic: ≥30% CJK chars → Chinese).
- **Behavior**:
  1. OCR with bilingual setting (`tesseract -l eng+chi_sim`).
  2. Generate topic packs in **exam language** (priority).
  3. Provide a parallel `*_BILINGUAL_GLOSS.md` with key-term mapping (中→en) for
     terminology disambiguation.
  4. Verbatim-repeat detection: match on **language-normalized term tokens**, not
     raw bytes (e.g., 强化学习 ≡ "reinforcement learning").
- **Failure if unhandled**: frequency table double-counts the same topic under two
  language renderings; verbatim detection misses obvious repeats.

### 1.6 No lecturer review document — P0 (already noted in SKILL.md L198)

- **Existing rule**: `0 lecturer review → use slide highlight detection (Bo An style
  RED) heuristics`.
- **Specify further**:
  1. Run a `slide-highlight-extractor` agent: search all slide PDFs for visually
     marked items (red text / bold / boxed / "key" / "important" / "exam" keywords).
  2. If even slides have no markings, fall back to **frequency-only priority**
     (past papers do all the work).
  3. If neither lecturer review nor slides → see 1.7.

### 1.7 Slides only (no review, no past papers) — P1

- **Trigger**: only lecture slide PDFs.
- **Behavior**:
  1. Generate **outline-style topic packs** (one per lecture week) — pure
     content distillation.
  2. **Refuse** to produce verbatim_repeats or frequency analysis (would be lies).
  3. Cheatsheet builder runs normally.
  4. Strongly recommend in INDEX: "Ask classmates / TA for past papers — current
     output is generic study notes, not empirical drill."
- **Failure if unhandled**: skill produces fake "Tier 1 / Tier 2" rankings from
  zero data.

### 1.8 Handwritten material (OCR fails) — P1

- **Trigger**: OCR confidence <40% on a paper, or Tesseract output is garbage
  (≥30% non-word tokens).
- **Detection**: post-OCR validation step (count fraction of dictionary-words).
- **Behavior**:
  1. Try a 2nd-pass with `pdftotext` (handles digital PDFs that look scanned).
  2. If still failing, try VLM (Gemini 2.5 Flash) on rendered page images.
  3. If VLM also fails: **flag the paper as `OCR_FAILED`**, exclude from frequency
     table, surface to user: `Paper 2024 OCR failed — please transcribe manually
     or skip. Continue with N-1 papers? [yes/no]`.
  4. Never silently substitute fake content.

---

## 2. Time edge cases

### 2.1 Less than 2h to exam — P0

- **Trigger**: `exam_datetime - now < 2h`.
- **Detection**: Turn 1 time computation.
- **Behavior**: **REFUSE** politely.
  > "你离考试只剩 X 小时。这个 skill 需要至少 2-3 小时跑 verbatim 提取 +
  > cheatsheet 生成才有意义。现在最佳行动：(1) 复习 lecturer's RED 清单，(2) 走一遍
  > 最近一份 past paper 的答案，(3) 睡 30 分钟。要我帮你做这三件事的简短版吗？"
- Offer a fallback "**panic mode**": single agent reads ONLY the lecturer's RED
  list and outputs a 1-page screen-readable markdown (no PDF, no pandoc, no
  topic packs) — total runtime ≤10 min.
- **Failure if unhandled**: skill kicks off 10-step pipeline that finishes after
  the exam starts.

### 2.2 2-6h to exam (emergency) — P0

- **Trigger**: 2h ≤ time_to_exam < 6h.
- **Existing rule**: SKILL.md L178 says "Hard-fail at <6h to exam unless user opts
  into emergency mode (verbatim only)".
- **Specify**:
  1. AskUserQuestion confirm: "Only Xh left. Run emergency mode? Output =
     verbatim_repeats + cheatsheet ONLY. Skip topic packs + PYP keys. Confirm?"
  2. On confirm: run only steps 1, 2, 8 (OCR, frequency, cheatsheet) — skip 5,6,9.
  3. Output as **markdown to stdout + 1 PDF cheatsheet** (no 25-PDF bundle).
  4. Cap total runtime at 60 min; warn at 30 min mark.

### 2.3 Exam already passed — P0

- **Trigger**: `exam_datetime < now`.
- **Behavior**:
  1. AskUserQuestion: "Date entered is in the past. Did you mean a future date,
     or do you want post-exam analysis (different skill)?"
  2. If post-exam: suggest `/retro` or a future `/exam-postmortem` skill — do NOT
     run drill pipeline.
- **Failure if unhandled**: skill happily produces drill PDFs for an exam that
  already happened.

### 2.4 User changes exam date mid-session — P1

- **Trigger**: in any turn, user says "actually the exam is tomorrow not next week"
  or similar.
- **Detection**: pattern-match in user message, OR explicit re-confirmation prompt
  before launching expensive pipeline (step 5 onward).
- **Behavior**:
  1. Acknowledge change, recompute time budget.
  2. If new time → different mode (e.g., standard → emergency), **stop running
     agents**, summarize what's already produced, ask user to confirm scope reduction.
  3. Save partial state to `_process/session_state.json` so re-run can resume.

### 2.5 User in non-default timezone — P2

- **Trigger**: ambiguous time string ("exam at 9am" but no TZ).
- **Detection**: Turn 1.
- **Behavior**:
  1. Always ask explicitly: "Exam time + timezone (e.g., '2026-05-03 09:00 SGT')."
  2. Compute time-to-exam in user's TZ, not server TZ.
  3. Display `Exam in: 18h 23m (your local time)` so user can sanity-check.

---

## 3. User input edge cases

### 3.1 User doesn't know exam format — P1

- **Trigger**: user replies "I don't know" / "not sure" to format questions in Turn 1.
- **Behavior**:
  1. Try to **infer from past papers** (count questions, marks, duration printed
     on the paper).
  2. If past papers absent → ask: "Check the course handbook / NTUlearn / email
     from lecturer. Common formats: 4Q × 25mk closed-book, 2h. Want me to
     proceed assuming this?"
  3. Mark inferred format with `[INFERRED]` in master plan; do not pretend to
     know.

### 3.2 User unsure how confident they are — P2

- **Trigger**: skip / "I don't know" on confidence-per-topic question.
- **Behavior**: skip the personalization step. Use uniform priors. Run pipeline
  normally; the cold-mock diagnostic in Turn 9 will surface real weak spots.
- Do NOT block pipeline for missing self-assessment.

### 3.3 Multiple exams simultaneously — P1

- **Trigger**: user says "I have 3 exams this week, help me with all".
- **Behavior**:
  1. Decompose into 3 separate `/exam-prep` invocations, one per course.
  2. Build a **meta-plan** spanning all three: shared time budget, per-course
     hour allocation by (difficulty × confidence × time-to-exam).
  3. Each course gets its own `{course-folder}/exam-prep/` directory.
  4. Surface a `META_STUDY_PLAN.md` at root with all 3 schedules interleaved.

### 3.4 User in non-default timezone — see 2.5.

### 3.5 User provides materials inline (paste, not files) — P2

- **Trigger**: user pastes lecturer's review text into chat instead of giving a
  file path.
- **Behavior**: Write to `_process/lecturer_review.md`, treat as if it were a file.
  Note the source in audit trail (`source = inline_paste`).

---

## 4. Tool failure edge cases

### 4.1 OCR garbles 50%+ of paper — P1

- **Detection**: post-OCR word-recognition rate <50%.
- **Behavior**: see 1.8.

### 4.2 PDF is encrypted / password-protected — P1

- **Trigger**: pdftotext / tesseract fails with encryption error.
- **Behavior**:
  1. Detect via `qpdf --is-encrypted file.pdf` exit code.
  2. Ask user: "Paper {YEAR} is password-protected. Provide password or skip?"
  3. If user provides → `qpdf --password=X --decrypt`, retry.
  4. If skip → exclude from analysis, note in `_process/papers/SKIPPED.md`.
- **Never** attempt to crack the password.

### 4.3 PDF is corrupted — P2

- **Trigger**: `pdfinfo` returns error.
- **Behavior**: log to SKIPPED.md, continue with remaining papers. Surface count
  to user in Turn 2 inventory.

### 4.4 Memory / context exceeded mid-pipeline — P0

- **Trigger**: agent dispatch fails because aggregate OCR text exceeds context, OR
  user has 15+ past papers each 20 pages.
- **Detection**: pre-flight estimate (sum of page counts × ~500 tokens/page);
  warn at >150K tokens.
- **Behavior**:
  1. **Per-paper agents instead of monolithic agent** — each parallel agent reads
     1 paper's OCR, returns frequency contribution as small JSON, synthesizer
     merges.
  2. If still too large → window to recent 5 papers (see 1.4).
  3. Persist intermediate state to `_process/` so re-run can pick up.
- **Failure if unhandled**: pipeline crashes mid-run, user loses 20+ min of work.

### 4.5 pandoc / xelatex not installed — P1

- **Detection**: `which pandoc` + `which xelatex` at start of step 9.
- **Behavior**:
  1. If missing → surface install instruction (`brew install --cask mactex` etc.).
  2. **Fall back to markdown-only delivery** if user can't install — they can
     read .md on iPad too. Do NOT silently skip step 9.

### 4.6 PDF too large for AirDrop after pandoc — see 5.1.

### 4.7 Disk space low — P2

- **Trigger**: write fails with ENOSPC during OCR image generation.
- **Behavior**: surface error, suggest cleaning `~/Desktop/.../exam-prep/_process/`
  from prior runs. Do not auto-delete user data.

---

## 5. Output edge cases

### 5.1 Pandoc PDF too large (>100 pages or >50MB) — P1

- **Trigger**: any single PDF >100pp or >50MB after generation.
- **Behavior**:
  1. **Split** by section: a topic pack >25pp gets split into `02a_*`, `02b_*`.
  2. Compress images (`gs -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook`).
  3. Warn user if total bundle >500MB ("AirDrop will be slow; consider USB-C
     transfer").

### 5.2 Output filename collisions — P1

- **Trigger**: re-running pipeline; existing `01_VERBATIM_REPEATS_MEMORIZE.pdf`.
- **Behavior**:
  1. Detect existing `exam-prep/` directory.
  2. AskUserQuestion: "Existing exam-prep folder found from {timestamp}.
     [overwrite / archive-and-rerun / resume / cancel]?"
  3. **archive** → `mv exam-prep exam-prep_archive_{ISO_TIMESTAMP}` then fresh run.
  4. **resume** → check `_process/session_state.json`, skip already-completed
     steps. Critical for long pipelines that crashed mid-way.
- **Default**: never silently overwrite without asking.

### 5.3 User wants to re-run mid-session — P1

- **Trigger**: in middle of pipeline, user says "re-do step 5" or "regenerate
  topic pack 03".
- **Behavior**:
  1. Support targeted re-run: `/exam-prep --resume --step=5` or
     `/exam-prep --regen=topic_03`.
  2. Re-uses cached OCR + frequency from `_process/`.
  3. Idempotent: same inputs + same step → same output.

### 5.4 Pandoc xelatex Unicode failure — P2

- **Trigger**: CJK chars in markdown but xelatex font missing.
- **Behavior**: detect with smoke-test, fall back to `--pdf-engine=lualatex`
  with `mainfont=PingFang SC` (or `Songti SC`). If that fails, fall back to
  HTML→PDF via Chromium headless.

---

## 6. Content edge cases (the hard ones)

### 6.1 Lecturer's RED items contradict past-paper reality — P0 (THE killer case)

- **Reference**: SC4003 Shapley case. Lecturer red-flagged Shapley value heavily;
  past-paper frequency analysis showed it appeared once in 8 years.
- **Detection**: cross-reference step 4 — RED ∩ frequency.
- **Behavior** (this is the differentiated value of the skill):
  1. Compute `discrepancy_score = |RED_emphasis_rank - frequency_rank|` per topic.
  2. For top 3 discrepancies, generate a `_process/analysis/discrepancies.md` with:
     - Topic name
     - Lecturer signal (rank, # mentions in review)
     - Past-paper signal (years appeared, count)
     - **Recommendation**: "Lecturer says HIGH, papers say LOW → spend 30min
       not 3h. Likely defensive 'just in case' coverage."
  3. **Surface to user as discussion**, not silent decision. They choose.
  4. Mark Tier in master plan with both signals: `Tier 2 [RED+1, FREQ-3]`.
- **Failure if unhandled**: student over-invests in topics that won't appear, OR
  skill blindly trusts past papers and misses a topic the lecturer telegraphed.
- **This is the skill's unique selling point — must not be hand-waved.**

### 6.2 Past papers all from <3 years ago — P1

- **Trigger**: span of past-paper years < 3.
- **Behavior**:
  1. Frequency table runs but is labeled `time_stability = UNKNOWN` — can't tell
     if a topic that appeared 2/3 years is "always there" or "recent fad".
  2. Tier ranking confidence reduced one notch (Tier-1 candidates labeled `T1?`).
  3. Lecturer RED gets higher weight in priority formula:
     `priority = 0.4 × frequency + 0.6 × lecturer_red` (vs default 0.5/0.5).

### 6.3 Course was redesigned recently — P1

- **Trigger**: lecturer's review explicitly says "syllabus changed", OR
  topics in old past papers don't appear in current slides at all (set difference
  between slide-topics and past-paper-topics > 50%).
- **Detection**: step 4 cross-reference plus heuristic on slide↔paper topic overlap.
- **Behavior**:
  1. Identify "stale" past papers (those covering topics not in current slides).
  2. Window frequency analysis to **post-redesign years only**.
  3. Surface explicit warning: "Course redesigned around {YEAR}. Frequency uses
     N papers from after that. Old papers in `_process/historical/`."
  4. Verbatim-repeat detection runs only within post-redesign window.

### 6.4 Lecturer review is in a non-text format (audio recording, video) — P2

- **Trigger**: user provides MP3 / MP4 of review session.
- **Behavior**:
  1. Offer to transcribe via Whisper (`whisper file.mp3 --model medium`).
  2. After transcription, treat as lecturer_review.md.
  3. Note: confidence on RED-item extraction is lower (lecturer's vocal
     emphasis ≠ "RED" highlight).

### 6.5 Conflicting answers between past-paper years — P1

- **Trigger**: same question appears in 2 years with different "official" answers
  (e.g., curriculum drift, errata).
- **Behavior**:
  1. Detect via verbatim-repeat module (matches question, compares answers).
  2. Surface in PYP answer keys: `⚠ Year {A} answer differs from Year {B}.
     Likely curriculum update — use newer.`
  3. In coverage audit, flag as a topic to clarify with TA.

### 6.6 Lecturer review explicitly says "X will not appear" — P2

- **Trigger**: phrase patterns like "won't be tested" / "skip this" / "not in scope".
- **Behavior**:
  1. Add to `_process/analysis/blacklist.md`.
  2. Exclude from topic packs even if past-paper frequency is high (lecturer's
     word > history when it's an explicit exclusion).
  3. Note in INDEX: `Excluded by lecturer: [topic list]`.

---

## Top 5 most-likely edge cases V1 must handle

Ordered by frequency-of-occurrence × severity-if-mishandled:

1. **6.1 — Lecturer RED contradicts past-paper frequency.** This is the literal
   raison d'être of the skill (per SKILL.md core philosophy #2). If V1 doesn't
   surface discrepancies as discussions, the skill is just another generic
   study-pack generator. SC4003 reference impl already proves this case occurs.

2. **2.1 + 2.2 — Time pressure (<6h / <2h to exam).** Users invoke this skill
   *when panicking*. The "exam in 90 minutes" case is statistically certain to
   happen. V1 must distinguish between hard-refuse (<2h), emergency mode (2-6h),
   and normal mode — with crisp AskUserQuestion gates so the user cannot
   accidentally launch a 45-min pipeline at T-30min.

3. **5.2 — Filename collisions / re-run mid-session.** Anyone who uses this skill
   twice (same course, second prep session; or first run crashed) hits this.
   Without the archive/resume/overwrite prompt, the skill silently destroys prior
   work — unacceptable. Should pair with `_process/session_state.json` for resume.

4. **4.4 — Memory / context exceeded with many papers.** Bullseye user
   (NTU/NUS, 5+ years of past papers) is exactly at the edge of context. The
   per-paper-agent decomposition (already implied by step 1's "parallel agents,
   1 per paper") must be enforced; monolithic OCR-then-analyze will fail at N≥7.

5. **1.1 — Zero past papers.** Common in: new courses, courses with NDA past
   papers, transfer students. SKILL.md L198 already mentions it but doesn't
   specify the fallback pipeline or the success-criteria downgrade. V1 must have
   a documented "lecturer-only mode" that doesn't pretend to do frequency
   analysis.

---

## V2 / future concerns (deferred — not blockers for V1)

- 1.5 (bilingual) — stub support in V1, full normalization in V2
- 1.7 (slides only) — minimal warning + outline mode in V1
- 6.4 (audio review) — V2 only
- 3.3 (multi-exam meta-plan) — V2 only; V1 = "run me once per course"
- 2.5 (TZ handling) — V1 should ask explicitly; V2 can integrate calendar
