# A3: Dependency Probe + Fallback Strategy

**Skill:** exam-prep
**Problem:** Skill currently assumes `pandoc`, `xelatex`, `marker-pdf`, `pymupdf4llm`, `tesseract`, `weasyprint` are installed. They aren't, on most machines. Skill must degrade gracefully.

**Goal:** Detect what's available, route to the best pipeline, and tell the user concretely how to fix gaps — instead of crashing mid-run.

---

## 1. Bash Probe Script

Save as `skills/exam-prep/scripts/probe_deps.sh`. Skill calls this **once** at the start of every run, parses output (JSON), and stores it in the run context.

```bash
#!/usr/bin/env bash
# probe_deps.sh — emit JSON describing which exam-prep dependencies are present.
# Exit code is always 0; the caller inspects the JSON to decide what to do.

set -u

have() { command -v "$1" >/dev/null 2>&1; }

py_has() {
    # py_has <module> — succeeds iff `python3 -c 'import <module>'` works.
    python3 -c "import importlib,sys; importlib.import_module('$1')" >/dev/null 2>&1
}

bin_version() {
    # Best-effort version string. Empty if not installed.
    have "$1" || { printf ''; return; }
    "$1" --version 2>/dev/null | head -n1
}

# --- Probe each dependency -------------------------------------------------
PANDOC=$(have pandoc          && echo true || echo false)
XELATEX=$(have xelatex        && echo true || echo false)
PDFLATEX=$(have pdflatex      && echo true || echo false)
TESSERACT=$(have tesseract    && echo true || echo false)
PDFTOPPM=$(have pdftoppm      && echo true || echo false)   # poppler
PDFTOTEXT=$(have pdftotext    && echo true || echo false)   # poppler
PDFTK=$(have pdftk            && echo true || echo false)
QPDF=$(have qpdf              && echo true || echo false)   # pdftk replacement
WEASYPRINT_BIN=$(have weasyprint && echo true || echo false)

PY3=$(have python3 && echo true || echo false)
PY_PYMUPDF4LLM=false
PY_MARKER=false
PY_PYPDF2=false
PY_PYPDF=false
PY_WEASYPRINT=false
if [ "$PY3" = "true" ]; then
    py_has pymupdf4llm && PY_PYMUPDF4LLM=true
    py_has marker      && PY_MARKER=true
    py_has PyPDF2      && PY_PYPDF2=true
    py_has pypdf       && PY_PYPDF=true
    py_has weasyprint  && PY_WEASYPRINT=true
fi

OS=$(uname -s)

# --- Derive capability flags ----------------------------------------------
ANY_PDF_PARSER=false
[ "$PY_PYMUPDF4LLM" = "true" ] || [ "$PY_MARKER" = "true" ] \
  || [ "$PY_PYPDF2" = "true" ] || [ "$PY_PYPDF" = "true" ] \
  || [ "$PDFTOTEXT" = "true" ] && ANY_PDF_PARSER=true

ANY_PDF_RENDERER=false
[ "$XELATEX" = "true" ] || [ "$PDFLATEX" = "true" ] \
  || [ "$WEASYPRINT_BIN" = "true" ] || [ "$PY_WEASYPRINT" = "true" ] \
  && ANY_PDF_RENDERER=true

OCR=$([ "$TESSERACT" = "true" ] && echo true || echo false)

# --- Emit JSON -------------------------------------------------------------
cat <<EOF
{
  "os": "$OS",
  "binaries": {
    "pandoc":     $PANDOC,
    "xelatex":    $XELATEX,
    "pdflatex":   $PDFLATEX,
    "tesseract":  $TESSERACT,
    "pdftoppm":   $PDFTOPPM,
    "pdftotext":  $PDFTOTEXT,
    "pdftk":      $PDFTK,
    "qpdf":       $QPDF,
    "weasyprint": $WEASYPRINT_BIN,
    "python3":    $PY3
  },
  "python_modules": {
    "pymupdf4llm": $PY_PYMUPDF4LLM,
    "marker":      $PY_MARKER,
    "PyPDF2":      $PY_PYPDF2,
    "pypdf":       $PY_PYPDF,
    "weasyprint":  $PY_WEASYPRINT
  },
  "capabilities": {
    "any_pdf_parser":   $ANY_PDF_PARSER,
    "any_pdf_renderer": $ANY_PDF_RENDERER,
    "ocr":              $OCR,
    "markdown_only":    true
  }
}
EOF
```

**Human-readable variant** — for direct invocation by the user, also emit a `--report` mode that prints a checklist:

```bash
# probe_deps.sh --report
[FOUND]    pandoc 3.1.9
[MISSING]  xelatex          -> see install hints below
[FOUND]    tesseract 5.3.4
[MISSING]  pdftoppm         -> brew install poppler
[FOUND]    python3 3.12.4
[MISSING]  pymupdf4llm      -> pip install pymupdf4llm
[OK]       any_pdf_parser=false  any_pdf_renderer=true  ocr=true
```

The skill always parses the JSON form; the report form is only for `exam-prep --check-deps`.

