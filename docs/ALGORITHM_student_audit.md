# Step 10.5 — Codex-Student Audit (v0.5 addition)

**Status:** P0 gate. New in v0.5.0. Closes the biggest systemic hole found in v0.4 SC4023 testing.

---

## Why this step exists

In the **NTU SC4023 May 2026 dry-run**, v0.4 declared `STATUS: DONE` after Step 10
(PDF generation). A *manual* `codex exec` invocation acting as a cold-reading
student then surfaced **6 P0 bugs** the skill's own validation gate had missed:

1. Stale exam datetime inherited silently from a prior SC4003 run (would have
   caused the student to miss the actual exam by 8 hours).
2. Narrator pollution — meta-commentary like "this answer demonstrates…" leaked
   into the verbatim drill PDFs.
3. Master plan claimed "12 hours of prep" while reverse-counting from the wrong
   exam datetime, producing a forward-additive schedule with no anchor.
4. Two contradictory "canonical" answers shipped for the same past-paper question.
5. EXAM_METADATA block absent from MASTER_PLAN.pdf header.
6. Coverage audit listed three RED items as ✓ that were nowhere in any pack.

Score progression across three audit rounds:

| Round | Audit score | Pass-probability estimate |
|-------|-------------|---------------------------|
| 0 (skill says DONE) | **6.2 / 10** | 48% |
| 1 (after surgical fixes) | **7.5 / 10** | 71% |
| 2 (second fix loop) | **8.1 / 10** | 84% |

The same pattern almost certainly applied to the SC4003 reference run — we
simply never audited it. v0.5 makes the audit **mandatory and automatic**.

---

## When this step runs

- **After:** Step 10 (PDF generation completes; INDEX + master plan + cheatsheet
  + per-topic packs all rendered to `ipad_topic_packs/`).
- **Before:** the skill prints `STATUS: DONE` to the user.
- **Skipped only if:** dependency probe (Step 0) reports `codex_cli: missing`
  OR `codex auth: failed`. In that case → emit a WARN line and proceed (see
  *Failure modes* below).

---

## How it runs (mechanics)

### 1. Spawn the auditor

```bash
codex exec --skip-git-repo-check \
  --model gpt-5.4 \
  --cwd "{exam_prep_root}" \
  --prompt-file "{exam_prep_root}/_process/audits/round_{N}_prompt.md"
```

### 2. Student-persona prompt template

Write this to `_process/audits/round_{N}_prompt.md` before invoking codex:

```markdown
You are a student with {days_to_exam} days until the {course_code} exam on
{exam_datetime} ({format}, {total_marks} marks, duration {duration_minutes} min).

You have just opened the folder `ipad_topic_packs/` and you are cold-reading
{N_packs} markdown files in `_source_md/`. You have NOT seen the source past
papers, the lecturer review, or the slides. All you have is what the skill
shipped.

Your job in the next 30 minutes:

1. Read every file in `_source_md/` in study order (start with INDEX).
2. For each file, flag anything that is:
   - **Confusing** — you cannot follow the argument or worked solution.
   - **Broken** — math doesn't add up, citations point nowhere, dead refs.
   - **Contradictory** — two files give different "canonical" answers to
     the same past-paper question.
   - **Missing** — the master plan references content that isn't in any pack.
   - **Polluted** — narrator/meta voice ("this demonstrates…", "as we saw
     earlier…") instead of clean drill content.
   - **Stale** — dates, course codes, or exam metadata that look inherited
     from a different course/run.
3. Score the pack 0-10 on study-readiness (10 = I would walk into the exam
   confident; 0 = useless).
4. Estimate pass-probability % if you only studied from this pack.

OUTPUT FORMAT (strict — must parse):

```
SCORE: <0-10>
PASS_PROBABILITY: <0-100>%
BUGS:
- [P0|P1|P2] <file:section> — <one-line description>
- ...
FIXED_FROM_LAST_ROUND: (only on round 2+)
- <file:section> — <how it was fixed>
STILL_BROKEN: (only on round 2+)
- <file:section> — <why the fix didn't land>
```
```

### 3. Parse codex output

```python
import re

def parse_audit(audit_text: str) -> dict:
    score = float(re.search(r"SCORE:\s*([\d.]+)", audit_text).group(1))
    prob = int(re.search(r"PASS_PROBABILITY:\s*(\d+)", audit_text).group(1))
    bugs = re.findall(
        r"- \[(P0|P1|P2)\]\s+(\S+)\s+—\s+(.+)",
        audit_text,
    )
    return {
        "score": score,
        "pass_probability": prob,
        "bugs": [{"severity": s, "location": l, "desc": d} for s, l, d in bugs],
    }
```

---

## Gate logic

```
if score >= 8.0:
    STATUS = "DONE"
    write_artifact(_process/audits/round_{N}_audit.md)
    print("Codex-student audit: {score}/10 ({pass_prob}%). Shipping.")
    EXIT
else:
    enter_fix_loop(round=N+1)
```

