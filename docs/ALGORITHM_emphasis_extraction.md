# B3: Lecturer Emphasis Extraction Algorithm

## Purpose

Extract items the lecturer has flagged as important from review materials (slides, handouts, recap PDFs, recorded summaries). Output a structured list of emphasized items with confidence scores, ready for cross-referencing against past-paper frequency in the coverage audit (B5).

This algorithm generalizes the SC4003 case where 30 RED items were extracted from a 12-slide lecturer review PDF. Not every lecturer uses red text — the algorithm must degrade gracefully across emphasis styles.

---

## 1. Emphasis Signal Types

Six signal classes, ordered by typical reliability:

| # | Signal | Detection difficulty | Typical hit rate |
|---|--------|----------------------|------------------|
| 1 | **Color** (red text, colored background, yellow highlight) | Easy with PDF text-color attr; needs vision otherwise | High — explicit lecturer intent |
| 2 | **Marker words** (`important`, `must know`, `exam`, `MUST`, `key`, `note`, `recall`, `★`, `⭐`, `!!`, surrounding asterisks `*X*`) | Easy with regex on extracted text | High when present |
| 3 | **Bold / weight change** | Medium — needs font-weight attr from PDF | Medium — bold often used cosmetically |
| 4 | **Repetition across slides** (item appears in ≥2 slides, especially recap/summary slides) | Medium — needs topic normalization | High — strong signal for "lecturer cares" |
| 5 | **Position** (slide title, summary slide bullets, "what you must know" slide, last-slide bullets) | Easy with structural parsing | Very high for explicit summary slides |
| 6 | **Underlining / italic / boxed** | Hard without vision; PDF rarely encodes underline as attribute | Medium |

Implementation note: signals 1 + 2 + 5 deliver ~90% of useful coverage. Signals 3, 4, 6 are tie-breakers / fallbacks.

---

## 2. Extraction Methods (in order of preference)

### Method A — PDF color/font extraction (preferred when available)

Use `pymupdf4llm` or raw `PyMuPDF` (fitz) to walk the PDF span tree. Each span carries `color` (sRGB int), `font` (name), `flags` (bold/italic bits), and `bbox`.

```python
import fitz  # PyMuPDF

def extract_styled_spans(pdf_path: str) -> list[dict]:
    """Return spans with non-default styling."""
    doc = fitz.open(pdf_path)
    spans = []
    for page_num, page in enumerate(doc, start=1):
        blocks = page.get_text("dict")["blocks"]
        for block in blocks:
            if block.get("type") != 0:  # text only
                continue
            for line in block["lines"]:
                for span in line["spans"]:
                    color_int = span["color"]
                    is_bold = bool(span["flags"] & 16)  # 2^4 = bold flag
                    is_italic = bool(span["flags"] & 2)
                    if _is_emphasized(color_int, is_bold, is_italic):
                        spans.append({
                            "slide": page_num,
                            "text": span["text"].strip(),
                            "color_rgb": _int_to_rgb(color_int),
                            "bold": is_bold,
                            "italic": is_italic,
                            "bbox": span["bbox"],
                        })
    return spans

def _is_emphasized(color_int: int, bold: bool, italic: bool) -> bool:
    r, g, b = _int_to_rgb(color_int)
    is_red = r > 150 and g < 100 and b < 100
    is_orange = r > 200 and 100 < g < 180 and b < 100
    is_blue_strong = b > 150 and r < 100  # some lecturers use blue
    is_non_black = (r, g, b) != (0, 0, 0) and (r + g + b) < 600
    return is_red or is_orange or is_blue_strong or bold or (is_non_black and not italic)
```

**Pros:** Exact verbatim text, lossless, fast (~1s/100 slides).
**Cons:** Fails when PDF was scanned (image-only PDF) or lecturer used a highlight rectangle (annotation, not text color).

Detection: if `extract_styled_spans()` returns 0 spans on a 10+ slide PDF, fall back to Method B.

---

### Method B — Claude vision (PDF → PNG → multimodal)

Convert each slide to a PNG and ask Claude to identify emphasized regions. Use this when Method A returns nothing or PDF has highlight annotations / handwritten ink.

```bash
# 200 DPI is enough for slide-style PDFs; 300 for dense academic PDFs
pdftoppm -r 200 -png review.pdf /tmp/slides/slide
```

Per-slide vision prompt (template):

