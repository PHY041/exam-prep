# A2 — Dialogue Flow v2 (Deterministic, No Forward References)

**Fix target:** Codex review issue #3 — Turn 2 in current SKILL.md computes a time
budget that subtracts `sleep / meals / travel` *before those values exist*. Turn 3 then
asks for an open-ended "go" while the hard rules contradict (e.g. "<6h hard-fail unless
emergency mode" is never surfaced as a choice).

This document specifies the corrected Turns 1–3. Each `AskUserQuestion` block is
self-contained: it only references inputs already collected in earlier turns.

---

## Section 1 — Turn 1: Discovery (collect ALL inputs needed for time math)

**Goal of this turn:** gather every variable Turn 2 needs to compute total focused
study hours. Nothing is derived in Turn 1; we only collect.

### EXAM_METADATA — REQUIRED FIRST BLOCK (v0.5)

**Before any other Turn 1 question**, the skill MUST collect and persist a
canonical `EXAM_METADATA` block. This block is the single source of truth for
all downstream time math (master plan, Step 10.5 audit, deadline gating).

**Required fields:**

| Field | Format | Notes |
|-------|--------|-------|
| `date` | `YYYY-MM-DD` | The exam day. NEVER inherit from prior runs. |
| `start_time` | `HH:MM` (24-hour) | Local time the exam begins. |
| `duration` | `HH:MM` | Exam length, e.g. `02:30`. |
| `venue` | free text (optional) | e.g. `LT19, NTU North Spine`. |
| `format` | enum: `closed-book` / `open-book` / `take-home` | Routes to adapter. |
| `total_marks` | integer | Used by master-plan time-budget per mark. |

#### NEVER INHERIT rule (v0.5, P0)

**Even if a prior run's metadata exists in `.context/`, memory, or the user's
recent SKILL invocations, ALWAYS re-confirm `exam_datetime` in the current
invocation.**

Cite the SC4023 incident: in May 2026 the skill silently inherited SC4003's
`17:00` exam time when the student kicked off SC4023 prep. The generated master
plan would have caused the student to miss the actual `09:00` exam by 8 hours.
The fix is mandatory re-confirmation, not "auto-fill from last run".

Implementation:

```python
# WRONG (v0.4 bug):
exam_datetime = context.get("exam_datetime") or ask_user("exam_datetime?")

# RIGHT (v0.5):
exam_datetime = ask_user("exam_datetime?", prefill=None)
# If prior context exists, surface as a warning, not a default:
if context.get("exam_datetime"):
    print(f"WARN: prior run had {context['exam_datetime']}. "
          f"Confirm current: {exam_datetime}.")
```

#### Validation rule — reverse-counting only

Master-plan generation (Step 9) MUST compute time budget by reverse-counting:

```python
time_to_exam = exam_datetime - now()   # CORRECT
```

NOT by forward-additive scheduling:

```python
# FORBIDDEN — caused SC4023 incident
schedule_end = now() + sum(planned_block_hours)
```

Step 9 enforces this: if `time_to_exam` is missing or negative, refuse to
render the master plan and emit `ERROR: EXAM_METADATA gate failed`. Step 10.5
(codex-student audit) will additionally flag any pack referencing dates
inconsistent with the EXAM_METADATA block.

---

**Six inputs to collect.** Send as a single `AskUserQuestion` payload (six questions,
each independent, no forward refs):

```yaml
ask_user_question:
  - id: course
    question: "Course code + name?"
    placeholder_example: "SC4003 Intelligent Agents"
    type: free_text
    required: true

  - id: exam_datetime
    question: "Exam date + time (local)? Format: YYYY-MM-DD HH:MM"
    placeholder_example: "2026-05-04 09:00"
    type: free_text
    required: true
    validation: parseable as ISO datetime; must be in the future

  - id: exam_format
    question: "Exam format?"
    type: multi_field
    fields:
      - book_policy: [closed_book, open_book, restricted_open_book]
      - calculator: [allowed, not_allowed]
      - duration_minutes: integer
      - num_questions: integer
      - total_marks: integer
    required: true

  - id: materials_path
    question: "Absolute path to the folder containing past papers / lecturer review / slides?"
    placeholder_example: "/Users/.../SC4003 Intelligent Agents/"
    type: free_text
    required: true
    note: |
      Skill will Glob this folder for *.pdf and report what it finds.
      You don't need to list materials manually — just give the folder path.

  - id: daily_hours_available
    question: "How many hours per day can you realistically study between now and the exam?"
    type: integer
    range: [1, 16]
    required: true
    help_text: |
      Be honest. Count only focused, distraction-free hours.
      Typical: 4–6 (with classes/job), 8–10 (full cram day), 12+ (last-day grind).

  - id: sleep_hours_per_night
    question: "Sleep hours per night you will protect?"
    type: integer
    range: [4, 10]
    default: 7
    required: true
    help_text: "Below 6 degrades retention. Skill will warn if <6."
```

**Implementation notes for the skill:**

- All six fields MUST be collected before Turn 2 runs. If the user skips one, re-ask.
- `materials_path` is *just a path*. The skill itself will `Glob` and `ls` to inventory
  contents in Turn 2 — do not ask the user to enumerate files.
- Confidence-per-topic and "what's already memorized" are deferred to **Turn 4
  (post-inventory)** — they require the skill to first know the topic list, which it
  doesn't until OCR runs. Asking for them in Turn 1 (as v1 did) was a forward reference.

---

## Section 2 — Turn 2: Deterministic Time Computation (NO new questions)

**Goal of this turn:** purely mechanical math from Turn 1 inputs + filesystem inventory.
No questions to the user. Output is a single computed budget + mode recommendation.

### 2.1 Inventory (filesystem only, no user input)

```python
import glob, os
materials = {
    "past_papers":   glob(f"{materials_path}/**/*[Pp]aper*.pdf", recursive=True),
    "lecturer_review": glob(f"{materials_path}/**/*[Rr]eview*.pdf", recursive=True),
    "slides":        glob(f"{materials_path}/**/*[Ll]ecture*.pdf", recursive=True),
    "tutorials":     glob(f"{materials_path}/**/*[Tt]utorial*.pdf", recursive=True),
}
```

Show counts back to the user as a status line, not a question:
`Found: 6 past papers, 1 lecturer review, 12 lecture slides, 8 tutorials.`

### 2.2 Compute total_focused_hours (deterministic formula)

```python
from datetime import datetime, timedelta

now = datetime.now()
exam = datetime.fromisoformat(exam_datetime)
wall_clock_hours = (exam - now).total_seconds() / 3600

days_remaining = wall_clock_hours / 24

# Total study hours = daily_hours_available × days_remaining,
# capped by the wall-clock window.
# Sleep/meals/travel are NOT subtracted again — they're already excluded
# by the user's own honest "daily_hours_available" answer.
total_focused_hours = min(
    daily_hours_available * days_remaining,
    wall_clock_hours - (sleep_hours_per_night * days_remaining)
)
total_focused_hours = max(0, round(total_focused_hours, 1))
```

**Why this is deterministic and bug-free:**

- `daily_hours_available` is the user's already-net figure (they self-deducted sleep,
  meals, commute, classes). The v1 bug was double-deducting these.
