# {{COURSE_CODE}} — Empirical Past-Paper Analysis v2 ({{N_YEARS}} years: {{EARLIEST_YEAR}} → {{LATEST_YEAR}})

**Purpose:** Data-driven re-prioritization of the {{TOTAL_HOURS}}-hour study window. Replaces speculative tier rankings with empirical hit rates, verbatim-repeat detection, and lecturer-vs-frequency conflict resolution.

<!--
  THIS IS THE GOLD-STANDARD INPUT (v2). Every other template depends on this
  file's frequency table, RED list, and tier assignments. Do not skip.

  v2 ADDITIONS over v1:
    - Section 0:  Operational spec (which agent, which prompt, which inputs)
    - Section 0.5: Algorithms (B1 normalization, B2 verbatim, B3 RED, B4 confidence)
    - Section 3.5: Cross-paper template detection (formal output schema)
    - Section 3.6: Verbatim-repeat detection output schema
    - Section 8:   Tier 1/2/3/4 + Skip rubric made EXPLICIT (was implicit)
    - Section 8.5: Lecturer-vs-frequency conflict matrix (4 quadrants)
-->

---

## Section 0 — Operational spec (HOW to fill this template)

This section is the build manual. Do NOT delete when instantiating — replace placeholders.

### 0.1 — Inputs required

| Input | Source | Format | Notes |
|---|---|---|---|
| Past papers | Course repo / NTULearn / lecturer | PDF (text or scanned) | Need ≥3 yrs, ideally 5 |
| Lecturer slides | NTULearn / shared drive | PDF / PPTX | For RED extraction (§B3) |
| Tutorial sheets | Course repo | PDF | For verbatim cross-check |
| Existing cheat-sheets (if any) | Student's notes | MD / PDF | For Section 7 gap analysis |
| Controlled topic vocabulary | Hand-curated, ~30-60 terms | YAML/JSON | Drives §B1 normalization |

### 0.2 — Agent / prompt mapping

| Section | Filling agent | Prompt template | Output |
|---|---|---|---|
| §1 per-paper tables | `paper-extractor` (sub-agent) | `prompts/extract_paper.md` | One markdown table per paper |
| §2 frequency table | `frequency-aggregator` | `prompts/aggregate_frequency.md` | Single table, sorted desc |
| §3 numerical setups | `template-detector` | `prompts/detect_templates.md` | List + diff blocks (§B2) |
| §3.5 cross-paper templates | `template-detector` | (same) | Schema in §3.5 |
| §3.6 verbatim repeats | `verbatim-detector` | `prompts/detect_verbatim.md` | Schema in §3.6 (§B2) |
| §4 mini cheat-sheets | `topic-writer` | `prompts/write_topic_recap.md` | One subsection per Tier-1 |
| §5 watch-list | `frequency-aggregator` | (same) | Table |
| §6 new-in-latest | `paper-extractor` | (same) | Bullet list + theme |
| §7 gap analysis | `gap-auditor` | `prompts/audit_coverage.md` | Table + skip list |
| §8 tier ranking | `tier-assigner` | `prompts/assign_tiers.md` (uses §B4) | 4 tier tables |
| §8.5 conflict matrix | `tier-assigner` | (same) | 2×2 quadrant grid |
| §9 drills | `drill-writer` | `prompts/write_drill.md` | One per Tier-1 topic |
| §10 hour budget | `time-allocator` | `prompts/allocate_hours.md` | Table summing to {{TOTAL_HOURS}} |

### 0.3 — Build order (DAG)

```
§1 (per-paper)  ──┬──>  §2 (frequency)  ──┬──>  §4 (cheat-sheets)
                  │                        ├──>  §5 (watch-list)
                  └──>  §3 (templates) ────┘     §7 (gap)
                  └──>  §3.5 / §3.6 (verbatim)   │
                                                 ├──>  §8  (tiers)  ──>  §8.5 (conflict)
                                                 ├──>  §9  (drills)
                                                 └──>  §10 (hours)
```

§6 (new in latest year) depends only on §1 of {{LATEST_YEAR}}. §0.5 algorithms are referenced by §B1–B4 throughout.

---

## Section 0.5 — Algorithms (B1 / B2 / B3 / B4)

