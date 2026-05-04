---
title: "{{COURSE_CODE}} Pack {{PACK_NUM}} — {{TOPIC}}"
subtitle: "{{ONE_LINE_PITCH}}"
geometry: margin=0.7in
fontsize: 11pt
mainfont: "Helvetica"
monofont: "Menlo"
header-includes:
  - \usepackage{fancyhdr}
  - \usepackage{amsmath}
  - \usepackage{siunitx}
  - \pagestyle{fancy}
  - \fancyhead[L]{{{COURSE_CODE}} Pack {{PACK_NUM}} — {{TOPIC_SHORT}}}
  - \fancyhead[R]{\thepage}
---

<!--
  Generic topic pack. One pack = one exam-question-shaped concept.
  Course-agnostic: works for CS, physics, engineering, IB Math, chemistry,
  econ — anywhere you have past papers and a repeating question shape.
  Keep packs to 200-400 lines. They print to ~5-10 PDF pages each.

  Substitution model:
    {{COURSE_CODE}}      e.g. "SC4003" / "IB-PHY-SL" / "EE3331C" / "MATH-AA-HL"
    {{TOPIC}}            the exam-question-shaped concept (e.g. "Newton's 2nd Law (Linear Dynamics)")
    {{TOPIC_SHORT}}      header-tab version (e.g. "Newton 2")
    {{ONE_LINE_PITCH}}   e.g. "5 past FBD problems + method + worked solutions"
    {{HIT_RATE}}         e.g. "5/5" (from past-paper-analysis)
    {{TOTAL_MARKS}}      sum across past papers (or "% of paper" if unmarked)
    {{GOVERNING_LAW}}    formal definition / law / theorem / equation
    {{ASSUMPTIONS}}      validity conditions for the law (frictionless? linear? small-angle?)
    {{METHOD}}           step-by-step recipe (procedural OR derivation-style)
    {{WORKED_EXAMPLE}}   1+ fully solved past-paper instance
    {{RECALL_CARD}}      end-of-pack memorization checklist

  Two question archetypes this template supports:
    A. PROCEDURAL (CS/discrete math/algorithms): plug-and-chug recipe
    B. DERIVATIONAL (physics/engineering/calc): law → diagram → equations → solve → check units
-->

# Why this pack matters

**{{TOPIC}} appeared in {{HIT_RATE}} past papers** {{FREQUENCY_NOTE}}.

**Total expected marks: {{TOTAL_MARKS}}.** {{LIKELIHOOD_NOTE}}

**Study time: {{STUDY_TIME}}.** Approach: read → hand-copy once → close book → quiz yourself → redo errors.

---

# Core principle (memorize verbatim)

<!-- For derivation-heavy courses (physics/engineering), state the governing
     law/equation here in its canonical form. For procedural topics, state
     the formal definition + discriminator vs neighboring concepts. -->

**Governing law / definition:**

> {{GOVERNING_LAW}}

**Valid when:** {{ASSUMPTIONS}}

**Units / dimensions:** {{UNITS_OR_DIMENSIONS}}

**One-line discriminator** (vs nearest-neighbor concept): {{DISCRIMINATOR}}

---

# The Method (memorize the recipe)

<!-- Step-by-step recipe. Each step gets its own ## section.
     Procedural topics: be algorithmic.
     Derivational topics: diagram → equations → solve → check.
     Drop / merge steps that don't apply to your topic. -->

## Step 1 — {{STEP_1_NAME}}

**What you do:** {{STEP_1_DEFINITION}}

**How:**
- {{STEP_1_BULLET_1}}
- {{STEP_1_BULLET_2}}

**State explicitly in answer:** "{{STEP_1_PHRASING}}"

## Step 2 — {{STEP_2_NAME}}

**What you do:** {{STEP_2_DEFINITION}}

**How:** {{STEP_2_METHOD}}

**Common pitfall:** {{STEP_2_PITFALL}}

## Step 3 — {{STEP_3_NAME}}

{{STEP_3_BODY}}

## Step 4 — {{STEP_4_NAME}}

{{STEP_4_BODY}}

## Step 5 (optional) — Sanity / dimensional check

<!-- For physics/engineering: ALWAYS include this step. Catches half the errors. -->

