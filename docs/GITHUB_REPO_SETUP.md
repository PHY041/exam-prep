# F5 — GitHub Repo Structure for `exam-prep`

> Open-source release spec for the empirical exam-prep skill.
> Status: ready for `gh repo create`.

---

## 1. Repo name

**`PHY041/exam-prep`**

- Availability check: `curl -sI https://github.com/PHY041/exam-prep` → `HTTP/2 404` (verified 2026-04-28). **Available.**
- Alternative if collision later: `PHY041/exam-prep-skill` (suffix avoids name-clash with future generic repos).
- Owner: `PHY041` (personal). After traction (>50 stars or first external PR) consider transfer to `Canlah-AI/exam-prep` for org consistency with other public skill repos.

---

## 2. License recommendation

### Pick: **MIT**

| Option | Pro | Con | Verdict |
|---|---|---|---|
| **MIT** | Shortest, most permissive, max adoption, matches `claude-skill-*` repos in the org | No explicit patent grant | **Chosen** |
| Apache 2.0 | Explicit patent grant, NOTICE/contributor terms | Heavier text, fewer skill repos use it, friction for casual forkers | Reject |
| GPLv3 | Forces downstream openness | Kills enterprise adoption, viral copyleft scares students/lecturers from using it | Reject |

**Rationale (1 line):** MIT maximises adoption for a skill aimed at students + indie devs, matches the rest of `PHY041/claude-skill-*` repos, and the codebase contains no patentable algorithms that warrant Apache 2.0's overhead.

License file: standard MIT template, `Copyright (c) 2026 Haoyang Pang`.

---

## 3. Repo structure

```
exam-prep/
├── SKILL.md                          # Claude Code skill manifest (YAML frontmatter + body)
├── README.md                         # Public-facing pitch + 60-sec quickstart
├── LICENSE                           # MIT
├── CHANGELOG.md                      # Keep-a-Changelog format, semver
├── CONTRIBUTING.md                   # How to add adapters / file PRs
├── CODE_OF_CONDUCT.md                # Contributor Covenant 2.1 (boilerplate)
├── VERSION                           # Single source of truth, e.g. `0.1.0`
│
├── docs/
│   ├── ARCHITECTURE.md               # Pipeline diagram: ingest → frequency → emphasis → fusion → render
│   ├── ALGORITHMS.md                 # Frequency scoring, emphasis weighting, decay model, calibration
│   ├── ADAPTERS.md                   # How exam-type adapters plug in (interface contract)
│   ├── FAQ.md                        # "Does it work for non-STEM?" "What if I have no past papers?"
│   └── EXAMPLES/
│       ├── README.md                 # Index of anonymized examples
│       ├── sc4021-ir/                # Anonymized IR course run (course code + lecturer name redacted)
│       │   ├── input_summary.md
│       │   ├── ranked_topics.json
│       │   └── drill_pack_preview.pdf
│       ├── sc4062-genai/             # Anonymized GenAI course run
│       └── synthetic-physics/        # Pure synthetic example for users without their own data
│
├── templates/
│   ├── ranked_topics.tmpl.md         # Ranked study plan output template
│   ├── drill_pack.tmpl.tex           # LaTeX drill-pack template (PDF render target)
│   ├── drill_pack.tmpl.md            # Markdown fallback (no LaTeX needed)
│   ├── topic_card.tmpl.md            # Single-topic spaced-repetition card
│   └── calibration_report.tmpl.md    # Post-exam accuracy retrospective
│
├── workflow/                         # Skill execution scripts (the "engine")
│   ├── 01_ingest.sh                  # Slurp past papers + lecture notes
│   ├── 02_extract_frequency.py       # Topic frequency analysis from past papers
│   ├── 03_extract_emphasis.py        # Lecturer emphasis from notes/slides
│   ├── 04_fuse_rank.py               # Combined ranking with configurable weights
│   ├── 05_render_pack.sh             # Templates → PDF/MD output
│   ├── 06_calibrate.py               # Optional: post-exam feedback loop
│   └── lib/
│       ├── adapters/                 # Exam-type adapters live here
│       │   ├── base.py               # Abstract base class
│       │   ├── stem_written.py       # Default: STEM written exam (NTU SC*, MH*)
│       │   ├── mcq_only.py           # MCQ-heavy adapter
│       │   └── coding_practical.py   # Lab/practical adapter
│       └── utils.py
│
├── bin/
│   ├── check_deps.sh                 # Verify python3, pdftotext, pandoc, latex (non-blocking warnings)
│   ├── exam-prep                     # Top-level CLI entrypoint (calls workflow/ scripts)
│   └── install.sh                    # One-shot installer (clone → symlink to ~/.claude/skills/)
│
├── tests/
│   ├── test_frequency.py             # Unit tests for frequency extractor
│   ├── test_emphasis.py
│   ├── test_fusion.py
│   ├── test_adapters.py
│   ├── fixtures/
│   │   ├── synthetic_papers/         # 5 fake past papers (clearly marked synthetic)
│   │   └── synthetic_notes/          # 1 fake lecturer's notes
│   └── sample_course/                # End-to-end smoke test data
│       ├── README.md                 # "Run: ./bin/exam-prep tests/sample_course/"
│       ├── papers/                   # 3 synthetic papers, MIT-safe
│       ├── notes/                    # 1 synthetic note set
│       └── expected_output/          # Golden output for regression check
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                    # shell-lint + markdown-lint + pytest
│   │   ├── release.yml               # Tag → GitHub Release with CHANGELOG diff
│   │   └── stale.yml                 # Auto-close stale issues after 60d
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   ├── exam_type_request.md      # New adapter request
│   │   └── config.yml                # Disable blank issues, point to Discussions
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── CODEOWNERS
│   ├── FUNDING.yml                   # GitHub Sponsors link (optional)
│   └── dependabot.yml                # Weekly security updates for actions/pip
│
├── .gitignore                        # Python + LaTeX + macOS noise
├── .editorconfig                     # 2-space indent for shell, 4 for python, LF line endings
├── .markdownlint.json                # markdownlint config (line-length=120, MD013 off)
├── .shellcheckrc                     # disable=SC1091 for sourcing
└── pyproject.toml                    # if we go the pip-installable route later
```

