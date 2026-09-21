# The 29% coverage ceiling: what it is, whether it can be estimated, and a formal sensitivity distribution

Prepared 21 September 2026, in response to Reviewer 3, weakness 1 ("the 29% ceiling
appears arbitrary"). Script: `scripts/05_coverage_ceiling.R`.

## 1. Reproduction

The published beneficiary projection is reproduced exactly:

| | 2030 coverage | 2030 beneficiaries | 2035 coverage | 2035 beneficiaries |
|---|---|---|---|---|
| Published | 0.27466 | 59,593,837 | 0.29000 | 63,616,502 |
| Reproduced | 0.27466 | 59,593,837 | 0.29000 | 63,616,502 |

The generating mechanism is the fallback branch of the pipeline, not the logistic
specification. `nls(cob ~ K/(1 + exp(-(a + b·t))))` with the pipeline's own starting
values (K = 0.28, a = −1.0, b = 0.15) does not converge on six annual observations, so
the code falls through to a logit-linear trend in coverage, projects it, and clips the
result at 0.29. The clip becomes binding in 2033; before that the projection is the
uncapped trend, which reaches 0.3287 by 2040 and has an asymptote of 1.0.

This matters for how the ceiling should be described. It is not a saturation parameter
of the model — the manuscript already says so in Methods ("an imposed cap, not an
estimated saturation parameter") — but the Results text and Table S2 discuss it as if it
were a modelling choice among alternatives. It is a boundary condition applied after
projection.

## 2. A free asymptote is not identified from these data

The reviewer's objection has a stronger answer than "the value is defensible": no value
is estimable. Three lines of evidence.

**Starting-value dependence.** With K free, the logistic converges from one of four
starting configurations and fails from the other three; Gompertz converges from one of
five. Where they do converge:

| Specification | K | SE |
|---|---|---|
| Logistic, K free | 0.2630 | 0.0095 |
| Gompertz, K free | 0.2644 | 0.0107 |

Both land ~1.5 percentage points above the last observed coverage (0.24787) — the
classic fragile-asymptote result, in which the estimated ceiling is pinned to the end of
the observed sample rather than to any saturation behaviour in the data.

**A flat concentrated profile.** Fixing K on a grid and optimising (a, b) at each point:

| K | RSS | R² | ΔRSS vs minimum |
|---|---|---|---|
| 0.25 | 1.14e−05 | 0.9706 | +243% |
| 0.26 | 3.32e−06 | 0.9914 | — |
| 0.27 | 3.56e−06 | 0.9908 | +7% |
| 0.29 | 5.34e−06 | 0.9863 | +61% |
| 0.32 | 7.03e−06 | 0.9819 | +112% |
| 0.35 | 7.97e−06 | 0.9795 | +140% |
| 0.50 | 9.64e−06 | 0.9752 | +190% |
| 0.60 | 1.00e−05 | 0.9742 | +201% |

R² stays between 0.9706 and 0.9914 as K ranges from 0.25 to 0.60. A doubling of the
assumed market ceiling costs less than two points of R². The fit does not discriminate.

**A profile-likelihood interval that does not close.** For the one converging logistic,
the 95% profile interval for K has a lower limit of 0.2510 and no attainable upper limit
(the Wald interval, 0.2444 to 0.2816, is not credible here: n = 6, three parameters).
An unbounded upper profile limit is the standard signature of an unidentified asymptote.

## 3. A formal sensitivity distribution replaces the three fixed values

Instead of the three point ceilings used in S2 (25%, 29%, 32%), we place a distribution
on the cap: **K ~ Normal(0.287, 0.02) truncated to [0.20, 0.35]**, with 20,000 draws
(seed 42). The location is the mean of the three ceilings previously used; the scale
spans the range of Brazilian hospital-medical coverage over the last two decades; the
truncation bounds sit below the 2020 observed coverage and a third above the current
level.

| Horizon | Draws in which the cap binds | Inertial claims, median | 95% range | Width |
|---|---|---|---|---|
| 2030 | 27.0% | 745,321 | 670,925 – 745,321 | 74,396 |
| 2035 | 76.0% | 1,066,682 | 919,092 – 1,118,934 | 199,841 |

The 2030 interval is one-sided by construction: a cap can only remove beneficiaries from
the uncapped trend, never add them, so the upper limit coincides with the median. This
is a property of the mechanism, not an artefact of the draws, and it should be stated as
such rather than presented as a symmetric interval.

## 4. Effect on the policy-to-market ratio

| Component | Value |
|---|---|
| Policy range, nominal scenarios as published | 419,425 |
| Policy range, response surface (τ_d 3 to 20) | 348,799 |
| Market range, three fixed ceilings as published | 66,918 |
| Market range, formal ceiling distribution | 74,396 |

| Ratio | Value |
|---|---|
| As published | 6.27 : 1 (reported as 6.3 : 1) |
| Published policy range / formal market range | 5.64 : 1 |
| Response surface / formal market range | 4.69 : 1 |

Replacing the fixed ceilings with a distribution widens market-size uncertainty by 11%
and moves the ratio from 6.3 : 1 to between 4.7 : 1 and 5.6 : 1, depending on which
policy range is used. The qualitative conclusion survives in every combination:
regulatory response dominates market size by roughly half an order of magnitude. But the
specific figure "6.3 to 1" is an artefact of comparing a policy range computed across
scenarios with a market range computed across three arbitrary point values, and it
should not be carried into the Abstract as a precise quantity.

## 5. What this implies for the revision

1. Keep the 29% cap as the primary specification and keep the existing honest Methods
   sentence, but add the identification result: a free asymptote is not estimable from
   six annual observations, which is *why* a cap is imposed rather than estimated.
2. Replace S2's three fixed ceilings with the truncated-normal sensitivity above, and
   report the one-sided character of the 2030 interval explicitly.
3. Recompute the policy-to-market ratio with the formal market range, and report it as
   an approximate magnitude ("roughly fivefold", "about half an order of magnitude")
   rather than as 6.3 : 1.
4. Remove any residual framing of the cap as a modelling alternative; it is a boundary
   condition applied post hoc.

## Reproducibility

```
Rscript scripts/05_coverage_ceiling.R
```

R 4.x with `readr` and `dplyr`. Seed 42, 20,000 draws. Inputs:
`data/ans_beneficiaries_projected.csv` (observed coverage 2020–2025 and IBGE population
projections, 2024 revision).
