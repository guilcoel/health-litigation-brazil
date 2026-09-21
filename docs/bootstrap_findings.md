# Bootstrap: justification, sensitivity, and what kind of interval it is
Prepared 21 September 2026, in response to Reviewer 2, comment 5.

## Reproduction

| | 2030 lower | 2030 median | 2030 upper | width |
|---|---|---|---|---|
| Published | 511,204 | 742,791 | 1,074,782 | 563,578 |
| Reproduced | 511,406 | 743,064 | 1,075,125 | 563,719 |

Within 0.04%. Inputs: sigma from the annual log-linear model = 0.0829, base growth 18.87%
(delta-method SE 0.89 pp), 2025 anchor rate 6.4605 per 1,000, damping horizon 12 years,
2,000 iterations, seed 42.

## The halving of the baseline residual standard deviation is not consequential

The reviewer's concern is that halving sigma on the anchor rate "directly affects the uncertainty
estimates". Empirically it barely does, because the 2030 interval is dominated by the compounding
annual noise rather than by uncertainty at the anchor year.

| Factor on sigma | 2030 interval | Width | Median |
|---|---|---|---|
| 0.00, no baseline uncertainty | 518,915 to 1,086,914 | 567,999 | 749,741 |
| 0.25 | 515,104 to 1,064,601 | 549,497 | 744,326 |
| **0.50, as published** | **511,406 to 1,075,125** | **563,719** | **743,064** |
| 1.00, full sigma | 495,781 to 1,085,035 | 589,254 | 747,393 |

Removing the term entirely or doubling it moves the width by about 4%. The ordering is not strictly
monotonic because 2,000 iterations leave visible Monte Carlo noise; the final version should use
20,000 iterations and report across several seeds.

## The plausibility ceiling does not bind at the primary horizon

| Ceiling per 1,000 | 2030 interval | Trajectories at the ceiling in 2030 | 2035 upper bound |
|---|---|---|---|
| 15 | 511,406 to 893,908 | 17.2% | 954,248 |
| 20 | 511,406 to 1,075,125 | 0.7% | 1,272,330 |
| **25, as published** | **511,406 to 1,075,125** | **0.1%** | **1,590,413** |
| 30 | 511,406 to 1,075,125 | 0.0% | 1,831,309 |
| none | 511,406 to 1,075,125 | 0.0% | 1,832,592 |

At 2030 the ceiling is irrelevant: only one trajectory in a thousand touches it, and the interval is
identical whether the ceiling is 20, 25, 30 or absent. It shapes only the upper tail beyond the
primary horizon, and even at 2035 the difference between a ceiling of 25 and no ceiling at all is
15%. The ceiling would matter materially only if set at 15 per 1,000, which is below the level the
pessimistic scenario itself reaches.

The code carries a justification the manuscript does not state: 25 claims per 1,000 beneficiaries is
one claim for every 40 beneficiaries, roughly five times the 2025 level, and above the rate implied
by the IESS pessimistic projection for 2035. That reasoning should be moved into the Methods.

## It is a predictive interval, and the decomposition can be quantified

The annual term `exp(rnorm(1, 0, sigma_anual))` is redrawn every year and multiplies the accumulated
rate, so it compounds over the horizon. It is process noise, not estimation error.

| Source | 2030 interval width |
|---|---|
| Parameter uncertainty only, growth rate and anchor | **148,614** |
| Parameter uncertainty plus annual process noise, as published | **563,719** |

Process noise accounts for 74% of the width. The bounds are predictive and must be labelled as
such, in the Methods and wherever the interval appears.

## The claim about structural uncertainty should be reframed, not retracted

The reviewer observes that the within-scenario interval of about 564,000 exceeds the policy scenario
spread of about 419,000, so the statement that structural uncertainty is "the larger of the two" is
wrong. On those two figures he is right. But the comparison is not like for like: the bootstrap
interval includes annual process noise, which the scenario spread deliberately excludes.

Comparing quantities of the same kind:

| Comparison | Value |
|---|---|
| Parameter uncertainty, no process noise | 148,614 |
| Policy range from the declared damping function, tau_d 3 to 20 | 348,799 |

On that basis structural uncertainty is **2.3 times** the parametric uncertainty, and the
manuscript's claim survives. The fix is to state which comparison is being made and to report both
decompositions, rather than to withdraw the statement.

## What to do in the revision
1. Report the two sensitivity tables above; both support the published choices.
2. Move the ceiling justification from the code comments into the Methods.
3. Relabel the bounds as predictive intervals throughout, including paragraph 88.
4. Rewrite the structural-versus-parametric sentence around the like-for-like comparison, and report
   the parameter-only width alongside the full predictive width.
5. Rerun with 20,000 iterations across several seeds for the final figures.
