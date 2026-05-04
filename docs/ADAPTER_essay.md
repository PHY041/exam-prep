# E1: Essay-Heavy Exam Adapter

**Scope:** History, Philosophy, Law, Business Strategy, English Literature, Political Theory,
Sociology, International Relations, Theology, Cultural Studies.

**Status:** V2 design (partial V1 feasibility — see §5).

**Companion to:** Core exam-prep skill (calc-heavy default pipeline).

---

## 1. What's Different from Calc-Heavy

The default exam-prep skill assumes a STEM model: questions repeat verbatim or near-verbatim,
numerical methods recur (Newton-Raphson, integration by parts, t-test), mark allocation is
mechanical (1 mark per algebra step), and "drill" means re-computing the same method 20×.

Essay-heavy courses break **all four** of those assumptions:

### 1.1 No verbatim repeat

Essay prompts are deliberately re-phrased every cycle. "Discuss the causes of WWI" becomes
"To what extent was nationalism the primary driver of the July Crisis?" → same underlying
content, totally different surface text. **Levenshtein/n-gram similarity scoring fails.**
The repeating unit is the **topic** and the **argumentative move**, not the prompt string.

**Implication:** frequency analysis needs to operate on extracted *topics* + *argument types*
(causal, comparative, evaluative, counterfactual), not raw question text.

### 1.2 Topic frequency works — per source, not per method

In calc-heavy: "Newton-Raphson appeared 8 of last 10 years." Clean signal, clean drill target.

In essay-heavy: the unit of recurrence is **(topic × source × question-type)**.
- *Topic*: "Treaty of Versailles legacy"
- *Source*: a primary text, case, statute, or canonical thinker (e.g. Keynes' *Economic Consequences*, *Donoghue v Stevenson*, Kant's *Groundwork*)
- *Question-type*: causal / evaluative / comparative / counterfactual / interpretive

A topic that appeared 7/10 years through 3 different question-types is more important than
one that appeared 9/10 years all in one narrow framing. **Frequency is multidimensional.**

### 1.3 Marking rubric > mark allocation

Calc-heavy: "[2 marks]" tells you exactly what's expected (2 algebra steps, or 1 setup + 1 answer).
Mark hints are mechanical and stable.

Essay-heavy: "[25 marks]" tells you almost nothing. What separates a 16/25 from a 22/25 is the
**rubric** — the grade-band descriptors that examiners use:

> A (70+): Sustained, original argument; engages with historiographical debate; uses primary sources critically.
> B (60-69): Clear argument; some engagement with secondary literature; sources used as illustration.
> C (50-59): Descriptive; lists facts without argumentative thread; minimal source engagement.

The rubric is the **target function**. Mark hints are noise; rubric bands are signal.

### 1.4 Drill ≠ repetition

You cannot drill an essay by writing the same one 20×. The skill that transfers is **argument
construction under time pressure**: thesis → evidence → counter → resolution → conclusion in
45 minutes. Drill mode must time-box and grade against the rubric, not against a model answer.

---

## 2. Adapted Pipeline

| Step | Calc-Heavy (default) | Essay-Heavy (E1 adapter) |
|------|----------------------|--------------------------|
| 1. OCR past papers | same | same |
| 2. Extract questions | same | same (but tag as essay vs short-answer) |
| 3. Frequency analysis | by method/topic | **by (topic × source × question-type)** |
| 4. Mark hints | extract `[N marks]` per sub-part | **extract grade-band rubrics** |
| 5. Drill generation | method drills (20× same method) | **argument templates per topic** |
| 6. Model answers | worked solutions w/ marking | **model essays w/ rubric annotations** |

Steps 1-3 reuse the calc-heavy pipeline with one config flag (`mode: essay`) that changes
the frequency aggregation function. Steps 4-6 are essay-specific and net-new code.

### 2.1 Step 4 — Rubric extraction

Source material:
- **Past mark schemes / examiner reports** (gold standard, often public for A-Level, IB, LSAT, US bar exam, business school finals)
- **Course syllabus** (often contains a generic rubric)
- **Marking criteria sheets** distributed in tutorials

Extraction targets (regex + LLM hybrid):
- Grade band labels: `A`, `B`, `C` / `First`, `2:1`, `2:2` / `Distinction`, `Merit`, `Pass` / `70+`, `60-69`, `50-59`
- Per-band descriptors (typically 2-5 sentences each)
- Cross-cutting criteria: argument quality, source use, originality, clarity, structure

Output: `rubric.json` per course, with shape:
```json
{
  "course": "HIST301",
  "bands": [
    {"grade": "First", "range": "70+", "criteria": {
      "argument": "Sustained original thesis...",
      "sources": "Primary sources used critically...",
      "engagement": "Engages with historiography..."
    }},
    ...
  ]
}
```

### 2.2 Step 5 — Argument template extraction

For each high-frequency topic, mine all past model answers (or top-graded student exemplars,
if available) and extract the recurring argumentative structure:

