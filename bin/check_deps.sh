#!/usr/bin/env bash
# D3_check_deps.sh - Probe dependencies for the exam-prep v2 pipeline
# and emit a capability matrix.
#
# Usage:
#   ./D3_check_deps.sh           # human-readable, colored
#   ./D3_check_deps.sh --json    # machine-readable JSON
#
# Exit codes:
#   0 = all critical deps present (full pipeline available)
#   1 = PDF output unavailable but pipeline can degrade to markdown only
#   2 = critical missing (no markdown converter / no python3) — pipeline cannot run
#
# Compatible with bash 3.2+ (macOS default) — no associative arrays.

set -u

# ----- args -----------------------------------------------------------------
JSON_MODE=0
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=1 ;;
        -h|--help)
            cat <<EOF
D3_check_deps.sh — probe deps for exam-prep v2 pipeline

Options:
  --json     Emit JSON instead of human-readable matrix
  -h|--help  Show this help

Exit codes:
  0 = all critical deps present
  1 = PDF output unavailable, markdown still works
  2 = critical missing — pipeline cannot run
EOF
            exit 0
            ;;
        *)
            echo "Unknown arg: $arg" >&2
            exit 2
            ;;
    esac
done

# ----- color setup ----------------------------------------------------------
if [[ $JSON_MODE -eq 0 ]] && [[ -t 1 ]]; then
    C_GREEN=$'\033[0;32m'
    C_RED=$'\033[0;31m'
    C_YELLOW=$'\033[0;33m'
    C_BLUE=$'\033[0;34m'
    C_BOLD=$'\033[1m'
    C_RESET=$'\033[0m'
    OK_MARK="✅"
    FAIL_MARK="✗"
else
    C_GREEN=""; C_RED=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""; C_RESET=""
    OK_MARK="OK"
    FAIL_MARK="MISSING"
fi

# ----- helpers --------------------------------------------------------------
have_cmd() { command -v "$1" >/dev/null 2>&1; }

have_pip_pkg() {
    # $1 = importable module name
    if ! have_cmd python3; then
        return 1
    fi
    python3 -c "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec('$1') else 1)" 2>/dev/null
}

# Detect platform for suggestion phrasing
PLATFORM="unknown"
case "$(uname -s)" in
    Darwin) PLATFORM="mac" ;;
    Linux)  PLATFORM="linux" ;;
esac

# ----- dep table ------------------------------------------------------------
# Parallel arrays (bash 3.2 compatible). Index = dep id.
# Fields: NAME, KIND (cmd|pip), PROBE (cmd or import name), BREW_PKG, APT_PKG
DEP_NAMES=(
    "pandoc"
    "xelatex"
    "pdflatex"
    "tesseract"
    "pdftoppm"
    "pdftotext"
    "python3"
    "pymupdf4llm"
    "sentence-transformers"
    "marker-pdf"
    "weasyprint"
)

DEP_KINDS=(
    "cmd"
    "cmd"
    "cmd"
    "cmd"
    "cmd"
    "cmd"
    "cmd"
    "pip"
    "pip"
    "pip"
    "pip"
)

DEP_PROBES=(
    "pandoc"
    "xelatex"
    "pdflatex"
    "tesseract"
    "pdftoppm"
    "pdftotext"
    "python3"
    "pymupdf4llm"
    "sentence_transformers"
    "marker"
    "weasyprint"
)

DEP_BREW=(
    "pandoc"
    "--cask mactex-no-gui"
    "--cask mactex-no-gui"
    "tesseract"
    "poppler"
    "poppler"
    "python@3.12"
    "-"
    "-"
    "-"
    "-"
)

DEP_APT=(
    "pandoc"
    "texlive-xetex"
    "texlive-latex-base"
    "tesseract-ocr"
    "poppler-utils"
    "poppler-utils"
    "python3"
    "-"
    "-"
    "-"
    "-"
)

# Result arrays
DEP_PRESENT=()
DEP_SUGGEST=()

