# Gotchas from Real Runs

Empirical lessons from SC4003 (Apr 2026) and SC4023 (May 2026). Update after every new course run with anything non-obvious that bit us.

## NEVER INHERIT prior-run metadata

**Lesson from SC4023:** Skill silently used SC4003's exam time (17:00) when generating SC4023's master plan. Real SC4023 time was 09:00. A student following the materials would have missed the exam by 8 hours.

**Rule:** Turn 1 EXAM_METADATA confirmation is MANDATORY every invocation. Never read from prior `.context/`, prior `~/.gstack/`, or memory. The user must re-state.

## FORBIDDEN narrator phrases (auto-fail)

Found in SC4023 round-1 output. Each is a trust-killer for a student under exam stress.

- "Wait —" / "Wait,"
- "Hmm," / "Let me re-derive" / "Let me redo"
- "I'll commit to" / "I think" / "I realize"
- "Tedious" / "see lecturer's full" / "Approximate answer" / "Solution sketch"
- "This gets messy" / "It is genuinely impossible" / "closest feasible"
- "raise your hand" / "tell the lecturer"

These are auto-detected by `bin/check_pollution.sh`. Agent prompts (Prompt 6/7) explicitly forbid them.

## OCR ambiguity markers — use the standard

Use ONE of:
- `🚨 OCR-AMBIGUOUS: [committed answer] (alternative: [single alt])`
- `🚨 OCR-NOTE: [single committed answer, medium confidence]`

Do NOT invent variations like `🚨 OCR-WARNING:` or `🚨 SCAN-NOTE:`.

## Hardest questions deserve the BEST teaching, not punted answers

**Lesson from SC4023:** Q4 LSM (30 marks/year, the highest-frequency question pattern) had Drill 4 written as "Tedious — see lecturer's full solution." This is the single highest-value question in the course; punting on it loses the student ~15-25 marks.

**Rule:** Worked-answer agents (Prompt 6, Prompt 7) are forbidden from "see notes" / "see lecturer" / "see Tut N solutions" as substitute for actual derivation. If the question is structurally hard, provide best-effort + mark scheme + flag with `🚨 HARD-Q:`.

## Master plan must be a function of `time_to_exam`

**Lesson from SC4023:** v0.4 generated master plan forward from "today + 3 days." When exam time changed from 17:00 to 09:00, the Day 3 schedule still ran to 14:00 (with cold mock at 13:00) — directly conflicting with a 09:00 exam.

**Rule:** Master plan MUST reverse-count from `exam_datetime`. Day N = N days before exam. Last study slot ends at `exam_datetime - 1h` minimum. STOP rule MUST be `exam_datetime - (sleep_hours + buffer)`.

## ONE canonical answer per sub-question

**Lesson from SC4023:** PYP_AY2223 Q5(d) had 4 attempted answers (14-insert, 16-insert, 17-insert, 18-insert sequences) presented in parallel. A student under exam stress reads this and panics: "which one do I write?"

**Rule:** Prompt 7 enforces ONE canonical answer per sub-Q. If the question is structurally impossible: 1-sentence impossibility statement + 1 closest-feasible + 📝 EXAM-DAY SCRIPT callout. No alternative enumeration in answer body.

## Audit BEFORE you ship, not after

**Lesson from SC4003 + SC4023:** Both runs declared DONE before any external review. SC4003 we got lucky (or shipped silent defects we never measured). SC4023 we caught 6 P0 bugs only because we ran codex-as-student manually post-delivery.

**Rule:** Step 10.5 codex-student-audit is MANDATORY. Score < 8.0 = not-DONE. Cap 3 fix-loop rounds.

## Cost of NOT auditing >> cost of auditing

Audit cost: ~$0.30-$0.80 per round, ~$1-$2.40 max per invocation.
Cost of shipping with 6 P0 bugs: incalculable (student fails exam, trust destroyed, skill becomes useless).

ROI: ~10000x. Always audit.
