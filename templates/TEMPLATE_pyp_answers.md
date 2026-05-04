---
title: "{{COURSE_CODE}} — {{PAPER_YEAR}} Past Year Paper (with Model Answers)"
subtitle: "{{PAPER_NOTES}}"
geometry: margin=0.7in
fontsize: 11pt
mainfont: "Helvetica"
header-includes:
  - \usepackage{xcolor}
  - \usepackage{fancyhdr}
  - \pagestyle{fancy}
  - \fancyhead[L]{{{COURSE_CODE}} {{PAPER_YEAR}} — Model Answers}
  - \fancyhead[R]{\thepage}
---

<!--
  Past-Year Paper (PYP) full-answer template — v2.
  One file per past paper. Drives "cold mock + self-grade" workflow.

  v2 improvements over TEMPLATE_pyp_answers.md:
    1. Per-step marking-scheme notation `[+N marks]` inline with each step
    2. Explicit "Common Mistake / Examiner Trap" callout per sub-part
    3. Bidirectional cross-reference back to topic pack ("see Pack 02 §method")
    4. Per-sub-question timing budget AND running clock for paper pacing
    5. Sanity-check section per sub-part (e.g. "verify Σφᵢ = v(N)")
    6. Worked example for a non-CS course (BU8201 economics) at the bottom

  Substitution model:
    {{PAPER_YEAR}}        e.g. "AY2324"
    {{PAPER_NOTES}}       e.g. "Most recent paper — strongest signal for AY2425"
    {{TOTAL_MARKS}}       100
    {{DURATION}}          2 hours
    {{TARGET_SCORE}}      85+
    For each question Qk and sub-part:
      {{Qk_VERBATIM}}        question text copied from PDF
      {{Qk_MARKS}}           total mark value
      {{Qk_ANSWER_STEPS}}    model answer with [+N] per step
      {{Qk_HINTS}}           marking-scheme hints
      {{Qk_TRAP}}            single sentence — what graders punish
      {{Qk_TIME}}            time target in minutes
      {{Qk_RUNNING_CLOCK}}   cumulative minute mark by end of this sub-part
      {{Qk_PACK_REF}}        which topic pack covers this Q
      {{Qk_PACK_SECTION}}    section anchor inside that pack
      {{Qk_SANITY_CHECK}}    a 1-line invariant to verify the answer
-->

# Instructions

- **DO NOT READ until you've attempted the cold mock.** Open this AFTER you finish your {{DURATION}} mock attempt.
- After mock, use this to self-grade. Mark every sub-part: **full marks / partial / wrong**.
- Identify weak topics → revisit corresponding pack:
  - Q1 weak → {{Q1_REMEDIATION_PACKS}}
  - Q2 weak → {{Q2_REMEDIATION_PACKS}}
  - Q3 weak → {{Q3_REMEDIATION_PACKS}}
  - Q4 weak → {{Q4_REMEDIATION_PACKS}}

**Total marks: {{TOTAL_MARKS}}. Time: {{DURATION}}. Target: {{TARGET_SCORE}}/{{TOTAL_MARKS}}.**

## How to read the marking-scheme notation

- `[+N marks]` after a step = this step earns N marks if shown correctly.
- `[partial]` = examiners typically award partial credit for setup even if final number wrong.
- `[zero]` = wrong here means lose all marks for the sub-part — usually a definition or sign convention.
- The **Sanity Check** line at the end of each model answer is an invariant the correct solution must satisfy. Use it in the exam to catch arithmetic slips before moving on.

---

# Question 1 ({{Q1_TOTAL_MARKS}} marks) — {{Q1_THEME}}

## Q1(a) [{{Q1A_MARKS}} marks] — {{Q1A_TOPIC}}

**Question (verbatim):**
> "{{Q1A_VERBATIM}}"

**Time target:** {{Q1A_TIME}} min · **Running clock:** {{Q1A_RUNNING_CLOCK}} min into paper

**Model Answer (with mark allocation):**

{{Q1A_ANSWER_STEPS}}

<!-- Each step must be tagged inline, e.g.:
  Step 1. State definition of X  ............................. [+1]
  Step 2. Apply Bellman update with γ = 0.9  ................. [+2]
  Step 3. Compute V*(s) = 7.3  ............................... [+1]