These are the deterministic procedures the agents must implement. Treat them as test-locked: if you change one, regenerate everything downstream.

### B1 — Topic normalization

**Input:** raw question text (a sub-part) → **Output:** one canonical topic label from the controlled vocabulary.

```
function normalize_topic(question_text, vocabulary):
    # 1. Strip boilerplate ("Consider the following...", "Given that...")
    cleaned = strip_boilerplate(question_text)

    # 2. Extract noun-phrase keywords (lowercased, lemmatized, stopwords removed)
    keywords = extract_keywords(cleaned)

    # 3. Score each vocabulary term by:
    #    a) exact phrase hit  (+3)
    #    b) all-keyword overlap (+2 per keyword)
    #    c) synonym table hit  (+1)
    scores = {}
    for term in vocabulary:
        scores[term] = score_topic(keywords, term, synonyms)

    # 4. If max(scores) < THRESHOLD (default 3): flag as UNKNOWN — needs human review
    # 5. Else return argmax(scores)
    if max(scores.values()) < 3:
        return "UNKNOWN_REQUIRES_REVIEW"
    return argmax(scores)
```

**Failure mode to watch for:** the same concept appearing under two labels (e.g. "Nash equilibrium" vs "NE in matrix game"). Solution: maintain a synonym table next to the vocabulary file; collapse before scoring.

**Output schema:** every sub-part in §1 must carry exactly one normalized topic. UNKNOWN entries block the build until resolved.

### B2 — Verbatim / near-verbatim detection

**Input:** two question strings A and B → **Output:** match level ∈ {EXACT, NEAR, PARAPHRASE, DISTINCT}.

```
function classify_repeat(A, B):
    # Step 1: numeric scrub — replace numbers with NUM token
    A_scrub = re.sub(r'-?\d+(\.\d+)?', 'NUM', A)
    B_scrub = re.sub(r'-?\d+(\.\d+)?', 'NUM', B)

    # Step 2: token-level Levenshtein ratio (after lowercasing, removing punctuation)
    ratio = levenshtein_ratio(tokenize(A_scrub), tokenize(B_scrub))

    # Step 3: structural diff — same sub-question count? same mark distribution?
    struct_match = (
        count_subparts(A) == count_subparts(B) and
        mark_distribution(A) == mark_distribution(B)
    )

    if ratio >= 0.95 and struct_match: return "EXACT"        # only numbers changed
    if ratio >= 0.85 and struct_match: return "NEAR"         # minor wording tweak
    if ratio >= 0.65:                  return "PARAPHRASE"   # same topic, rephrased
    return "DISTINCT"
```

**Why structural diff matters:** two questions can share 90% tokens but reorder sub-parts (a)–(d), which changes the answer template. Treat as NEAR not EXACT in that case.

**Cross-paper run:** O(N²) over all sub-parts across all years; small enough to brute-force when N_years ≤ 10.

### B3 — RED (Repeated / Emphasized / Drilled) extraction from lecturer signal

**Input:** lecturer slides + tutorials + (if available) lecture transcripts → **Output:** ranked list of "lecturer-flagged" topics.

```
function extract_RED(slides, tutorials, transcripts):
    signals = []

    # R — Repeated across multiple lectures
    for topic in topics:
        repeat_count = count_lectures_mentioning(topic, slides)
        signals.append((topic, "R", repeat_count))

    # E — Emphasized: bold, red text, "important", "exam", "must know", asterisks
    for slide in slides:
        for highlight in extract_highlights(slide):
            topic = normalize_topic(highlight.text, vocabulary)
            signals.append((topic, "E", highlight.weight))
            # weight: bold=1, red=2, "exam"/"important"=3, "[Not covered]"=−999

    # D — Drilled: appears in tutorial sheet AND has worked solution
    for tut in tutorials:
        for q in tut.questions:
            if q.has_full_solution:
                topic = normalize_topic(q, vocabulary)
                signals.append((topic, "D", 1))

    # Aggregate per topic, normalize to 0–10 scale
    return aggregate_and_rank(signals)
```

**Special tokens to watch:**
- `[Not covered]`, `[Skip]`, `[FYI only]` → set lecturer_score to **−1** (active deprioritization), not 0.
- "Exam-style", "past-year question" near a slide → +5 boost.

