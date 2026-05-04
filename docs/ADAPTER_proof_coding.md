# E3 — Proof + Coding Adapter (V2/V3 stretch)

**Status:** Design spec. Not buildable on V1 pipeline. Proof support targeted for V2; coding support targeted for V3.
**Audience:** Pipeline maintainers + future contributors.
**Owner of this doc:** exam-prep skill team.

---

## 1. Why the current pipeline fails on these exams

The V1 pipeline (E1/E2: closed-form STEM exams) is built on three load-bearing assumptions:

1. **Topic = unit of frequency.** "Eigenvalues showed up 4 times in 5 years" is meaningful because eigenvalue questions look structurally similar.
2. **Past papers leak the test.** A drill bank of paraphrased past questions is high-yield because real exams reuse problem structure.
3. **Lecturer emphasis disambiguates.** When two topics tie on frequency, the slide deck and lecture notes pick the winner.

All three break for proof-heavy math and coding exams. Specifically:

### 1a. Proof-heavy math (e.g., MIT 18.100 Real Analysis, Abstract Algebra)

| V1 assumption | Why it breaks |
|---|---|
| Topic = unit of frequency | "Sequences" appearing 6 times tells you nothing useful. The student already knows sequences will appear. The signal is: *what proof move solved them* — induction? epsilon-N? subsequence extraction? Cauchy criterion? |
| Past papers leak the test | A 2023 problem "prove every bounded sequence has a convergent subsequence" and a 2024 problem "prove a continuous function on \[a,b\] attains its max" are *the same exam* in proof-method terms (both = Bolzano-Weierstrass + extraction) but look completely different by topic. Topic-frequency hides the real signal. |
| Lecturer emphasis disambiguates | Lecturers in proof courses don't emphasize topics — they emphasize *technique* ("you should always try contradiction first when..."). This is encoded in worked examples in lecture notes, not slide bullets. The V1 emphasis extractor (which keys off bold text + repeated phrases) misses it. |

**Net effect on V1:** the ranking is technically correct (sequences > series > continuity) but useless. The student is told "study sequences hard" when what they actually need is "drill 50 epsilon-N proofs and 30 contradiction setups." V1 cannot produce that drill bank because it has no method labels.

### 1b. Coding exams (live coding, take-home, lab practical)

| V1 assumption | Why it breaks |
|---|---|
| Topic = unit of frequency | A coding exam's "topic" (sliding window, DFS, DP) is shallow taxonomy. Real difficulty lives in: (a) *recognizing* which pattern applies in 2 minutes, (b) *coding it cleanly* under time pressure, (c) *language fluency* (off-by-one, edge cases, syntax). None of these are topics. |
| Past papers leak the test | **There are essentially no verbatim repeats.** Every exam invents a new problem. A "frequency analysis" of past coding exams gives you the pattern distribution (e.g., "graph problems: 3/5 years") but the actual problem text is single-use. The V1 paraphrase generator can't turn one past problem into 20 drills — it can only turn it into 1 drill with cosmetic variation. |
| Lecturer emphasis disambiguates | Coding instructors sometimes telegraph patterns ("we'll definitely test recursion") but more often the syllabus is the only signal — and the syllabus over-covers. The V1 emphasis layer adds little here. |

**Net effect on V1:** the pipeline will happily extract "topics" like "arrays, hash maps, trees" and rank them, which is approximately useless because every CS student already knows those will appear. The actionable signal is *pattern recognition speed* + *typing fluency*, neither of which V1 measures or trains.

---

## 2. Proof adapter (partial V1, full V2)

Goal: keep the frequency machinery, but change the unit of count from "topic" to **(topic, proof method)** and add a method-aware drill generator.

### 2a. Method frequency analysis

Re-classify each past-paper proof problem on two axes:

```
axis 1 (V1 already): topic       — sequences, continuity, groups, rings...
axis 2 (NEW):        method      — induction, contradiction, contrapositive,
                                    direct, construction, pigeonhole, extremal,
                                    epsilon-delta, diagonalization
```

Output is a 2D heatmap, not a 1D ranking:

```
                  induction   contradiction   contrapositive   direct   constr.
sequences            12             4               1             6        2
continuity            2             8               3            14        1
series                7             3               0             4        5
groups                4             2               6             8        9
rings                 1             1               2             3       11
```

The student now sees: *"contradiction is the tool for continuity, construction is the tool for ring theory, induction owns sequences."* That's actionable.