-->

**Sanity check:** {{Q1A_SANITY_CHECK}}
<!-- Examples:
  - "verify Σφᵢ = v(N)" (Shapley)
  - "verify Σ probabilities = 1"
  - "verify discount factor γ ∈ [0,1)"
  - "verify supply curve slope > 0"
-->

**Marking hints:**
- {{Q1A_MARKING_HINT_1}}
- {{Q1A_MARKING_HINT_2}}

**⚠ Common mistake / examiner trap:** {{Q1A_TRAP}}
<!-- One sharp sentence about what graders punish hardest, e.g.:
  - "Forgetting the γ on the future-reward term loses the whole [+2] step."
  - "Writing Pareto-optimal when the question asked Pareto-dominant — automatic [zero] for that line."
-->

**Cross-reference:** see {{Q1A_PACK_REF}} → §{{Q1A_PACK_SECTION}}.

---

## Q1(b) [{{Q1B_MARKS}} marks] — {{Q1B_TOPIC}}

**Question (verbatim):**
> "{{Q1B_VERBATIM}}"

**Time target:** {{Q1B_TIME}} min · **Running clock:** {{Q1B_RUNNING_CLOCK}} min

**Model Answer (with mark allocation):**

{{Q1B_ANSWER_STEPS}}

**Sanity check:** {{Q1B_SANITY_CHECK}}

**Marking hints:**
- {{Q1B_MARKING_HINT_1}}

**⚠ Common mistake / examiner trap:** {{Q1B_TRAP}}

**Cross-reference:** see {{Q1B_PACK_REF}} → §{{Q1B_PACK_SECTION}}.

---

<!-- Repeat the (Q, verbatim, timing, answer-with-marks, sanity-check, hints, trap, cross-ref) block for every sub-part:
     Q1(c), Q1(d), Q2(a), Q2(b), Q2(c), Q3(a)..(e), Q4(a)..(d).
     SC4003 had 16-17 sub-parts per paper. -->

# Question 2 ({{Q2_TOTAL_MARKS}} marks) — {{Q2_THEME}}

{{Q2_BODY}}

---

# Question 3 ({{Q3_TOTAL_MARKS}} marks) — {{Q3_THEME}}

{{Q3_BODY}}

---

# Question 4 ({{Q4_TOTAL_MARKS}} marks) — {{Q4_THEME}}

{{Q4_BODY}}

---

# Self-Grade Sheet

After completing the mock, fill in:

| Q | Topic | Marks | Earned | Time used | Sanity check passed? | Weak? | Pack to revisit |
|---|-------|-------|--------|-----------|---------------------|-------|-----------------|
| 1(a) | {{Q1A_TOPIC}} | {{Q1A_MARKS}} | __ / {{Q1A_MARKS}} | __ / {{Q1A_TIME}} min | □ | □ | {{Q1A_PACK_REF}} |
| 1(b) | {{Q1B_TOPIC}} | {{Q1B_MARKS}} | __ / {{Q1B_MARKS}} | __ / {{Q1B_TIME}} min | □ | □ | {{Q1B_PACK_REF}} |
| ... | ... | ... | ... | ... | □ | □ | ... |
| **Total** | — | **{{TOTAL_MARKS}}** | **__ / {{TOTAL_MARKS}}** | **__ / {{DURATION}}** | — | — | — |

**Score interpretation:**
- ≥{{TARGET_SCORE}} → on track. Drill weak topics + memorize verbatim repeats.
- {{MIDDLE_SCORE}}–{{TARGET_SCORE}} → review weakest 2 packs first.
- <{{MIDDLE_SCORE}} → halt. Cold-read the index, reset study order.

**Time-budget interpretation:**
- Finished early (>10 min spare) → use spare for sanity-check sweep on every sub-part.
- Finished on time → ideal pacing.
- Ran over → identify which sub-part(s) ate budget; flag for "drill under timer" sessions.

---

# Worked Example (non-CS) — BU8201 "Business Finance" AY2324 Q2(b)

> Concrete instantiation showing the v2 fields applied to a non-CS course.
> Course: BU8201 Business Finance · Topic: NPV vs IRR conflict.