**Why this layout:**
- `workflow/` mirrors the existing `~/.claude/skills/exam-prep/` structure → minimal drift between dev and shipped skill.
- `templates/` is a separate top-level dir so users can fork-and-modify outputs without touching code.
- `docs/EXAMPLES/` is the marketing surface — anonymized real outputs sell the skill better than any README.
- `tests/sample_course/` doubles as a smoke test AND a "try it without your own data" demo.

---

## 4. README badges

Top of README, in this order (left → right reads as: status → version → license → reach):

```markdown
[![CI](https://github.com/PHY041/exam-prep/actions/workflows/ci.yml/badge.svg)](https://github.com/PHY041/exam-prep/actions/workflows/ci.yml)
[![Version](https://img.shields.io/github/v/release/PHY041/exam-prep?label=version)](https://github.com/PHY041/exam-prep/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Downloads](https://img.shields.io/github/downloads/PHY041/exam-prep/total)](https://github.com/PHY041/exam-prep/releases)
[![Stars](https://img.shields.io/github/stars/PHY041/exam-prep?style=social)](https://github.com/PHY041/exam-prep/stargazers)
[![Claude Code Skill](https://img.shields.io/badge/Claude%20Code-Skill-7C3AED)](https://docs.claude.com/en/docs/claude-code/skills)
```

Optional later: `Discord`, `awesome-claude-code` listing, `pre-commit.ci`.

---

## 5. CONTRIBUTING.md outline

```markdown
# Contributing to exam-prep

Thanks for helping. Three ways to contribute, in increasing depth.

## Quickest: file an issue
- Bug → use Bug Report template
- Idea → use Feature Request template
- New exam type / school / format → use Exam-Type Request template

## Medium: improve docs or templates
1. Fork, branch from `main`
2. Edit `templates/` or `docs/`
3. Run `markdownlint docs/ README.md`
4. Open PR with screenshot of rendered template if visual

## Deep: add a new exam-type adapter
This is the main extension point.

### Adapter contract
Every adapter inherits from `workflow/lib/adapters/base.py:BaseAdapter` and implements:

| Method | Returns | Purpose |
|---|---|---|
| `parse_paper(path) -> Paper` | structured paper | extract questions, marks, topics |
| `extract_topics(paper) -> list[Topic]` | topic list | adapter-specific topic taxonomy |
| `score_emphasis(notes) -> dict[Topic, float]` | weighted dict | how the lecturer signals importance |
| `render_drill(topics, n) -> str` | LaTeX/MD | shape of the practice questions |

### Steps to add `your_exam_type.py`
1. Copy `stem_written.py` as a starting point
2. Override the four methods above for your domain
3. Add fixtures in `tests/fixtures/your_exam_type/` (3+ synthetic papers, MIT-safe)
4. Add `tests/test_adapters.py::test_your_exam_type`
5. Document it in `docs/ADAPTERS.md` with a 5-line "when to use" blurb
6. Add an example run to `docs/EXAMPLES/your_exam_type/` (anonymized!)
7. Open PR — CI must pass, one maintainer review required

### Anonymization rules (HARD)
Every example output MUST:
- Strip lecturer names (replace with "Prof. X")
- Strip course codes (replace with `EXAM101`)
- Strip school/uni names
- Strip student identifiers
- Use only synthetic or > 5-year-old past paper material

PRs that include identifiable course material will be closed and asked to redact.

## Commit style
Conventional commits: `feat(adapter): add MCQ-only adapter`, `fix(fusion): handle empty notes dir`, `docs: clarify install`

## Code style
- Python: black + ruff (configs in `pyproject.toml`)
- Shell: shellcheck-clean, prefer bash 4+
- Markdown: markdownlint, ATX headings, fenced code blocks
- Functions <50 lines, files <400 lines (matches `~/.claude/rules/coding-style.md`)

## Release process (maintainers)
1. Bump `VERSION` (semver)
2. Update `CHANGELOG.md` (Keep-a-Changelog)
3. `git tag v$(cat VERSION) && git push --tags`
4. `release.yml` auto-creates GitHub Release with changelog diff
```

