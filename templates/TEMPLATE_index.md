---
title: "{{COURSE_CODE}} — Topic Packs (Index & Study Order)"
subtitle: "Empirical-data-driven exam prep, {{N_YEARS}} years of past papers"
geometry: margin=0.7in
fontsize: 11pt
mainfont: "Helvetica"
header-includes:
  - \usepackage{fancyhdr}
  - \pagestyle{fancy}
  - \fancyhead[L]{{{COURSE_CODE}} — Topic Pack Index}
  - \fancyhead[R]{\thepage}
---

<!--
  v0.6 note: 00_PRIMER_FROM_ZERO.pdf must appear FIRST in the study order list
  (above this INDEX file). It is the conceptual foundation; the INDEX is the
  navigation layer. Order on the iPad: PRIMER → INDEX → drill packs.

  Top-level index. The first navigation PDF a student opens (after the primer).
  Anchors: exam logistics, predicted question structure, study order, skip list,
  exam-day playbook, packing list. One file. ~200 lines.

  Substitution model:
    {{COURSE_CODE}}         e.g. SC4003
    {{COURSE_TITLE}}        e.g. Intelligent Agents
    {{EXAM_DATE_TIME}}      e.g. 2026-04-30, 17:00-19:00
    {{EXAM_VENUE}}          e.g. Hall A-Foyer
    {{EXAM_SEAT}}           if assigned
    {{EXAM_FORMAT}}         duration, # questions, marks, open/closed-book
    {{CALCULATOR_RULES}}    NTU FX-991/FX-115 etc.
    {{N_YEARS}}             past-paper sample size
    {{N_PACKS}}             total # topic packs produced
-->

# Exam Snapshot

| Item | Value |
|------|-------|
| **Date** | {{EXAM_DATE_TIME}} |
| **Venue** | {{EXAM_VENUE}} |
| **Seat** | {{EXAM_SEAT}} |
| **Format** | {{EXAM_FORMAT}} |
| **Calculator** | {{CALCULATOR_RULES}} |

---

# Empirical Question Structure ({{N_YEARS}}/{{N_YEARS}} papers)

<!-- Build this from past_paper_analysis frequency table.
     Only list patterns that recur in ≥80% of past papers. -->

| Q | Topic pattern | Marks | This pack |
|---|---------------|-------|-----------|
| **Q1** | {{Q1_PATTERN}} | {{Q1_MARKS}} | **Pack {{Q1_PACK_ID}}** |
| **Q2** | {{Q2_PATTERN}} | {{Q2_MARKS}} | **Pack {{Q2_PACK_ID}}** |
| **Q3** | {{Q3_PATTERN}} | {{Q3_MARKS}} | **Pack {{Q3_PACK_ID}}** |
| **Q4** | {{Q4_PATTERN}} | {{Q4_MARKS}} | **Pack {{Q4_PACK_ID}}** |

**Total: ~{{PREDICTABLE_MARKS}} marks predictable from {{N_YEARS}}-year empirical analysis.**

---

# All {{N_PACKS}} PDFs (study in this order)

<!-- One row per pack. Sort by Priority desc, then by Marks-per-hour desc.
     Priority stars: ⭐⭐⭐ = 5/5 hit, ⭐⭐ = 3-4/5 hit, ⭐ = 1-2/5 hit. -->

| # | Pack | Topic | Marks worth | Time | Priority |
|---|------|-------|-------------|------|----------|
| **00** | **PRIMER_FROM_ZERO** | **Read first.** From-scratch concept primer (~5-9k words, ~30-40 pages). Bridges database/systems baseline. | — (foundation) | ~90-120 min | ⭐⭐⭐ |
| **00** | INDEX | This file (TOC + study plan) | — | — | — |
| **01** | {{PACK_01_NAME}} | {{PACK_01_DESC}} | {{PACK_01_MARKS}} | {{PACK_01_TIME}} | {{PACK_01_PRIORITY}} |
| ... | ... | ... | ... | ... | ... |

**Total study time across all packs: ~{{TOTAL_HOURS}} hours.** Plus {{DRILL_HOURS}} hours of past-paper drill.

---

# Recommended Study Order (T-{{HOURS_TO_EXAM}}h)

<!-- Hour-by-hour plan. Reference TEMPLATE_master_plan.md for the full version.
     Index keeps a 5-line summary. -->

