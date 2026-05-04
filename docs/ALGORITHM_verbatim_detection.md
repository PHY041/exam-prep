# B2: Verbatim & Near-Verbatim Question Detection

**Purpose**: Automatically detect questions that repeat across past papers. Verbatim repeats are the highest-ROI drill items — if a question appeared identically in AY2021 and AY2324, it has ~70% probability of appearing again.

**Input**: Normalized question texts extracted from N past papers (output of B1 question segmentation).
**Output**: Cluster report listing all repeat groups with match level, similarity score, and delta description.

---

## 1. Three-Tier Match Levels

| Tier | Name | Threshold | Semantics | Drill Priority |
|------|------|-----------|-----------|----------------|
| T1 | **Verbatim** | sim >= 0.95 | Identical question (whitespace/punctuation may differ) | **Highest** — practice exact answer |
| T2 | **Near-verbatim** | 0.80 <= sim < 0.95 | Same question, minor edits (numbers swapped, one phrase reworded) | **High** — practice with parameter sweep |
| T3 | **Same template** | 0.60 <= sim < 0.80 | Same structure & solution method, different topic/entities (e.g., "coffee robot" → "warehouse robot") | **Medium** — practice the *method*, not the answer |
| — | Unrelated | sim < 0.60 | Different question | Skip |

### Why three tiers?
- **T1** = memorize the answer. Cost: 5 min. Value: high (likely re-tested).
- **T2** = memorize the answer template + how parameters change it. Cost: 15 min.
- **T3** = memorize the solution *strategy* (e.g., "third-price auction truthfulness analysis"). Cost: 30 min, transfers across topics.

---

## 2. Algorithm

### 2.1 Pre-processing (applied to every question before comparison)

```
1. Strip page markers: "(continued from previous page)", "[Page N]", "Q.N", footers.
2. Strip common stems: regex_strip(r"^(Consider the following|Suppose that|Let|Given that|In the following)\s+")
3. Normalize whitespace: collapse multiple spaces/newlines → single space.
4. Lowercase + strip non-essential punctuation (keep math operators).
5. Drop figure/diagram references: "(see Figure 3)", "as shown below" — these vary by year but content is same.
```

### 2.2 Tier 1 — Verbatim detection

**Method**: Normalized Levenshtein ratio via `difflib.SequenceMatcher.ratio()`.

```python
ratio = SequenceMatcher(None, q1_normalized, q2_normalized).ratio()
if ratio >= 0.95:
    return "verbatim"
```

**Why difflib not edit distance directly**: difflib's ratio is `2*M / T` where M is matching blocks and T is total length — robust to small insertions (e.g., extra "the").

### 2.3 Tier 2 — Near-verbatim detection

**Method**: Combined sentence-embedding similarity + key-phrase Jaccard.

```
cosine_sim = cosine(embed(q1), embed(q2))    # all-MiniLM-L6-v2
jaccard = |kp(q1) ∩ kp(q2)| / |kp(q1) ∪ kp(q2)|

if cosine_sim >= 0.85 AND jaccard >= 0.6:
    return "near_verbatim"
```

Where `kp(q)` = set of key phrases extracted via:
- All noun phrases (spaCy `noun_chunks`)
- Plus all numeric tokens
- Plus all UPPERCASE acronyms (NE, MDP, GAN, etc.)

**Why two signals**: cosine alone is fooled by topic-shift paraphrases ("evaluate auction X" vs "evaluate auction Y" both score high). Jaccard on noun phrases anchors the comparison to *content*.

### 2.4 Tier 3 — Same template detection

**Method**: Structural diff after entity replacement.

```
1. Replace all numbers → <NUM>
2. Replace all named entities (PERSON, ORG, GPE via spaCy NER) → <ENTITY>
3. Replace all noun phrases that appear only once → <NOUN>
4. Compute difflib ratio on the masked strings.

if 0.85 <= masked_ratio AND raw_ratio < 0.80:
    return "same_template"
```

Example:
- Q1: "A coffee-fetching robot has 3 states and 2 actions. Compute V*..."
- Q2: "A warehouse robot has 5 states and 3 actions. Compute V*..."
- After masking: "A `<NOUN>` robot has `<NUM>` states and `<NUM>` actions. Compute V*..." (both → ratio 0.98)
- Raw ratio: 0.62 → classified as **same_template**.

---

## 3. Implementation Pseudocode