- Do the units of the answer match the quantity asked for?
- Limiting cases: does the answer reduce to a known result when a parameter → 0 or → ∞?
- Order of magnitude: is the number physically plausible?

---

# Drill 1 — {{DRILL_1_PAPER}} ({{DRILL_1_TAGS}})

## The problem (verbatim)

{{DRILL_1_VERBATIM_QUESTION}}

## Given / Find / Assume

<!-- Drop this block for purely procedural CS topics. Mandatory for physics/eng. -->

- **Given:** {{DRILL_1_GIVEN}}
- **Find:** {{DRILL_1_FIND}}
- **Assume:** {{DRILL_1_ASSUMPTIONS}}

## Diagram / setup

<!-- Free-body diagram, circuit, control block diagram, phase portrait,
     truth table, automaton — whatever the topic demands. ASCII OK; better
     to insert a hand-drawn scan. Drop if the problem is purely symbolic. -->

```
{{DRILL_1_DIAGRAM}}
```

## Worked answer

### (a) {{DRILL_1_PART_A_TASK}} [{{DRILL_1_PART_A_MARKS}} marks]

{{DRILL_1_PART_A_ANSWER}}

### (b) {{DRILL_1_PART_B_TASK}} [{{DRILL_1_PART_B_MARKS}} marks]

{{DRILL_1_PART_B_ANSWER}}

### (c) {{DRILL_1_PART_C_TASK}} [{{DRILL_1_PART_C_MARKS}} marks]

{{DRILL_1_PART_C_ANSWER}}

**Sanity check:** {{DRILL_1_SANITY_CHECK}}

**Units check:** {{DRILL_1_UNITS_CHECK}}

---

# Drill 2 — {{DRILL_2_PAPER}}

{{DRILL_2_PROBLEM_AND_WORKED_ANSWER}}

---

# Drill 3 — {{DRILL_3_PAPER}}

{{DRILL_3_PROBLEM_AND_WORKED_ANSWER}}

---

<!-- Add as many drills as you have past-paper instances.
     Aim for >=3 drills per high-frequency pack. -->

# Common pitfalls (avoid in exam)

1. **{{PITFALL_1}}** — {{PITFALL_1_FIX}}
2. **{{PITFALL_2}}** — {{PITFALL_2_FIX}}
3. **{{PITFALL_3}}** — {{PITFALL_3_FIX}}

---

# Speed-drill template (fill in for any new instance)

<!-- A reusable scaffold so the student can solve unseen problems by mapping
     the new inputs onto the same skeleton. Critical for "method, not memorize
     numbers" courses where the examiner uses fresh inputs every year. -->

For a {{INSTANCE_DESCRIPTOR}} (e.g. "two-body system on incline" / "2x2 payoff matrix" / "second-order PID loop"):

1. **{{STEP_1_SHORT}}:** {{STEP_1_PROCEDURE}}
2. **{{STEP_2_SHORT}}:** {{STEP_2_PROCEDURE}}
3. **{{STEP_3_SHORT}}:** {{STEP_3_PROCEDURE}}
4. **{{STEP_4_SHORT}}:** {{STEP_4_PROCEDURE}}
5. **Check:** units + limiting cases + order-of-magnitude.

**Target speed:** {{TARGET_SPEED}} per problem.

---

# Recall card

Tick when you can recite from memory **without notes**:

- [ ] {{RECALL_ITEM_1}}
- [ ] {{RECALL_ITEM_2}}
- [ ] {{RECALL_ITEM_3}}
- [ ] {{RECALL_ITEM_4}}
- [ ] {{RECALL_ITEM_5}}

If you can recite all from memory, **you've banked ~{{BANKED_MARKS}} marks before walking in**.

---
---

# ============================================================
# WORKED EXAMPLE 1 — IB Physics SL: Newton's 2nd Law
# (filled-in instantiation of the template above)
# ============================================================

**Course:** IB-PHY-SL
**Pack:** 03 — Newton's 2nd Law (Linear Dynamics)
**Topic short:** Newton 2
**One-line pitch:** "Every paper has a connected-body or incline FBD problem. Same recipe every time."

## Why this pack matters

**Newton's 2nd law appeared in 6/6 past papers** (May 2019 → Nov 2024 SL P2).