# ----- probe each dep -------------------------------------------------------
N=${#DEP_NAMES[@]}
i=0
while [[ $i -lt $N ]]; do
    name="${DEP_NAMES[$i]}"
    kind="${DEP_KINDS[$i]}"
    probe="${DEP_PROBES[$i]}"
    brew_pkg="${DEP_BREW[$i]}"
    apt_pkg="${DEP_APT[$i]}"

    if [[ "$kind" == "cmd" ]]; then
        if have_cmd "$probe"; then
            DEP_PRESENT[$i]=1
        else
            DEP_PRESENT[$i]=0
        fi
    else
        if have_pip_pkg "$probe"; then
            DEP_PRESENT[$i]=1
        else
            DEP_PRESENT[$i]=0
        fi
    fi

    # build suggestion
    if [[ "${DEP_PRESENT[$i]}" == "0" ]]; then
        if [[ "$kind" == "pip" ]]; then
            DEP_SUGGEST[$i]="pip install $name"
        else
            if [[ "$PLATFORM" == "mac" ]]; then
                DEP_SUGGEST[$i]="brew install $brew_pkg"
            else
                DEP_SUGGEST[$i]="sudo apt-get install -y $apt_pkg"
            fi
        fi
    else
        DEP_SUGGEST[$i]=""
    fi

    i=$((i + 1))
done

# Lookup helper: get index for a dep name
idx_of() {
    local target=$1
    local k=0
    while [[ $k -lt $N ]]; do
        if [[ "${DEP_NAMES[$k]}" == "$target" ]]; then
            echo $k
            return 0
        fi
        k=$((k + 1))
    done
    echo -1
    return 1
}

is_present() {
    local target=$1
    local idx
    idx=$(idx_of "$target")
    [[ "${DEP_PRESENT[$idx]}" == "1" ]]
}

# ----- compute capability matrix --------------------------------------------
# A markdown converter exists if pandoc OR pymupdf4llm OR marker-pdf is present.
HAS_MD_CONVERTER=0
if is_present pandoc || is_present pymupdf4llm || is_present marker-pdf; then
    HAS_MD_CONVERTER=1
fi

# PDF output: pandoc + (xelatex|pdflatex)  OR  weasyprint
HAS_PDF_OUTPUT=0
if is_present pandoc && { is_present xelatex || is_present pdflatex; }; then
    HAS_PDF_OUTPUT=1
fi
if is_present weasyprint; then
    HAS_PDF_OUTPUT=1
fi

# OCR availability
if is_present tesseract; then
    OCR_AVAILABLE="tesseract"
else
    # Claude vision is always available as a fallback (Claude is the runtime).
    OCR_AVAILABLE="claude-vision"
fi

# Topic normalization always works (LLM is the runtime).
TOPIC_NORMALIZATION="requires LLM (always available)"

# Verbatim detection
if is_present sentence-transformers; then
    VERBATIM_DETECTION="sentence-transformers (semantic) + difflib"
else
    VERBATIM_DETECTION="difflib only (no semantic)"
fi

# Full pipeline = md converter + python3 + PDF output
FULL_PIPELINE="no"
if [[ $HAS_MD_CONVERTER -eq 1 ]] && is_present python3 && [[ $HAS_PDF_OUTPUT -eq 1 ]]; then
    FULL_PIPELINE="yes"
fi

# Decide exit code
EXIT_CODE=0
if ! is_present python3 || [[ $HAS_MD_CONVERTER -eq 0 ]]; then
    EXIT_CODE=2
elif [[ $HAS_PDF_OUTPUT -eq 0 ]]; then
    EXIT_CODE=1
fi

PDF_OUTPUT_STR="no"
[[ $HAS_PDF_OUTPUT -eq 1 ]] && PDF_OUTPUT_STR="yes"

# ----- emit JSON -----------------------------------------------------------
if [[ $JSON_MODE -eq 1 ]]; then
    deps_json=""
    j=0
    while [[ $j -lt $N ]]; do
        name="${DEP_NAMES[$j]}"
        present_bool="false"
        [[ "${DEP_PRESENT[$j]}" == "1" ]] && present_bool="true"
        suggestion="${DEP_SUGGEST[$j]}"
        # escape backslash and quote for JSON
        suggestion_escaped=${suggestion//\\/\\\\}
        suggestion_escaped=${suggestion_escaped//\"/\\\"}
        if [[ $j -gt 0 ]]; then
            deps_json+=","
        fi
        deps_json+="\"$name\":{\"present\":$present_bool,\"suggestion\":\"$suggestion_escaped\"}"
        j=$((j + 1))
    done

    cat <<EOF
{
  "deps": {$deps_json},
  "capabilities": {
    "FULL_PIPELINE": "$FULL_PIPELINE",
    "PDF_OUTPUT": "$PDF_OUTPUT_STR",
    "OCR_AVAILABLE": "$OCR_AVAILABLE",
    "TOPIC_NORMALIZATION": "$TOPIC_NORMALIZATION",
    "VERBATIM_DETECTION": "$VERBATIM_DETECTION"
  },
  "exit_code": $EXIT_CODE,
  "platform": "$PLATFORM"
}
EOF
    exit $EXIT_CODE
fi

# ----- emit human-readable --------------------------------------------------
print_row() {
    local name=$1 present=$2
    if [[ "$present" == "1" ]]; then
        printf "  ${C_GREEN}%s${C_RESET}  %s\n" "$OK_MARK" "$name"
    else
        printf "  ${C_RED}%s${C_RESET}  %s\n" "$FAIL_MARK" "$name"
    fi
}

print_row_by_name() {
    local target=$1
    local idx
    idx=$(idx_of "$target")
    print_row "$target" "${DEP_PRESENT[$idx]}"
}

echo
printf "${C_BOLD}exam-prep v2 dependency probe${C_RESET}\n"
printf "platform: %s\n\n" "$PLATFORM"

printf "${C_BOLD}System tools${C_RESET}\n"
print_row_by_name "pandoc"
print_row_by_name "xelatex"
print_row_by_name "pdflatex"
print_row_by_name "tesseract"
print_row_by_name "pdftoppm"
print_row_by_name "pdftotext"
print_row_by_name "python3"

echo
printf "${C_BOLD}Python packages${C_RESET}\n"
print_row_by_name "pymupdf4llm"
print_row_by_name "sentence-transformers"
print_row_by_name "marker-pdf"
print_row_by_name "weasyprint"

echo
printf "${C_BOLD}Capability matrix${C_RESET}\n"
printf "  FULL_PIPELINE:        %s\n" "$FULL_PIPELINE"
printf "  PDF_OUTPUT:           %s\n" "$PDF_OUTPUT_STR"
printf "  OCR_AVAILABLE:        %s\n" "$OCR_AVAILABLE"
printf "  TOPIC_NORMALIZATION:  %s\n" "$TOPIC_NORMALIZATION"
printf "  VERBATIM_DETECTION:   %s\n" "$VERBATIM_DETECTION"

# ----- suggestions ----------------------------------------------------------
missing_any=0
k=0
while [[ $k -lt $N ]]; do
    if [[ "${DEP_PRESENT[$k]}" == "0" ]]; then
        missing_any=1
        break
    fi
    k=$((k + 1))
done

if [[ $missing_any -eq 1 ]]; then
    echo
    printf "${C_BOLD}${C_YELLOW}Suggestions to install missing deps${C_RESET}\n"
    k=0
    while [[ $k -lt $N ]]; do
        if [[ "${DEP_PRESENT[$k]}" == "0" ]]; then
            printf "  ${C_BLUE}%-22s${C_RESET}  %s\n" "${DEP_NAMES[$k]}" "${DEP_SUGGEST[$k]}"
        fi
        k=$((k + 1))
    done
fi

# ----- summary line ---------------------------------------------------------
echo
case $EXIT_CODE in
    0) printf "${C_GREEN}${C_BOLD}status: full pipeline available${C_RESET} (exit 0)\n" ;;
    1) printf "${C_YELLOW}${C_BOLD}status: degraded — markdown only, no PDF${C_RESET} (exit 1)\n" ;;
    2) printf "${C_RED}${C_BOLD}status: critical deps missing — pipeline cannot run${C_RESET} (exit 2)\n" ;;
esac
echo

exit $EXIT_CODE