**Implementation:** classifier prompt over each past-paper problem. LLM tags `(topic, method, sub-method)`. Calibrate on a labeled set of ~50 problems per course. Method taxonomy is universal across analysis/algebra/discrete math — labeling cost is one-time.

**Cost:** ~$2-5 per course in API calls. Feasible.

### 2b. Topic-specific lemma library

For each (topic, method) cell, attach a small library of *atomic moves* (one-step lemmas + canonical tricks) that combine into proofs.

Example for `(continuity, contradiction)`:

```yaml
lemmas:
  - name: "Sequential criterion"
    statement: "f continuous at a iff for every x_n → a, f(x_n) → f(a)"
    when_to_use: "convert continuity into a sequence statement"
  - name: "IVT"
    statement: "continuous on [a,b], f(a)<0<f(b) → exists c with f(c)=0"
    when_to_use: "existence on intervals"
  - name: "EVT"
    statement: "continuous on [a,b] attains max and min"
    when_to_use: "boundedness on compact sets"
tricks:
  - "Assume not, build a sequence violating the conclusion, contradict continuity via sequential criterion"
  - "Tubular neighborhood: if f(a) > 0 and f continuous, f > 0 on an interval around a"
```

These are extracted once from the textbook + lecture notes. They become the "vocabulary" the drill generator can compose.

### 2c. Standard proof skeleton templates per method

Each method gets a fill-in-the-blank skeleton the student internalizes by repetition:

**Induction skeleton:**
```
Base: verify P(<smallest>).
IH:   assume P(k) for some k ≥ <base>.
Step: show P(k+1). Connect P(k+1) to P(k) via <inductive move>.
       Common moves: peel off last element, double recursion, strong IH.
Conclude by induction.
```

**Contradiction skeleton:**
```
Suppose for contradiction <negation of conclusion, written explicitly>.
Note <negation unpacks to: ∃ counterexample with property X>.
Derive <known true statement> ∧ <its negation>.
Contradiction. Therefore <original conclusion>.
```

**Contrapositive skeleton:**
```
We prove the contrapositive: ¬Q → ¬P.
Assume ¬Q, i.e., <unpacked form>.
Show ¬P, i.e., <unpacked form>.
[Direct proof from here.]
```

