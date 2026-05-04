# Changelog

## v0.4.0 (2026-05-02) — initial public release

First open-source release. 4 internal review iterations completed (incl. /codex peer review).

### Added
- 5-archetype scope routing (calc-heavy STEM full / proof-math partial / live-coding refused / MCQ Anki-only / essay refused)
- 3-mode validation (Mode A N≥3 STANDARD / Mode B N=1-2 SPARSE / Mode C N=0 ZERO-PAPER)
- 4-quadrant TRAP WATCH matrix (lecturer emphasis × past-paper frequency)
- Tier-based dependency probe (`bin/check_deps.sh`) with graceful fallback
- 17 fallback adapters for missing dependencies
- Reference implementation: NTU SC4003 Intelligent Agents (AY2425)

### Known limitations (V1)
- Validated on 1 course only
- Multi-doc consistency requires careful editing (SKILL.md is authoritative)
- No grade prediction — produces study plan, not score forecast
