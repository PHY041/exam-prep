# /exam-prep

![version](https://img.shields.io/badge/version-0.5.0-blue) ![tested-on](https://img.shields.io/badge/tested--on-NTU%20SC4003%20%2B%20SC4023-green) ![audit-gate](https://img.shields.io/badge/audit--gate-codex--student-orange) ![license](https://img.shields.io/badge/license-MIT-lightgrey)

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

- **NTU SC4003 — Intelligent Agents (AY2425, S2)** — reference impl, 5 PYPs, real exam pass (Apr 30 2026).
- **NTU SC4023 — Big Data Management (AY2425, S2)** — full Mode A pipeline, 3 PYPs + 7 lecture PDFs, 3-round codex-student audit (6.2 → 7.5 → 8.1 score progression, 84% pass probability).

> **Note on validation:** "validated" here means "produced usable materials + student passed or is expected to pass." It does NOT mean "zero defects." The v0.5 codex-student-audit gate (`docs/ALGORITHM_student_audit.md`) is the empirical defect catcher — without it, the SC4003 run would also have shipped with similar latent defects. Your mileage varies by course; please open issues with bug reports.

Other STEM closed-book + past-paper-rich courses are **expected to work** but not yet independently validated.

---

## What changed in v0.5 (May 2026)

After running v0.4 on SC4023 and auditing the output via codex-as-student, 6 P0 defect classes were discovered. v0.5 encodes fixes for each:

| Defect class found | v0.5 fix |
|--------------------|----------|
| Wrong exam time silently inherited from prior run | EXAM_METADATA gate in Turn 1 (`docs/ARCH_dialogue.md`) — never inherit, always re-confirm |
| Worked-answer agents punted with "see lecturer" | No-punt rule in `templates/AGENT_PROMPTS_LIBRARY.md` Prompt 6/7 |
| Narrator commentary leaked into final docs ("Wait —", "Hmm,") | Forbidden-pattern detector in `bin/check_pollution.sh` + Prompt 6/7 hard constraint |
| MapReduce variables undefined in pseudocode | Variable-consistency check in audit gate |
| PYP answers self-contradicting | ONE canonical answer rule in Prompt 7 |
| Master plan numbering/arithmetic drift | SELF-CHECK section in `templates/TEMPLATE_master_plan.md` + `bin/check_master_plan.sh` |
| **No self-validation gate after PDF generation** | **NEW Step 10.5: codex-student-audit** (`docs/ALGORITHM_student_audit.md`) — auto-runs codex with student persona, score gate ≥ 8/10, fix-loop cap 3 rounds |

Score deltas observed on SC4023 across audit rounds: **6.2 → 7.5 → 8.1+** (+1.9). Pass probability: **78% → 84%**.

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

~$1.80–$5.50 per invocation (Claude Sonnet 4.6, with/without prompt caching). v0.5 adds the codex-student-audit gate, which contributes ~$0.30–$0.80 per round (max 3 rounds = ~$1–$2.40 added cost over v0.4's ~$1.30–$4.00 base). Auto-degrades at >$5, hard-fails at >$8. Full breakdown: `docs/COST_BUDGET.md`.

---

## License

MIT (planned at v0.3 GitHub release; see `docs/GITHUB_REPO_SETUP.md` for repo plan).

---

## Contributing

Open issues / PRs welcome. The skill is single-course-validated, so reports of running it on a new course (especially a failure report) are highly valuable. See `docs/GITHUB_REPO_SETUP.md` for the contribution model + how to add adapters for new exam types.
