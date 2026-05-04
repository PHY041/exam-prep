# E2 — MCQ Adapter

**Scope:** High-volume multiple-choice exams where the answer is binary (right/wrong) and the corpus is too broad for verbatim drilling.

**Canonical exams:** USMLE Step 1, FE / PE engineering, CFA L1–L3, MCAT, AP exams (Bio, Chem, Calc), bar prep MBE, NCLEX, GRE, ASVAB.

**Why a separate adapter:** Default `exam-prep` pipeline assumes ~6–12 long-form questions per paper, dense lecturer-emphasis fingerprints, and PDF "topic packs" as the deliverable. MCQ exams break every one of those assumptions:

| Default pipeline assumes | MCQ reality |
|---|---|
| 6–12 questions / paper | 100–300 questions / paper |
| Verbatim phrasing matters (essays, derivations) | Distractors rotate; concepts repeat |
| Marking is partial-credit | Binary right/wrong |
| Topic packs (~20) PDFable | Topic count too large to PDF (50–200 micro-topics) |
| Spaced repetition optional | SRS is the entire game |
| Lecturer emphasis = strong signal | Past papers themselves ARE the emphasis signal |

---

## 1. Pipeline differences (vs. default `exam-prep`)

```
Default (E1 STEM)                  MCQ adapter (E2)
─────────────────                  ────────────────
Past papers ────────►              Past papers (>=3) ───────────►
   │                                   │
   │ frequency analysis                │ frequency analysis
   ▼                                   ▼ (per micro-topic)
Topic ranking (20 topics)          High-yield topic ranking (50-200 micro-topics)
   │                                   │
   │                                   │ allocate cards by yield (Pareto: top 20% topics → 80% cards)
   ▼                                   ▼
Lecturer fingerprint               Question-bank ingestion (past Qs + generated)
   │                                   │
   ▼                                   ▼
Topic packs (PDF)        ◄── SKIP    Anki deck generation (.csv / .apkg)
   │                                   │
   ▼                                   ▼
Master plan (PDF)                  Master plan (1 PDF) + Anki deck + import script
                                       │
                                       ▼
                                   Confidence-weighted re-generation
                                   (only weak topics, after first review pass)
```

### Stages (overrides)

1. **`ingest_past_papers`** — same as default but expects MCQ format. Parser extracts `(stem, options[A-E], correct_letter, topic_tag, year)`. Supports common past-paper formats: NBME, AAMC, official CFA mocks, FE reference handbook practice, AP released exams.
2. **`frequency_analysis`** — count occurrences per micro-topic across all years. **Output:** `topic_yield.json` ranked by appearance count × recency weight (recent papers count 1.5x).
3. **SKIP `topic_packs`** — explicitly disabled. Reasoning: 50–200 micro-topics × 4 pages each = 800-page deliverable nobody reads. Anki replaces this.
4. **SKIP `lecturer_fingerprint`** — for licensing/standardized exams there is no lecturer. Past papers ARE the emphasis signal.
5. **`anki_generation`** — produce CSV (default) or `.apkg` (optional, requires `genanki`). See §2.
6. **`high_yield_allocation`** — distribute card budget by yield rank. See §3.
7. **`master_plan`** — single PDF with: study calendar, daily Anki target, weak-topic review cadence, exam-day strategy. ~10 pages max.
8. **`confidence_loop`** — after first review pass (user marks each card again/hard/good/easy in Anki), re-export weak topics and generate **fresh** questions only for those. See §4.

### Config knobs (in `exam-prep.yaml`)

```yaml
adapter: mcq
mcq:
  total_card_budget: 2000          # typical USMLE Step 1 prep
  yield_pareto_split: [0.2, 0.8]   # top 20% topics → 80% cards
  recency_weight: 1.5              # recent papers count more
  min_past_papers: 3               # see report-back at end
  generate_distractors: true       # synthesize 3 wrong options when source has only stem+answer
  anki_format: csv                 # csv | apkg
  difficulty_levels: [easy, medium, hard]
  confidence_threshold: 0.7        # below this = "weak topic" for re-generation
  srs_algorithm: anki_default      # anki_default | sm2_minimal | leitner_5box
```

---

## 2. Anki integration

### 2.1 CSV schema (default)