- Sleep is only used as a *sanity cap* (you can't study more hours than wall-clock
  minus required sleep), not subtracted twice.
- No forward reference. Every variable comes from Turn 1.

### 2.3 Map total_focused_hours → mode (deterministic table — see §4)

```python
if total_focused_hours < 6:
    primary_mode = "emergency"
    fallback_mode = "abort_or_emergency"  # see §4 for what abort means
elif total_focused_hours < 30:
    primary_mode = "crunch"
    fallback_mode = "emergency"
elif total_focused_hours < 168:  # < 7 days × 24h ceiling
    primary_mode = "standard"
    fallback_mode = "crunch"
else:
    primary_mode = "luxury"
    fallback_mode = "standard"
```

### 2.4 Output of Turn 2 (no question — just a computed status block)

The skill prints:

```
Inventory:
  Past papers found: {N}
  Lecturer review:   {0|1}
  Lecture slides:    {N}
  Tutorials:         {N}

Time budget (computed):
  Wall-clock hours to exam: {wall_clock_hours}
  Days remaining:           {days_remaining:.1f}
  Daily focused hours:      {daily_hours_available} (your input)
  Protected sleep / night:  {sleep_hours_per_night}
  → Total focused hours:    {total_focused_hours}

Mode (deterministic):
  Primary recommendation:  {primary_mode}
  Fallback if you want lighter scope: {fallback_mode}
```

This block is read-only. Turn 3 is where the user confirms or overrides.

---

## Section 3 — Turn 3: Recommendation + Single-Confirm

**Goal of this turn:** show the student exactly *one* primary plan + *one* fallback,
plus the deliverables they will get. Single yes/no confirm. No menu of N options.

### 3.1 The recommendation block (rendered, not asked)

Show this verbatim:

```
Recommended plan: {primary_mode_name}
  - Pipeline stages: {stages_for_primary_mode}        (see mode table §4)
  - Deliverables:    {deliverable_count_primary} PDFs
  - Time required:   ~{primary_mode_min_hours}h focused work

Fallback plan: {fallback_mode_name}
  - Pipeline stages: {stages_for_fallback_mode}
  - Deliverables:    {deliverable_count_fallback} PDFs
  - Time required:   ~{fallback_mode_min_hours}h focused work
```

### 3.2 The single AskUserQuestion confirm

```yaml
ask_user_question:
  - id: confirm_plan
    question: |
      I'll run the {primary_mode_name} plan. Confirm to start?
    type: single_choice
    options:
      - "go"             # → launch primary plan
      - "use_fallback"   # → launch fallback plan
      - "exit"           # → exit skill, user wants something different
    required: true
```

**Behavior on each answer:**

| Answer | Skill action |
|---|---|
| `go` | Launch Turn 4 pipeline with `primary_mode` |
| `use_fallback` | Launch Turn 4 pipeline with `fallback_mode` |
| `exit` | Print one line: "Exiting. Run `/exam-prep` again with different inputs if you want a different plan." Then stop. |