**Threshold rationale:** 8.0 = empirically the score at which all P0 bugs are
gone and only P1/P2 polish items remain. Below 8.0 there is at least one
P0 still in flight.

---

## Fix loop (cap = 3 rounds)

```
for round_n in 1, 2, 3:
    audit = run_codex_audit(round_n)
    write_artifact(f"_process/audits/round_{round_n}_audit.md", audit)

    if audit.score >= 8.0:
        return STATUS_DONE

    # Group bugs by file for surgical batched edits
    bugs_by_file = group_by(audit.bugs, key="location.file")

    fix_agents = []
    for file_path, file_bugs in bugs_by_file.items():
        agent_prompt = build_fix_prompt(file_path, file_bugs)
        fix_agents.append(spawn_agent(agent_prompt))

    parallel_wait(fix_agents, max_parallel=6)

    affected_pdfs = {bug.location.file.replace(".md", ".pdf")
                     for bug in audit.bugs}
    regenerate_pdfs(affected_pdfs)

# Fell out of loop without crossing threshold
return STATUS_DONE_WITH_CONCERNS(unfixable=audit.bugs)
```

**Surgical fix prompt template (per file):**

```
You are a fix-agent for the exam-prep skill, v0.5.

File to edit: {absolute_path}
Bugs to address (all in this file):
{numbered_bug_list}

Constraints:
- Edit ONLY the lines/sections cited. Do not refactor surrounding content.
- Preserve original drill structure, numbering, and answer keys.
- If a bug is "narrator pollution", strip the meta-voice but keep the answer.
- If a bug is "contradiction with file X", read X first, then choose the
  version that matches the past-paper source (in `_process/papers/`).
- If you cannot fix without more context, leave the file unchanged and
  emit STATUS: UNFIXABLE — <reason> as your final line.
```

---

## Cost cap

| Item | Per round (est.) | Notes |
|------|------------------|-------|
| Codex audit invocation | $0.30 – $0.80 | reads ~30 markdown files, gpt-5.4 |
| Fix-agent fan-out (5-10 agents) | $0.20 – $0.70 | Sonnet 4.6, surgical edits |
| PDF re-render | ~$0.00 | local pandoc/xelatex |
| **Per-round total** | **$0.50 – $1.50** | |
| **3-round hard cap** | **$5.00** | abort + STATUS_DONE_WITH_CONCERNS |

If `cumulative_cost > $5.00` mid-loop → emit `STATUS: DONE_WITH_CONCERNS`,
write `_process/audits/cost_cap_exceeded.md`, surface unfixable items to user.

---

## Failure modes

| Condition | Action |
|-----------|--------|
| `codex` CLI not on PATH | SKIP audit, print `WARN: codex CLI missing — manual review recommended.` Continue to DONE. |
| `codex login status` returns unauthenticated | SKIP audit, print `WARN: codex auth failed (run 'codex login') — manual review recommended.` Continue to DONE. |
| Codex output unparseable (no `SCORE:` line) | Retry once with reinforced prompt. If still unparseable → SKIP audit, print warning. |
| All 3 rounds fail to cross 8.0 | `STATUS: DONE_WITH_CONCERNS`. Print top 5 unfixed bugs to user. |
| Cumulative cost > $5 mid-loop | Same as above. |
| Codex response timeout (>5 min) | Kill, retry once with smaller batch (split files in half). If second attempt also times out → SKIP. |

**Critical:** the skill MUST NOT silently fail. Every skip / abort path emits
a visible WARN line so the user knows to do manual review.

---

## Output artifact

Path: `_process/audits/round_{N}_audit.md`

Schema:

```markdown
# Codex Student Audit — Round {N}

**Date:** {ISO datetime}
**Course:** {course_code}
**Exam datetime:** {exam_datetime}      ← from EXAM_METADATA, not inherited
**Score:** {score}/10
**Pass-probability:** {pct}%
**Cost this round:** ${cost}
**Cumulative cost:** ${cumulative}

## Bugs found ({count})
{bug_list_grouped_by_severity}

## Fixed since last round
{diff_from_round_N_minus_1}

## Still broken
{persistent_bugs}

## Verdict
{DONE | CONTINUE | DONE_WITH_CONCERNS}

## Score progression
| Round | Score |
|-------|-------|
{full_history}
```

Final summary printed to user (regardless of outcome):

```
Codex-student audit: round {N} → {score}/10 ({prob}% pass-probability).
Score progression: {6.2 → 7.5 → 8.1}
Status: {DONE | DONE_WITH_CONCERNS}
Audit log: _process/audits/round_{N}_audit.md
```

---

## Cross-references

- **Triggered from:** `SKILL.md` Step 10.5
- **Reads:** `ipad_topic_packs/_source_md/*.md`, `EXAM_METADATA` from Turn 1
- **Writes:** `_process/audits/round_*_audit.md`
- **Related validation rules:** `docs/ARCH_dialogue.md` §EXAM_METADATA gate
- **Related cost spec:** `docs/COST_BUDGET.md`