**Output:** `lecturer_score ∈ [−1, 10]` per topic, fed into §B4.

### B4 — Confidence score (per topic)

**Input:** empirical hit rate + lecturer_score → **Output:** confidence ∈ [0, 1] and tier assignment.

```
function compute_confidence(hits, n_years, lecturer_score, recency_boost):
    # Empirical component: hits / n_years, with half-hits as 0.5
    empirical = hits / n_years              # ∈ [0, 1]

    # Lecturer component: clamp to [0, 1]
    lecturer = max(0, lecturer_score) / 10.0

    # Recency: did it appear in {{LATEST_YEAR}}? (+0.1)
    # Did it appear 2 years in a row most recently? (+0.05)
    # Hasn't appeared in 3+ years? (−0.1)
    recency = compute_recency_boost(hits_per_year)

    # Weighted combination — empirical dominates for STEM exams
    confidence = 0.65 * empirical + 0.25 * lecturer + 0.10 * recency
    return clamp(confidence, 0, 1)
```

**Tier mapping (used by §8 rubric):**

| Confidence | Tier |
|---|---|
| ≥ 0.75 | Tier 1 — CERTAIN |
| 0.50–0.74 | Tier 2 — HIGH |
| 0.25–0.49 | Tier 3 — POSSIBLE |
| 0.05–0.24 | Tier 4 — IGNORE |
| < 0.05 OR lecturer_score = −1 | SKIP |

**Note:** SKIP is its own bucket (separate from Tier 4) because it's an *active decision* not to study, often driven by `[Not covered]` lecturer flags. See §8 rubric.

---

## Format constants across all {{N_YEARS}} papers

- {{FORMAT_CONSTANTS}}
- Q1 = {{Q1_PATTERN}}
- Q2 = {{Q2_PATTERN}}
- Q3 = {{Q3_PATTERN}}
- Q4 = {{Q4_PATTERN}}

---

## Section 1 — Per-paper question-by-question breakdown

<!-- One subsection per past paper. Tabulate every sub-part. Filled by `paper-extractor`. -->

### {{PAPER_1_YEAR}} ({{PAPER_1_DATE}})

| Q | Marks | Topic (normalized via §B1) | Type | Verbatim/paraphrase | Hash (for §B2) |
|---|---|---|---|---|---|
| 1(a) | {{Q1A_MK}} | {{Q1A_TOPIC}} | {{Q1A_TYPE}} | "{{Q1A_VERBATIM}}" | {{Q1A_HASH}} |
| 1(b) | {{Q1B_MK}} | {{Q1B_TOPIC}} | {{Q1B_TYPE}} | "{{Q1B_VERBATIM}}" | {{Q1B_HASH}} |
| ... | ... | ... | ... | ... | ... |
| 4(d) | {{Q4D_MK}} | {{Q4D_TOPIC}} | {{Q4D_TYPE}} | "{{Q4D_VERBATIM}}" | {{Q4D_HASH}} |

**Numerical setups used:** {{PAPER_1_NUMERICAL_SETUPS}}
**UNKNOWN topics flagged for review:** {{PAPER_1_UNKNOWN_LIST}}

---

### {{PAPER_2_YEAR}}

{{PAPER_2_TABLE}}

<!-- Repeat for every past paper. -->

---

## Section 2 — Empirical frequency table (THE KEY DELIVERABLE)

Counting convention: **Full hit (1.0)** = topic dominates a question (≥{{FULL_HIT_MARKS}} marks); **Half hit (0.5)** = sub-part only.

| Topic | {{Y1}} | {{Y2}} | {{Y3}} | {{Y4}} | {{Y5}} | Hits | Total marks | Avg/yr | Confidence (§B4) | Stickiness |
|---|---|---|---|---|---|---|---|---|---|---|
| **{{TOPIC_A}}** | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | **5/5** | 125 | 25.0 | 0.95 | **CERTAIN — {{NOTE}}** |
| **{{TOPIC_B}}** | 1.0 | 1.0 | 0.5 | 1.0 | 1.0 | **4.5/5** | 50 | 10.0 | 0.85 | **CERTAIN — {{NOTE}}** |
| **{{TOPIC_C}}** | 0.5 | 0.5 | 0.5 | 0.5 | 0.5 | **2.5/5** | 25 | 5.0 | 0.55 | **HIGH — every-year sub-part** |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |
| **{{NEVER_TOPIC}}** | 0 | 0 | 0 | 0 | 0 | **0/5** | 0 | 0 | 0.00 | **NEVER APPEARED** |