```
You are looking at slide {N} of a lecturer's exam-review deck.
List ONLY items the lecturer has visually emphasized — red/orange text,
yellow/colored highlight, bold standalone phrases, asterisks, stars,
hand-drawn boxes/circles, or items in slide titles/summary bullets.

Skip body prose, examples, and decorative headers (the slide template).

Return JSON array:
[{
  "verbatim_text": "<exact text as written>",
  "emphasis_type": "color:red" | "highlight:yellow" | "bold" | "marker_word"
                  | "underline" | "box" | "title" | "summary_bullet",
  "confidence": 0.0-1.0
}]
If nothing is emphasized, return [].
```

**Pros:** Catches highlights, scanned PDFs, ink annotations, slide titles.
**Cons:** ~$0.01-0.03/slide on Sonnet, slower (~3-5s/slide), occasional verbatim drift on long phrases.

Mitigation for verbatim drift: after vision returns a candidate `verbatim_text`, fuzzy-match it back against Method A's full-text extraction of that slide and snap to the closest substring (Levenshtein ratio > 0.85). This guarantees the stored text actually appears in the PDF.

---

### Method C — Marker-word regex (fallback for plain-text PDFs)

When the PDF has no color/style info at all (e.g., `pdftotext` plain output), scan for explicit marker words and surrounding context.

```python
import re

MARKER_PATTERNS = [
    (r"\b(IMPORTANT|MUST KNOW|MUST UNDERSTAND|KEY POINT|EXAM|EXAMINABLE|REMEMBER|NOTE WELL|NB)\b", "marker_word"),
    (r"[★⭐✦✱✪☆]", "star_glyph"),
    (r"\*\*([^*]{3,80})\*\*", "asterisk_pair"),         # **emphasized**
    (r"!!\s*([^!\n]{3,80})", "double_bang"),             # !! item
    (r"\b(do not forget|don't forget|will be tested|on the exam|past year)\b", "exam_phrase"),
]

def extract_marker_items(text_by_slide: dict[int, str]) -> list[dict]:
    items = []
    for slide_num, text in text_by_slide.items():
        for pattern, kind in MARKER_PATTERNS:
            for m in re.finditer(pattern, text, flags=re.IGNORECASE):
                # Capture surrounding sentence (up to 200 chars)
                start = max(0, m.start() - 100)
                end = min(len(text), m.end() + 100)
                snippet = text[start:end].strip()
                items.append({
                    "slide": slide_num,
                    "verbatim_text": snippet,
                    "emphasis_type": f"marker:{kind}",
                    "confidence": 0.7,  # lower than color
                })
    return items
```

**Pros:** Works on any text. **Cons:** Many false positives (`important` in body prose). Confidence capped at 0.7.

---

### Method D — User-flagged

If Methods A/B/C all return < 5 items on a non-trivial deck (or no review document exists), prompt the user:

> "Couldn't auto-detect lecturer emphasis. Paste the bullets/quotes the lecturer flagged as important (one per line), or upload screenshots of the review slides."

Treat user-pasted lines as `emphasis_type: "user_flagged"`, `confidence: 1.0`. This is the ground-truth fallback and should be the only source when no review document exists.

---

## 3. Per-Slide Processing Pseudocode

```
function extract_emphasis(pdf_path, optional user_paste):
    items = []

    # Step 1: try Method A
    spans_A = extract_styled_spans(pdf_path)
    if len(spans_A) >= MIN_SPANS_THRESHOLD (default 5):
        items += normalize_spans(spans_A)
    else:
        # Step 2: fall back to Method B (vision)
        png_dir = pdftoppm(pdf_path, dpi=200)
        for slide_num, png in enumerate(sorted(png_dir), start=1):
            vision_items = ask_claude_vision(png, slide_num)
            for it in vision_items:
                # snap verbatim_text to actual PDF text
                it["verbatim_text"] = snap_to_pdf_text(it["verbatim_text"], slide_num, pdf_path)
            items += vision_items

    # Step 3: always run Method C in parallel (marker words add cheap signal)
    text_by_slide = pdftotext_per_slide(pdf_path)
    marker_items = extract_marker_items(text_by_slide)
    items += marker_items

    # Step 4: structural pass — slide titles + summary slides
    items += extract_structural(pdf_path)

    # Step 5: deduplicate (same verbatim_text on same slide)
    items = dedupe_by(items, key=("slide", "verbatim_text_normalized"))

    # Step 6: repetition signal — boost confidence if topic appears in 2+ slides
    items = boost_repeated(items)

    # Step 7: fallback to user paste
    if len(items) < 5 and user_paste:
        items += parse_user_paste(user_paste)

    # Step 8: classify each item to a topic (LLM call)
    for it in items:
        it["topic"] = classify_topic(it["verbatim_text"], course_syllabus)

    return items
```