---

## 2. Capability Matrix

Each row = a feature the skill exposes. Columns = the minimal dep set required.

| Feature                              | Hard requirement                                      | Notes |
|--------------------------------------|-------------------------------------------------------|-------|
| **Markdown-only output** (always)    | (none)                                                | Plain text fallback. Always works. |
| Read text-based PDF                  | `python3` + (`pymupdf4llm` \| `pypdf` \| `PyPDF2` \| `pdftotext`) | At least one parser. |
| Read image/scanned PDF (OCR)         | `tesseract` + `pdftoppm`                              | Or online OCR API as fallback. |
| Read structured math PDF (high quality) | `python3` + `marker-pdf`                            | Optional. Falls back to `pymupdf4llm`. |
| **PDF-only output**                  | `pandoc` + (`xelatex` \| `pdflatex` \| `weasyprint`)  | LaTeX engines preferred for math. |
| **Full pipeline** (input PDFs → ranked plan → drill PDF) | `pandoc` + `xelatex` + `tesseract` + `pdftoppm` + Python parser | Best quality, ideal install. |
| Split/merge past papers              | `pdftk` \| `qpdf` \| Python parser                    | Optional. |

**Decision rule:** the skill computes the highest tier achievable from the probe and tells the user which tier it picked.

```
Tier 0 — Markdown-only        (always available)
Tier 1 — Markdown + simple PDF (pandoc + any renderer)
Tier 2 — Tier 1 + OCR          (+ tesseract + pdftoppm)
Tier 3 — Tier 2 + math-quality (+ marker-pdf)   ← target
```

---

## 3. Fallback Decision Tree

For every missing dep, the skill takes a **specific** action — not a generic "install it".

### Missing PDF parser (no `pymupdf4llm`/`marker`/`pypdf`/`PyPDF2`/`pdftotext`)

```
1. Check if user-supplied PDFs are accompanied by .txt/.md siblings.
   - If yes: use those, skip parsing entirely.
2. Else: print a clear message:
   "I can't parse PDFs on this machine. Either:
    (a) Run: pip install pymupdf4llm   (recommended, ~30s)
    (b) Paste each past paper's text into a .txt file next to the PDF
    (c) Re-run me with the --md-only flag and I'll skip PDF input"
3. Stop run.
```

### Missing OCR (`tesseract` absent) but PDFs are scanned

```
1. Detect "scanned" by: parser returns <100 chars per page on average.
2. Try fallbacks in order:
   a. If OPENAI_API_KEY is set → use GPT-5.4 vision on rasterized pages
      (requires pdftoppm; if also missing, skip to step b).
   b. If GOOGLE_GENAI_API_KEY is set → use Gemini 2.5 Flash multimodal.
   c. Neither available → print:
      "This PDF is scanned and I can't OCR it locally.
       Paste the past paper text manually into:
         <paper>.txt
       Then re-run me. Or install tesseract:
         macOS: brew install tesseract
         Linux: sudo apt install tesseract-ocr"
3. Continue with whatever papers we *did* parse, mark the rest as "skipped".
```

### Missing `pandoc`

```
1. Skill emits Markdown only (no PDF / DOCX).
2. Print at end of run:
   "Output is in: ./exam-prep-output/plan.md
    To convert to PDF yourself, run one of:
      pandoc plan.md -o plan.pdf --pdf-engine=xelatex   (after: brew install pandoc)
      Open plan.md in Typora / Obsidian and File → Export → PDF
      Open plan.md in VS Code with Markdown PDF extension"
3. Do NOT silently skip the run.
```

### Missing `xelatex`/`pdflatex` (but `pandoc` present)

```
1. Try fallbacks in order:
   a. weasyprint (binary or python module)
        pandoc plan.md -o plan.pdf --pdf-engine=weasyprint
   b. Generate HTML instead, open in user's default browser:
        pandoc plan.md -o plan.html --standalone --mathjax
        open plan.html   # macOS
        xdg-open plan.html  # Linux
      Then instruct: "Press Cmd/Ctrl+P → Save as PDF"
   c. None of the above → emit Markdown + clear PDF instructions
      (same wording as the no-pandoc branch).
2. Note in the output: "PDF rendered via <engine>. Math may render
   differently from xelatex. To get xelatex output, install MacTeX
   (macOS) or texlive-xetex (Linux)."
```

### Missing `pdftoppm` (poppler)

```
- If we needed it for OCR rasterization: see "Missing OCR" branch
  (online VLM fallback can ingest the PDF directly).
- If we needed it for thumbnail extraction in the drill PDF: skip
  thumbnails, log a warning. Drill PDF still ships.
```

### Missing `pdftk`/`qpdf`

```
- We only need these for splitting multi-paper bundles. Fall back to
  Python parser (pypdf can extract page ranges natively). If no Python
  parser either, ask the user to pre-split the bundle.
```

### Missing `python3` entirely