Tab-separated, importable directly via Anki's *File → Import* with field mapping. One row = one card.

```
field_1: question         # stem + options (formatted)
field_2: answer           # correct letter + 1-line explanation + source citation
field_3: topic_tag        # hierarchical: cardio::pharmacology::beta_blockers
field_4: subtopic_tag     # finer: beta_blockers::contraindications
field_5: difficulty       # easy | medium | hard
field_6: yield_rank       # 1 = highest-yield (used for sort/filter)
field_7: source           # "USMLE 2021 Q47" or "generated:gpt-5.4"
field_8: extra            # mnemonics, related-concept links, image refs
```

**Tags column:** Anki interprets the last column as space-separated tags. Map `topic_tag` and `difficulty` here so Anki's tag browser works:

```
cardio_pharmacology_beta_blockers difficulty_medium yield_top20
```

### 2.2 Card formatting

Front (question side):

```html
<div class="stem">A 58-year-old man with HTN and asthma...</div>
<div class="options">
  A. Propranolol
  B. Metoprolol
  C. Atenolol
  D. Carvedilol
  E. Labetalol
</div>
```

Back (answer side):

```html
<div class="answer">B. Metoprolol</div>
<div class="explanation">Cardioselective β1 blocker — safe in asthma. Propranolol/carvedilol/labetalol are non-selective and contraindicated.</div>
<div class="source">USMLE Step 1 2021 Q47 · yield_rank: 12</div>
```

### 2.3 .apkg output (optional)

When `anki_format: apkg`, generate via `genanki` (Python). Pre-baked deck with model, styling, and tags. User double-clicks → Anki imports automatically. Useful for distribution; CSV is better for personal iteration.

### 2.4 Folder structure delivered

```
out/exam_prep_v2/<exam_id>/
  master_plan.pdf
  anki/
    deck.csv                # main import
    deck.apkg               # optional
    import_instructions.md  # 30-sec how-to
    media/                  # images referenced by cards (if any)
  raw/
    topic_yield.json
    past_papers_index.json
    weak_topics_round_1.json   # populated after confidence loop
```

**No PDF topic packs.** Per spec.

---

## 3. High-yield ranking (5x rule)

Topic yield = `(appearance_count × recency_weight) / total_questions_across_all_papers`.

### Card allocation

```
top 20% of topics by yield  → 5x card density (e.g., 50 cards/topic)
middle 50% of topics        → 1x density (10 cards/topic)
bottom 30% of topics        → 0.5x density (5 cards/topic) or skip if budget tight
```

**Worked example — USMLE Step 1, budget 2000 cards, 100 micro-topics:**

| Tier | Topics | Cards/topic | Total cards | % of deck |
|---|---|---|---|---|
| Top 20% (high-yield) | 20 | 50 | 1000 | 50% |
| Middle 50% | 50 | 10 | 500 | 25% |
| Bottom 30% | 30 | 5 (or skip) | 150 (or 0) | 7.5% (or 0) |
| Buffer (new/weak topics from confidence loop) | — | — | 350+ | 17.5%+ |

### Sourcing per topic

For each topic at allocation `N`:
1. **First fill from past papers** (real Qs, highest fidelity).
2. **Then synthesize** with LLM (gpt-5.4) using the past-paper Qs as few-shot exemplars. Prompt enforces: same stem length, same difficulty register, distractor plausibility checked against topic ontology.
3. **Tag synthesized cards** clearly (`source: generated:gpt-5.4`) so user can filter them out if they prefer real-only.

---

## 4. Adaptive review schedule

### 4.1 Default: lean on Anki's built-in SRS

Anki ships with a modified SM-2 algorithm (FSRS available in v23.10+). For 95% of users, this is correct. The adapter:
- Sets sane defaults: new cards/day = `total_budget / days_until_exam`, max reviews/day = `new_cards_per_day × 10`.
- Pre-tags cards by yield so user can prioritize: `yield_top20` filter → study high-yield first when behind schedule.
- Writes recommended Anki settings into `import_instructions.md` (learning steps `15m 1d`, graduating interval `3d`, easy interval `4d`).

### 4.2 Optional: minimal Leitner box (offline / non-Anki users)

For users without Anki (paper flashcards, custom app), adapter can emit a 5-box Leitner schedule:

```
Box 1: review daily          (new cards land here)
Box 2: review every 2 days   (got it right once)
Box 3: review every 4 days
Box 4: review weekly
Box 5: review biweekly       (mastered — surface 2 weeks pre-exam)

Rule: wrong → drop to Box 1. Right → advance one box.
```

Output: `leitner_schedule.csv` — date column, list of card IDs to review that day. Generate for `days_until_exam` days.

### 4.3 Calibration to exam date

Adapter computes:
- **Days remaining** = `exam_date - today`
- **New cards/day** = `total_cards / (days_remaining × 0.7)` (reserve 30% for review-only sprint)
- **Final 14 days = review-only**, no new cards. Hardcoded into master plan calendar.

---

## 5. Past-paper integration as ground truth

For MCQ exams, **past papers ARE the high-yield signal.** No lecturer fingerprint needed.

### Inputs

- `past_papers/` directory: PDFs, Markdown, or pre-parsed JSON.
- Optional `topic_ontology.yaml`: hierarchical topic tree (e.g., USMLE: organ system → discipline → mechanism). Without it, adapter clusters questions by embedding similarity.

### Frequency extraction

```python
def compute_topic_yield(papers: list[Paper], ontology: TopicTree | None) -> dict[str, float]:
    """
    Returns {topic_id: yield_score} where score = (count * recency_weight) / total_questions.
    If ontology is None, cluster questions via embeddings (k=50-200) and label clusters via LLM.
    """
```

### Recency weighting

```
weight(year) = 1 + 0.5 * max(0, (year - (current_year - 5)) / 5)
# Most recent year: 1.5x. Five years ago: 1.0x. Older: 1.0x floor.
```

Rationale: exam boards rotate emphasis. Last 3 years predict next year better than 10-year-old papers.

### Distractor mining

Past-paper distractors are gold — they're the wrong answers exam writers thought were tempting. When generating new cards for a topic, prompt the LLM with real distractors as exemplars:

```
Topic: beta-blocker contraindications
Real distractors seen in past papers: [propranolol, carvedilol, labetalol]
→ When generating new Qs, prefer plausible cardioselective vs non-selective traps.
```

---

## 6. Confidence-based re-generation loop

After user finishes one review pass through the deck (typically week 2–3), they export Anki review log:

```
Anki → File → Export → "Cards in Plain Text" → include scheduling info
```

Or use Anki's Python `anki` package to read `collection.anki2` directly.

### Adapter reads:

```python
@dataclass
class CardStats:
    card_id: str
    topic: str
    again_count: int   # times marked "again" (failed)
    review_count: int
    success_rate: float  # = 1 - (again_count / review_count)
```

### Weak-topic detection

```
weak_topic = topic where mean(success_rate across cards) < confidence_threshold (default 0.7)
```

### Re-generation

For each weak topic:
1. Generate **fresh** questions (not duplicates) — different stem framings, different correct answers within the topic.
2. Add to deck under tag `round_2` or `weak_<topic>`.
3. Bump these cards to top of new-card queue in Anki via `due` field manipulation.

Output: `weak_topics_round_1.json` + new cards appended to `deck.csv`.

**No regeneration for topics already at success_rate ≥ 0.7.** That's the whole point — don't waste reps on what's solid.

---

## 7. No PDF deliverables (except master plan)

Hard rule. Outputs:
- `master_plan.pdf` (1 file, ~10 pages): study calendar, daily targets, weak-topic policy, exam-day checklist.
- `anki/deck.csv` (or `.apkg`): the actual study material.
- `anki/import_instructions.md`: 30-second setup.

**Explicitly omitted vs. default pipeline:** topic packs PDF, lecturer fingerprint report, per-topic worksheet PDFs.

Reason: MCQ prep is a flow (review every day), not a document (read once). Anything not in the SRS queue is a distraction.

---

## 8. Implementation hooks (in `exam-prep` skill)

