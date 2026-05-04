#!/usr/bin/env bash
# v0.5 master-plan self-consistency checker
# Verifies subtitle claims match actual table contents.
# Usage: ./check_master_plan.sh <master_plan.md>
# Exit codes: 0 = consistent, 1 = mismatch found, 2 = bad invocation
#
# Added v0.5 after SC4023 incident: subtitle claimed '3 cold mocks / 16h study'
# but actual schedule had 2 mocks / 15.75h. Mismatch caused student trust erosion.

set -uo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <master_plan.md>" >&2
    exit 2
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "ERROR: '$FILE' is not a regular file" >&2
    exit 2
fi

python3 - "$FILE" <<'PYEOF'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
lines = text.splitlines()

# Look in the first ~80 lines for subtitle claims (header + frontmatter region).
header_region = "\n".join(lines[:80])

def find_claim(patterns):
    """Return first regex group hit across the patterns list, else None."""
    for pat in patterns:
        m = re.search(pat, header_region, re.IGNORECASE)
        if m:
            return m
    return None

# Claimed values (best-effort extraction).
claimed_hours_match = find_claim([
    r"(\d+(?:\.\d+)?)\s*h\s*(?:focused|study|of\s+study|total)",
    r"(?:total|focused|study)[^0-9\n]{0,30}(\d+(?:\.\d+)?)\s*h",
    r"FOCUSED_H[^0-9\n]{0,10}(\d+(?:\.\d+)?)",
])
claimed_hours = float(claimed_hours_match.group(1)) if claimed_hours_match else None

claimed_mocks_match = find_claim([
    r"(\d+)\s*cold\s*mocks?",
    r"cold\s*mocks?[^\n0-9]{0,10}[:=]\s*(\d+)",
])
claimed_mocks = int(claimed_mocks_match.group(1)) if claimed_mocks_match else None

claimed_days_match = find_claim([
    r"(\d+)[\s-]*day\s+plan",
    r"plan[^\n0-9]{0,15}(\d+)\s*days?",
])
claimed_days = int(claimed_days_match.group(1)) if claimed_days_match else None

# Exam time pattern: HH:MM (24h). Capture from header region only.
exam_time_match = re.search(r"(\d{1,2}:\d{2})\s*(?:am|pm|AM|PM)?", header_region)
claimed_exam_time = exam_time_match.group(1) if exam_time_match else None

# Actual values from the body.
# Cold mock headers — match patterns like "Cold Mock 1", "## Cold Mock 2", etc.
cold_mock_lines = [
    (i, ln) for i, ln in enumerate(lines, start=1)
    if re.search(r"\bCold\s*Mock\b", ln)
]
# Extract all numbers attached to "Cold Mock N".
cold_mock_numbers = []
for _, ln in cold_mock_lines:
    for m in re.finditer(r"Cold\s*Mock\s*#?(\d+)", ln, re.IGNORECASE):
        cold_mock_numbers.append(int(m.group(1)))
cold_mock_numbers = sorted(set(cold_mock_numbers))
actual_mock_count = len(cold_mock_numbers) if cold_mock_numbers else len(cold_mock_lines)

# Day headers: "# DAY 1", "## Day 2 — ...", etc.
day_headers = [
    ln for ln in lines
    if re.match(r"^#+\s*DAY\s*\d+", ln, re.IGNORECASE)
]
actual_day_count = len(day_headers)

# Hours: sum any "(~Xh)" or "(Xh)" markers attached to day/block headers.
hour_markers = re.findall(r"\(\s*~?\s*(\d+(?:\.\d+)?)\s*h\b", text)
actual_hours_sum = sum(float(h) for h in hour_markers) if hour_markers else None

# Exam time consistency in body — collect HH:MM occurrences that look like exam times.
# Heuristic: any line mentioning "exam" near a time.
exam_body_times = re.findall(
    r"(?:EXAM|exam)[^\n]{0,40}(\d{1,2}:\d{2})", text
) + re.findall(
    r"(\d{1,2}:\d{2})[^\n]{0,20}(?:EXAM|exam)", text
)
exam_body_times = sorted(set(exam_body_times))

# Numbering contiguity check.
def numbering_ok(nums):
    if not nums:
        return True, "(no cold mocks declared)"
    expected = list(range(1, len(nums) + 1))
    if nums == expected:
        return True, ",".join(str(n) for n in nums)
    return False, ",".join(str(n) for n in nums) + f" (expected 1..{len(nums)})"

mock_num_ok, mock_num_obs = numbering_ok(cold_mock_numbers)

# Reporting.
print(f"File: {path}")
print("")
print("| Check                  | Claimed              | Actual                  | Pass |")
print("|------------------------|----------------------|-------------------------|------|")

failures = 0

def row(label, claimed, actual, ok):
    global failures
    mark = "✓" if ok else "✗"
    if not ok:
        failures += 1
    c = str(claimed) if claimed is not None else "(not stated)"
    a = str(actual) if actual is not None else "(not derivable)"
    print(f"| {label:<22} | {c:<20} | {a:<23} | {mark}    |")

# Hours check — pass if claimed is None (can't compare) OR within 0.5h.
if claimed_hours is not None and actual_hours_sum is not None:
    hours_ok = abs(claimed_hours - actual_hours_sum) < 0.5
else:
    hours_ok = True  # unverifiable, don't fail
row("Total study hours", f"{claimed_hours}h" if claimed_hours else None,
    f"{actual_hours_sum}h" if actual_hours_sum else None, hours_ok)

# Mock count check.
if claimed_mocks is not None:
    mocks_ok = (claimed_mocks == actual_mock_count)
else:
    mocks_ok = True  # unverifiable
row("Cold mock count", claimed_mocks, actual_mock_count, mocks_ok)

# Mock numbering check.
row("Cold mock numbering", "contiguous 1..N", mock_num_obs, mock_num_ok)

# Exam time consistency: claimed time should appear in body.
if claimed_exam_time and exam_body_times:
    exam_ok = claimed_exam_time in exam_body_times and len(exam_body_times) == 1
    body_repr = ",".join(exam_body_times)
elif claimed_exam_time:
    exam_ok = True  # claimed but not echoed in body — can't fail confidently
    body_repr = "(not found in body)"
else:
    exam_ok = True
    body_repr = ",".join(exam_body_times) if exam_body_times else "(none)"
row("Exam time consistency", claimed_exam_time, body_repr, exam_ok)

# Day count check.
if claimed_days is not None:
    days_ok = (claimed_days == actual_day_count)
else:
    days_ok = True
row("Day count", claimed_days, actual_day_count, days_ok)

print("")
if failures == 0:
    print("✅ PASS: all stated claims consistent with body")
    sys.exit(0)
else:
    print(f"❌ FAIL: {failures} mismatch(es) — patch + re-verify before delivery")
    sys.exit(1)
PYEOF
RC=$?
exit $RC