Threshold tuning notes:
- `MIN_SPANS_THRESHOLD = 5` — below this, Method A is probably picking up template colors (slide footer, page number) rather than real emphasis.
- Repetition boost: `confidence += 0.1` per additional slide the topic appears on, capped at 0.99.

---

## 4. Output Schema

Single canonical record per emphasized item:

```json
{
  "slide": 7,
  "topic": "Vickrey truthfulness",
  "emphasis_type": "color:red",
  "verbatim_text": "Truthful bidding is a dominant strategy in 2nd-price auctions",
  "confidence": 0.95,
  "source_method": "A",
  "bbox": [120.5, 340.2, 480.8, 360.1],
  "repeated_on_slides": [7, 11]
}
```

Fields:
- `slide` — 1-indexed slide number in the review PDF.
- `topic` — normalized topic key matching the course syllabus / past-paper topic taxonomy. Used for joining with B5 coverage audit.
- `emphasis_type` — taxonomy: `color:red`, `color:orange`, `color:blue`, `highlight:yellow`, `bold`, `marker:important`, `marker:star_glyph`, `marker:asterisk_pair`, `title`, `summary_bullet`, `repetition`, `user_flagged`.
- `verbatim_text` — exact text as it appears in the PDF (snapped via fuzzy match if vision was used).
- `confidence` — 0.0-1.0, see scoring rules below.
- `source_method` — `A` | `B` | `C` | `D` (or comma-joined `A,C` if multiple methods detected).
- `bbox` — optional, useful for generating annotated screenshots.
- `repeated_on_slides` — list of slide numbers if the topic repeated; empty if unique.

Confidence scoring:

| Source | Base confidence |
|--------|-----------------|
| Method A, red/orange | 0.95 |
| Method A, bold only | 0.70 |
| Method A, non-black non-red | 0.80 |
| Method B (vision), color/highlight | 0.90 |
| Method B (vision), bold/title | 0.75 |
| Method C, marker_word | 0.70 |
| Method C, star_glyph | 0.85 |
| Structural (summary slide) | 0.90 |
| Structural (slide title) | 0.65 |
| Method D (user-flagged) | 1.00 |
| Repetition boost | +0.05 per extra slide, cap 0.99 |

---

## 5. Coverage Audit Logic

Cross-reference emphasized items against historical past-paper frequency to surface traps and blue oceans.

Inputs:
- `emphasized` — output from this algorithm.
- `paper_freq` — output from B1 (past-paper topic frequency analysis): `{topic: {years_asked: [...], freq: int}}`.

Logic:

```python
def coverage_audit(emphasized: list[dict], paper_freq: dict) -> dict:
    audit = {
        "high_signal": [],      # emphasized AND frequently asked → study first
        "trap": [],             # emphasized but rarely/never asked → still study, possible new exam item
        "blue_ocean": [],       # asked frequently but NOT emphasized → easy points others miss
        "noise": [],            # neither emphasized nor asked
    }

    emph_topics = {it["topic"]: max_conf(it) for it in emphasized}
    asked_topics = set(paper_freq.keys())

    for topic, conf in emph_topics.items():
        freq = paper_freq.get(topic, {}).get("freq", 0)
        if freq >= 2:
            audit["high_signal"].append({"topic": topic, "emph_conf": conf, "freq": freq})
        else:
            audit["trap"].append({"topic": topic, "emph_conf": conf, "freq": freq,
                                   "reason": "Lecturer flagged but rarely asked — possibly NEW exam item"})

    for topic in asked_topics - set(emph_topics.keys()):
        freq = paper_freq[topic]["freq"]
        if freq >= 2:
            audit["blue_ocean"].append({
                "topic": topic, "freq": freq,
                "reason": "Asked often, lecturer didn't flag — easy points if you prep"
            })

    audit["high_signal"].sort(key=lambda x: (x["emph_conf"], x["freq"]), reverse=True)
    audit["blue_ocean"].sort(key=lambda x: x["freq"], reverse=True)
    return audit
```