```python
# exam_prep/adapters/mcq.py

from .base import Adapter

class MCQAdapter(Adapter):
    name = "mcq"
    skip_stages = {"topic_packs", "lecturer_fingerprint"}
    requires = {"min_past_papers": 3}

    def run(self, ctx: Context) -> Outputs:
        papers = ctx.ingest_past_papers()
        if len(papers) < self.requires["min_past_papers"]:
            raise InsufficientDataError(
                f"MCQ adapter needs >=3 past papers; got {len(papers)}. "
                f"Fall back to E1 default adapter or supply more sources."
            )
        yield_map = self._frequency_analysis(papers, ctx.ontology)
        cards = self._allocate_and_generate(yield_map, papers, ctx.config)
        self._emit_anki(cards, ctx.out_dir / "anki")
        self._emit_master_plan(yield_map, ctx.exam_date, ctx.out_dir)
        # confidence loop is invoked separately via `exam-prep mcq refresh`

    def refresh(self, ctx: Context) -> Outputs:
        """Called after week-2 review pass — re-generate weak topics only."""
        stats = ctx.read_anki_stats()
        weak = [t for t, s in stats.topic_success.items() if s < ctx.config.confidence_threshold]
        new_cards = self._regenerate(weak, ctx)
        self._append_anki(new_cards, ctx.out_dir / "anki" / "deck.csv")
```

Detection trigger (in main `exam-prep` entry):

```python
def detect_adapter(papers: list[Paper]) -> str:
    avg_q_per_paper = mean(len(p.questions) for p in papers)
    if avg_q_per_paper >= 50 and all(p.format == "mcq" for p in papers):
        return "mcq"
    return "default"
```

---

## 9. Quality gates (MCQ-specific)

| Gate | Threshold | Action if failed |
|---|---|---|
| Past-paper count | >= 3 | Raise `InsufficientDataError` |
| Topic coverage of past Qs | >= 80% questions tagged | Cluster untagged via embeddings, surface for review |
| Distractor plausibility (synthesized cards) | LLM-judge score >= 0.7 | Regenerate distractors |
| Duplicate card detection | <2% near-duplicates (cosine sim > 0.92 on stems) | Dedupe before emit |
| Card budget vs. days remaining | new/day <= 50 (sustainable cap) | Warn user; suggest extending timeline or trimming bottom-tier topics |

---

## Report-back: minimum past-paper count for MCQ adapter to be valuable

**Answer: 3 past papers (hard minimum). 5+ for reliable yield ranking. 8+ for stable recency-weighted ranking.**

Reasoning:

| Past papers available | Yield-ranking reliability | Adapter recommendation |
|---|---|---|
| 0–1 | None — no frequency signal | **Don't use MCQ adapter.** Fall back to default E1 adapter or third-party qbank (UWorld, NBME, etc.). |
| 2 | Coin-flip — single anomaly distorts ranking | Marginal. Use only if you have a `topic_ontology.yaml` with ground-truth weights from the exam board's official content outline. |
| **3 (hard minimum)** | First point where Pareto split is statistically meaningful (top 20% topics emerge from noise) | **Adapter activates.** This is the floor enforced in `requires.min_past_papers`. |
| 5 | Ranking stabilizes; cross-year topic shifts visible | **Recommended.** This is where the 5x high-yield allocation pays off. |
| 8+ | Recency weighting becomes meaningful (5-year sliding window populated) | **Optimal.** Recency weight (1.5x for last year) actually shifts allocations. |
| 10+ | Diminishing returns — older papers add noise, not signal | Cap analysis at last 8–10 years. |

**Why 3 and not 2:** With 2 papers, any topic appearing in both looks "high-yield" and any topic appearing in one looks "low-yield" — but a 1/2 vs 2/2 hit rate is not statistically distinguishable from random. With 3 papers, the Pareto split (top 20% covering ~80% of question volume) starts to emerge as a stable signal across runs.

**Fallback policy:** If user has <3 past papers, adapter raises `InsufficientDataError` with two recommendations:
1. Use default E1 adapter (concept-based, lecturer-fingerprint-driven).
2. Supplement with an official content outline (e.g., USMLE Content Description, CFA Learning Outcome Statements) treated as a synthetic "past paper" with uniform topic weights.

**Bonus signal — exam-board content outlines count as 0.5 papers:** Most licensing bodies publish official topic weights. If available, ingest as a synthetic paper with `recency_weight=2.0` (it IS the source of truth). This effectively lowers the past-paper minimum to 2 real + 1 outline.