**Total expected marks: ~14** across short-answer + extended-response. **Likelihood of appearing: certain.**

**Study time: 3 hours.**

## Core principle

**Governing law:**

> $$\sum \vec{F} = m\vec{a}$$
>
> Net force on a body equals its mass times its acceleration. Apply per-axis after choosing axes.

**Valid when:** body is treated as a point mass; mass is constant; non-relativistic (v ≪ c); inertial reference frame.

**Units / dimensions:** Force in newtons (N) = kg·m·s⁻². Acceleration in m·s⁻². Always carry units through every line.

**Discriminator:** vs Newton's 3rd law — N2 is about *one* body's net force; N3 is about a force *pair* on two different bodies. If asked "by which force on which body", that's N3 territory.

## The Method

### Step 1 — Draw the free-body diagram (FBD)

**What you do:** for *each* body, draw an arrow per real force acting *on it* (weight, normal, tension, friction, applied). No "force of motion" or "centrifugal" — those don't exist in inertial frames.

**State explicitly:** "Forces on body A: weight $m_A g$ down, normal $N$ perpendicular to surface, tension $T$ along string, friction $f$ opposing motion."

### Step 2 — Choose axes (align with motion)

**What you do:** for incline problems, rotate axes so x is along the incline. For pulley problems, treat the string as one coordinate (positive = the direction the system accelerates).

**Common pitfall:** mixing horizontal/vertical with along/perpendicular-to-incline in the same equation. Pick one frame per body.

### Step 3 — Write $\sum F = ma$ per axis, per body

For body A, x-axis: $T - m_A g \sin\theta - \mu m_A g \cos\theta = m_A a$
For body B, vertical: $m_B g - T = m_B a$

### Step 4 — Solve the simultaneous equations

Add the two equations to eliminate $T$, solve for $a$, back-substitute for $T$.

### Step 5 — Sanity / dimensional check

- Units of $a$: $[N]/[kg] = m\cdot s^{-2}$. ✓
- Limit $\mu \to 0, \theta \to 0$: reduces to $a = m_B g / (m_A + m_B)$ (classic Atwood). ✓
- If $a$ comes out negative, the system accelerates the *other* way — re-check the assumed direction.

## Drill 1 — May 2023 P2 Q4 (15 marks)

**Problem:** A 2.0 kg block on a 30° frictionless incline is connected by a light string over a frictionless pulley to a 3.0 kg hanging mass. Find (a) the acceleration, (b) the tension, (c) the speed after 1.5 s from rest.

**Given:** $m_A = 2.0$ kg, $m_B = 3.0$ kg, $\theta = 30°$, $\mu = 0$, $g = 9.81$ m/s².
**Find:** $a$, $T$, $v(1.5\text{ s})$.
**Assume:** massless string, frictionless pulley, point masses, inertial frame.

**Diagram:**

```
        [B]  3.0 kg
         |
         |  T
        ===
        / |
       /  | T
      /[A] 2.0 kg
     /__30°
```

**(a) Acceleration [6 marks]**

Body A (along incline, up-slope positive): $T - m_A g \sin\theta = m_A a$
Body B (downward positive): $m_B g - T = m_B a$

Add: $m_B g - m_A g \sin\theta = (m_A + m_B) a$

$a = \frac{(3.0)(9.81) - (2.0)(9.81)(0.5)}{2.0 + 3.0} = \frac{29.43 - 9.81}{5.0} = 3.92 \text{ m/s}^2$

**(b) Tension [4 marks]**

$T = m_B(g - a) = 3.0 \times (9.81 - 3.92) = 17.7$ N

**(c) Speed after 1.5 s [3 marks]**

$v = u + at = 0 + 3.92 \times 1.5 = 5.89$ m/s

**Sanity check:** $a < g$ ✓ (system can't free-fall, string holds it). $T < m_B g$ ✓ (if $T = m_B g$ the system wouldn't accelerate).
**Units check:** $a$ in m/s², $T$ in N, $v$ in m/s. ✓

## Common pitfalls

1. **Decomposing weight wrong on incline** — use $m g \sin\theta$ along, $m g \cos\theta$ perpendicular. Drawing it always beats remembering it.
2. **Treating tension as different on the two sides of a massless pulley** — it's the same magnitude. Different tensions only if pulley has mass/friction.
3. **Forgetting to set the same positive direction for both bodies** — pick "the direction the system accelerates", then both equations are consistent.

