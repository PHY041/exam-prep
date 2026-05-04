# /exam-prep

Past-paper frequency analysis + lecturer emphasis fusion for closed-book written exams.

> **Single source of truth: [`SKILL.md`](./SKILL.md).** This README is for humans browsing the repo on GitHub. The skill execution contract, workflow, dependency tiers, taxonomy, dialogue logic, and validation rules all live in `SKILL.md`. If you find a difference between this README and `SKILL.md`, **`SKILL.md` wins**.

---

## Install

```bash
# Clone or copy to ~/.claude/skills/exam-prep/
cp -r exam-prep ~/.claude/skills/

# Probe deps
~/.claude/skills/exam-prep/bin/check_deps.sh
```

Then invoke any of these aliases:

```
/exam-prep    /cram    /drill
```

(All three are equivalent triggers.)

---

## What it does (1-paragraph summary; full operational spec in SKILL.md)

Reads ≥3 past-paper PDFs + lecturer review materials. Produces a ranked study plan + per-topic drill PDFs + per-paper full-answer PDFs + a coverage audit. Unique capability: surfaces discrepancies between what the lecturer emphasizes (RED items) and what they actually test (4-quadrant matrix: CERTAIN / TRAP WATCH / BLUE OCEAN / SKIP).

For the full 10-step pipeline + dependency tiers + algorithm specs, see `SKILL.md` and the `docs/` subfolder.

---

## When to use

- ✅ **Closed-book** written exams with deterministic answers (calc-heavy STEM, IB Math/Physics/Chem HL+SL, NTU/NUS engineering, finance with formulas)
- ⚠ Partial: proof-heavy math (skips verbatim drills), MCQ board exams (Anki-only output)
- ❌ Not supported in V1: live coding (redirect to /investigate), essay-heavy humanities (V2 `/essay-prep` planned), open-book (V2 `/study-companion` planned), oral / lab / viva exams

Full archetype routing logic: `docs/ARCH_scope.md`.

---

## Validated on

- **NTU SC4003 — Intelligent Agents (AY2425, S2)** — reference implementation, 5 past papers (AY1819 / AY2021 / AY2122 / AY2223 / AY2324), used as primary study material through to exam day.

Other STEM closed-book + past-paper-rich courses are **expected to work** but not yet validated.

---

## Folder layout

```
exam-prep/
├── SKILL.md                  ← canonical spec (read this for everything)
├── README.md                 ← you are here (humans only)
├── bin/check_deps.sh         ← dependency probe + capability tier reporter
├── workflow/WORKFLOW_STEPS.md ← step-by-step contracts (input/output per step)
├── templates/                ← 8 v2 templates + agent prompts library
└── docs/                     ← detailed specs (algorithms, adapters, edge cases)
```

---

## Limitations

- Sample size: validated on 1 course. Other courses unknown failure modes.
- No grade prediction. Skill produces a study plan, not a score forecast.
- OCR quality is the dominant failure mode for scanned PDFs.
- Lecturer-emphasis extraction depends on how the lecturer marks slides (color > marker words > vision fallback).
- Network dependency: dependency probe + LLM calls + Claude vision fallback for OCR all require network. "Offline-only" is not a supported mode.

Full audit: `docs/EDGE_CASES.md` (22 cases).

---

## Cost

~$1.30–$4.00 per invocation (Claude Sonnet 4.6, with/without prompt caching). Auto-degrades at >$5, hard-fails at >$8. Full breakdown: `docs/COST_BUDGET.md`.

---

## License

MIT (planned at v0.3 GitHub release; see `docs/GITHUB_REPO_SETUP.md` for repo plan).

---

## Contributing

Open issues / PRs welcome. The skill is single-course-validated, so reports of running it on a new course (especially a failure report) are highly valuable. See `docs/GITHUB_REPO_SETUP.md` for the contribution model + how to add adapters for new exam types.