Interpretation rules:
- **High-signal** (emphasized + frequent): top study priority. Allocate ~50% of revision time.
- **Trap** (emphasized + rare): the lecturer is signaling a likely new exam item or refreshed Q. Allocate ~25%. Don't skip — emphasized + low historical freq is the #1 predictor of the next exam refresh.
- **Blue ocean** (frequent + not emphasized): easy points others miss. Allocate ~20%.
- **Noise**: skip unless time permits.

---

## 6. Edge Cases

### No review document at all
Skip Methods A/B/C. Run a degraded structural pass on the main lecture slides:
- Treat every slide title as `emphasis_type: title, confidence: 0.4`.
- Look for slides whose title contains "summary", "recap", "key points", "what you must know", "review", "in summary" — treat all bullets on those slides as `confidence: 0.85`.
- Topics appearing in ≥3 lecture decks → `emphasis_type: repetition, confidence: 0.7`.
- Then prompt user (Method D) to fill gaps.

### Multi-color emphasis (lecturer uses red AND yellow AND bold)
Priority order when the SAME phrase has multiple emphasis types:
`user_flagged > color:red > highlight:yellow > color:orange > color:other > bold > marker_word > underline > italic > title`

Store the highest-priority type in `emphasis_type`, but keep all detected types in an optional `all_signals` array for debugging.

### Lecturer doesn't use any color (monochrome slides)
- Method A returns 0 → automatically falls through to Method B.
- If Method B also returns < 5 items → Method C marker-word scan.
- If Method C also returns < 5 → prompt user (Method D).
- Always show the user a count: "Detected 3 emphasized items from Method C only. Paste anything else?"

### Scanned (image-only) PDF
- Method A finds zero spans (no text layer).
- Skip directly to Method B (vision works on rendered PNGs regardless of source).
- Optionally OCR with Tesseract to enable Method C in parallel.

### Highlight rectangles (PDF annotations, not text color)
- Method A misses these because the text underneath is still black.
- Detect via `page.annots()` in PyMuPDF — look for `Highlight` annotation type, get its bbox, then re-extract text within that bbox and tag as `highlight:yellow`.

```python
for annot in page.annots() or []:
    if annot.type[0] == fitz.PDF_ANNOT_HIGHLIGHT:
        rect = annot.rect
        text_under = page.get_textbox(rect)
        items.append({"slide": page_num, "verbatim_text": text_under,
                       "emphasis_type": "highlight:yellow", "confidence": 0.92})
```

### Lecturer's review is a video/audio recording (no PDF)
Out of scope for B3. Suggest user transcribe (Whisper) → run Method C on transcript with relaxed marker-word patterns ("on the exam", "you must know", "I want you to remember", "this is testable").

### Very long review deck (50+ slides)
Method B vision cost grows linearly. Optimization: run Method A first; only call vision on slides where Method A returned 0 styled spans. Typical slide deck has emphasis on ~30% of slides, so vision cost drops by ~70%.

---

## Reliability Across Lecturer Styles — Summary

Ranked from most to least reliable across the typical lecturer population:

| Rank | Method | Why |
|------|--------|-----|
| 1 | **Method B (vision)** | Catches everything Method A catches, plus highlights, ink, scanned PDFs, layout cues. Cost is the only downside. |
| 2 | **Method A (PDF color/font)** | Lossless and fast when it works (~60-70% of academic decks have native colored text). Fails on scanned/image PDFs and highlight annotations. |
| 3 | **Method D (user-flagged)** | 100% precision but requires user labor and gives sparse coverage. |
| 4 | **Method C (marker words)** | Useful as a parallel signal everywhere, but high false-positive rate makes it unsuitable as a sole source. |

**Recommended default pipeline**: Method A first → Method B for slides where A returned nothing → Method C in parallel for cheap extra signal → Method D fallback when total < 5 items. This combination handles the long tail of lecturer styles (red-text users, highlight users, monochrome+bold users, plain-text scanned-handout users, no-review-doc users) with one codepath.

The single most reliable individual signal across styles is **Method B (vision)** — it's the only method that adapts to whatever visual emphasis convention the lecturer happens to use, including ones we haven't enumerated. If budget is unconstrained, run vision on every slide and use Methods A/C as cross-validators to snap verbatim text and boost confidence.