**Sorted by confidence (§B4):** {{TOPIC_A}} (0.95) > {{TOPIC_B}} (0.85) > … > {{NEVER_TOPIC}} (0.00).

**The {{N_YEARS}}/{{N_YEARS}} lock:** {{LOCKED_TOPIC}} is GUARANTEED. {{LOCKED_MARKS}} marks free if you drill it.

---

## Section 3 — Recurring numerical setups (examiner reuse)

<!-- Highest-yield section. Filled by `template-detector` using §B2. -->

### 3.1 — "{{REUSED_TEMPLATE_1}}" ({{TEMPLATE_1_YEARS}}, **identical structure**)

Both papers used the SAME problem template, just renumbered:
- {{TEMPLATE_1_YEAR_A}}: {{TEMPLATE_1_PARAMS_A}}
- {{TEMPLATE_1_YEAR_B}}: {{TEMPLATE_1_PARAMS_B}}

**Same exact sub-questions verbatim** in both years (§B2 = EXACT or NEAR):
1. ({{TEMPLATE_1_SUBQ_1_MARKS}}) {{TEMPLATE_1_SUBQ_1}}
2. ({{TEMPLATE_1_SUBQ_2_MARKS}}) {{TEMPLATE_1_SUBQ_2}}
3. ({{TEMPLATE_1_SUBQ_3_MARKS}}) {{TEMPLATE_1_SUBQ_3}}

**→ Highest-yield drill in the entire paper.** If "{{TEMPLATE_1_TOPIC}}" appears in {{NEXT_YEAR}}, the format will likely be {{TEMPLATE_1_PROJECTED_FORMAT}}.

### 3.2 — {{REUSED_TEMPLATE_2}}

{{TEMPLATE_2_DETAIL}}

---

## Section 3.5 — Cross-paper template detection (formal schema)

<!-- Output of `template-detector`. One entry per detected template family. -->

```yaml
templates:
  - id: T1
    topic: "{{TEMPLATE_1_TOPIC}}"
    canonical_name: "{{REUSED_TEMPLATE_1}}"
    years_appeared: ["{{Y_A}}", "{{Y_B}}"]
    match_level: EXACT          # from §B2: EXACT / NEAR / PARAPHRASE
    structural_signature:
      n_subparts: 4
      marks_distribution: [5, 8, 7, 5]
      subpart_types: ["definition", "compute", "compute", "interpret"]
    invariants:                 # things that did NOT change across years
      - "Same question wording for sub-parts (a)-(d)"
      - "Same answer template (4×4 matrix → DS → NE → Pareto → SW)"
    mutables:                   # things that DID change
      - "Payoff numbers"
      - "Player labels"
    projected_next_year:
      probability: 0.85
      expected_format: "{{TEMPLATE_1_PROJECTED_FORMAT}}"
      expected_marks: 25
    drill_priority: 1           # 1 = drill to muscle memory first
```

Repeat the block for T2, T3, … One yaml block per detected family.

---

## Section 3.6 — Verbatim-repeat detection output schema

<!-- Output of `verbatim-detector` using §B2 algorithm. -->

```yaml
verbatim_repeats:
  - pair_id: V1
    question_a:
      paper: "{{Y_A}}"
      qref: "Q4(a)-(d)"
      raw_text: "Consider the following 2-player matrix game..."
    question_b:
      paper: "{{Y_B}}"
      qref: "Q4(a)-(d)"
      raw_text: "Consider the following 2-player matrix game..."
    classification: EXACT       # §B2 output: EXACT / NEAR / PARAPHRASE / DISTINCT
    levenshtein_ratio: 0.97
    structural_match: true
    differences:
      - "Payoff matrix entries (numbers only)"
    confidence_recurrence: 0.90  # P(this exact wording appears in {{NEXT_YEAR}})
    drill_recommendation: "Memorize 4-step answer template; sub in new payoffs"
```

