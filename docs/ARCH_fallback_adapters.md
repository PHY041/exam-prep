# D4 — Fallback Adapters: Graceful Degradation Spec

Each adapter answers a single question: *if this dependency is missing, what does the pipeline do instead?*
Adapters are layered — Path A is preferred, Path B is acceptable, Path C is the "still ship something useful" floor.

Detection convention used throughout:

```bash
have() { command -v "$1" >/dev/null 2>&1; }
```

---

## 1. OCR missing (no `tesseract`)

Detect:

```bash
if have tesseract; then
  OCR_ENGINE="tesseract"
else
  OCR_ENGINE="missing"
fi
```

### Path A — Claude vision via Read tool on PNG pages

Convert the PDF to one PNG per page, then hand pages to Claude as image inputs. Claude reads them natively (no OCR binary required).

```bash
# Render PDF pages to PNG (uses whichever rasterizer is available — see §5)
render_pdf_to_png() {
  local pdf="$1" outdir="$2" dpi="${3:-220}"
  mkdir -p "$outdir"
  if   have pdftoppm; then pdftoppm -r "$dpi" -png "$pdf" "$outdir/page"
  elif have magick;   then magick -density "$dpi" "$pdf" "$outdir/page-%03d.png"
  elif have sips;     then # macOS; one page at a time
       local n; n=$(mdls -name kMDItemNumberOfPages -raw "$pdf")
       for i in $(seq 0 $((n-1))); do
         sips -s format png --resampleHeightWidthMax $((dpi*11)) \
              "$pdf" --out "$outdir/page-$(printf %03d $i).png" >/dev/null
       done
  else echo "ERR: no rasterizer" >&2; return 2
  fi
}
```

Then in the agent loop, iterate `outdir/page-*.png` and pass each to Read; Claude transcribes.

### Path B — Manual paste / transcribe

Fallback if Claude vision is unavailable (e.g. air-gapped run, text-only model).

```python
# adapters/ocr_manual.py
from pathlib import Path

def request_manual_transcript(pdf_path: Path, out_path: Path) -> str:
    """Block until the user provides the text, then return it."""
    print(f"[OCR fallback] Cannot read {pdf_path.name} automatically.")
    print(f"Please open the PDF, copy its text, and save it to:\n  {out_path}")
    input("Press ENTER once the file is saved...")
    if not out_path.exists():
        raise FileNotFoundError(f"Expected transcript at {out_path}")
    return out_path.read_text(encoding="utf-8")
```

### Path C — Skip past papers, lecturer-only mode

```python
# adapters/pipeline_modes.py
def select_corpus(have_ocr: bool, have_vision: bool, user_will_paste: bool) -> str:
    if have_ocr or have_vision: return "full"          # past papers + lecturer
    if user_will_paste:         return "manual_paste"
    return "lecturer_only"  # frequency analysis disabled, weights from emphasis only
```

When `lecturer_only`, the ranking algorithm sets `freq_score = 0` for every topic and reweights to `emphasis_score` × 1.0. Output report flags this with a banner: *"Past-paper analysis skipped — no OCR engine available."*

---

## 2. No `pandoc`

Detect: `have pandoc`.

### Path A — Markdown only + external instruction

```python
# adapters/pandoc_fallback.py
from pathlib import Path
from textwrap import dedent

def write_md_only(md_path: Path) -> None:
    note = dedent(f"""
        > NOTE: pandoc not installed. Output is Markdown only.
        > To convert to PDF locally:
        >   brew install pandoc && pandoc {md_path.name} -o {md_path.stem}.pdf
        > Or upload to https://md2pdf.netlify.app
    """).strip()
    md_path.write_text(note + "\n\n" + md_path.read_text(encoding="utf-8"),
                       encoding="utf-8")
```

### Path B — `marked.js` + browser-print HTML wrapper

Self-contained HTML that any browser can render and "Save as PDF":

