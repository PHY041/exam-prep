# B1 — Topic Normalization Across Years

**Problem.** A single underlying concept appears under different surface phrasings across past papers. Example from SC4003:

| Year   | Surface phrasing                                        | True topic              |
|--------|---------------------------------------------------------|-------------------------|
| AY2021 | "Vickrey auction truthfulness"                          | `second_price_ic`       |
| AY2122 | "Second-price sealed-bid incentive compatibility"       | `second_price_ic`       |
| AY2223 | "Show that bidding true value is a dominant strategy"   | `second_price_ic`       |

If the frequency table is built on raw question text, these collapse to three different rows and the topic looks rare. We need a deterministic mapping `question → canonical_topic_id`.

This document specifies the algorithm.

---

## 1. Two-Tier Ontology

We separate **what topics exist** (Tier 1, closed set) from **which topic a question instantiates** (Tier 2, classification).

### Tier 1 — Controlled Vocabulary `V`

`V` is a closed, course-specific set of canonical topic IDs. It is built **once per course-offering** and frozen before classification.

Sources, in order of authority:

1. **Lecture slide TOC / section headings** (primary). Every numbered section becomes a candidate topic.
2. **Lecturer's red-flagged items** from the review session ("this *will* be on the exam", "make sure you can do X"). These get a `lecturer_emphasized: true` flag on the topic record.
3. **Tutorial / problem-set headings** (tertiary, only if 1 and 2 are sparse).

Each entry in `V` has the schema:

```json
{
  "topic_id": "second_price_ic",
  "display_name": "Second-Price Auction Incentive Compatibility",
  "aliases": ["Vickrey auction", "VCG single-item", "sealed-bid second-price"],
  "parent": "auction_theory",
  "lecturer_emphasized": true,
  "source_slides": ["L7-Auctions", "L8-Mechanism-Design"]
}
```

`topic_id` is `snake_case`, stable across the course, and used as the join key.

### Tier 2 — Per-Question Tagging

Each past-paper sub-question gets exactly one **primary** `topic_id` from `V`, and optionally one **secondary** topic if the question genuinely spans two areas (e.g. a Shapley-value question framed in a data-pricing context).

Tagging is done by an LLM classifier constrained to `V` (closed-set classification, not free-form generation). Confidence below threshold flags for human review.

---

## 2. Algorithm — Pseudocode

```python
def normalize_topics(
    papers: list[Paper],              # parsed past papers, each with sub-questions
    lecture_slides: list[Slide],      # parsed slide decks (PDF -> text)
    lecturer_review: ReviewNotes,     # transcribed review-session red flags
    confidence_threshold: float = 0.70,
) -> list[QuestionTopic]:
    """
    Map every past-paper sub-question to a canonical topic in V.
    Returns a list of QuestionTopic records (see §5 for schema).
    """

    # ── Phase A: Build controlled vocabulary V ────────────────────────────
    candidates_slides   = llm_extract_topics(lecture_slides)        # ~30-80 candidates
    candidates_review   = llm_extract_topics(lecturer_review)       # ~10-20 candidates
    V_raw               = candidates_slides + candidates_review

    # Dedup by semantic similarity (embedding cosine ≥ 0.85 → same topic)
    V = semantic_dedupe(V_raw, sim_threshold=0.85)

    # Mark lecturer-emphasized topics
    for t in V:
        t.lecturer_emphasized = any_match(t, candidates_review)

    # Human gate: lecturer (or TA) reviews V before tagging starts.
    # This is a 15-min pass — much cheaper than re-tagging on a wrong V.
    V = human_review_vocabulary(V)         # blocking step

    # ── Phase B: Tag each sub-question against V ──────────────────────────
    tagged: list[QuestionTopic] = []
    for paper in papers:
        for q in paper.sub_questions:
            scores = llm_classify_closed_set(
                question_text = q.text,
                vocabulary    = V,
                top_k         = 2,         # need top-1 and top-2 for tie/secondary logic
            )
            top1, top2 = scores[0], scores[1]

            record = QuestionTopic(
                paper           = paper.id,
                qid             = q.id,
                topic           = top1.topic_id,
                confidence      = top1.score,
                secondary_topic = top2.topic_id if top2.score >= 0.30 else None,
                needs_review    = top1.score < confidence_threshold,
            )
            tagged.append(record)

    # ── Phase C: Conflict resolution + human-in-loop ──────────────────────
    tagged = resolve_ties(tagged, V)                          # see §3
    flagged = [r for r in tagged if r.needs_review]
    tagged  = human_review_flagged(tagged, flagged)           # blocking if flagged > 0

    return tagged
```

**Why a closed-set classifier rather than free generation.** Free-generation tagging produces synonyms-of-synonyms and re-introduces the original problem. We force the LLM to pick from `V` (e.g. by passing `V` in the prompt and asking for an index, or via constrained decoding).

**LLM choice.** Use `gpt-5.4` (per machine policy). Prompt template lives at `/tmp/exam_prep_v2/templates/topic_classify_prompt.md`.

---

## 3. Conflict Resolution

A "tie" means the top-2 topics from the classifier are within `0.05` of each other. Three deterministic rules, tried in order:

| Rule | Condition                                                                 | Action                                                          |
|------|---------------------------------------------------------------------------|-----------------------------------------------------------------|
| R1   | One candidate has `lecturer_emphasized: true`, the other does not         | Pick the emphasized one as primary, the other as `secondary`.   |
| R2   | Candidates share a `parent` topic                                          | Pick the `parent` as primary; both children become `secondary`. |
| R3   | None of the above                                                         | Mark `needs_review=true`, defer to human.                       |

Rationale: R1 honours the lecturer's signal, which is the highest-quality prior. R2 prevents over-fragmentation when two leaves of the same subtree both fit. R3 refuses to silently coin-flip.

We never split a single question into "0.5 of topic A + 0.5 of topic B" in the frequency table — that destroys the count semantics. Secondary topics are tracked separately and weighted at `0.5` only when computing a *secondary-frequency* table (used purely as a tiebreaker in study-plan ranking, never as the headline number).

---

## 4. Sparsity Handling

With only a handful of papers, raw frequency counts are noisy. We handle this with three knobs.

### 4.1 Confidence bands by `N` (number of past papers)

| `N` | Frequency analysis status                  | What we do                                                                             |
|-----|--------------------------------------------|----------------------------------------------------------------------------------------|
| 1   | **Anecdote.** Not statistically meaningful | Skip the frequency table entirely. Rank topics by `lecturer_emphasized` only.          |
| 2   | **Weak signal**                            | Show frequency but **fuse 70/30 with lecturer emphasis**: `score = 0.3·freq + 0.7·emp` |
| 3   | **Usable**                                 | Fuse 50/50: `score = 0.5·freq + 0.5·emp`                                               |
| 4   | **Solid**                                  | Fuse 60/40 (freq dominant): `score = 0.6·freq + 0.4·emp`                               |
| 5+  | **Confident**                              | Fuse 70/30 (freq dominant): `score = 0.7·freq + 0.3·emp`                               |

`emp ∈ {0, 1}` is the lecturer-emphasis indicator. `freq` is the share-of-questions on that topic, normalized to `[0, 1]`.

### 4.2 Smoothing

For `N ≤ 4`, apply Laplace smoothing to avoid zero-counts: `freq(t) = (count(t) + 1) / (total_q + |V|)`. This pulls unseen topics off the floor, which matters because "topic never appeared in N=3 papers" is *not* strong evidence the topic won't appear this year.

### 4.3 Minimum viable `N`

**Minimum viable `N` for confident frequency-driven ranking is 4.**

Reasoning, based on SC4003-style papers (~10 sub-questions per paper, ~25-40 topics in `V`):

- `N=4` gives ~40 sub-question samples against ~30 topics — average ~1.3 hits per topic, enough that a topic appearing 3+ times is signal, not noise.
- Below `N=4`, lecturer emphasis must dominate the ranking; frequency is a tiebreaker, not the lead signal.
- At `N=3`, we still produce a ranking but explicitly label it "lecturer-weighted" in the output.
- At `N≤2`, we refuse to ship a frequency table and surface only the lecturer-emphasis list.

The confidence bands in §4.1 implement this: the freq weight only crosses 0.5 at `N=3` and only dominates at `N=4+`.

---

## 5. Output Schema

One JSON record per sub-question. Stored as JSONL at `/tmp/exam_prep_v2/output/question_topics.jsonl`.

```json
{
  "paper": "AY2324",
  "qid": "Q3a",
  "topic": "shapley_value",
  "confidence": 0.92,
  "secondary_topic": "data_pricing",
  "secondary_confidence": 0.41,
  "needs_review": false,
  "review_reason": null,
  "classifier_model": "gpt-5.4",
  "vocabulary_version": "sc4003-2026-04-28-v1"
}
```

Field notes:

- `topic` and `secondary_topic` MUST be members of the frozen `V` (referenced by `vocabulary_version`).
- `secondary_topic` is `null` unless the second-place score ≥ `0.30`.
- `needs_review=true` triggers a human pass; `review_reason ∈ {"low_confidence", "tie_unresolved", "off_vocabulary"}`.
- `vocabulary_version` lets us re-run frequency analysis if `V` is later revised without re-classifying everything from scratch.

---

## 6. Failure Modes & Mitigations

| Failure mode                                              | Mitigation                                                                       |
|-----------------------------------------------------------|----------------------------------------------------------------------------------|
| `V` misses a topic that actually appears in a paper       | Classifier returns low confidence everywhere → `needs_review=true` → human adds. |
| Lecturer review is verbal/unstructured                    | Transcribe first, then run `llm_extract_topics` on the transcript.               |
| LLM hallucinates a `topic_id` not in `V`                  | Constrained decoding; on violation, fall back to embedding nearest-neighbour.    |
| Two papers' Q3 are nearly identical wording               | Expected — they correctly map to the same topic. This is the whole point.        |
| `V` drift across course offerings                         | Pin `vocabulary_version`. Don't merge frequencies across vocabulary versions.    |

---

## 7. Summary

- Two-tier ontology: closed vocabulary `V` (Tier 1, built once, lecturer-validated) → per-question tags (Tier 2, LLM-classified into `V`).
- Conflict resolution prefers lecturer-emphasized topics, then parent topics, then defers to human.
- Sparsity handled by fusing frequency with lecturer emphasis on a sliding weight that depends on `N`.
- **Minimum viable `N` for confident frequency analysis is 4.** Below that, lecturer emphasis carries the ranking.