### 3.3 Hard-rule reconciliation (fixes v1's contradiction)

The current SKILL.md has a hard rule: *"Hard-fail at <6h to exam unless user opts into
emergency mode."* In v2 this is no longer a contradiction with Turn 3 because:

1. If `total_focused_hours < 6`, Turn 2 sets `primary_mode = "emergency"` automatically.
2. The Turn 3 confirm still shows three buttons (go / fallback / exit), but the
   `fallback_mode` for emergency is `abort_or_emergency` — i.e. there is no lighter
   pipeline below emergency. Picking `use_fallback` in this case prints:
   *"No lighter mode exists below emergency. Pick `go` to run emergency, or `exit`."*
3. The "<6h hard-fail" rule is satisfied because emergency is *already* the offered
   mode — the user explicitly opts in by clicking `go`.

This removes the open-ended "go" ambiguity from v1 (where Turn 3 said "get explicit
'go'" without specifying what was being agreed to).

---

## Section 4 — Mode Mapping Table (single source of truth)

| Mode | total_focused_hours range | Pipeline stages run | Deliverables | Min focused hours | Fallback |
|---|---|---|---|---|---|
| `emergency` | < 6 h | Verbatim repeats only + Q4-method (steps 1, 2, partial 3 of WORKFLOW_STEPS) | 1 verbatim PDF + 1 method PDF (~2 PDFs) | 4 h | `abort_or_emergency` (no lighter mode exists) |
| `crunch` | 6 – 30 h | OCR → frequency → RED-cross-ref → top-3 topic packs + verbatim (steps 1–5 partial, skip per-paper answer keys) | ~6 PDFs (verbatim + 3 topic packs + INDEX + 1 weak-spot patch) | 8 h | `emergency` |
| `standard` | 30 – 168 h (1–7 days) | Full 10-step workflow | ~25–30 PDFs (verbatim + per-topic packs + per-paper answer keys + cheatsheet + INDEX + master plan) | 24 h | `crunch` |
| `luxury` | > 168 h (>7 days) | Full 10-step workflow + cold-mock + diagnostic loop + handwritten cheatsheet practice | ~25–30 PDFs + scheduled mock-test reminders + spaced-repetition reviews | 40 h | `standard` |

**Boundary clarifications:**

- The `wall_clock_hours - (sleep × days)` cap means a user with a 24h-away exam claiming
  "I will study 20 h/day" still gets capped at ~17 h focused (24 − 7 protected sleep) →
  lands in `crunch`, not `standard`. This is correct.
- A user with 8 days × 4 h/day = 32 h lands in `standard`, not `luxury`. The 168h
  threshold means **calendar wall-clock above 7 days** AND focused hours above the
  threshold — both must be true (the `min(...)` formula enforces this naturally).
- Under 4 h focused time → the skill should still offer `emergency` but print a warning:
  *"Below 4h focused, even verbatim drilling has limited ROI. You may benefit more from
  rest. Continue?"*

**Stage-to-mode mapping cross-reference:**

The 10 pipeline steps from the current SKILL.md (`workflow/WORKFLOW_STEPS.md`) map as:

| Step | emergency | crunch | standard | luxury |
|---|---|---|---|---|
| 1. OCR past papers | partial (1 paper) | yes | yes | yes |
| 2. Frequency table | skip | yes | yes | yes |
| 3. Lecturer RED items | skip | yes | yes | yes |
| 4. RED × frequency cross-ref | skip | yes | yes | yes |
| 5. Topic packs | skip | top 3 only | all | all |
| 6. PYP answer keys | skip | skip | yes | yes |
| 7. INDEX + master plan | minimal | yes | yes | yes |
| 8. Coverage audit | skip | skip | yes | yes |
| 9. PDF conversion | yes | yes | yes | yes |
| 10. AirDrop instructions | yes | yes | yes | yes |
| +9. Cold mock + diagnostic | skip | skip | optional | yes |
| +10. Handwritten cheatsheet | skip | skip | yes | yes |

---

## Summary of v1 → v2 changes

1. **Turn 1** now collects `daily_hours_available` and `sleep_hours_per_night`
   *before* Turn 2 needs them. v1 referenced these in Turn 2's formula without
   collecting them — that was the ordering bug.
2. **Turn 2** is now zero-question and purely deterministic. The formula uses
   `daily_hours_available` (already net of sleep/meals/travel from the user's POV)
   and only applies sleep as a sanity cap, not a second deduction.
3. **Turn 3** offers exactly one primary mode + one fallback (deterministically
   derived in §4), instead of v1's open-ended "go" against a menu of options.
4. **Hard-rule reconciliation**: the "<6h emergency" rule is now baked into the
   mode table rather than living as a separate hard rule that can contradict Turn 3.
5. **Confidence-per-topic** is moved out of Turn 1 (where it was a forward
   reference — the topic list doesn't exist until after OCR) into Turn 4.