```
1. The skill itself runs Python. If python3 is missing, we can't even
   start. Bail with:
   "exam-prep needs python3. Install it:
     macOS: brew install python@3.12   (or use the system python)
     Linux: sudo apt install python3 python3-pip
     Windows: download from python.org/downloads, tick 'Add to PATH'"
2. Exit 1.
```

---

## 4. Install Hints

Printed by the skill at the end of any run that hit fallbacks, and by `exam-prep --check-deps`.

### macOS (Homebrew)

```bash
# Core (required for Tier 1)
brew install pandoc

# PDF engines (pick one)
brew install --cask mactex-no-gui   # full xelatex, ~4GB
brew install basictex               # ~100MB, then: sudo tlmgr install xetex collection-fontsrecommended
brew install weasyprint             # lighter, no LaTeX

# OCR + PDF utils (Tier 2)
brew install tesseract
brew install poppler                 # provides pdftoppm, pdftotext
brew install qpdf                    # pdftk replacement; pdftk-java is also fine

# Python modules (Tier 3)
pip install pymupdf4llm marker-pdf weasyprint pypdf
```

### Linux (Debian / Ubuntu / WSL)

```bash
# Core
sudo apt update
sudo apt install -y pandoc

# PDF engines
sudo apt install -y texlive-xetex texlive-fonts-recommended texlive-latex-extra
# OR: sudo apt install -y weasyprint

# OCR + PDF utils
sudo apt install -y tesseract-ocr poppler-utils qpdf

# Python
sudo apt install -y python3 python3-pip
pip install --user pymupdf4llm marker-pdf weasyprint pypdf
```

### Linux (Fedora / RHEL)

```bash
sudo dnf install -y pandoc texlive-xetex tesseract poppler-utils qpdf python3-pip
pip install --user pymupdf4llm marker-pdf weasyprint pypdf
```

### Windows (native, no WSL)

Native Windows is officially **unsupported** by this skill — see Section 5.
If user insists:

```powershell
# Use Chocolatey or Scoop
choco install pandoc miktex tesseract poppler qpdf python
pip install pymupdf4llm pypdf weasyprint
```

`marker-pdf` won't install reliably on Windows (Torch + native deps). Skip it.

---

## 5. Cross-Platform Notes

| Platform | Status | Caveats |
|----------|--------|---------|
| **macOS (Apple Silicon)** | Fully supported | `marker-pdf` uses MPS acceleration. Brew handles everything. `mactex-no-gui` is 4GB — `basictex` is fine for our use. |
| **macOS (Intel)** | Fully supported | Same as above. |
| **Linux (Debian/Ubuntu)** | Fully supported | apt ships everything. `marker-pdf` uses CPU unless CUDA present. |
| **Linux (Fedora/RHEL/Arch)** | Supported | Package names differ slightly. Use the same logic. |
| **WSL2 (Ubuntu on Windows)** | Supported | Treat as Linux. **File paths**: skill must handle `/mnt/c/...` paths if user points at PDFs on the Windows side. Slow disk IO across the boundary. |
| **Windows native (PowerShell)** | **Not supported** | (a) Many Python deps ship Linux wheels only. (b) `marker-pdf` requires Torch with native libs — fragile. (c) Path separators break shell scripts. **Recommendation:** the skill detects `OS=Windows_NT` from `uname -s` and tells user to use WSL2. |
| **Docker / CI** | Supported via image | Skill should ship a `Dockerfile` with all deps preinstalled for users on locked-down machines. |

### Specific Windows-native failure modes

```
- bash probe script won't run (no /usr/bin/env bash). Skill provides
  probe_deps.ps1 stub that prints "Use WSL2" and exits.
- pdftk: the original is Java — works. pdftk-server (newer) doesn't
  exist on Windows; we use qpdf instead.
- xelatex via MiKTeX: works, but auto-installs missing packages on
  first run, which is slow and noisy. We document this.
- tesseract: UB Mannheim build works. PATH must be set manually.
- weasyprint: requires GTK runtime on Windows. Annoying. We skip.
```

### File path handling

```python
# Skill must use pathlib for cross-platform safety:
from pathlib import Path
paper = Path(user_input).expanduser().resolve()
# Never str-concat paths with "/".
```

---

## Minimum Viable Dependency Set

> **What MUST be present for any output at all?**

```
python3        (the skill runs in Python)
```

That is the only hard requirement. With **just** `python3`, the skill produces a Markdown study plan from user-pasted past-paper text. No PDF in, no PDF out — but it runs end-to-end and emits something useful.

**Practical floor** (what we tell users to install for a useful experience):

```
python3 + pandoc + (xelatex OR weasyprint) + (pymupdf4llm OR pypdf)
```

This gives Tier 1 (PDF in via text-based parsing, PDF out via pandoc). OCR and high-quality math parsing are bonuses, not blockers.

**Skill behavior contract:**

1. Always run the probe first.
2. Compute the highest reachable tier.
3. **Tell the user upfront** which tier we're operating at, and what they'd gain by installing the missing pieces.
4. Never crash on a missing optional dep — degrade with a concrete fallback message.
5. Persist the probe result for the session so we don't re-probe on every sub-step.