## Speed-drill template

For any connected-body Newton-2 problem:
1. **FBD each body:** weight, normal, tension, friction, applied.
2. **Axes:** along motion for inclines; vertical for hanging masses.
3. **Equations:** $\sum F = ma$ per axis per body. Tension equal across massless pulley.
4. **Solve:** add equations to eliminate $T$, get $a$, back-sub for $T$.
5. **Check:** units, $a < g$, limits.

**Target speed:** 8 minutes per two-body system.

## Recall card

- [ ] Newton 2 statement: $\sum F = ma$, per body, per axis.
- [ ] Validity: point mass, constant mass, inertial frame.
- [ ] Incline weight components: $mg\sin\theta$ along, $mg\cos\theta$ perpendicular.
- [ ] Atwood limit: $a = (m_B - m_A)g/(m_A + m_B)$ when both hanging, no friction.
- [ ] Tension across massless frictionless pulley: same on both sides.

If you can recite all from memory, **you've banked ~14 marks**.

---
---

# ============================================================
# WORKED EXAMPLE 2 — Engineering: PID Control Tuning
# (filled-in instantiation of the template above)
# ============================================================

**Course:** EE3331C (Feedback Control Systems)
**Pack:** 04 — PID Controller Design (Ziegler-Nichols + closed-loop response)
**Topic short:** PID
**One-line pitch:** "Every final has one PID design problem. ZN tuning rules + step-response analysis = guaranteed marks."

## Why this pack matters

**PID design appeared in 5/5 past finals** (AY1920 → AY2324).

**Total expected marks: ~25** (typically Q3, full long question). **Likelihood: guaranteed.**

**Study time: 4 hours.**

## Core principle

**Governing controller:**

> $$u(t) = K_p e(t) + K_i \int_0^t e(\tau) d\tau + K_d \frac{de(t)}{dt}$$
>
> Or in Laplace: $C(s) = K_p + \frac{K_i}{s} + K_d s = K_p\left(1 + \frac{1}{T_i s} + T_d s\right)$

**Valid when:** plant is approximately LTI; reference and disturbance are bounded; actuator is not saturated.

**Units / dimensions:** $K_p$ dimensionless (or output-units / error-units); $K_i$ in s⁻¹; $K_d$ in s. Time constants $T_i, T_d$ in seconds.

**Discriminator:** vs lead/lag compensator — PID is parametric (3 gains); lead/lag is structural (zero/pole placement). PID handles tracking + disturbance; lead/lag shapes phase margin at a target frequency.

## The Method

### Step 1 — Identify plant model from given data

**What you do:** from a step-response curve, extract dead time $L$, time constant $\tau$, process gain $K$. Or from a transfer function, factor into FOPDT form $G(s) = \frac{K e^{-Ls}}{\tau s + 1}$.

**State explicitly:** "Approximating plant as FOPDT with $K = ...$, $L = ...$, $\tau = ...$"

### Step 2 — Apply Ziegler-Nichols tuning rules

| Controller | $K_p$        | $T_i$    | $T_d$   |
|------------|--------------|----------|---------|
| P          | $\tau/(KL)$  | —        | —       |
| PI         | $0.9\tau/(KL)$ | $L/0.3$ | —       |
| PID        | $1.2\tau/(KL)$ | $2L$    | $0.5L$  |

(Or use ultimate-gain method: $K_u, T_u$ from sustained oscillation → $K_p = 0.6 K_u$, $T_i = T_u/2$, $T_d = T_u/8$.)

### Step 3 — Compute closed-loop transfer function

$T(s) = \frac{C(s)G(s)}{1 + C(s)G(s)}$

### Step 4 — Verify performance specs

Check rise time, overshoot, settling time, steady-state error against requirements. If overshoot > spec, reduce $K_p$ or increase $T_d$. If steady-state error nonzero (P-only), add I term.

### Step 5 — Sanity check

- Steady-state error to step: PI/PID → 0; P-only → $1/(1+K_p K)$. Verify with final-value theorem.
- Stability: all closed-loop poles in LHP.
- Units: $K_p \cdot e(t)$ should produce control signal in actuator units.

