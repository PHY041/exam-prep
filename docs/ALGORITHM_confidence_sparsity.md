# B4: Confidence Reporting & Sparsity Handling

**Purpose:** When past-paper data is sparse (N < 5), naive frequency analysis produces false signals. This spec defines how confidence is computed, tiered, and reported to the student so they know what to trust.

**Defensibility threshold:** **N ≥ 3** is the absolute minimum for *any* frequency claim. Below that, frequency analysis MUST be suppressed and replaced with lecturer-emphasis-only ranking. (See § 6 for justification.)

---

## 1. Global confidence tiers (based on N papers available)

`N` = number of distinct past papers the corpus contains for this course.

| N (papers) | Global tier | Frequency analysis | Student-facing label |
|------------|-------------|--------------------|----------------------|
| **≥ 5** | HIGH | Run normally. Per-topic tiers (§ 2) apply. | "5+ years of data — frequency signals are reliable." |
| **3–4** | MEDIUM | Run, but every recommendation must carry a `[MEDIUM CONFIDENCE]` flag. | "Only 3–4 years of data — patterns suggestive, not definitive." |
| **1–2** | LOW | **DO NOT report frequency.** Frequency analysis is statistically meaningless at N≤2. Fall back to **lecturer-emphasis-only** ranking. | "Too few past papers for trend analysis. Ranking based on lecturer emphasis only." |
| **0** | NONE | **SKIP frequency module entirely.** Output a single banner. | "No past papers available. Study the syllabus + lecturer's flagged topics." |

**Hard rule:** if N ≤ 2, the `frequency_score` field is `null` in all internal data structures, and the report renders a top-of-page disclaimer banner.

---

## 2. Per-topic confidence formula (only when N ≥ 3)

For each topic `t`, count `hits(t)` = number of papers in which the topic appears.

| Per-topic tier | Hit threshold | Meaning |
|----------------|---------------|---------|
| **Tier 1 — CERTAIN** | `hits(t) ≥ 0.8 × N` | Appears in 80%+ of papers. Effectively guaranteed. |
| **Tier 2 — HIGH** | `0.5N ≤ hits(t) < 0.8N` | Appears in majority of papers. Strong signal. |
| **Tier 3 — MEDIUM** | `0.2N ≤ hits(t) < 0.5N` | Appears in a minority. Possibly cyclical. |
| **Tier 4 — LOW / SKIP** | `hits(t) < 0.2N` | Below noise floor. Do not include in primary plan. |

**Worked example (N=5, SC4003):**

| hits | tier | examples |
|------|------|----------|
| 5/5 | CERTAIN | Bellman update, Value Iteration |
| 4/5 | HIGH | Policy Iteration |
| 2/5 | MEDIUM | POMDPs |
| 1/5 | LOW | Shapley value calculation |

**Worked example (N=3):**

| hits | tier | rule |
|------|------|------|
| 3/3 | CERTAIN | ≥ 0.8 × 3 = 2.4 → need 3 |
| 2/3 | HIGH | ≥ 0.5 × 3 = 1.5 → need 2 |
| 1/3 | MEDIUM | ≥ 0.2 × 3 = 0.6 → need 1 |
| 0/3 | LOW | excluded |

Note: at N=3, MEDIUM and LOW collapse — anything that appeared even once clears the 0.2N floor. This is why the **global** MEDIUM-confidence flag (§ 1) is required: per-topic tiers alone underrepresent uncertainty at low N.

---

## 3. Reporting templates (student-facing)

These are the canonical strings rendered in the study plan output. `{topic}`, `{hits}`, `{N}`, `{last_year}` are interpolated.

### CERTAIN (Tier 1)
```
✅ {topic} — {hits}/{N} years confirmed. Drill this for ~25 marks.
```

### HIGH (Tier 2)
```
🟢 {topic} — {hits}/{N} years. Strong recurrence; allocate full study session.
```

### MEDIUM (Tier 3)
```
🟡 {topic} — {hits}/{N} years. Likely but not guaranteed. Review notes, do 1 past Q.
```

### LOW (Tier 4)
```
🔴 {topic} — {hits}/{N} years (last seen {last_year}). Could be cyclical, could be retired. Allocate small time only.
```

### Global LOW (N=1–2) — top-of-report banner
```
⚠️  LOW DATA: only {N} past paper{s} available. Frequency trends cannot be computed.
    Ranking below uses LECTURER EMPHASIS only. Treat all "predictions" as suggestive.
```

### Global NONE (N=0) — top-of-report banner
```
⚠️  NO PAST PAPERS. Frequency analysis skipped. Study the full syllabus,
    weighted by lecturer's in-class emphasis (see § 5).
```

---

## 4. Recency weighting

