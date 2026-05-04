# {{COURSE_CODE}} — Final Memorization Pass

<!--
  The very last artifact. Compress everything to fit on ONE A4 page
  (or 2 sides). If it doesn't fit, it's not memorized.

  ============================================================
  TWO MODES — pick BEFORE filling this template
  ============================================================
  CLOSED-BOOK exams:
    This becomes your MENTAL cheatsheet — what you should be able
    to write out from memory in the first 5 minutes after the exam
    starts. Every section is "memorization-only".

  OPEN-BOOK / cheatsheet-allowed exams:
    This is your physical cheatsheet. Split each section into:
      - MEMORIZE: things you'll recall instantly (triggers, recipes
        you'll execute many times — copying wastes seconds per use)
      - LOOKUP: dense reference material (rare formulas, edge-case
        tables, long enumerations — putting them in memory wastes
        cram time you could spend on practice)

  Rule of thumb for the MEMORIZE / LOOKUP split:
    - Used > 3 times per exam     → MEMORIZE
    - Used 1-2 times per exam     → LOOKUP
    - Long enumeration / table    → LOOKUP
    - Trigger word → action map   → MEMORIZE (lookup is too slow)
    - 4+ step recipe              → MEMORIZE the skeleton, LOOKUP edge cases

  Substitution model:
    {{COURSE_CODE}}, {{EXAM_DATE}}, {{TOTAL_MARKS}}
    {{OPEN_OR_CLOSED}}        "Open-book" | "Closed-book" | "1-page cheatsheet"
    {{Q_K_LOCKED_FORMULA}}    one-line formula or recipe per question slot
    {{TIER_1_RECALL}}         bulleted list of must-recall items
-->

**Mode:** {{OPEN_OR_CLOSED}} — {{MODE_NOTE}}

---

# Top of page — Exam logistics

```
{{EXAM_DATE}} {{EXAM_TIME}} | {{EXAM_VENUE}} | Seat {{SEAT}}
{{N_QUESTIONS}} Q × {{MARKS_PER_Q}} = {{TOTAL_MARKS}} mks | {{DURATION}} | {{OPEN_OR_CLOSED}}
Per Q: {{MIN_PER_Q}} min | Buffer: {{BUFFER_MIN}} min
```

---

# Q-by-Q lock-in (the spine) — MEMORIZE

## Q1 — {{Q1_FORMULA}}
- Trigger words: {{Q1_TRIGGERS}}
- Verbatim freebies: {{Q1_VERBATIM_TOPICS}}
- Time: {{Q1_TIME_MIN}} min

## Q2 — {{Q2_FORMULA}}
- Trigger words: {{Q2_TRIGGERS}}
- Recipe: {{Q2_RECIPE}}
- Sanity check: {{Q2_SANITY}}
- Time: {{Q2_TIME_MIN}} min

## Q3 — {{Q3_FORMULA}}
- Sub-parts likely: {{Q3_SUBPARTS}}
- Anchors: {{Q3_ANCHORS}}
- Time: {{Q3_TIME_MIN}} min

## Q4 — {{Q4_FORMULA}}
- Locked recipe: {{Q4_RECIPE_4_STEPS}}
- Speed target: {{Q4_SPEED}}
- Common pitfall: {{Q4_PITFALL}}
- Time: {{Q4_TIME_MIN}} min

---

# Tier-1 must-recall — MEMORIZE
*(Closed-book: write from memory in first 5 min of exam. Open-book: do NOT put on cheatsheet — these should be reflexive.)*

## {{TIER_1_TOPIC_1}}
{{TIER_1_TOPIC_1_RECALL}}

## {{TIER_1_TOPIC_2}}
{{TIER_1_TOPIC_2_RECALL}}

## {{TIER_1_TOPIC_3}}
{{TIER_1_TOPIC_3_RECALL}}

---

# Verbatim repeats — MEMORIZE
*(High-frequency past-paper items. Write before walking in.)*

| # | Topic | One-line answer |
|---|-------|-----------------|
| 1 | {{VERBATIM_1_TOPIC}} | {{VERBATIM_1_ONELINE}} |
| 2 | {{VERBATIM_2_TOPIC}} | {{VERBATIM_2_ONELINE}} |
| 3 | {{VERBATIM_3_TOPIC}} | {{VERBATIM_3_ONELINE}} |
| 4 | {{VERBATIM_4_TOPIC}} | {{VERBATIM_4_ONELINE}} |
| 5 | {{VERBATIM_5_TOPIC}} | {{VERBATIM_5_ONELINE}} |

---

# Core formulas / recipes — MEMORIZE
*(Anything used 3+ times during the exam belongs here.)*

```
{{KEY_FORMULA_1_NAME}}: {{KEY_FORMULA_1}}
{{KEY_FORMULA_2_NAME}}: {{KEY_FORMULA_2}}
{{KEY_FORMULA_3_NAME}}: {{KEY_FORMULA_3}}
```

---

# Reference tables — LOOKUP (open-book only)
*(Dense material that's faster to look up than memorize. Closed-book exams: skip this section, OR pick the 1-2 most likely entries and promote them to MEMORIZE.)*

## {{LOOKUP_TABLE_1_NAME}}
{{LOOKUP_TABLE_1_BODY}}

## {{LOOKUP_TABLE_2_NAME}}
{{LOOKUP_TABLE_2_BODY}}

## Edge cases / rare formulas
{{LOOKUP_EDGE_CASES}}

---

# Sanity checks — MEMORIZE
*(Run after EACH question.)*

- {{SANITY_1}}
- {{SANITY_2}}
- {{SANITY_3}}
- {{SANITY_4}}

---

# Skip list (do NOT panic if you see these — 0 hits in {{N_YEARS}} past papers)

- {{SKIP_1}}
- {{SKIP_2}}
- {{SKIP_3}}

---

# First 5 minutes ritual

1. Write your matric number FIRST.
2. Read all {{N_QUESTIONS}} questions before writing.
3. Tag green/yellow/red next to each.
4. Closed-book only: brain-dump Tier-1 must-recall onto scratch paper.
5. Start with Q4 (locked recipe).
6. Move to Q2 (numerical, recipe-driven).
7. Then Q1 (grab-bag, write what you know).
8. Q3 last (mixed bag, harder to recover from).

# Last 5 minutes ritual

- Reread every question stem.
- Verify every numerical answer's units / sign / range.
- Reread Q1 grab-bag (often missed sub-parts).
- Sign and submit.

<!-- ============ EXAMPLE FILL (REMOVE WHEN INSTANTIATING) ===================
- OPEN_OR_CLOSED = "Closed-book"
- MODE_NOTE = "Everything below is memorization-only. No physical sheet allowed."

For an open-book variant:
- OPEN_OR_CLOSED = "1-page A4 double-sided cheatsheet allowed"
- MODE_NOTE = "MEMORIZE sections must be reflexive (don't waste seconds reading own sheet).
   LOOKUP sections fill the physical cheatsheet."

- Q4 = "Game theory matrix: DS / NE / Pareto / SW (recipe locked, fresh numbers)"
- Q4 recipe: (1) DS row vs row / col vs col (2) NE = both stay (3) Pareto = no
  cell weakly dominates (4) SW = max sum
- LOOKUP_TABLE_1 example: full payoff-matrix worked example with all 4 metrics
  filled in (good for open-book; skip for closed-book unless picked as Tier-1)
=========================================================================== -->
