# A4 — Scope Narrowing & Exam-Type Adapters

> **Issue addressed (Codex #4):** v1 skill copy says "STEM exams" but the
> empirical pipeline (past-paper frequency × lecturer-RED × verbatim repeats)
> only converts well on a *specific subset* of STEM: calculation-heavy,
> past-paper-rich, structured-answer courses. The reference implementation
> (SC4003 Intelligent Agents) is exactly that subset. Generalizing to "STEM"
> oversells.
>
> **This doc:** replace generic scope language, define 5 exam archetypes with
> go/no-go decisions, specify Turn-1 detection logic, mode-switching
> pseudocode, and refusal templates for unsupported types.

---

## 1. Honest scope statement

### 1.1 Replacement copy (drop-in for SKILL.md / README.md)

> **`/exam-prep` is purpose-built for one shape of exam:**
> **calculation-heavy + past-paper-rich + structured-answer.**
>
> That means courses where (a) most marks come from showing working on
> numerical / algorithmic / derivation problems, (b) the institution releases
> 3+ years of past papers with marking schemes or worked solutions, and
> (c) answers are structured (sub-parts a/b/c, fixed mark allocations) rather
> than free-form essays.
>
> **Bullseye institutions/programs:**
> - NTU SCSE & EEE (e.g., SC4003 Intelligent Agents, EE2010 Signals & Systems)
> - NUS Engineering & Computing (CS modules with past-paper culture)
> - Cambridge Engineering Tripos (Part IA/IB/IIA structured papers)
> - IB Math AA/AI HL+SL, IB Physics HL+SL, IB Chemistry HL+SL
> - Singapore A-Level H2 Math / Physics / Chemistry / Computing
> - UK A-Level Further Maths / Physics / Computer Science
>
> **Not designed for:** essay-heavy humanities, open-ended proofs, live
> coding, MCQ-only board exams (USMLE Step 1, Bar, CFA), oral defences,
> lab practicals, or music performance. See § 2 for the full archetype map
> and § 5 for what the skill will say when you point it at one of these.

### 1.2 What changes in user-facing copy

| Location | Before (v1) | After (v2) |
|---|---|---|
| SKILL.md `description` | "ranked study plans + drill-ready PDFs for STEM exams" | "ranked study plans + drill-ready PDFs for **calculation-heavy, past-paper-rich, structured-answer exams** (NTU SCSE-style, Cambridge Tripos-style, IB Math/Physics)" |
| SKILL.md "Best for" | "STEM exams with 3+ years of past papers" | "**Calc-heavy STEM** courses with 3+ years of past papers + a lecturer review document. Bullseye: NTU/NUS/Cambridge engineering, IB Math/Physics SL/HL." |
| README.md "Limitations" | "Currently optimized for STEM closed-book exams" | Replace with the archetype table from § 2 below. |
| Adaptive logic block | "Exam type: STEM / humanities / MCQ / mixed" | Replace with archetype detector (§ 3) + mode switch (§ 4). |

---

## 2. Adapter typology — 5 exam archetypes

Each archetype has a **decision** (full / partial / refuse), the **failure mode** if forced, and the **fallback** the skill should redirect to.

### Archetype A — Calc-heavy STEM ✅ FULL SUPPORT

- **Examples:** NTU SC4003 Intelligent Agents, NTU EE2010 Signals & Systems,
  NUS CS3243, Cambridge Engineering Mechanics papers, IB Math AA HL P1/P2,
  IB Physics HL P2, A-Level H2 Math/Physics/Further Maths.
- **Marker characteristics:**
  - Questions split into sub-parts (a)(b)(c) with explicit mark allocation
  - 60%+ of marks require numerical/derivation/algorithmic working
  - Marking schemes / worked answers exist for past papers
  - Topic vocabulary is stable across years (e.g., "Bellman equation",
    "Fourier transform", "RC circuit" — verbatim or near-verbatim repeats)
- **Why pipeline works:** frequency analysis is meaningful (topics repeat),
  verbatim detection finds high-ROI drills, drills produce a clear
  pass/fail signal (right number or wrong number).
- **Output:** full 10-step pipeline, ~25–30 PDFs, INDEX + verbatim pack +
  topic packs + per-year answer keys + cheatsheet.

### Archetype B — Proof-heavy math ⚠ PARTIAL SUPPORT

- **Examples:** MIT 18.100 Real Analysis, Cambridge Math Tripos Pure papers,
  Part III Analysis, Putnam, university-level Topology/Algebra finals.
- **Marker characteristics:**
  - Questions ask for *proofs*, not numerical answers
  - Mark allocation often single number per question (e.g., "[20 marks]")
  - "Right answer" is a valid argument, not a value — many proofs accepted
  - Past papers exist but verbatim repeats are rare; *technique* repeats
    (e.g., "use compactness", "epsilon-delta") are common
- **What works:**
  - Frequency analysis at the **technique level** (not topic level): which
    proof tactics recur (diagonalization, induction on rank, Zorn's lemma)
  - Lecturer-RED audit (which theorems they emphasized)
  - Per-paper "full answers" pack as a *worked-proof anthology*
- **What breaks:**
  - Verbatim drill cards (proofs aren't memorize-and-regurgitate)
  - Numerical "did you get the right answer" diagnostic on the cold mock
  - Method packs assume "plug-and-chug" structure
- **Output:** reduced pipeline — frequency table (technique-tagged), RED
  audit, worked-proof anthology PDFs, **no** verbatim drill pack, **no**
  numerical-diagnostic mock. Add a "proof-technique cheatsheet" template
  (1 page: top 8 recurring techniques with one-line trigger).

### Archetype C — Live coding exams ❌ NOT SUPPORTED

- **Examples:** Google/Meta/Amazon onsite coding rounds, Codeforces-style
  university finals, NTU's live-coding lab assessments, LeetCode-graded
  modules.
- **Marker characteristics:**
  - Tested in an IDE / compiler / online judge in real time
  - Graded on test-case pass rate, not on written work
  - "Past papers" rarely exist or aren't representative (problems rotate)
- **Why pipeline fails:**
  - No PDF artifact to OCR
  - Frequency analysis on problem patterns (graph BFS, two-pointer, DP) is
    real but already solved by NeetCode / LeetCode / Codeforces ladders
  - This skill cannot run code in an exam-realistic environment
- **Action:** **refuse**, redirect to `/investigate` for system-design
  practice or to public ladders (NeetCode 150, Blind 75, Codeforces Edu)
  for pattern drilling.

### Archetype D — MCQ-only board/cert exams ⚠ PARTIAL SUPPORT

- **Examples:** USMLE Step 1, USMLE Step 2 CK, NCLEX, CFA Level I/II,
  AWS/GCP/Azure cert exams, Bar exam MBE section, UK GMC PLAB.
- **Marker characteristics:**
  - 100% multiple-choice or extended-matching
  - Question banks are huge (UWorld, Anki decks, Kaplan QBank)
  - "Past papers" are leaked recall posts (legally grey) or vendor QBanks
  - Graded purely on pick-the-right-letter; no working shown
- **What works:**
  - High-frequency topic identification from official content outlines +
    QBank stats (if user has UWorld/Kaplan exports, the skill can ingest)
  - Verbatim/near-duplicate question detection across leaked-recall PDFs
  - Anki-export of weak-spot drill cards
- **What breaks:**
  - Topic packs (long-form drill on derivations doesn't help MCQ; what
    helps is testlet pacing + elimination heuristics)
  - Per-paper "full worked answers" makes no sense — the answer is "C"
  - Cheatsheet (closed-book proctored, no aids allowed)
- **Output:** reduced pipeline — **skip topic packs**, **skip cheatsheet**,
  **skip per-paper answer keys**. Produce: high-frequency drill cards
  (Anki-importable .apkg or .csv), a pacing strategy memo, and an
  elimination-heuristic guide. Recommend the user ALSO use UWorld /
  Kaplan / official QBank — this skill is supplementary, not primary.

### Archetype E — Essay-heavy humanities/law ❌ V1 NOT SUPPORTED (V2 roadmap)

- **Examples:** Oxford PPE / History finals, Cambridge English Tripos,
  US law school (Torts, Contracts), undergraduate essay-based History,
  Philosophy, Sociology, Political Science finals.
- **Marker characteristics:**
  - 1-3 long essays per paper (1500-3000 words each)
  - Graded against a rubric weighting argument, evidence, structure
  - Past papers exist but "frequency" is at the *theme* level (e.g.,
    "essays on liberalism appear 3/5 years")
  - Verbatim repeats almost never happen
- **Why v1 fails:**
  - Frequency table at the topic level is too coarse (every paper
    "covers" liberalism; the discriminator is the angle of the prompt)
  - No worked-answer model (essays are open; many valid takes)
  - Rubric extraction requires NLP we haven't built
  - The high-ROI artifact for these students is a **bank of pre-planned
    essay outlines + quote banks**, not topic drill packs
- **V2 roadmap (do not promise in v1):**
  - Essay-prompt clustering (theme + angle + injunction verb)
  - Rubric-aware outline generation (intro → 3 args → counter → conclusion)
  - Quotation/citation bank extraction from lecturer notes
  - Mock essay grading via rubric prompt + worked exemplar
  - Owner: separate skill `/essay-prep` (sister to `/exam-prep`), not a
    branch inside this skill
- **Action in v1:** **refuse**, document V2 roadmap in refusal template.

---

### 2.1 Decision matrix (one-look)

| Archetype | Decision | Skip in pipeline | Add to pipeline |
|---|---|---|---|
| A. Calc-heavy STEM | ✅ Full | — | — |
| B. Proof-heavy math | ⚠ Partial | Verbatim drills, numerical diagnostic | Technique-tagged frequency, proof anthology, technique cheatsheet |
| C. Live coding | ❌ Refuse | All | — (redirect) |
| D. MCQ-only board | ⚠ Partial | Topic packs, per-paper answers, cheatsheet | High-freq drill cards (.apkg), pacing memo, elimination guide |
| E. Essay-heavy | ❌ Refuse v1 | All | — (V2 roadmap doc) |

---

## 3. Detection logic — how to detect archetype in Turn 1

Detection runs **after** the user answers Turn-1 discovery questions but
**before** committing to the pipeline. Inputs available: course code+name,
exam format answers, materials inventory (Glob results).

### 3.1 Signal sources (in order of cost)

1. **Cheap — explicit user signal:** the Turn-1 dialogue should add an
   explicit question: *"Roughly, what does an answer look like? (a) numerical
   working, (b) written proof, (c) live code in an IDE, (d) pick A/B/C/D,
   (e) essay)"* — this single question covers 80% of cases.
2. **Cheap — course code lookup:** maintain a small JSON map of known
   institutions/codes (`NTU SC4xxx → A`, `MIT 18.1xx → B`, `USMLE → D`,
   `Oxford PPE → E`, etc.) for instant resolution. Ships in
   `data/course_archetype_hints.json`.
3. **Medium — past-paper sniff:** if past papers are provided, OCR the first
   page of one paper and run heuristic regexes:
   - `\[\s*\d+\s*marks?\s*\]` per sub-part → A or B
   - `prove that|show that|demonstrate that` density > 30% → B
   - `(A)\s|(B)\s|(C)\s|(D)\s` per question → D
   - `discuss|evaluate|to what extent|compare and contrast` → E
   - No paper found, exam format = "live IDE" → C
4. **Expensive — LLM classification:** if signals 1-3 conflict or are
   inconclusive, dispatch a small classifier prompt (sonnet, ~500 tokens)
   that takes course name + first OCR'd page + format answers and returns
   one of {A, B, C, D, E, MIXED}.

### 3.2 Tie-breaking rules

- **Mixed (e.g., 70% calc + 30% short essay):** classify as the dominant
  archetype, but flag the secondary in the scope confirmation. User can
  override.
- **Ambiguous A vs B:** default to A; B is opt-in via user override (most
  "math" exams in undergrad are calc-heavy, not proof-heavy).
- **Ambiguous A vs D:** decide by mark structure — if every question is
  worth equal marks with no sub-parts, it's D; if marks vary by sub-part,
  it's A.

### 3.3 Output of detection

A small `detection_result` object passed to the mode switcher:

```python
detection_result = {
  "archetype": "A",                    # one of A|B|C|D|E
  "confidence": 0.92,                  # 0.0–1.0
  "signal_sources": ["user_q", "code_map", "paper_sniff"],
  "secondary": None,                   # or e.g. "B" for mixed
  "user_override": False,              # True if user manually set it
}
```

If `confidence < 0.7`, the skill MUST surface its guess to the user and
ask for confirmation before proceeding. Never silently route to a partial
or refusal path.

---

## 4. Mode-switching pseudocode

Insert this between Turn 2 (inventory + time budget) and Turn 3 (confirm
scope). Keep it shallow (≤4 nesting levels per skill rules).

```python
def route_pipeline(detection_result: dict, turn1: dict) -> PipelinePlan:
    """Branch the 10-step workflow based on detected exam archetype."""
    arch = detection_result["archetype"]

    # Hard refusals first — these short-circuit the rest of the skill.
    if arch == "C":  # live coding
        return refuse_with_redirect(
            reason="live_coding_not_supported",
            redirect="/investigate or NeetCode 150 / Blind 75",
        )
    if arch == "E":  # essay-heavy
        return refuse_with_redirect(
            reason="essay_heavy_v1_not_supported",
            redirect="V2 roadmap: /essay-prep (planned)",
        )

    # Confidence gate — ask user if we're not sure.
    if detection_result["confidence"] < 0.7:
        confirmed = ask_user_to_confirm_archetype(detection_result)
        if not confirmed:
            return abort_with_message("scope_unconfirmed")

    # Supported archetypes branch into pipeline shape.
    plan = base_pipeline()  # the canonical 10-step plan

    if arch == "A":
        return plan  # full pipeline, no changes

    if arch == "B":
        plan.skip("verbatim_drill_pack")
        plan.skip("numerical_cold_mock_diagnostic")
        plan.add("technique_tagged_frequency_table")
        plan.add("proof_anthology_per_paper")
        plan.add("proof_technique_cheatsheet")
        plan.note = "proof-heavy mode — drilling reduced, anthology emphasized"
        return plan

    if arch == "D":
        plan.skip("topic_packs")
        plan.skip("per_paper_full_answer_pdfs")
        plan.skip("handwritten_cheatsheet")
        plan.add("high_frequency_drill_cards_anki")
        plan.add("pacing_strategy_memo")
        plan.add("elimination_heuristics_guide")
        plan.note = "MCQ-only mode — supplementary to QBank, not primary"
        return plan

    raise ValueError(f"unhandled archetype: {arch}")
```

The `PipelinePlan` object is the same plan object today's workflow uses;
this is purely additive (new `skip()` and `add()` methods plus a `note`
field that surfaces in Turn-3 scope confirmation).

---

## 5. Refusal message templates

Refusals are user-facing. They must be: (a) honest about why, (b) short,
(c) actionable (always provide an alternative), (d) free of jargon.

### 5.1 Template — Live coding (Archetype C)

```
This skill isn't built for live coding exams.

The pipeline relies on past-paper PDFs + frequency analysis, which doesn't
map to a graded-by-test-cases coding round. You'd burn time and not get
the right output.

What works better for live coding prep:
  • Pattern drilling: NeetCode 150 / Blind 75 / Codeforces Edu rounds
  • System design: /investigate to walk through 5-10 canonical designs
  • Mock interviews: pramp.com or peer rounds

If you're prepping a *written* algorithms exam (paper-based, with
worked-answer marking schemes), say so — that's calc-heavy STEM and
this skill handles it. Otherwise, redirect above.
```

### 5.2 Template — Essay-heavy (Archetype E)

```
This skill doesn't support essay-heavy exams in v1.

Honest reason: the high-ROI artifact for essay exams is a bank of
pre-planned outlines + quote/citation banks scored against a rubric —
not the topic-frequency-and-drill packs this skill produces. Forcing the
current pipeline onto an essay paper would give you topic lists that
don't actually predict the prompt angle, and "model answers" that are
bad essays.

What we're planning (V2 roadmap, no ETA yet):
  • A sister skill /essay-prep covering: prompt clustering by theme +
    angle + injunction verb, rubric-aware outline generation,
    quotation/citation bank extraction, rubric-graded mock essays
  • Track here: <future link to roadmap doc>

In the meantime, what helps for essay exams:
  • Build a 12-15 outline bank covering the 4-6 most likely themes
  • Memorize 3-4 quotes per theme with attribution
  • Practice planning (not writing) outlines under time pressure
  • Get rubric-based feedback from your tutor or a study partner

If your paper is mixed (e.g., 60% calc + 40% short essay), tell me —
I can run the calc portion and leave the essay portion to you.
```

### 5.3 Template — Low-confidence detection (any archetype)

```
Before I commit to a pipeline, I want to confirm the exam shape.

Based on what you told me + a quick look at {paper_filename}, my best
guess is:
  → Archetype: {archetype_name}
  → Confidence: {confidence:.0%}
  → Why: {top_signals_human_readable}

Does that match? If yes, I'll route to the {full|partial} pipeline
(skipping {skipped_steps}, adding {added_steps}). If not, tell me which
of these fits better:
  (A) Calc-heavy STEM — numerical working, sub-part mark scheme
  (B) Proof-heavy math — written proofs, technique-driven
  (C) Live coding — IDE/compiler, test-case graded → I can't help
  (D) MCQ-only — pick A/B/C/D, no working shown
  (E) Essay-heavy — long written essays, rubric-graded → I can't help in v1
```

### 5.4 Template — Unsupported materials shape (orthogonal to archetype)

```
You're prepping a {archetype_name} exam, which I can support — but I'm
missing the inputs the pipeline needs:
  • Past papers found: {n_past_papers} (need ≥3 for frequency analysis)
  • Lecturer review doc: {found|missing}
  • Slide PDFs: {n_slides}

Options:
  1. If you have past papers stored elsewhere, point me at them.
  2. Run with {n_past_papers} papers and accept low-confidence frequency
     flags on every output.
  3. Skip frequency analysis and run a slides-only pipeline (lower ROI,
     but better than nothing).

Which do you want?
```

---

## 6. Implementation checklist (what changes in the codebase)

These are the concrete edits A4 implies. Listed here so the reviewer can
check them off against the v2 PR.

- [ ] **SKILL.md**: replace generic "STEM" copy with § 1.1 language
- [ ] **SKILL.md**: replace `## Adaptive logic` block with reference to A4
- [ ] **SKILL.md**: replace `## When NOT to use this skill` with § 5 refusal templates (compressed)
- [ ] **README.md**: replace `## Limitations` with § 2 archetype matrix
- [ ] **README.md**: update "Bullseye users" with § 1.1 explicit list
- [ ] **workflow/WORKFLOW_STEPS.md**: insert new Step 0.5 — "Detect archetype" (between Turn 1 and Turn 2)
- [ ] **NEW** `data/course_archetype_hints.json` — institution/code → archetype map (seed: NTU SCSE codes, MIT 18.x, Cambridge Tripos, IB programs)
- [ ] **NEW** `templates/TEMPLATE_proof_anthology.md` — for archetype B
- [ ] **NEW** `templates/TEMPLATE_high_freq_drill_cards.md` — for archetype D (Anki-importable CSV format)
- [ ] **NEW** `templates/TEMPLATE_pacing_strategy_memo.md` — for archetype D
- [ ] **NEW** `templates/TEMPLATE_proof_technique_cheatsheet.md` — for archetype B
- [ ] **AGENT_PROMPTS_LIBRARY.md**: add "archetype detector" agent prompt
- [ ] **AGENT_PROMPTS_LIBRARY.md**: add "technique-tagged frequency" agent (variant of frequency agent for archetype B)
- [ ] **AGENT_PROMPTS_LIBRARY.md**: add "MCQ high-freq topic miner" agent (for archetype D)

---

## 7. Out of scope for A4 (handed off elsewhere)

- Concrete prompts for the new agents → A5/A6 (algorithm specs)
- The full V2 `/essay-prep` sister skill design → separate doc, not this
- Multi-language (Chinese/English mixed) handling — already in v1 edge cases, untouched
- Open-book vs closed-book branching — already handled in v1 adaptive logic, orthogonal to archetype