A topic that appeared in the **last 2 years** is upweighted. Rationale: syllabi drift; a topic seen 5 years ago and never since is likely retired, while a topic seen this year and last year is hot.

```python
def recency_score(hits_years: list[int], max_year: int) -> float:
    """
    hits_years: list of years the topic appeared, e.g. [2019, 2021, 2023]
    max_year:   most recent year in the corpus, e.g. 2023
    Returns weighted hit count.
    """
    return sum(1.5 if y >= max_year - 1 else 1.0 for y in hits_years)
```

**Example:** SC4003 corpus 2019–2023 (`max_year=2023`).
- Topic A appears in [2019, 2020, 2023] → score = 1.0 + 1.0 + 1.5 = **3.5**
- Topic B appears in [2022, 2023] → score = 1.5 + 1.5 = **3.0**

Topic B has fewer raw hits but higher recency. Both stay in HIGH tier; recency breaks ties when ordering the study plan.

**Tier classification still uses raw `hits` count** (§ 2). Recency only re-orders within a tier and never promotes a topic across tiers — that would let a single recent appearance masquerade as a multi-year trend.

---

## 5. Lecturer-vs-frequency conflict reporting (4 quadrants)

Every topic falls into one of four quadrants based on two binary axes:
- **Lecturer emphasis** — flagged in lecture notes / "this is important" markers (Y/N)
- **Frequency** — appears in ≥ 0.5N papers (Y/N)

| | Frequent (≥ 0.5N) | Not frequent (< 0.5N) |
|---|---|---|
| **Emphasized** | **CERTAIN** — drill heavily | **TRAP WATCH** — could be the year it gets asked |
| **Not emphasized** | **BLUE OCEAN** — known-to-be-asked, low coverage | **SKIP** — no signal from either source |

### Quadrant labels (in-report)

**CERTAIN** — `Both lecturer and past papers confirm. Maximum priority.`

**TRAP WATCH** — `Lecturer flagged, but 0/{N} past papers. Could be cyclical or new addition. Allocate 30 min review only — don't sink hours.`
> *Example:* Bo An red-flagged Shapley value calculation in SC4003, but it's 0/5 in past papers. Classify as TRAP WATCH, not CERTAIN. Read the slides; don't drill it.

**BLUE OCEAN** — `Past papers ask this often, but lecturer didn't dwell. Easy marks if studied — high ROI.`

**SKIP** — `No signal. Don't study unless time remains after all other tiers.`

### Required behavior

1. The study plan MUST surface **all four quadrants** explicitly. Hiding TRAP WATCH or BLUE OCEAN destroys the conflict-resolution value-add.
2. TRAP WATCH items appear in their own section, never mixed into the CERTAIN list.
3. When N ≤ 2, the entire quadrant grid degenerates — only the lecturer-emphasis axis is reported. Render this as a 1×2 list, not a 2×2 grid.

---

## 6. Why N ≥ 3 is the defensibility floor

Question to caller: *"Minimum N for any frequency claim to be defensible?"*

**Answer: N = 3.**

Reasoning:
- **N = 1:** A "100% frequency" topic just means it appeared in the only paper you have. Zero information about recurrence — you've sampled a population of size 1.
- **N = 2:** A topic appearing in both papers gives you a 2-point trend, which cannot distinguish "always asked" from "coincidence." 2/2 and 1/2 are both within noise. Calling 2/2 "guaranteed" is the kind of overclaim that destroys trust when the prediction misses.
- **N = 3:** The minimum where a topic appearing in all 3 (3/3) starts to look like a pattern rather than coincidence. Still weak — that's why N=3–4 carries the global MEDIUM flag — but it crosses the threshold where the signal-to-noise ratio justifies showing the number to the student.
- **N ≥ 5:** Standard threshold for routine frequency reporting without disclaimers.

**Therefore:** below N = 3, the spec replaces frequency analysis with lecturer-emphasis-only ranking and a visible disclaimer. Reporting "1/2 years" as a trend is not defensible and is forbidden.

---

## 7. Implementation checklist

- [ ] `N` computed and stored as a top-level field of every plan
- [ ] If N ≤ 2: frequency module disabled, banner rendered, plan ranked by lecturer-emphasis only
- [ ] If N == 0: frequency module skipped entirely, NONE banner rendered
- [ ] If N == 3 or 4: every recommendation carries `[MEDIUM CONFIDENCE]` tag
- [ ] Per-topic tiers computed using raw `hits` thresholds in § 2
- [ ] Recency score computed but used only for intra-tier ordering, never for tier promotion
- [ ] All four conflict quadrants surfaced with their canonical labels
- [ ] TRAP WATCH section rendered separately from CERTAIN
- [ ] Templates in § 3 used verbatim — no ad-hoc wording per course