## TODAY (~{{TODAY_HOURS}}h focused)
- Hour 1 — {{TIER1_HIGHEST_ROI_PACK}} (verbatim repeats / freebies)
- Hours 2-3 — {{GUARANTEED_NUMERICAL_PACK}} ({{GUARANTEED_MARKS}} marks GUARANTEED)
- Hours 4-5 — {{SECOND_NUMERICAL_PACK}}
- Hour 6 — Cold past-paper attempt (most recent year)
- Evening — Patch weak spots from cold mock

## TOMORROW (~{{TOMORROW_HOURS}}h)
- Morning: light review, do NOT learn new material
- Mid-day: speed-pass remaining packs
- Afternoon: final recall test (close all packs, recite from memory)
- Pre-exam: STOP studying, pack ID + calculator + pens

---

# Topics to SKIP entirely (0/{{N_YEARS}} hits)

<!-- These are syllabus topics that NEVER appeared in the past-paper sample.
     Listing them explicitly is what frees the most study hours.
     Verify each entry against the frequency table in past_paper_analysis. -->

- ❌ {{SKIP_TOPIC_1}}
- ❌ {{SKIP_TOPIC_2}}
- ❌ {{SKIP_TOPIC_3}}

This skip list **frees ~{{HOURS_FREED}} hours** that earlier (non-empirical) plans wasted.

---

# Exam Day Tactical Playbook

## First {{INITIAL_READ_MIN}} minutes: Don't write
- Read all {{N_QUESTIONS}} questions.
- Mark each: 🟢 instant-recall / 🟡 needs computation / 🔴 unsure.
- Allocate: ~{{MIN_PER_Q}} min/Q.

## Order of attack
1. **{{LOCKED_Q}} first** — locked structure, banks {{LOCKED_Q_MARKS}} marks fast.
2. **{{SECOND_Q}}** — likely {{SECOND_Q_TOPIC}}.
3. **{{THIRD_Q}}** — {{THIRD_Q_NOTE}}.
4. **{{FOURTH_Q}}** — {{FOURTH_Q_NOTE}}.

## Sanity checks before submitting

<!-- One-line sanity checks per question type. Examples from SC4003:
     - NE means BOTH players don't want to deviate
     - Probabilities sum to 1
     - Σ φᵢ = v(N) (Shapley)
     Customize per course. -->

- {{SANITY_CHECK_1}}
- {{SANITY_CHECK_2}}
- {{SANITY_CHECK_3}}

---

# What to Bring (pack tonight)

- ✅ Matric card ({{MATRIC_NO}})
- ✅ 2 black pens + 1 backup
- ✅ Approved calculator (verify batteries)
- ✅ Watch (no visible clock guaranteed)
- ✅ Water bottle
- {{OPEN_OR_CLOSED_BOOK_FLAG}} cheat sheet
- ❌ NO phone in hall

---

# Confidence Calibration

Based on {{N_YEARS}}-year empirical evidence:
- **Score floor: {{FLOOR_SCORE}}** if you complete all packs.
- **Realistic upper: {{UPPER_SCORE}}** if past-paper drills go cleanly.
- **Score killer:** {{TYPICAL_FAILURE_MODE}}.

---

# File Map

All packs: `{{PACKS_DIR}}/*.pdf`
Source markdowns: same folder.
Past-paper analysis: `{{PROCESS_DIR}}/06-past-paper-analysis.md`.
Coverage audit: `{{COVERAGE_AUDIT_PATH}}`.
PYP model answers: `{{PYP_DIR}}/PYP_*_FULL_ANSWERS.md`.

---

End. Now go drill {{HIGHEST_PRIORITY_PACK}}.

<!-- ============ EXAMPLE FROM SC4003 (REMOVE WHEN INSTANTIATING) ============
- {{COURSE_CODE}} = "SC4003"
- {{N_YEARS}} = 5
- {{N_PACKS}} = 11
- Q4 pattern: "Game theory matrix: DS / NE / Pareto / SW" → 25 marks
- Skip list: BDI / Subsumption / AGENT0 / Tileworld / Value Iteration / 6 rationality axioms
- Confidence floor: 60-65 / Upper: 80-85
- Highest priority pack: Pack 02 (Q4 Game Theory)
============================================================================== -->
