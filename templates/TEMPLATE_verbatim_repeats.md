---
title: "{{COURSE_CODE}} Pack {{PACK_NUM}} — Verbatim Repeats (Memorize Word-for-Word)"
subtitle: "{{N_ITEMS}} highest-confidence answers from {{N_YEARS}}-year past-paper analysis"
geometry: margin=0.7in
fontsize: 11pt
mainfont: "Helvetica"
monofont: "Menlo"
header-includes:
  - \usepackage{xcolor}
  - \usepackage{fancyhdr}
  - \pagestyle{fancy}
  - \fancyhead[L]{{{COURSE_CODE}} — Verbatim Repeats}
  - \fancyhead[R]{\thepage}
---

<!--
  Verbatim Repeats pack. Highest-ROI study artifact when criteria are met.

  ============================================================
  INCLUSION CRITERIA — both must hold (no exceptions)
  ============================================================
    1. REPEAT REQUIREMENT: the same question (or a close paraphrase)
       has appeared in ≥ 2 past papers within the analyzed window.
       - "Close paraphrase" = same answer expected, wording shuffled.
       - A topic that recurs but with materially different sub-questions
         each year does NOT qualify (it's a frequency-pack item, not a
         verbatim item).

    2. ANSWER LENGTH: the model answer is ≤ 300 words.
       - Memorizable in ~5 min.
       - Anything longer belongs in a regular topic pack, not here.

  If only ONE criterion holds:
    - Repeat-only: include in the frequency-ranked topic pack with a
      "high recurrence" flag. Don't put here.
    - Short-only: it's just a short item, not high-ROI. Don't put here.

  Output: usually 8-12 items when both criteria are met. May be fewer
  for courses with low repeat rates.

  Substitution model:
    {{N_ITEMS}}            number of verbatim items
    For each item:
      {{ITEM_K_TITLE}}     short topic name
      {{ITEM_K_HISTORY}}   "AY1819 Q1(b) -> AY2324 Q1(c). Verbatim repeat."
      {{ITEM_K_QUESTION}}  the question, copied verbatim from a past paper
      {{ITEM_K_ANSWER}}    the model answer, ≤300 words
      {{ITEM_K_MARKS}}     mark value
      {{ITEM_K_HINT}}      optional one-line marking hint
-->

# Why this pack first

Each item below has **already repeated across multiple past-paper years** AND has a **short (≤300 word) model answer**. Both conditions together make these the highest-ROI items per minute of study.

Past recurrence is evidence of likelihood — not a guarantee. Lecturers can rotate or replace items without notice.

**Study time: 30-45 minutes.** Read → hand-copy once → close book → quiz yourself → redo errors.

---

# 1. {{ITEM_1_TITLE}} ({{ITEM_1_MARKS}} marks)

**History:** {{ITEM_1_HISTORY}}

**Q (verbatim):** "{{ITEM_1_QUESTION}}"

**Answer (memorize, ≤300 words):**

{{ITEM_1_ANSWER}}

**Marking hint:** {{ITEM_1_HINT}}

---

# 2. {{ITEM_2_TITLE}} ({{ITEM_2_MARKS}} marks)

**History:** {{ITEM_2_HISTORY}}

**Q (verbatim):** "{{ITEM_2_QUESTION}}"

**Answer (memorize, ≤300 words):**

{{ITEM_2_ANSWER}}

---

# 3. {{ITEM_3_TITLE}} ({{ITEM_3_MARKS}} marks)

<!-- Repeat for each verbatim item that satisfies BOTH inclusion criteria.
     If you find yourself wanting to include a 400-word answer "because it's
     important," stop. Move it to the regular topic pack. -->

{{ITEM_3_BODY}}

---

# {{N_ITEMS}}. {{ITEM_N_TITLE}} ({{ITEM_N_MARKS}} marks)

{{ITEM_N_BODY}}

---

# Recall checklist (test yourself once you've read)

Tick when you can recite from memory **without notes**:

- [ ] 1. {{ITEM_1_RECALL_PROMPT}}
- [ ] 2. {{ITEM_2_RECALL_PROMPT}}
- [ ] 3. {{ITEM_3_RECALL_PROMPT}}
- [ ] ...
- [ ] {{N_ITEMS}}. {{ITEM_N_RECALL_PROMPT}}

If you can recite all {{N_ITEMS}} from memory you've banked the maximum possible value from this pack — the rest depends on whether the items recur in this year's paper.

<!-- ============ EXAMPLE FILL (REMOVE WHEN INSTANTIATING) ===================
Item 1 example (passes both criteria):
  TITLE     = "Agent Control Loop — 5 Steps"
  MARKS     = 10
  HISTORY   = "AY2021 Q1(c) -> AY2324 Q1(a). Verbatim repeat across 3-year gap."
  QUESTION  = "Clearly list the 5 steps of the Agent Control Loop."
  ANSWER    = numbered list with B := brf(B, percept), D := options(B, I), etc.
              [~80 words — well under 300]
  HINT      = "all 5 names + the function notation"

Item 2 example (passes both criteria):
  TITLE     = "Third-Price Auction Truthfulness"
  MARKS     = 5
  HISTORY   = "AY2021 Q3(c) -> AY2324 Q3(c). Verbatim repeat."
  ANSWER    = counter-example with v=10, others (12, 8), table of utilities
              [~120 words]

Counter-example — what NOT to include here:
  TITLE     = "Compare reactive vs deliberative architectures"
  PROBLEM   = Recurs frequently but the model answer runs ~600 words
              with diagrams. FAILS criterion 2. Put it in the regular
              topic pack, not here.
=========================================================================== -->