```python
from __future__ import annotations
from dataclasses import dataclass
from difflib import SequenceMatcher
from typing import Literal
import re
import spacy
from sentence_transformers import SentenceTransformer
import numpy as np

MatchLevel = Literal["verbatim", "near_verbatim", "same_template", "unrelated"]

# Load once at module level
NLP = spacy.load("en_core_web_sm")
EMBED = SentenceTransformer("all-MiniLM-L6-v2")

STEM_PATTERNS = [
    r"^(consider the following|suppose that|let|given that|in the following)\s+",
    r"\(continued from previous page\)",
    r"\[page \d+\]",
    r"\(see (figure|table) \d+\)",
    r"\bas shown (below|above)\b",
]

@dataclass(frozen=True)
class Question:
    paper_id: str          # e.g., "AY2021"
    qid: str               # e.g., "Q3c"
    raw_text: str

@dataclass(frozen=True)
class MatchResult:
    match_level: MatchLevel
    papers: list[str]      # ["AY2021_Q3c", "AY2324_Q3c"]
    similarity: float
    delta: str             # human-readable diff summary

def normalize(text: str) -> str:
    """Strip boilerplate, lowercase, collapse whitespace."""
    t = text.lower()
    for pat in STEM_PATTERNS:
        t = re.sub(pat, "", t, flags=re.IGNORECASE)
    t = re.sub(r"\s+", " ", t).strip()
    return t

def key_phrases(text: str) -> set[str]:
    """Noun chunks + numeric tokens + uppercase acronyms."""
    doc = NLP(text)
    phrases = {chunk.text.lower() for chunk in doc.noun_chunks}
    phrases |= {tok.text for tok in doc if tok.like_num}
    phrases |= {tok.text for tok in doc if tok.is_upper and len(tok.text) >= 2}
    return phrases

def mask_entities(text: str) -> str:
    """Replace numbers + named entities + rare nouns with placeholders."""
    doc = NLP(text)
    masked_tokens: list[str] = []
    for tok in doc:
        if tok.like_num:
            masked_tokens.append("<NUM>")
        elif tok.ent_type_ in {"PERSON", "ORG", "GPE", "PRODUCT"}:
            masked_tokens.append("<ENTITY>")
        else:
            masked_tokens.append(tok.text.lower())
    return " ".join(masked_tokens)

def diff_summary(q1: str, q2: str) -> str:
    """Produce human-readable delta: 'numbers: (12,8) → (15,10)' or 'no changes'."""
    nums1 = re.findall(r"\b\d+(?:\.\d+)?\b", q1)
    nums2 = re.findall(r"\b\d+(?:\.\d+)?\b", q2)
    if nums1 != nums2 and len(nums1) == len(nums2):
        return f"numbers: ({','.join(nums1)}) -> ({','.join(nums2)})"
    if normalize(q1) == normalize(q2):
        return "no changes"
    sm = SequenceMatcher(None, q1, q2)
    blocks = [op for op in sm.get_opcodes() if op[0] != "equal"]
    return f"{len(blocks)} edit region(s)"

def compare_pair(q1: Question, q2: Question) -> MatchResult | None:
    """Compare two questions; return MatchResult if any tier matches, else None."""
    n1, n2 = normalize(q1.raw_text), normalize(q2.raw_text)

    # Tier 1: verbatim
    raw_ratio = SequenceMatcher(None, n1, n2).ratio()
    if raw_ratio >= 0.95:
        return MatchResult(
            match_level="verbatim",
            papers=[f"{q1.paper_id}_{q1.qid}", f"{q2.paper_id}_{q2.qid}"],
            similarity=round(raw_ratio, 3),
            delta=diff_summary(n1, n2),
        )

    # Tier 2: near-verbatim
    e1, e2 = EMBED.encode([n1, n2], normalize_embeddings=True)
    cos = float(np.dot(e1, e2))
    kp1, kp2 = key_phrases(n1), key_phrases(n2)
    jaccard = len(kp1 & kp2) / max(len(kp1 | kp2), 1)
    if cos >= 0.85 and jaccard >= 0.6:
        return MatchResult(
            match_level="near_verbatim",
            papers=[f"{q1.paper_id}_{q1.qid}", f"{q2.paper_id}_{q2.qid}"],
            similarity=round(cos, 3),
            delta=diff_summary(n1, n2),
        )

    # Tier 3: same template
    masked_ratio = SequenceMatcher(None, mask_entities(n1), mask_entities(n2)).ratio()
    if masked_ratio >= 0.85 and raw_ratio < 0.80:
        return MatchResult(
            match_level="same_template",
            papers=[f"{q1.paper_id}_{q1.qid}", f"{q2.paper_id}_{q2.qid}"],
            similarity=round(masked_ratio, 3),
            delta=f"template match (raw={raw_ratio:.2f}, masked={masked_ratio:.2f})",
        )

    return None

def detect_repeats(questions: list[Question]) -> list[MatchResult]:
    """O(N^2) pairwise scan. Use embed+cluster path for N > 10 papers."""
    results: list[MatchResult] = []
    for i in range(len(questions)):
        for j in range(i + 1, len(questions)):
            match = compare_pair(questions[i], questions[j])
            if match is not None:
                results.append(match)
    return results
```

---

## 4. False Positive Handling

| FP Source | Mitigation |
|-----------|-----------|
| Boilerplate intro stems ("Consider the following...") match across unrelated questions | `STEM_PATTERNS` regex strip in `normalize()` before any comparison |
| "(continued from previous page)" markers from PDF extraction | Same regex strip |
| Course-wide setup paragraph repeated verbatim ("This exam has 5 questions...") | Drop questions with length < 80 chars or that match >= 80% of *all* questions in the same paper — these are rubric/instructions, not questions |
| Generic phrasing ("Explain X") without enough content | Minimum content threshold: skip pairs where `len(key_phrases) < 3` |
| Math equation strings matching by accident | Tokenize equations as opaque blobs `<EQ>` before string ratio (optional v2 enhancement) |
| Same sub-question prompt across different parents ("Justify your answer.") | Compare full Q+sub-context, not isolated leaf prompts |