**Aggregate stats (required summary):**
- Total sub-parts analyzed: {{N_SUBPARTS_TOTAL}}
- EXACT pairs found: {{N_EXACT}}
- NEAR pairs found: {{N_NEAR}}
- PARAPHRASE pairs found: {{N_PARAPHRASE}}
- Mean recurrence-confidence across EXACT pairs: {{MEAN_REC_CONF}}

---

## Section 4 — "Definite" topics (≥3/{{N_YEARS}} years) — mini cheat-sheets

<!-- For each Tier-1 topic, write a 1-page recap: definitions + method + worked example. -->

### 4.1 — {{TOPIC_A}} ({{TOPIC_A_HITS}})

**Definitions:** {{TOPIC_A_DEFINITIONS}}
**Method:** {{TOPIC_A_METHOD}}
**Worked example:** {{TOPIC_A_WORKED_EXAMPLE}}

### 4.2 — {{TOPIC_B}}

{{TOPIC_B_BODY}}

---

## Section 5 — "Watch-list" topics (1–2/{{N_YEARS}} papers)

| Topic | Last seen | Confidence (§B4) | Likelihood for {{NEXT_YEAR}} |
|---|---|---|---|
| {{WATCH_TOPIC_1}} | {{WATCH_LAST_SEEN_1}} | {{WATCH_CONF_1}} | {{WATCH_LIKELIHOOD_1}} |
| {{WATCH_TOPIC_2}} | {{WATCH_LAST_SEEN_2}} | {{WATCH_CONF_2}} | {{WATCH_LIKELIHOOD_2}} |

---

## Section 6 — NEW topics in {{LATEST_YEAR}} (highest signal for {{NEXT_YEAR}})

<!-- Examiners tend to recycle topics they recently introduced. Flag these. -->

1. **{{NEW_TOPIC_1}}** — {{NEW_TOPIC_1_NOTE}}
2. **{{NEW_TOPIC_2}}** — {{NEW_TOPIC_2_NOTE}}

**Theme:** {{LATEST_YEAR_DRIFT_NOTE}}

---

## Section 7 — Topic gaps in existing study materials

| Past-paper topic | Hits | Existing coverage | Gap action |
|---|---|---|---|
| {{GAP_TOPIC_1}} | {{HITS_1}} | {{EXISTING_1}} | **{{ACTION_1}}** |
| {{GAP_TOPIC_2}} | {{HITS_2}} | {{EXISTING_2}} | **{{ACTION_2}}** |

**Existing study topics that NEVER appear in past papers (deprioritize):**
- {{NEVER_TOPIC_1}} — 0/{{N_YEARS}} hits.
- {{NEVER_TOPIC_2}} — 0/{{N_YEARS}}.

---

## Section 8 — Final empirical priority ranking (Tier 1/2/3/4 + SKIP)

### 8.0 — Explicit tier rubric

A topic is assigned a tier based on its **§B4 confidence score**, with two override rules:

| Tier | Confidence | Hit-rate floor | Marks floor | Lecturer override |
|---|---|---|---|---|
| **Tier 1 — CERTAIN** | ≥ 0.75 | ≥ 0.6 (3/5) | ≥ 15 mks/yr typical | — |
| **Tier 2 — HIGH** | 0.50–0.74 | ≥ 0.4 (2/5) | ≥ 8 mks/yr | Promote 1 tier if lecturer_score ≥ 8 |
| **Tier 3 — POSSIBLE** | 0.25–0.49 | ≥ 0.2 (1/5) | any | Promote 1 tier if lecturer_score ≥ 8 AND latest_year hit |
| **Tier 4 — IGNORE** | 0.05–0.24 | < 0.2 | small | Demote to SKIP if lecturer_score = −1 |
| **SKIP** | < 0.05 OR lecturer flags `[Not covered]` | 0/N | 0 | Active deprioritization — **do not study** |

**Override rules (apply IN ORDER):**
1. **Lecturer red-flag override:** if lecturer_score = −1 (`[Not covered]`/`[Skip]`/`[FYI only]`), force SKIP regardless of empirical hits.
2. **Lecturer boost override:** if lecturer_score ≥ 8 AND empirical confidence ≥ 0.25, promote one tier.
3. **Recency override:** if topic appeared in BOTH {{LATEST_YEAR}} AND {{LATEST_YEAR_MINUS_1}} (back-to-back), promote one tier.
4. **Floor protection:** Tier 1 requires hit-rate ≥ 0.6. A topic with confidence 0.80 but hit-rate 0.4 (lecturer-inflated) is capped at Tier 2.