The drill generator picks a (topic, method) cell weighted by exam frequency, picks a skeleton, picks 2-3 lemmas from the library, and produces a problem statement + a graded solution sketch using that exact skeleton. Student fills the skeleton; pipeline grades by structural match (does the student's proof have a base case? does it cite a relevant lemma? does it close on a contradiction? — *not* by exact text match).

### 2d. What survives from V1, what's new

| Component | V1 reuse | New for V2 |
|---|---|---|
| PDF/past-paper ingest | ✅ | — |
| Topic extraction | ✅ | — |
| Frequency ranking | ✅ but as joint dist | 2D (topic × method) |
| Lecturer emphasis | ✅ partial | Add "worked example" extractor — count which methods appear in textbook examples |
| Drill generation | ❌ | New: skeleton-based generator |
| Grading | ❌ V1 has none for proofs | New: structural rubric (LLM judge with anchor exemplars) |

---

## 3. Coding adapter (V2 stretch / V3)

Goal: replace topic frequency with **pattern frequency**, add a sandboxed code runner, and bias toward *speed drills* over content drills.

### 3a. Pattern library

Instead of topics, the unit is *algorithmic pattern*:

```
sliding_window, two_pointers, fast_slow_pointers, prefix_sum,
binary_search_on_answer, monotonic_stack, monotonic_deque,
dfs_recursive, bfs_level_order, topological_sort, union_find,
dijkstra, bellman_ford, kruskal,
dp_1d_linear, dp_2d_grid, dp_interval, dp_bitmask, dp_tree,
greedy_exchange_argument, divide_and_conquer, backtracking,
trie, segment_tree, fenwick_tree
```

~25 patterns covers >95% of undergrad coding exams. Library entries:

```yaml
sliding_window:
  signature: "subarray/substring problem with size or sum constraint"
  recognition_signals:
    - "longest/shortest contiguous"
    - "at most K distinct"
    - "sum/product in range"
  template_python: |
    left = 0
    state = ...
    best = ...
    for right in range(len(arr)):
        # extend state with arr[right]
        while not_valid(state):
            # shrink: remove arr[left], left += 1
        best = max(best, right - left + 1)
    return best
  common_pitfalls:
    - "off-by-one when shrinking"
    - "forgetting to update state on shrink"
  drills: [<links to 10 graded problems>]
```

### 3b. Past-question difficulty estimation

For each past coding exam problem, compute a feature vector and train (or rule-extract) a difficulty score:

| Feature | How to extract |
|---|---|
| Pattern (single or compound) | LLM classifier |
| Input size hint (n ≤ ?) | Regex on problem statement |
| Required time complexity | Inferred from input size + pattern |
| Edge case count | LLM count of conditions in problem statement |
| Nested-pattern flag | Whether the solution requires combining ≥2 patterns |

Difficulty ≈ rough mapping to LeetCode Easy/Medium/Hard. Feeds into the drill scheduler so the student warms up on the average past-paper level, not pain-trains on hardest.

### 3c. Language-specific syntax cheatsheet

Per language (Python, C++, Java), a one-page reference of:

- Common stdlib calls used in coding exams (`heapq`, `bisect`, `collections.Counter`, `defaultdict`, `deque`, `sorted(key=...)`)
- Idioms that save 30 seconds (list comprehension, slicing, `*` unpacking)
- Footguns specific to that language (Python: mutable default args; C++: integer overflow; Java: array vs ArrayList)

This is static content, generated once per language and cached. Not LLM-driven.

### 3d. Mock coding environment (the hard part)

This is the V3 stretch. Requires:

- **Sandboxed runner.** Probably Docker container per session, or pyodide/judge0-style remote sandbox. Must enforce CPU/memory/time limits and prevent network calls.
- **Test harness.** Each drill ships with hidden + visible test cases. Visible tests show during practice; hidden tests are revealed at submit. Models the actual exam pressure.
- **Timer.** Configurable: 20-min sprints (interview style), 90-min sets (lab practical), or 4-hour blocks (take-home).
- **Auto-grader.** For each submission: run tests, measure runtime vs reference, report pass-rate + Big-O alignment. Optionally run an LLM critique of code style.
- **Replay.** Save every keystroke or at least intermediate snapshots so the student can review *how they got stuck*, not just final code.

Build vs buy: prefer wrapping an existing OJ (Codeforces gym, LeetCode private problems, Judge0) over rolling our own. The exam-prep skill becomes the *curator* (selects pattern-balanced problems matched to the past-paper difficulty distribution) rather than the runner.

---

## 4. Decision tree — when to use the adapter vs redirect

```
User uploads materials. Pipeline classifies exam type:

├── Closed-form STEM (calculus, physics, intro stats, EE basics)
│     → V1 pipeline. Full power.
│
├── Proof-heavy math
│     ├── Past papers available? → V2 proof adapter (method × topic frequency,
│     │                            skeleton drills, lemma library).
│     └── No past papers (course just launched)?
│           → Degraded mode: pull lemma library from textbook,
│             generate skeleton drills uniformly across methods,
│             warn user: "no frequency signal — coverage mode only."
│
├── Coding exam
│     ├── Take-home / project-style?
│     │     → V3 coding adapter is overkill. Redirect:
│     │       "Take-homes are about design + correctness, not pattern speed.
│     │        Use a code review tool + practice the spec → tests workflow.
│     │        exam-prep doesn't add value here."
│     │
│     ├── Live interview / timed lab?
│     │     ├── V3 available? → Coding adapter (pattern drills + sandbox).
│     │     └── V3 not built yet? → Polite redirect (see §5):
│     │             "exam-prep is content-frequency-driven. For coding exams,
│     │              speed and pattern fluency dominate. We recommend:
│     │              - LeetCode (general patterns)
│     │              - NeetCode 150 (curriculum)
│     │              - Codeforces gym (timed contests)
│     │              - your course's own past problems on the OJ
│     │              We'll gladly extract the pattern distribution from your
│     │              past papers as a one-shot study guide, but we won't
|     |              run your drills."
│
└── Mixed (theory + coding, e.g., MIT 6.046 algorithms)
      → Run both adapters in parallel, merge ranking with theory-side weighted
        higher (since theory problems have past-paper repeats; coding problems
        usually don't).
```

### Routing signal extraction (V1 can do this today)

Run a lightweight classifier on the uploaded syllabus + past papers:

- > 60% of past-paper marks come from "prove that..." → proof-heavy
- > 40% of marks require running code → coding
- LaTeX `\proof` environment density in solutions → proof-heavy
- Code blocks in solutions → coding
- Mix → mixed

Even before V2/V3 ships, this routing prevents V1 from silently producing useless output on the wrong exam type.

---

## 5. V1 fallback — polite redirect

If a user runs V1 exam-prep on a proof or coding exam *today* (V2/V3 not built), the skill should:

### Detect early
After ingest, before generating drills, run the routing classifier above. If proof-heavy or coding is detected:

### Surface a clear message

```
exam-prep detected this is a {proof-heavy | coding} exam.

The current version of exam-prep is optimized for closed-form
STEM exams (calculus, physics, intro stats, etc.) where past
papers repeat structurally. Your exam doesn't fit that mold —
the signal that matters here is {proof method fluency | pattern
recognition speed}, which we don't fully measure yet.

We can still give you:
  ✓ A topic frequency table from past papers
  ✓ Lecturer emphasis cross-reference
  ✓ A coverage checklist

We won't give you (yet):
  ✗ {Method-aware drills with skeleton grading
     | Sandboxed timed coding drills with auto-grading}

Recommended now:
  - {Continue with the partial output above + use a textbook's
     end-of-chapter problems for method drills
     | Pair the topic frequency table with LeetCode/NeetCode
       filtered by the patterns we found}

Want to proceed with the partial output? [Y/n]
```

The redirect is **non-blocking by default** — the user can opt into the partial V1 output, which is still better than nothing (the topic frequency + lecturer emphasis ranking has real value even if it's not the full picture). The skill just refuses to overstate what it produced.

### Track the request

Every redirect logs `{exam_type, course_id, user_id}` to a backlog. When the V2/V3 work prioritizes which course families to support first, the log drives it. (E.g., if 80% of redirects are for real analysis, prioritize the analysis-flavored proof adapter over the algebra one.)

---

## 6. Build order summary

| Phase | What ships | Notes |
|---|---|---|
| V1.1 (now) | Routing classifier + polite redirect | 1 week. No new pipeline, just guardrail. |
| V2.0 | Proof adapter (method × topic, lemma library, skeleton drills, structural grader) | Biggest unknown is the structural grader — needs anchor-exemplar tuning per course family. |
| V2.1 | Proof adapter, second course family (algebra after analysis) | Library work, no new infra. |
| V3.0 | Coding adapter — pattern library + difficulty estimation + static cheatsheets, NO sandbox | Useful as a curated study guide even without a runner. |
| V3.1 | Coding adapter — sandbox + auto-grader (likely Judge0 wrap) | Big infra lift. May be cut if user demand is low. |

---

# Realistic timeline (the question asked)

Estimates assume one full-time engineer + occasional review from a maintainer. Multiply by ~1.5x for part-time.

### Proof support: **3-5 months to V2.0 GA**

- Routing classifier + redirect: **1 week**
- Method classifier + 2D frequency: **3 weeks** (lots of labeling iteration)
- Lemma library extraction tooling + first course (real analysis): **4 weeks**
- Skeleton drill generator: **3 weeks**
- Structural grader (LLM-judge with anchors): **4 weeks** — this is the variance source; could be 2 weeks if the heuristic grader is acceptable, could be 8 if we want >85% agreement with human graders
- Eval + tuning on a real cohort: **3 weeks**
- **Total: ~14-18 weeks ≈ 3.5-4.5 months**, conservative 5.

The lemma library is one-time per course family; second course (abstract algebra) ships in ~4-6 weeks reusing the V2.0 infra.

### Coding support: **6-9 months to V3.1 GA, or 3 months to V3.0 (no sandbox)**

- Pattern library (25 patterns × template + drills): **6 weeks** — content-heavy, needs domain expert review
- Difficulty estimator + curriculum scheduler: **3 weeks**
- Language cheatsheets (Python/C++/Java): **2 weeks**
- Pattern classifier on past papers: **2 weeks**
- → **V3.0 ships at ~13 weeks ≈ 3 months.** This already gives users a curated, frequency-aligned study guide.
- Sandbox runner integration (Judge0 wrap or similar): **6 weeks** including security review
- Test-case authoring tooling + grader: **4 weeks**
- Replay/timer/UX: **3 weeks**
- Eval on a real cohort: **3 weeks**
- → **V3.1 ships at ~29 weeks ≈ 7 months.** Add a 2-month buffer for sandbox security iteration → **~9 months**.

If we never ship the sandbox (V3.0 only, redirect to LeetCode/Codeforces for the running), coding support is realistically **~3 months** of real work.

### Combined recommendation

Ship V1.1 routing + redirect immediately (1 week, near-zero risk). Then commit to V2 proof adapter as the next major (4-5 months). Re-evaluate coding adapter demand from the redirect log before starting V3 — if demand is concentrated on take-homes (where exam-prep adds little) rather than timed live coding, skip V3 entirely and keep the redirect as the permanent answer.
