#!/usr/bin/env bash
# v0.5 narrator-pollution detector
# Scans markdown files for forbidden narrator patterns + validates OCR marker syntax.
# Usage: ./check_pollution.sh <file_or_dir>
# Exit codes: 0 = clean, 1 = pollution found, 2 = bad invocation
#
# Added v0.5 after SC4023 audit: narrator pollution ("Wait —", "let me re-derive",
# "raise your hand", "see lecturer's full") leaked into PYP_AY2122 Q4(c) and
# PYP_AY2223 Q5(b/c/d), undermining trust in the answer packs.

set -uo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <file_or_dir>" >&2
    exit 2
fi

TARGET="$1"

if [ ! -e "$TARGET" ]; then
    echo "ERROR: '$TARGET' does not exist" >&2
    exit 2
fi

# Build the file list — portable across bash 3.2 (macOS) and bash 4+.
# Use a temp file to avoid subshell variable scoping issues.
FILELIST="$(mktemp -t check_pollution_files.XXXXXX)"
trap 'rm -f "$FILELIST"' EXIT

if [ -d "$TARGET" ]; then
    find "$TARGET" -type f -name '*.md' >"$FILELIST"
else
    echo "$TARGET" >"$FILELIST"
fi

FILE_COUNT=$(wc -l <"$FILELIST" | tr -d ' ')
if [ "$FILE_COUNT" -eq 0 ]; then
    echo "ERROR: no markdown files found under '$TARGET'" >&2
    exit 2
fi

# Forbidden narrator patterns (case-insensitive grep -E regex).
# Each entry: "TYPE|REGEX"
PATTERNS=(
    "NARRATOR|Wait —"
    "NARRATOR|Wait,"
    "NARRATOR|Hmm,"
    "NARRATOR|let me re-derive"
    "NARRATOR|let me redo"
    "NARRATOR|I'?ll commit to"
    "NARRATOR|I think"
    "NARRATOR|I realize"
    "NARRATOR|actually,"
    "PUNT|raise your hand"
    "PUNT|tell the lecturer"
    "PUNT|see lecturer'?s full"
    "PUNT|see lecturer'?s notes"
    "PUNT|see official solution"
    "PUNT|see Tut [0-9]+ solutions?"
    "QUALITY|Tedious"
    "QUALITY|Approximate answer"
    "QUALITY|Solution sketch"
    "QUALITY|This gets messy"
    "QUALITY|It is genuinely impossible"
    "QUALITY|closest feasible"
)

FINDINGS=0
SCANNED=0

while IFS= read -r file; do
    [ -z "$file" ] && continue
    SCANNED=$((SCANNED + 1))

    # Check forbidden patterns.
    for entry in "${PATTERNS[@]}"; do
        ptype="${entry%%|*}"
        regex="${entry#*|}"
        # grep -nEi: line numbers, extended regex, case-insensitive.
        # Use --color=never for clean output. Skip if no match.
        while IFS= read -r match; do
            line_num="${match%%:*}"
            text="${match#*:}"
            echo "${file}:${line_num}: ${ptype}: ${text}"
            FINDINGS=$((FINDINGS + 1))
        done < <(grep -nEi --color=never "$regex" "$file" 2>/dev/null || true)
    done

    # OCR marker validation: 🚨 OCR-XXX: lines must use OCR-AMBIGUOUS or OCR-NOTE only.
    while IFS= read -r match; do
        line_num="${match%%:*}"
        text="${match#*:}"
        # Allowed forms only: OCR-AMBIGUOUS: or OCR-NOTE:
        if ! echo "$text" | grep -qE '🚨 OCR-(AMBIGUOUS|NOTE):'; then
            echo "${file}:${line_num}: OCR-MARKER-INVALID: ${text}"
            FINDINGS=$((FINDINGS + 1))
        fi
    done < <(grep -nE --color=never '🚨 OCR-' "$file" 2>/dev/null || true)
done <"$FILELIST"

if [ "$FINDINGS" -eq 0 ]; then
    echo "✅ CLEAN: ${SCANNED} files scanned"
    exit 0
else
    echo ""
    echo "❌ POLLUTION: ${FINDINGS} findings across ${SCANNED} files"
    exit 1
fi
