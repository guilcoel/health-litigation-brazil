# The two decisions that block Phase 3

Prepared 21 September 2026. Figures 1 and 2 and Tables 1–3 all depend on these, so nothing in the
figure and table pass can start until they are settled. Both are the author's calls, not mine: one
is about data provenance, the other about how to characterise your own analysis to a reviewer.
Scripts: `scripts/09_denominator_choice.R`, `scripts/10_optimistic_rule.R`.

---

## Decision 1 — which beneficiary denominators

The submitted manuscript used a series that differs from the official ANS figures by up to 1.7% in
2020–2022. The ANS series is the citable one; the series used is not reproducible from any ANS
publication we could find.

| Year | ANS official | Used in submission | Difference | Rate, ANS | Rate, used |
|---|---|---|---|---|---|
| 2020 | 47 939 243 | 47 135 000 | −1.68% | 2.930 | 2.980 |
| 2021 | 49 274 613 | 48 566 000 | −1.44% | 2.989 | 3.033 |
| 2022 | 50 530 569 | 49 703 000 | −1.64% | 3.387 | 3.443 |
| 2023 | 51 254 745 | 51 348 000 | +0.18% | 4.461 | 4.453 |
| 2024 | 51 956 946 | 52 210 000 | +0.49% | 5.757 | 5.729 |
| 2025 | 52 865 947 | 52 900 000 | +0.06% | 6.465 | 6.461 |

The discrepancy is systematic in the first three years and negligible from 2023 on, which is what a
retrospective revision of the ANS series looks like.

### What changes if you switch

| Quantity | Denominators used | ANS official | Change |
|---|---|---|---|
| Base growth rate g₀ | 18.87% (SE 0.89 pp) | **19.41%** (SE 0.91 pp) | +0.54 pp |
| Rate in 2020 | 2.980 | **2.930** | −0.050 |
| Rate in 2025 | 6.461 | 6.465 | +0.004 |
| Inertial 2030 | 745 602 | **759 409** | +13 807 (+1.85%) |
| SARIMA 2030 | 672 207 | 669 836 | −2 371 (−0.35%) |

So the cost of switching is small and bounded: the Abstract's headline growth figure moves from
18.9% to **19.4%**, the opening sentence from "2.98 to 6.46" to "**2.93 to 6.46**", and the inertial
2030 projection by under 2%. Every affected number is one you would have to touch anyway in this
revision.

**My recommendation: switch.** The gain is that every denominator in the paper becomes traceable to
a citable ANS source, which is what makes the Data Availability statement true and what a
methodological reviewer will check. The cost is a handful of numbers that are already being edited.
Keeping the current series means either explaining its provenance — and we could not establish it —
or leaving it unexplained in a paper already under criticism for reproducibility.

The one argument for keeping it: switching means the numbers in the revised manuscript differ from
the submitted ones in the Abstract, which has to be declared plainly in the response letter. That
is a presentational cost, not a scientific one.

---

## Decision 2 — the optimistic scenario: align the code, or document the real rule

Reviewer 2 recomputed the optimistic scenario from the equation as declared in the Methods and got
approximately 461 000 claims at 2030, against the 390 042 reported. **The reviewer's arithmetic is
correct.** The declared equation at τ_d = 3 gives 460 665. The code implements something else: a
piecewise rule with accelerated damping in the first three years followed by two fixed negative
growth plateaus (−3% then −2%).

| | 2030 | 2035 | 2040 |
|---|---|---|---|
| As implemented (the published figures) | 390 041 | 364 961 | 331 429 |
| Declared equation at τ_d = 3 | 460 665 | 491 760 | 494 045 |
| Difference | 70 624 | 126 799 | 162 616 |

And the year-1 growth rate has **four** different descriptions in play:

| Source | Year-1 growth, as a share of g₀ |
|---|---|
| Text of the scenarios section — "a 60% reduction" | 40% |
| Table 2 — "falls to 60% of g₀" | 60% |
| Declared equation at τ_d = 3 | 66.7% |
| What the code does | **26.7%** |

The implemented rule also makes the optimistic trajectory **peak at 6.956 per 1 000 in 2027 and then
decline to 5.186 by 2040**, which is the post-2030 kink visible in Figure 1. The declared equation
instead stabilises at 7.730 from 2028 onward. These are qualitatively different stories: sustained
decline versus a plateau.

### Option A — align the implementation to the declared equation

Recompute the optimistic scenario as g(τ|3) = max{0, g₀(1 − τ/3)}. Table 3 changes: 460 665 at 2030
and 491 760 at 2035. Figure 1's optimistic curve loses its kink and becomes a plateau. The scenario
spread narrows, so the policy range falls from 419 425 to 348 799 and the policy-to-market ratio
from 6.3 to roughly 4.7. The response surface already in the paper is exactly this family, so the
optimistic scenario becomes one point on it rather than an exception to it — which is internally
tidier than the current state.

### Option B — keep the implemented rule and document it as a second specification

Report both: the pure damping family for the response surface, and the piecewise rule as an explicit
"sustained reversal" variant, with its own equation stated in full. Table 3 keeps its published
numbers. But the paper then carries two scenario definitions, and the optimistic scenario is no
longer a point on its own response surface, which is the thing the reviewer will notice next.

**My recommendation: Option A.** It costs a recomputation of one column of Table 3 and one curve in
Figure 1, and in exchange the Methods equation, Table 2, the response surface and the scenario
figures finally all describe the same object. Option B keeps a number the reviewer has already
proved inconsistent with the stated method, and asks him to accept a second specification introduced
at revision — a harder sell than conceding the arithmetic.

Either way, the four conflicting descriptions of the year-1 growth rate must be reduced to one, and
the response letter should state plainly that the reviewer's recomputation was right.

---

## What unblocks on each answer

| Decision | Blocks |
|---|---|
| 1 (denominators) | Abstract opening sentence, §29, §76, Table 1, Table S1, Table S2, Figure 1, the base growth rate everywhere |
| 2 (optimistic rule) | Table 2, Table 3, Figure 1, Figure 2 Panel A, the policy-to-market ratio in the Abstract and §86 |

Both feed the same figures, so Phase 3 should start only once both are answered.