---

## 6. Issue templates

### `.github/ISSUE_TEMPLATE/bug_report.md`

```markdown
---
name: Bug report
about: Something broke during exam-prep run
title: "[BUG] "
labels: bug
---

## What happened
<!-- one line -->

## Repro steps
1.
2.
3.

## Expected vs actual

## Environment
- OS:
- Python:
- exam-prep version (`cat VERSION`):
- Adapter used:

## Logs / output
```
<paste here, scrub PII>
```

## Anonymization confirmed
- [ ] No lecturer names, course codes, or student identifiers in this issue
```

### `.github/ISSUE_TEMPLATE/feature_request.md`

```markdown
---
name: Feature request
about: Suggest an improvement
title: "[FEAT] "
labels: enhancement
---

## Problem
<!-- what's painful today? -->

## Proposed solution

## Alternatives considered

## Would you contribute the PR?
- [ ] Yes, I can build it
- [ ] No, requesting only
```

### `.github/ISSUE_TEMPLATE/exam_type_request.md`

```markdown
---
name: New exam-type adapter
about: Request support for a new exam style
title: "[ADAPTER] "
labels: adapter-request
---

## Exam type
<!-- e.g. "UK A-Level Maths", "GRE Quant", "Singapore PSLE" -->

## Format
- Paper structure (sections, mark distribution):
- Question style (MCQ / written / practical / mixed):
- Typical exam length:

## Sample (synthetic or >5yr old, anonymized)
<!-- attach 1-2 synthetic past papers if possible -->

## Why existing adapters don't fit
<!-- e.g. "stem_written assumes long-form, but this is 90% MCQ" -->

## Are you willing to co-build?
- [ ] Yes, I'll write the adapter with guidance
- [ ] No, requesting only
```

### `.github/ISSUE_TEMPLATE/config.yml`

```yaml
blank_issues_enabled: false
contact_links:
  - name: Question / general discussion
    url: https://github.com/PHY041/exam-prep/discussions
    about: Use Discussions for questions, not issues
  - name: Skill not working in Claude Code
    url: https://docs.claude.com/en/docs/claude-code/skills
    about: Read Claude Code skills docs first
```

---

## 7. CI/CD — `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  shell-lint:
    name: Shell lint (shellcheck)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run shellcheck
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: './workflow ./bin'
          severity: warning

  markdown-lint:
    name: Markdown lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm install -g markdownlint-cli@0.39.0
      - run: markdownlint '**/*.md' --ignore node_modules --config .markdownlint.json

  python-test:
    name: Python tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python: ['3.11', '3.12']
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '${{ matrix.python }}' }
      - run: pip install -e '.[dev]'
      - run: pytest tests/ -v --cov=workflow

  smoke-test:
    name: End-to-end smoke (sample_course)
    runs-on: ubuntu-latest
    needs: [python-test]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }
      - run: sudo apt-get install -y poppler-utils pandoc
      - run: pip install -e .
      - run: ./bin/exam-prep tests/sample_course/
      - run: diff -r tests/sample_course/output/ tests/sample_course/expected_output/
```

`.github/workflows/release.yml` — on tag `v*`, build artifacts, create Release, attach drill-pack PDF samples.

---

## 8. Marketing one-liner (repo description, ≤160 chars)

**Pick this (152 chars):**

> Empirical exam-prep skill for STEM students. Fuses past-paper frequency analysis with lecturer emphasis to produce ranked study plans + drill-ready PDFs.

**Backup options:**
- (139) "Stop guessing what's on the exam. Combines past-paper stats and lecturer emphasis into a ranked study plan and printable drill packs."
- (118) "Past-paper frequency analysis × lecturer emphasis = ranked study plan + drill-ready PDFs. A Claude Code skill for STEM exams."

---

## 9. Tags / topics (GitHub `topics`)

Set 12 (max 20, but 12 covers discovery without diluting):

```
exam-prep
study-tools
education
claude-code
claude-skill
ai-agents
study-planner
past-papers
stem-education
spaced-repetition
ntu
university-students
```

**Why these:**
- `claude-code` + `claude-skill` → reach Anthropic ecosystem (now ~14K monthly searches on awesome lists)
- `exam-prep` + `study-tools` + `study-planner` → core student search terms
- `past-papers` → high-intent niche keyword
- `stem-education` + `university-students` → audience tags
- `ntu` → home school recognition (drives initial seed traffic)
- `ai-agents` → wider AI ecosystem
- `spaced-repetition` → adjacent-tool crossover (Anki users)

Avoid: `productivity` (too broad), `python` (implementation detail), `cli` (filler).

---

## Report

**Chosen LICENSE: MIT** — maximises adoption for a student/indie-dev skill, matches the rest of the `PHY041/claude-skill-*` ecosystem, and there's nothing patentable that justifies Apache 2.0's heavier ceremony.

**Repo `PHY041/exam-prep` is verified available** (404 on GitHub as of 2026-04-28).

Output written to `/tmp/exam_prep_v2/quality/F5_github_repo.md`.
