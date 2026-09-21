# Scenario engine: what reproduces and what does not
Prepared 21 September 2026, in response to Reviewer 2 comments 2 and 3.

## The engine reproduces Table 3 exactly

Running the implemented rules on the corrected series, with the published beneficiary projections,
base growth rate g0 = 0.1886 and the 2025 anchor rate of 6.46055 per 1,000:

| Scenario | 2030 published | 2030 reproduced | 2035 published | 2035 reproduced |
|---|---|---|---|---|
| Optimistic | 390,042 | 390,041 | 364,961 | 364,961 |
| Inertial | 745,323 | 745,321 | 1,078,034 | 1,078,030 |
| Pessimistic | 809,467 | 809,464 | 1,476,388 | 1,476,379 |

Largest discrepancy is nine claims, from rounding of g0. **The scenario engine did not change between
the original and the revised analysis; only the input series did.** Comments 2 and 3 are therefore
matters of documentation and correction, not of re-analysis.

## The implemented optimistic rule

    growth = g0 * max(0, (1 - tau/3) * 0.4)   for tau <= 3
           = -0.03                            for 4 <= tau <= 8
           = -0.02                            for tau >= 9

The declared damping function is `g(tau | tau_d) = max{0, g0 * (1 - tau/tau_d)}`. The inertial
(tau_d = 12) and pessimistic (tau_d = 20) scenarios follow it exactly. The optimistic scenario does
not: it multiplies the damped growth by an extra factor of 0.4 and then applies two tiers of
negative growth that the declared function, floored at zero, cannot produce.

### Year-by-year trajectory

| Year | tau | Growth | Rate /1,000 | Claims |
|---|---|---|---|---|
| 2026 | 1 | +5.029% | 6.785 | 370,139 |
| 2027 | 2 | +2.515% | 6.956 | 388,116 |
| 2028 | 3 | 0.000% | 6.956 | 396,853 |
| 2029 | 4 | -3.000% | 6.747 | 393,492 |
| 2030 | 5 | -3.000% | 6.545 | 390,041 |
| 2031 | 6 | -3.000% | 6.349 | 386,486 |
| 2032 | 7 | -3.000% | 6.158 | 382,810 |
| 2033 | 8 | -3.000% | 5.973 | 378,636 |
| 2034 | 9 | -2.000% | 5.854 | 371,782 |
| 2035 | 10 | -2.000% | 5.737 | 364,961 |

The trajectory peaks at 396,853 claims in 2028 and declines thereafter.

### Three descriptions of the same first year
- Implemented: growth in 2026 is **26.67%** of g0, since (1 - 1/3) x 0.4 = 0.2667.
- Manuscript text: "a 60% reduction in year 1", implying 40% of g0.
- Table 2: "growth falls to 60% of base in year 1", implying 60% of g0.

All three differ. Neither published description mentions the two-tier negative growth after year 3.

## The response surface does not follow the declared function

Evaluating the declared function over tau_d from 3 to 20 years, 2030 claims:

| tau_d | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|
| claims | 460,665 | 503,585 | 550,459 | 601,670 | 640,377 | 670,611 | 694,857 | 714,724 | 731,294 | 745,321 |

| tau_d | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 |
|---|---|---|---|---|---|---|---|---|
| claims | 757,348 | 767,772 | 776,894 | 784,942 | 792,095 | 798,495 | 804,254 | 809,464 |

At tau_d = 3 the declared function gives **460,665**, confirming the reviewer's figure of
approximately 461,000. The reported optimistic scenario is 390,042, and Figure 2A plots that value
as the left end of the curve. The plotted surface therefore does not follow the declared function at
its left end; it substitutes the optimistic scenario's own rule.

| Quantity | Reported | Recomputed from the declared function |
|---|---|---|
| Policy range at 2030 | 419,425 | **348,799** |
| Average change per year of delay | 18,700 | **20,518** |
| Policy-to-market ratio | 6.3:1 | **5.21:1** |

The reported 419,425 is exactly the spread between the optimistic and pessimistic scenarios
(809,467 - 390,042), which is internally consistent with Figure 2A as drawn but not with the
Methods.

The reported 18,700 reconciles with neither: the chord over tau_d 3-20 is 20,518 from the declared
function and 24,672 from the scenario spread; 18,700 would imply a range of about 318,000. Several
plausible derivations were tested, including the mean of consecutive differences and restricted
sub-ranges, and none reproduces it. It has to be recomputed and the method stated.

## Consequences for the revision
1. Decide whether to align the optimistic implementation to the declared function or to document the
   implemented rule as a second, explicitly stated specification. Either way, text, Table 2 and
   Figure 2 must agree with the code.
2. Recompute the response surface, the policy range and the marginal change consistently, and
   redraw Figure 2.
3. Update the ratio in the Abstract, Results and Conclusions. At 5.21:1 the qualitative conclusion
   holds, policy still dominates market size by about five to one, but the reported figure changes.