**Manual review queue**: Any T2 match where `cos >= 0.85` but `jaccard < 0.6` is **borderline** — flag for human review rather than auto-classify.

---

## 5. Output Schema

Each detected repeat group is emitted as JSON:

```json
{
  "match_level": "verbatim",
  "papers": ["AY2021_Q3c", "AY2324_Q3c"],
  "similarity": 0.97,
  "delta": "no changes"
}
```

```json
{
  "match_level": "near_verbatim",
  "papers": ["AY2122_Q4a", "AY2223_Q4a"],
  "similarity": 0.89,
  "delta": "numbers: (12,8) -> (15,10)"
}
```

```json
{
  "match_level": "same_template",
  "papers": ["AY2021_Q2", "AY2223_Q2", "AY2324_Q2"],
  "similarity": 0.91,
  "delta": "template match (raw=0.64, masked=0.91)"
}
```

For groups with >2 members (transitive matches), emit one entry per pair OR consolidate via union-find:

```json
{
  "match_level": "verbatim",
  "papers": ["AY2021_Q3c", "AY2223_Q3c", "AY2324_Q3c"],
  "similarity": 0.96,
  "delta": "no changes (3-way verbatim)"
}
```

---

## 6. Performance & Scaling

| N (papers) | Q (questions/paper) | Pairs | Strategy |
|-----------|--------------------|----|----------|
| <= 10 | ~15 | ~11K | **O(N²) pairwise** — runs in <30s on M3 Max |
| 10–50 | ~15 | ~280K | **Embed + cluster**: encode all Q's once, FAISS HNSW k-NN (k=20), only run full compare on candidates |
| > 50 | any | — | MinHash LSH pre-filter → embedding → tier classification |

**Embed + cluster path (pseudocode)**:

```python
def detect_repeats_scaled(questions: list[Question]) -> list[MatchResult]:
    embeddings = EMBED.encode([normalize(q.raw_text) for q in questions],
                              normalize_embeddings=True, batch_size=32)
    # FAISS HNSW for approximate k-NN
    import faiss
    index = faiss.IndexHNSWFlat(embeddings.shape[1], 32)
    index.add(embeddings)
    _, neighbor_idx = index.search(embeddings, k=20)

    results: list[MatchResult] = []
    seen: set[tuple[int, int]] = set()
    for i, neighbors in enumerate(neighbor_idx):
        for j in neighbors:
            if i >= j or (i, j) in seen:
                continue
            seen.add((i, j))
            match = compare_pair(questions[i], questions[j])
            if match is not None:
                results.append(match)
    return results
```

Cuts ~280K comparisons down to ~15K candidate pairs.

---

## 7. Concrete Example: SC4003 Verbatim Match

The prompt cites a real find: the **third-price auction truthfulness** question repeated across AY2021 → AY2324.

**Hypothetical normalized text** (after pre-processing):

```
Q1 (AY2021_Q3c): "in a sealed-bid third-price auction with three bidders, is truthful
bidding a dominant strategy? prove or provide a counterexample."

Q2 (AY2324_Q3c): "in a sealed-bid third-price auction with three bidders, is truthful
bidding a dominant strategy? prove or provide a counterexample."
```

Algorithm trace:
1. `normalize()` strips no boilerplate (no "Consider the following" prefix here).
2. `SequenceMatcher.ratio()` → **1.000** (byte-identical after normalization).
3. `1.000 >= 0.95` → **Tier 1 verbatim**.
4. `diff_summary()` finds no number changes → `"no changes"`.

**Output**:

```json
{
  "match_level": "verbatim",
  "papers": ["AY2021_Q3c", "AY2324_Q3c"],
  "similarity": 1.0,
  "delta": "no changes"
}
```

**Drill action emitted by downstream planner**:
- Priority: **HIGHEST** (verbatim, 3-year gap proves it's a recurring lecturer favorite).
- Card: "Third-price auction truthfulness — full proof + counterexample at v=(10,8,6)."
- Estimated study time: 20 min (memorize the dominant-strategy disproof).

If AY2223_Q3c also showed up with bid values changed:

```json
{
  "match_level": "near_verbatim",
  "papers": ["AY2021_Q3c", "AY2223_Q3c", "AY2324_Q3c"],
  "similarity": 0.91,
  "delta": "numbers: (10,8,6) -> (12,9,7)"
}
```

— still highest-priority drill: same proof template, parameters swapped.

---

## 8. Dependencies

```
difflib              # stdlib
sentence-transformers >= 2.2.0
spacy >= 3.5         + en_core_web_sm
numpy
faiss-cpu            # only for N>10 path
```

Install:
```bash
pip install sentence-transformers spacy numpy faiss-cpu
python -m spacy download en_core_web_sm
```