## Drill 1 — AY2324 Q3 (25 marks)

**Problem:** A heating process has step response with $L = 2$ s, $\tau = 10$ s, $K = 4$. Design a PID controller using Ziegler-Nichols. Find $K_p, T_i, T_d$, the closed-loop transfer function, and the steady-state error to a unit-step reference.

**Given:** FOPDT plant: $L = 2$, $\tau = 10$, $K = 4$.
**Find:** PID gains, $T(s)$, $e_{ss}$.
**Assume:** linear plant, no actuator saturation, unity feedback.

**Diagram:**

```
   r(t) ─→[Σ]──e──→[ C(s) ]──u──→[ G(s) ]──→ y(t)
          ↑(-)                                  │
          └──────────────────────────────────────┘
```

**(a) Tuning [10 marks]**

ZN PID rules:
- $K_p = 1.2 \tau / (K L) = 1.2 \times 10 / (4 \times 2) = 1.5$
- $T_i = 2L = 4$ s ⇒ $K_i = K_p / T_i = 0.375$ s⁻¹
- $T_d = 0.5 L = 1$ s ⇒ $K_d = K_p T_d = 1.5$ s

**(b) Closed-loop transfer function [10 marks]**

Approximate dead time by Padé(1,1): $e^{-2s} \approx (1 - s)/(1 + s)$.

$C(s) = 1.5 \left(1 + \frac{1}{4s} + s\right) = \frac{1.5(4s^2 + 4s + 1)}{4s}$

$G(s) \approx \frac{4(1-s)}{(1+s)(10s+1)}$

$T(s) = \frac{C(s)G(s)}{1 + C(s)G(s)}$ — leave as expression unless numerical roots requested.

**(c) Steady-state error [5 marks]**

By final-value theorem: $e_{ss} = \lim_{s\to 0} s \cdot \frac{1}{1 + C(s)G(s)} \cdot \frac{1}{s}$.

As $s \to 0$, $C(s) \to \infty$ (integrator), so $e_{ss} = 0$.

**Sanity check:** $T_d < T_i$ ✓ (standard ZN ratio 1:4). PID with integrator → zero steady-state error to step ✓.
**Units check:** $K_p$ dimensionless, $T_i, T_d$ in seconds. ✓

## Common pitfalls

1. **Mixing parallel and ideal PID forms** — parallel: $K_p + K_i/s + K_d s$; ideal: $K_p(1 + 1/(T_i s) + T_d s)$. Convert: $K_i = K_p/T_i$, $K_d = K_p T_d$.
2. **Using ZN gains as final answer** — ZN gives a starting point with ~25% overshoot. Examiners often want you to *then* tune down $K_p$ to meet a spec.
3. **Forgetting derivative kick** — a step in reference makes $de/dt$ huge. Real implementations put $D$ on measurement only. Mention it in the writeup for full marks.

## Speed-drill template

For any "design a PID for plant X" question:
1. **Identify plant:** FOPDT params $K, L, \tau$ — from step response or by reduction.
2. **Apply ZN table:** $K_p = 1.2\tau/(KL)$, $T_i = 2L$, $T_d = 0.5L$ (PID row).
3. **Form $C(s), T(s)$:** write controller, multiply by plant, close the loop.
4. **Verify specs:** $e_{ss}$ via FVT, overshoot/rise from second-order approx if asked.
5. **Check:** units of gains, integrator → zero $e_{ss}$ to step, all poles LHP.

**Target speed:** 18 minutes per full PID design question.

## Recall card

- [ ] Parallel PID: $u = K_p e + K_i \int e + K_d \dot{e}$.
- [ ] ZN PID rules: $K_p = 1.2\tau/(KL)$, $T_i = 2L$, $T_d = L/2$.
- [ ] Ultimate-gain rules: $K_p = 0.6 K_u$, $T_i = T_u/2$, $T_d = T_u/8$.
- [ ] Final-value theorem: $e_{ss} = \lim_{s\to 0} s E(s)$; PID → 0 for step refs.
- [ ] Derivative kick fix: put $D$ on measurement, not error.

If you can recite all from memory, **you've banked ~25 marks**.