**SKIP is its own bucket, NOT Tier 5.** Tier 4 means "spend ≤5% of hours, glance at definitions only." SKIP means "zero hours, do not even read."

### 8.1 — TIER 1 — CERTAIN (≥{{TIER_1_THRESHOLD}}/{{N_YEARS}} papers, confidence ≥ 0.75)

| Rank | Topic | Empirical | Confidence | Marks/year |
|---|---|---|---|---|
| 1 | **{{TIER_1_TOPIC_1}}** | {{T1_HITS_1}} | {{T1_CONF_1}} | {{T1_MK_1}} |
| 2 | **{{TIER_1_TOPIC_2}}** | {{T1_HITS_2}} | {{T1_CONF_2}} | {{T1_MK_2}} |

**Tier 1 total guaranteed marks: ~{{TIER_1_TOTAL}} / {{TOTAL_MARKS}}.**

### 8.2 — TIER 2 — HIGH (2–3/{{N_YEARS}}, confidence 0.50–0.74)

| Rank | Topic | Empirical | Confidence | Notes |
|---|---|---|---|---|
| ... | ... | ... | ... | ... |

### 8.3 — TIER 3 — POSSIBLE (1/{{N_YEARS}}, confidence 0.25–0.49)

{{TIER_3_TABLE}}

### 8.4 — TIER 4 — IGNORE (0/{{N_YEARS}}, confidence 0.05–0.24)

{{TIER_4_LIST}}

### 8.5 — SKIP (active deprioritization — `[Not covered]` or confidence < 0.05)

| Topic | Reason | Source |
|---|---|---|
| {{SKIP_TOPIC_1}} | Lecturer flagged `[Not covered]` | {{SKIP_SOURCE_1}} |
| {{SKIP_TOPIC_2}} | 0 hits AND lecturer_score 0 AND not in syllabus update | {{SKIP_SOURCE_2}} |

---

## Section 8.5 — Lecturer-vs-frequency conflict matrix (4 quadrants)

When lecturer emphasis disagrees with past-paper frequency, use this matrix to decide. Each topic maps to exactly ONE quadrant.

```
                        FREQUENCY (past-paper hits)
                        LOW (≤1/N)              HIGH (≥3/N)
                       ┌──────────────────┬──────────────────┐
                       │                  │                  │
            HIGH       │   Q2: TRUST      │   Q1: ALL-IN     │
            (≥8/10)    │   LECTURER       │   (consensus)    │
                       │                  │                  │
                       │   "New material  │   "Drill until   │
                       │    they want to  │    muscle        │
                       │    test this yr" │    memory"       │
LECTURER               ├──────────────────┼──────────────────┤
EMPHASIS               │                  │                  │
            LOW        │   Q4: SKIP       │   Q3: TRUST      │
            (≤3/10)    │   (or Tier 4)    │   FREQUENCY      │
                       │                  │                  │
                       │   "Probably out  │   "Examiner has  │
                       │    of scope"     │    a habit; bet  │
                       │                  │    on history"   │
                       └──────────────────┴──────────────────┘
```

### Quadrant action rules

| Quadrant | Lecturer | Frequency | Action | Hours allocation |
|---|---|---|---|---|
| **Q1 — ALL-IN** | High | High | Tier 1; drill to muscle memory; this is a guaranteed earner | 20–35% of total |
| **Q2 — TRUST LECTURER** | High | Low | Tier 2; treat as new-material risk; cover definitions + 1 worked example | 10–15% |
| **Q3 — TRUST FREQUENCY** | Low | High | Tier 1 or 2; drill the past-paper template; lecturer may have de-emphasized but examiner is sticky | 15–25% |
| **Q4 — SKIP** | Low | Low | SKIP or Tier 4; if lecturer = −1 → hard SKIP | 0–5% |

### Quadrant assignment table (filled per course)

