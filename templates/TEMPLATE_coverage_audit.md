# {{COURSE_CODE}} — RED Items Coverage Audit (vs {{N_PACKS}} Topic Packs)

**Audit date:** {{AUDIT_DATE}} (T-{{DAYS_TO_EXAM}} days to exam)
**Source of RED items:** {{LECTURER_REVIEW_SOURCE}}
**Packs audited:** {{PACKS_DIR}}/{{PACKS_GLOB}}

<!--
  Cross-reference between (a) what the lecturer flagged in red ink as exam scope
  and (b) what the empirical-analysis topic packs cover. Catches the gap.

  Verification convention:
    ✓ = pack has BOTH definition/concept AND a worked example/application
    ⚠ = pack mentions topic but missing either drill OR formal definition
    ✗ = topic absent or only one passing mention

  Run this audit T-2 to T-3 days before exam. Fix the ✗ items in 10-15 min.

  Substitution model:
    {{LECTURER_REVIEW_SOURCE}}  e.g. "Review intel from MAS Review.pdf"
    {{N_RED_ITEMS}}             count of red-flagged items
    For each item:
      {{MOD_K}}, {{ITEM_K}}, {{COVERAGE_K}}, {{STATUS_K}}, {{NOTE_K}}
-->

**Verification convention:**
- ✓ = Pack has BOTH definition/concept AND a worked example/application
- ⚠ = Pack mentions topic, but missing either the worked drill OR the formal definition
- ✗ = Topic absent or only one passing mention

---

## Coverage table

### Module {{MOD_1}} — {{MOD_1_NAME}}

| Module | RED item | Covered in pack(s)? | Status |
|--------|----------|---------------------|--------|
| {{MOD_1}} | {{ITEM_1_1}} | {{COVERAGE_1_1}} | {{STATUS_1_1}} |
| {{MOD_1}} | {{ITEM_1_2}} | {{COVERAGE_1_2}} | {{STATUS_1_2}} |

### Module {{MOD_2}} — {{MOD_2_NAME}}

| Module | RED item | Covered in pack(s)? | Status |
|--------|----------|---------------------|--------|
| {{MOD_2}} | {{ITEM_2_1}} | {{COVERAGE_2_1}} | {{STATUS_2_1}} |

<!-- Repeat per module / lecture week. -->

---

## Summary

- **Total RED items audited:** {{N_RED_ITEMS}}
- **Fully covered (✓):** {{N_FULL}}
- **Partially covered (⚠):** {{N_PARTIAL}}
- **Missing (✗):** {{N_MISSING}}

---

## Critical gaps (✗) — must address before exam

<!-- These are the 1-3 items that get fixed in the next 10-15 min. -->

### 1. {{MISSING_ITEM_1_NAME}}
- **Status:** {{MISSING_ITEM_1_STATUS}}
- **Risk:** {{MISSING_ITEM_1_RISK}}
- **Recommendation:** spend {{TIME_1}} memorizing:
  - {{REMEDY_1_LINE_1}}
  - {{REMEDY_1_LINE_2}}
  - {{REMEDY_1_LINE_3}}
- ROI: {{TIME_1}} memorization vs potential {{POTENTIAL_MARKS_1}}-marker = highest ROI gap.

### 2. {{MISSING_ITEM_2_NAME}}
- **Status:** {{MISSING_ITEM_2_STATUS}}
- **Risk:** {{MISSING_ITEM_2_RISK}}
- **Recommendation:** {{REMEDY_2}}

### 3. {{MISSING_ITEM_3_NAME}}
- **Status:** {{MISSING_ITEM_3_STATUS}}
- **Risk:** {{MISSING_ITEM_3_RISK}}
- **Recommendation:** {{REMEDY_3}}

---

## Partial gaps (⚠) — strengthen if time permits

1. **{{PARTIAL_1}}** — {{PARTIAL_1_FIX}}
2. **{{PARTIAL_2}}** — {{PARTIAL_2_FIX}}
3. **{{PARTIAL_3}}** — {{PARTIAL_3_FIX}}

---

## Top 3 strengths

1. **{{STRENGTH_1_PACK}}** — {{STRENGTH_1_NOTE}}
2. **{{STRENGTH_2_PACK}}** — {{STRENGTH_2_NOTE}}
3. **{{STRENGTH_3_PACK}}** — {{STRENGTH_3_NOTE}}

---

## Single highest-priority action (next hour)

**Spend {{NEXT_HOUR_MINUTES}} minutes memorizing {{N_CHEAT_CARDS}} small cheat-cards to close the ✗/⚠ gaps with the largest mark-yield-to-time ratio:**

1. **{{CHEAT_CARD_1_NAME}} ({{CHEAT_CARD_1_MIN}} min)** — {{CHEAT_CARD_1_BODY}}
2. **{{CHEAT_CARD_2_NAME}} ({{CHEAT_CARD_2_MIN}} min)** — {{CHEAT_CARD_2_BODY}}
3. **{{CHEAT_CARD_3_NAME}} ({{CHEAT_CARD_3_MIN}} min)** — {{CHEAT_CARD_3_BODY}}

Total: {{NEXT_HOUR_MINUTES}} minutes. Closes all critical gaps; covers ~{{POTENTIAL_MARKS_AT_RISK}} potential exam marks currently at risk.

---

## Honest verdict

**Coverage is ~{{COVERAGE_PCT}}% complete.** {{HONEST_VERDICT_BODY}}

- **Where lecturer RED ≈ past-paper RED:** coverage is excellent.
- **Where lecturer RED ≠ past-paper history:** packs deliberately deprioritize. Rational on expected value but creates exposure if lecturer doubles down on emphasized items.

**The {{NEXT_HOUR_MINUTES}}-minute closure list above brings the audit to ~{{POST_FIX_COVERAGE_PCT}}% coverage.**

<!-- ============ SC4003 EXAMPLE (REMOVE WHEN INSTANTIATING) ===================
- N_RED_ITEMS = 28
- N_FULL = 17, N_PARTIAL = 8, N_MISSING = 3
- Critical gap 1: PD cooperation recovery (program equilibria / mediators / shadow of future)
  - Risk: lecturer red-flagged but never appeared in 5 years
  - Remedy: 5 min memorize 3 names + 1-line each
- Critical gap 2: Module 9 degrees of autonomy spectrum
- Critical gap 3: Induced graph / Marginal contribution nets
- Top 3 strengths: Pack 02 (Q4 game theory), Pack 06 (auctions), Pack 07 (voting)
- Coverage: ~85% pre-fix, ~98% post 10-min closure
=========================================================================== -->
