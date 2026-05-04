# {{COURSE_CODE}} Master Cramming Plan (T-{{HOURS_TO_EXAM}}h)

<!--
  Hour-by-hour study schedule. Different from the index; this is the
  "what do I do right now?" file.

  ============================================================
  TIME ALLOCATION FORMULA (deterministic — fill top-down)
  ============================================================
  Step 1. Anchor the wall clock:
    NOW              = current local datetime
    EXAM_DT          = exam start datetime
    WALL_HOURS       = (EXAM_DT - NOW) in hours        ← raw gap

  Step 2. Subtract non-negotiable physiological + logistical fixed costs:
    SLEEP_TOTAL      = sum of planned sleep blocks (h)
    MEALS            = breakfast + lunch + dinner blocks (h)
    TRAVEL           = commute to venue + arrive-early margin (h)
    BUFFER           = shower/toilet/transitions/decompression (h)
    HYGIENE          = exam-day morning routine before leaving (h)

  Step 3. Compute focused hours:
    FOCUSED_H = WALL_HOURS - SLEEP_TOTAL - MEALS - TRAVEL - BUFFER - HYGIENE

  Step 4. Sanity-check:
    - If FOCUSED_H < 4: warn user, skip Tier-2 entirely
    - If FOCUSED_H < 1: this template doesn't apply, suggest emergency triage
    - If FOCUSED_H > WALL_HOURS * 0.7: you under-counted overhead, recompute

  DO NOT decide block sizes before computing FOCUSED_H. The blocks below
  are scaled to fit FOCUSED_H, not the other way around.

  Substitution model:
    {{HOURS_TO_EXAM}}      raw WALL_HOURS
    {{FOCUSED_H}}          computed focused study hours
    {{EXAM_DATE_TIME}}     exam datetime anchor
    {{TIER_1_PACKS}}       packs to study first (highest hit rate)
    {{TIER_2_PACKS}}       packs to study second
    {{TIER_3_PACKS}}       optional buffer (skip if FOCUSED_H < 8)
-->

**Exam:** {{EXAM_DATE_TIME}}
**Wall-clock gap:** {{HOURS_TO_EXAM}}h until exam.
**Time budget (computed, not assumed):**

```
WALL_HOURS  = {{HOURS_TO_EXAM}}
- SLEEP     = {{SLEEP_TOTAL}}h
- MEALS     = {{MEALS_TOTAL}}h
- TRAVEL    = {{TRAVEL_TOTAL}}h
- HYGIENE   = {{HYGIENE_TOTAL}}h
- BUFFER    = {{BUFFER_TOTAL}}h
─────────────────────────
FOCUSED_H   = {{FOCUSED_H}}h ← actual study time available
```

**Goal:** Tier-1 mastery + Tier-2 coverage. (No score-target promised — outcomes depend on prior knowledge.)

---

# Phase 0 — Setup ({{PHASE_0_MIN}} min, do FIRST)

- [ ] Read past-paper analysis frequency table once.
- [ ] Open all {{N_PACKS}} topic packs.
- [ ] Set up timer / Pomodoro app.
- [ ] Snacks, water, no phone.
- [ ] Notify household: cram mode until {{EXAM_DATE}}.

---

# DAY 1 — TODAY ({{TODAY_FOCUSED_H}}h focused, T-{{TODAY_T_MINUS}}h)

## Block A: Hour 1 — {{HIGHEST_ROI_PACK}} (verbatim repeats)

**Why first:** highest expected ROI per minute among the available packs.

**What to do:**
1. Read each verbatim item once.
2. Hand-copy each answer onto a fresh sheet (no looking).
3. Close pack. Recite from memory.
4. Re-read items you got wrong. Repeat.

**Exit criterion:** can recite all {{N_VERBATIM_ITEMS}} items from memory.

## Block B: Hours 2-3 — {{GUARANTEED_NUMERICAL_PACK}}

**Why second:** {{GUARANTEED_TOPIC}} appeared {{LOCKED_HITS}} of {{N_YEARS}} past papers analyzed.

**What to do:**
- Drill all past-paper instances back to back.
- Time yourself: target {{TARGET_SPEED_PER_PROBLEM}} per problem.
- After each: self-grade against the model answer.

**Exit criterion:** can solve any unseen instance in {{TARGET_TIME}}.

## Block C: Hours 4-5 — {{SECOND_NUMERICAL_PACK}}

**Why:** {{SECOND_NUMERICAL_HIT_RATE}} appearance rate over the {{N_YEARS}}-year window.

{{BLOCK_C_INSTRUCTIONS}}