| Topic | Lecturer score | Hit rate | Quadrant | Final tier | Hours |
|---|---|---|---|---|---|
| {{TOPIC_A}} | {{TOPIC_A_LECT}} | {{TOPIC_A_HR}} | Q? | Tier ? | {{TOPIC_A_HRS}} |
| {{TOPIC_B}} | {{TOPIC_B_LECT}} | {{TOPIC_B_HR}} | Q? | Tier ? | {{TOPIC_B_HRS}} |
| ... | ... | ... | ... | ... | ... |

### Common conflict patterns to flag in the report-back

- **Q2 surprise:** a Tier-1-by-lecturer topic with 0 past-paper hits → IS this a syllabus revision year? Check for explicit "new for {{LATEST_YEAR+1}}" language.
- **Q3 betrayal:** a heavily-flagged `[Not covered]` topic that nonetheless appears 3/5 years → lecturer override of `−1` may be wrong. Re-read slides; if mention exists anywhere, downgrade override to lecturer_score 5 (neutral) and let frequency win.
- **Q4 zombie:** a topic with 0 hits AND lecturer_score 0 BUT in the official syllabus → 5% glance, not full SKIP, in case examiner finally tests it.

---

## Section 9 — {{N_DRILLS}} specific drill questions (highest exam-yield)

<!-- One per Tier-1 topic. Filled end-to-end (problem + worked solution). -->

### Drill 1 — {{DRILL_1_PAPER}} ({{DRILL_1_TOPIC}}, {{DRILL_1_MARKS}} marks)

{{DRILL_1_BODY}}

### Drill 2 — {{DRILL_2_PAPER}}

{{DRILL_2_BODY}}

---

## Section 10 — Time-allocated study plan ({{TOTAL_HOURS}} hours, revised)

| Hours | % | Topic | Quadrant (§8.5) | Justification |
|---|---|---|---|---|
| **{{H1}}** | **{{P1}}%** | **{{TOPIC_A}}** | Q1 | {{TOPIC_A_HITS}} hits, {{TOPIC_A_MARKS}} mks GUARANTEED |
| **{{H2}}** | **{{P2}}%** | **{{TOPIC_B}}** | Q? | {{TOPIC_B_NOTE}} |
| **0.0h** | **0%** | **{{NEVER_TOPICS}}** | Q4 | 0/{{N_YEARS}} hits. **SKIP.** |

**Total: {{TOTAL_HOURS}}h.** Tier-1 alone covers ~{{TIER_1_TOTAL}} marks of expected exam content.

---

## REPORT BACK (REQUIRED)

**(a) Single most-frequent topic (highest empirical priority, highest §B4 confidence):**
{{ANSWER_A}}

**(b) Biggest gap between existing study materials and past-paper evidence:**
{{ANSWER_B}}

**(c) Single most surprising finding (e.g. Q2/Q3 conflict from §8.5):**
{{ANSWER_C}}

**(d) Verbatim-repeat verdict — is there a copy-paste template the student should memorize?**
{{ANSWER_D}}

**(e) Word count:** ~{{WORD_COUNT}} words.

<!-- ============ SC4003 EXAMPLE ANSWERS (REMOVE WHEN INSTANTIATING) ==========
(a) Q4 game theory matrix appears 5/5 papers, identical 4-part structure
    (DS 5mk / NE 8mk / Pareto 7mk / SW 5mk = 25). Confidence 0.95. 25 free
    marks if drilled.

(b) Decision network + EU numerical computation: 4.5/5 hits worth ~25 marks/yr,
    but only briefly mentioned in prior cheat sheets. Coffee-robot reused
    VERBATIM in AY1819 + AY2324 with only numbers changed (§B2 = EXACT,
    Levenshtein 0.97).

(c) Q3 betrayal: Bo An red-flagged "How to calculate Shapley" but full
    numerical Shapley computation has NEVER appeared in 5 years. Meanwhile
    Policy Iteration appeared at 19 marks in AY2122 despite "[Not covered]"
    flag → Q3 quadrant; downgrade override and prioritize PI drill over
    Shapley calculation.

(d) YES. Q4 matrix-game template = EXACT match across 4/5 years (only payoff
    numbers change). Memorize the 4-step answer template (find DS → solve NE
    → Pareto check → SW max). Estimated 25 marks of muscle memory.

(e) ~6,400 words.
=========================================================================== -->