```
THESIS: [single-sentence claim]
EVIDENCE-1: [specific fact/source/case]
EVIDENCE-2: [specific fact/source/case]
EVIDENCE-3: [specific fact/source/case]
COUNTER: [strongest opposing view]
REBUTTAL: [why thesis still holds despite counter]
CONCLUSION: [restatement + so-what]
```

This is the essay-equivalent of "method template" in calc-heavy. The student doesn't memorise
one essay — they internalise the **scaffold** for ~15-20 high-frequency topics.

### 2.3 Step 6 — Model essays with rubric annotations

Instead of "marking hints" (calc-heavy: arrows pointing to which line earns which mark), model
essays carry **rubric annotations** in the margin:

> ¶3 — Engages directly with Fischer thesis (rubric: "Engages with historiography" = First-class).
> ¶5 — Concedes counter-argument before rebutting (rubric: "Sustained argument" = First-class).
> ¶7 — Primary source quoted but not contextualised (rubric: would drop to 2:1 here).

This teaches the student **what each rubric band looks like in practice**, not just abstract
descriptors.

---

## 3. Topic Pack Adaptation

Calc-heavy topic pack: { topic, formula, worked example, 5 drill problems, common mistakes }.

Essay-heavy topic pack:

```yaml
topic: "Treaty of Versailles legacy"
frequency: 7/10 years
question_types_seen: [causal, evaluative, counterfactual]

thesis_options:
  - "Versailles was structurally fatal — Keynesian view"
  - "Versailles was viable but politically mismanaged in the 1920s"
  - "Versailles is overstated as cause — domestic German politics primary"

supporting_arguments:
  - claim: "Reparations exceeded Germany's capacity"
    evidence: ["Keynes 1919 ch.5", "Schuker 1976 reparations data", "Young Plan revisions"]
  - claim: "Article 231 produced lasting legitimacy crisis"
    evidence: ["Weimar polling data", "Hindenburg 1925 election", "Stab-in-the-back myth"]
  - claim: "Disarmament clauses created revanchist coalition"
    evidence: ["Reichswehr/Red Army cooperation", "Rapallo 1922"]

counter_arguments:
  - claim: "Treaty was less harsh than 1871 Frankfurt or 1918 Brest-Litovsk"
    rebuttal: "Comparative leniency irrelevant — German public perception shaped politics"
  - claim: "1929 crash was independent shock"
    rebuttal: "Crash interacted with reparations structure — not independent"

key_citations:
  primary: ["Treaty text Articles 231, 232", "Keynes 1919", "Lloyd George Fontainebleau memo"]
  secondary: ["Fischer 1961", "Schuker 1988", "MacMillan 2001"]

rubric_targets:
  first_class: "Engage with Fischer/Schuker debate explicitly; use Keynes critically not as authority"
  upper_second: "Cite Keynes; mention Fischer thesis"
  lower_second: "Describe treaty terms without historiographical frame"
```

**Key difference:** the pack gives the student **multiple thesis options** (not one model answer).
A History exam with the same topic can be answered three different ways and all earn First-class
marks. The pack teaches *which thesis to pick given the prompt's framing*, not "the" answer.

---

## 4. Drill Mode

### 4.1 Timed essay writing

- Pick a topic from the user's high-frequency list.
- Generate a novel prompt (LLM-synthesised, framing ≠ any past paper to avoid memorisation).
- Set timer (45 / 60 / 90 min depending on exam format).
- User writes in plain text editor (or upload PDF).

### 4.2 Rubric-based self-grading

After submission, the skill produces a **structured rubric report**:

```
RUBRIC REPORT — HIST301 mock essay
────────────────────────────────────────
Argument quality:    ◉◉◉◉○  Upper Second (clear thesis, sustained, but not original)
Source use:          ◉◉◉○○  Lower Second (cited Keynes; no primary engagement)
Engagement w/ debate:◉◉○○○  Third (no historiography — Fischer/Schuker absent)
Structure:           ◉◉◉◉◉  First (clear intro, signposting, conclusion lands)
Clarity:             ◉◉◉◉○  Upper Second

OVERALL BAND: 2:1 (62-65 range)

TO REACH FIRST:
1. Add historiographical anchor in ¶2 — name Fischer or Schuker explicitly
2. Use a primary source critically (currently only secondary citations)
3. Sharpen thesis in opening — "Versailles was X" is too descriptive; what's the *argument*?
```

Implementation: the LLM grader receives (a) the rubric.json, (b) the student essay, (c) a
sample of First-class exemplars for calibration. Few-shot prompting with rubric-grounded
exemplars is more reliable than zero-shot grading.

### 4.3 Variants