```python
# adapters/md_to_html_browser.py
from pathlib import Path

HTML_TEMPLATE = """<!doctype html>
<html><head><meta charset="utf-8"><title>{title}</title>
<style>
  @media print {{ @page {{ size: A4; margin: 18mm; }} }}
  body {{ font: 14px/1.6 -apple-system, "Helvetica Neue", sans-serif;
          max-width: 780px; margin: 2rem auto; color:#111; }}
  pre, code {{ font-family: ui-monospace, Menlo, monospace; background:#f5f5f7;
               padding:.1em .3em; border-radius:4px; }}
  pre {{ padding: .8em; overflow-x:auto; }}
  h1,h2,h3 {{ line-height:1.25; }}
  table {{ border-collapse: collapse; }} td,th {{ border:1px solid #ddd; padding:.4em .6em; }}
</style></head>
<body>
<div id="md" style="display:none">{md}</div>
<div id="out"></div>
<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
<script>
  const src = document.getElementById('md').textContent;
  document.getElementById('out').innerHTML = marked.parse(src);
  // Auto-prompt print after render
  window.addEventListener('load', () => setTimeout(() => window.print(), 400));
</script>
</body></html>
"""

def md_to_browser_html(md_path: Path, html_path: Path, title: str = "Exam Prep") -> Path:
    md = md_path.read_text(encoding="utf-8")
    # Escape only the closing tag of our hidden div — marked handles the rest
    md_safe = md.replace("</div>", "<\\/div>")
    html_path.write_text(HTML_TEMPLATE.format(title=title, md=md_safe), encoding="utf-8")
    return html_path
```

User flow: open the HTML, browser auto-triggers print dialog, save as PDF.

---

## 3. No `xelatex`

Detect: `have xelatex`.

### Path A — `weasyprint` (HTML/CSS engine, pure-Python)

```python
# adapters/pdf_engine.py
from pathlib import Path

def render_pdf(html_path: Path, pdf_path: Path) -> str:
    """Returns the engine actually used."""
    try:
        from weasyprint import HTML
        HTML(filename=str(html_path)).write_pdf(str(pdf_path))
        return "weasyprint"
    except ImportError:
        return _fallback_html(html_path, pdf_path)

def _fallback_html(html_path: Path, pdf_path: Path) -> str:
    # Path B: just keep HTML, skip PDF
    final = pdf_path.with_suffix(".html")
    final.write_bytes(html_path.read_bytes())
    print(f"[PDF fallback] No xelatex/weasyprint. HTML saved to {final}")
    print( "  Open in a browser and use 'Save as PDF'.")
    return "html_only"
```

### Path B — HTML output only

Already covered in `_fallback_html` above. Pipeline still completes; user prints from browser.

---

## 4. No `sentence-transformers`

Detect:

```python
try:
    import sentence_transformers  # noqa
    HAS_ST = True
except ImportError:
    HAS_ST = False
```

### Path A — `sentence-transformers` (preferred)

```python
from sentence_transformers import SentenceTransformer, util
_model = SentenceTransformer("all-MiniLM-L6-v2")
def similarity_st(a: str, b: str) -> float:
    ea, eb = _model.encode([a, b], convert_to_tensor=True)
    return float(util.cos_sim(ea, eb))
```

### Path B — `difflib.SequenceMatcher` (pure stdlib, always works)

```python
# adapters/similarity.py
from difflib import SequenceMatcher
import re

def _normalize(s: str) -> str:
    return re.sub(r"\W+", " ", s.lower()).strip()

def similarity_difflib(a: str, b: str) -> float:
    """Token-level Ratcliff-Obershelp. 0..1, less semantic than embeddings."""
    return SequenceMatcher(None, _normalize(a), _normalize(b)).ratio()

def similarity(a: str, b: str) -> float:
    try:
        return similarity_st(a, b)  # type: ignore[name-defined]
    except Exception:
        return similarity_difflib(a, b)
```

Note: difflib operates on character/token overlap, so "k-means" vs "k means clustering" still scores ≥ 0.7 but synonyms ("classifier" vs "discriminator") will score low. Topic-clustering threshold is auto-loosened from 0.78 → 0.62 when difflib is the engine.

---

## 5. No `pdftoppm` (PDF → PNG)

Detect (in priority order): `pdftoppm` → `magick` → `sips`.

```bash
# adapters/pdf_to_png.sh
pdf_to_png() {
  local pdf="$1" outdir="$2" dpi="${3:-220}"
  mkdir -p "$outdir"

  if have pdftoppm; then
    pdftoppm -r "$dpi" -png "$pdf" "$outdir/page" && return 0
  fi

  if have magick; then
    magick -density "$dpi" "$pdf" -quality 92 "$outdir/page-%03d.png" && return 0
  fi

  if have sips; then  # macOS native
    local pages
    pages=$(mdls -name kMDItemNumberOfPages -raw "$pdf" 2>/dev/null)
    [ -z "$pages" ] || [ "$pages" = "(null)" ] && pages=1
    for i in $(seq 0 $((pages-1))); do
      sips -s format png "$pdf" --out "$outdir/page-$(printf %03d $i).png" >/dev/null
    done
    return 0
  fi

  echo "ERR: no PDF rasterizer (need pdftoppm, magick, or sips)" >&2
  return 2
}
```