## Q2(b) [6 marks] — Mutually exclusive projects, NPV vs IRR conflict

**Question (verbatim):**
> "Project A: initial outlay $100,000, cash inflow $60,000 in years 1 and 2.
> Project B: initial outlay $100,000, cash inflow $0 in year 1 and $140,000 in year 2.
> Cost of capital is 10%. (i) Compute NPV of each. (ii) Compute IRR of each. (iii) State which to accept and justify in one sentence."

**Time target:** 9 min · **Running clock:** 47 min into paper

**Model Answer (with mark allocation):**

Step 1. NPV(A) = −100,000 + 60,000/1.10 + 60,000/1.10² = −100,000 + 54,545 + 49,587 = **$4,132** ........ [+1]
Step 2. NPV(B) = −100,000 + 0 + 140,000/1.10² = −100,000 + 115,702 = **$15,702** ........ [+1]
Step 3. IRR(A): solve −100 + 60/(1+r) + 60/(1+r)² = 0 → r ≈ **13.07%** ........ [+1]
Step 4. IRR(B): solve −100 + 140/(1+r)² = 0 → (1+r)² = 1.40 → r ≈ **18.32%** ........ [+1]
Step 5. NPV says B (15,702 > 4,132). IRR says B (18.32% > 13.07%). **No conflict here, both rules pick B.** ........ [+1]
Step 6. Decision: **Accept Project B.** Justification: "When NPV and IRR agree on mutually exclusive projects, accept the higher-NPV project; B dominates on both criteria." ........ [+1]

**Sanity check:** verify both NPVs are positive (else reject both regardless of ranking); verify IRR > cost of capital (10%) for both, else IRR rule says reject.

**Marking hints:**
- Discount factors must be shown (1.10, 1.21) — markers want to see the working, not just final NPV.
- IRR(B) is exact: (1+r)² = 1.40 gives r = √1.40 − 1 = 0.1832. Closed-form is faster than trial-and-error here.

**⚠ Common mistake / examiner trap:** Students who memorise "when NPV and IRR conflict, follow NPV" reflexively *write that rule even when there is no conflict* — and lose [+1] on Step 5 for misreading the question. Always check whether rankings actually disagree before invoking the conflict rule.

**Cross-reference:** see Pack 04 (Capital Budgeting) → §4.3 "NPV vs IRR mutually exclusive projects".

---

<!-- ============ SC4003 AY2324 EXAMPLE (CS course — REMOVE WHEN INSTANTIATING) ============
- PAPER_YEAR = "AY2324"
- TOTAL_MARKS = 100, DURATION = "2 hours", TARGET_SCORE = "85+"
- Q1 sub-parts: (a) Agent Control Loop 10mk / (b) MDP discount factor 7mk /
  (c) Social property + 5 trends 4mk / (d) MAS social-science rebuttal 4mk
- Q2 sub-parts: (a) decision network 10mk / (b) clean-up logic 6mk /
  (c) EU computation 9mk
- Q3 sub-parts: (a) LLM-MAS essay 6mk / (b) voting manipulation 5mk /
  (c) third-price auction 5mk / (d) Pareto property 5mk / (e) Shapley data pricing 4mk
- Q4 sub-parts: (a) DS 5mk / (b) NE 8mk / (c) Pareto 7mk / (d) SW 5mk
  on 2x2 matrices

Each sub-part has: verbatim question + model answer with all algebra shown +
[+N] mark tag per step + sanity check + marking hints + common-mistake trap +
pack cross-reference (e.g., "Pack 03 §3.2") for remediation + timing budget +
running clock.

Sample sanity checks per topic:
  - Shapley:        "verify Σφᵢ = v(N)"
  - Voting:         "verify ranking is a total order (no ties unless stated)"
  - MDP/Bellman:    "verify γ ∈ [0,1) and V* converges"
  - Auctions:       "verify dominant-strategy bid = own valuation (truthful)"
  - Game theory:    "verify NE: no player benefits from unilateral deviation"
  - Decision nets:  "verify EU(action) summed over all chance-node outcomes"
  - Probability:    "verify Σ P = 1"
=========================================================================== -->