## Block D: Hour 6 — Cold past-paper attempt ({{MOST_RECENT_PAPER}})

- Set {{DURATION}} timer.
- Closed-book.
- Attempt every question.
- Self-grade with `PYP_{{MOST_RECENT_PAPER}}_FULL_ANSWERS.md`.

**Exit criterion:** identify the 2 weakest sub-parts (regardless of raw score).

## Block E (after dinner): patch weak spots

- Re-read the corresponding pack for the 2 weakest sub-parts.
- Redo only those sub-parts.

**STOP by {{DAY_1_STOP_TIME}}. Sleep ≥ {{SLEEP_HOURS}}h. Non-negotiable.**

---

# DAY 2 — EXAM DAY (~{{TOMORROW_FOCUSED_H}}h, no new material)

## Morning {{MORNING_START}}-{{MORNING_BREAK}} — Light review

- DO NOT learn new material.
- Read the index file.
- Read the cheatsheet.
- Recite verbatim repeats from memory.

## {{MORNING_BREAK}}-{{MIDDAY}} — Tier-2 speed pass

Speed-read packs {{TIER_2_PACK_LIST}}. 1 pack per 15-20 min.

## Lunch {{LUNCH_START}}-{{LUNCH_END}} — Q1 grab-bag review

Memorize all short-answer items in {{Q1_GRAB_BAG_PACK}}.

## Afternoon {{AFTERNOON_1_START}}-{{AFTERNOON_1_END}} — Speed-drill on hardest pack

{{N_FRESH_DRILLS}} fresh problems, {{TARGET_SPEED_PER_PROBLEM}} each.

## {{AFTERNOON_2_START}}-{{AFTERNOON_2_END}} — Final recall test

Close all packs. Recite from memory:
- {{RECALL_ITEM_1}}
- {{RECALL_ITEM_2}}
- {{RECALL_ITEM_3}}
- {{RECALL_ITEM_4}}
- {{RECALL_ITEM_5}}

## {{PRE_EXAM_START}}-{{EXAM_TIME}} — STOP STUDYING

- Pack: ID, calculator (test batteries), 2 pens + 1 backup, water.
- Eat a real meal.
- Travel to venue early.
- Find seat, breathe, do NOT open notes.

## {{EXAM_TIME}} — EXAM. Go.

---

# Exit checklist (10 minutes before walking in)

- [ ] {{CHECKLIST_ITEM_1}}
- [ ] {{CHECKLIST_ITEM_2}}
- [ ] {{CHECKLIST_ITEM_3}}

---

# Recovery plan if cold mock identifies major gaps

If your cold mock surfaces conceptual gaps (not just speed issues):
1. Stop drilling. The deficit is conceptual, not skill.
2. Re-read the {{N_YEARS}}-year past-paper analysis.
3. Re-tier topics: which packs scored 0?
4. Spend Day 2 morning re-reading those packs (not drilling).
5. Skip Tier-3 packs entirely.

# Recovery plan if cold mock shows you're well ahead

If you cleared the cold mock without gaps:
1. Skip Block E (no patching needed).
2. Day 2: do an additional cold mock on the second-most-recent paper.
3. Use saved time for {{TIER_3_PACKS}}.

---

# Skip list (delivery-fluff — NOT part of this plan)

The following are user-choice logistics, not study steps. Don't let them
eat your FOCUSED_H budget:
- AirDrop / sync-to-iPad / sync-to-tablet
- Reformat packs into a different style
- Reorganize folder structure
- Color-code highlighters
- Build a Notion / Anki deck from scratch

If you want any of these, do them OUTSIDE the FOCUSED_H budget (during
meals or buffer slots), or skip entirely.

<!-- ============ EXAMPLE FILL (REMOVE WHEN INSTANTIATING) ===================
- WALL_HOURS = 30
- SLEEP_TOTAL = 7 (one night, 23:00 → 06:00)
- MEALS = 2 (3 meals × ~40 min)
- TRAVEL = 1.5 (commute + arrive-early)
- HYGIENE = 1 (morning routine)
- BUFFER = 2 (transitions, toilet, decompression)
- FOCUSED_H = 30 - 7 - 2 - 1.5 - 1 - 2 = 16.5h
- TODAY_FOCUSED_H = 9, TOMORROW_FOCUSED_H = 7.5
- HIGHEST_ROI_PACK = Pack 01 (verbatim repeats)
- GUARANTEED_NUMERICAL_PACK = Pack 02
- LOCKED_HITS = "5/5 years"
- DAY_1_STOP_TIME = "23:00"
=========================================================================== -->