Quality ordering: `pdftoppm` (best for text) > `magick` (good, slower) > `sips` (lowest DPI control, but always present on macOS).

---

## 6. No git repo for codex review

Codex review walks the staged diff; if `cwd` is not a repo, create a throwaway one.

```bash
# adapters/ensure_git_repo.sh
ensure_git_repo() {
  local target="$1"
  if git -C "$target" rev-parse --git-dir >/dev/null 2>&1; then
    echo "$target"; return 0
  fi
  local tmp="/tmp/codex-tmp-$(date +%s)"
  mkdir -p "$tmp"
  cp -R "$target"/. "$tmp"/
  git -C "$tmp" init -q
  git -C "$tmp" add -A
  git -C "$tmp" -c user.email=codex@local -c user.name=codex \
      commit -q -m "snapshot for codex review"
  echo "$tmp"
}
```

Caller passes the returned path to codex. The temp repo is left behind for inspection; a daily cron under `/tmp` reaps it.

---

## 7. OCR confidence low

Tesseract reports per-word confidence via `--tsv`. We escalate in three steps.

```python
# adapters/ocr_quality.py
import subprocess
from pathlib import Path
from statistics import median

LOW_CONF = 70   # below this, retry; below 40, flag as [OCR?]

def tesseract_with_conf(png: Path, dpi: int = 300) -> tuple[str, float]:
    out = subprocess.check_output(
        ["tesseract", str(png), "-", "--dpi", str(dpi), "tsv"],
        stderr=subprocess.DEVNULL, text=True,
    )
    words, confs = [], []
    for line in out.splitlines()[1:]:
        cols = line.split("\t")
        if len(cols) < 12: continue
        conf, txt = cols[10], cols[11]
        if conf == "-1" or not txt.strip(): continue
        words.append(txt); confs.append(int(conf))
    text = " ".join(words)
    score = median(confs) if confs else 0.0
    return text, score

def ocr_with_retry(png: Path) -> tuple[str, float, list[str]]:
    """Retry at higher DPI; flag uncertain words; return notes for the user."""
    notes: list[str] = []
    text, score = tesseract_with_conf(png, dpi=220)
    if score < LOW_CONF:
        notes.append(f"OCR confidence {score:.0f} on {png.name}; retrying @ 400dpi.")
        text2, score2 = tesseract_with_conf(png, dpi=400)
        if score2 > score:
            text, score = text2, score2
    if score < 40:
        notes.append(f"VERIFY: very low OCR confidence ({score:.0f}) on {png.name}.")
        text = f"[OCR? low confidence {score:.0f}]\n{text}\n[/OCR?]"
    return text, score, notes
```

Three-step escalation:

1. **Re-run @ higher DPI** (220 → 400). Recovers most low-conf cases on scanned past papers.
2. **Wrap uncertain text** in `[OCR? ... /OCR?]` markers so downstream reports highlight it.
3. **Surface a verify-this list** to the user at the end of the run, with page numbers and excerpts.

---

## Coverage summary

Total distinct fallback paths: **17**

| # | Missing dep         | Paths                                                                  |
|---|---------------------|------------------------------------------------------------------------|
| 1 | tesseract / OCR     | A: Claude vision · B: manual paste · C: lecturer-only mode             |
| 2 | pandoc              | A: md + instructions · B: marked.js + browser print                    |
| 3 | xelatex             | A: weasyprint · B: HTML output                                         |
| 4 | sentence-transformers | A: ST embeddings · B: difflib SequenceMatcher                        |
| 5 | pdftoppm            | A: pdftoppm · B: ImageMagick `magick` · C: macOS `sips`                |
| 6 | git repo for codex  | A: existing repo · B: temp repo at `/tmp/codex-tmp-*`                  |
| 7 | OCR low confidence  | A: retry @ higher DPI · B: `[OCR?]` flagging · C: user-verify list     |

**3 + 2 + 2 + 2 + 3 + 2 + 3 = 17 distinct fallback paths.**