- **Speed drill:** 5-min "thesis + 3 evidence" outline only (don't write full essay; train scaffolding speed).
- **Counter-argument drill:** given a thesis, generate strongest counter in 10 min.
- **Citation drill:** given a topic, list 3 primary + 3 secondary sources from memory in 5 min.

These sub-drills target specific rubric dimensions without requiring full 60-min essays.

---

## 5. V1 vs V2 Scope

### V1 — what's possible NOW (with calc-heavy infra + small additions)

**Feasible immediately (~1-2 weeks of work):**
- ✅ OCR + question extraction (already exists, no changes)
- ✅ Topic frequency aggregation (refactor: add `mode: essay` flag, change aggregation key)
- ✅ Manual rubric ingestion (user uploads marking scheme PDF; LLM extracts to JSON)
- ✅ Argument-template extraction from manually-supplied model essays (5-10 high-quality essays per course)
- ✅ Topic packs in the format above (yaml/markdown, no new UI needed)

**V1 limitations:**
- Drill mode = read-only study packs. No automated grading.
- Rubric extraction works only if a rubric exists in the course materials. ~50% of courses don't publish one.
- Question-type tagging (causal/evaluative/comparative) requires LLM classification — fast but error-prone (~85% accurate from initial spike, manual review needed).

### V2 — what needs more work

**Hard problems requiring 2-4 months each:**

1. **Reliable rubric-based auto-grading** (3-4 months)
   - Need to build a calibration dataset: 50-100 student essays graded by humans across the rubric bands per course family (history-style, philosophy-style, law-style — they grade differently).
   - LLM grading drifts without exemplars. Need few-shot retrieval pipeline.
   - Open question: how transferable are exemplars across institutions? A Cambridge First-class essay ≠ a US T14 law school A-paper.

2. **Question-type taxonomy + classifier** (1-2 months)
   - Build labelled dataset of past essay prompts × question-types.
   - Train or prompt-tune a classifier. Might need per-subject taxonomies (philosophy "compare X and Y" ≠ history "to what extent").

3. **Source-based question prediction** (2-3 months)
   - "Which primary texts get re-asked?" — frequency analysis at the **source** level, not the topic level.
   - Requires extracting source citations from past mark schemes / model answers, building a source × topic × year matrix.
   - Predictive signal: a source cited in 6/10 years' model answers is highly likely to appear in this year's exam regardless of topic.

4. **Counter-argument generation that's actually good** (2 months)
   - Generic "on the other hand" counters are useless. Need subject-specific counter libraries (e.g. for Versailles topic, the canonical counters are Schuker's economic argument, Keynes' moralism critique, structural-realist takes).
   - Likely requires curated counter-libraries per topic, not pure LLM generation.

5. **Multi-thesis-path drill** (1-2 months)
   - Same prompt, three valid thesis paths, three different rubric reports. Adds complexity to drill mode UI and grading.

6. **Subject-specific adapters under E1** (ongoing)
   - E1a: History (historiography engagement is rubric-critical)
   - E1b: Law (IRAC structure is rubric-critical, case citation specifics)
   - E1c: Philosophy (engagement with primary text + named opposing view)
   - E1d: English Literature (close reading + theoretical frame)
   - E1e: Business Strategy (framework application: Porter, BCG, etc. — closer to calc-heavy actually)
   - Each subject sub-adapter is ~3-4 weeks once the E1 base is solid.

---

## 6. Realistic V2 Timeline

| Milestone | Duration | Cumulative |
|-----------|----------|------------|
| V1 ship (study packs only, no auto-grading) | 2 weeks | Month 1 |
| Rubric extraction + manual-input grading | 1 month | Month 2 |
| Question-type classifier | 1.5 months | Month 3.5 |
| Auto-grading w/ calibration dataset (1 subject family) | 3 months | Month 6.5 |
| Source-based prediction | 2 months parallel w/ above | Month 6.5 |
| Counter-argument library (1 subject) | 2 months | Month 8.5 |
| Subject sub-adapters (E1a History first) | 1 month | Month 9.5 |
| Subject sub-adapters (E1b-e, sequential) | 4 months | Month 13.5 |

**Realistic V2 essay-support timeline: 9-14 months end-to-end** for full essay-heavy parity
with the current calc-heavy skill.

**Compressed MVP (V1.5, "good enough to be useful"):** 3-4 months — covers rubric-graded study
packs + timed drill + LLM grading (acknowledged-imperfect) for one subject family (likely
History or Law where rubrics are most public).

**Recommendation:** ship V1 (study packs only, no auto-grading) at 2 weeks, gather user feedback
on whether the topic-packs alone are valuable. If yes, prioritise rubric extraction + manual-grade
input next. Auto-grading is the highest-risk component; defer until V1 proves demand.

---

## 7. Open Questions

1. **Cross-institutional rubric portability.** Is one course's rubric transferable, or does
   every course need its own? Empirical question — sample 20 history courses, compare rubrics.
2. **Student-essay corpus access.** Auto-grading needs labelled exemplars. Where do we get them
   without violating academic integrity policies? Possibly: published thesis collections, public
   first-class essay archives (e.g. Oxbridge collections), opt-in user submissions.
3. **Subject coverage prioritisation.** Which subject family ships first? History has the most
   public mark schemes. Law has IRAC (most structured = easiest to grade). Philosophy is hardest.
4. **Rubric-band granularity.** Some institutions use 5 bands (First, 2:1, 2:2, Third, Fail);
   US uses letter grades; IB uses 1-7. Normalise to a common internal scale or preserve native?
   Probably preserve native + provide a mapping layer.
