# Table S2 rebuilt on the official ANS denominators

Prepared 21 September 2026. Script: `scripts/12_table_s2.R`. This was the last analytical gap
before the figures.

## S1 — SARIMA over alternative estimation windows

**The submitted Table S2 sentence is correct, and this matters for the drift response.** It says
shorter windows "replaced non-seasonal differencing with a drift term". They do:

| Window | n | Selected order | Drift | 2030 claims |
|---|---|---|---|---|
| Full series, 2020–2025 | 72 | (0,1,1)(0,1,0)[12] | no | 652 002 |
| From 2022 | 48 | (0,0,0)(0,1,1)[12] | **yes** | 686 596 |
| From 2023 | 36 | (0,0,0)(1,1,0)[12] | **yes** | 674 419 |

The mechanism is exactly the one that rules the drift out of the primary specification: with d = 0
in the shorter windows, d + D = 1 and a drift becomes admissible. In the full series d = 1 and
D = 1, so it never can be. The same rule explains both facts, and the response letter should use it
that way — the paper's own sensitivity analysis contains the explanation for its own reporting error.

The three 2030 projections span 652 002 to 686 596, a 5.3% spread. Robustness to the estimation
window holds and can be stated more strongly than "the projected upward trajectory was preserved".

### Where the reported drift of +0.119 (SE 0.019) does **not** come from

The drift terms actually fitted in the S1 windows are about **+0.007 per month** (SE 0.0004 to
0.0006), two orders of magnitude away, and annualising them (×12 ≈ 0.087) does not reach 0.119
either. I swept nine further specifications across both denominator series — the rate in levels and
in logs, the raw counts and their logs, with D forced to 0 and with the order left free, and windows
starting in each of 2020 to 2023. **None yields a drift near +0.119, and most fit no drift at all.**

The reportable conclusion is therefore the negative one, stated plainly: the coefficient is not
recoverable from any plausible specification of this series, and the reported prediction interval
matches the driftless fit to within 0.3% (see `docs/validation_claims_correction.md`). Do not offer
the reviewer a guess about its provenance — say it cannot be reproduced and has been removed.

## S2 — Coverage ceilings, inertial 2030

| Ceiling | 2030 coverage | 2030 claims |
|---|---|---|
| 25% | 0.25000 | 691 226 |
| 29% | 0.26735 | 739 191 (cap not reached) |
| 32% | 0.26735 | 739 191 (cap not reached) |

Uncapped 2030 coverage is 0.26735, so the qualitative finding survives the denominator change:
market size constrains the projection only under an implausibly low coverage assumption. The formal
distribution, K ~ Normal(0.287, 0.02) truncated to [0.20, 0.35], gives a median of 739 191 and a 95%
range of 683 607 to 739 191 — width **55 584**, with the cap binding in 16.7% of draws.

## S3 — Base growth rate over alternative reference periods

| Estimator | g₀ | 2030 claims |
|---|---|---|
| Log-linear, 2020–2025 (primary) | 19.41% | 739 191 |
| Point-to-point, 2020–2025 | 17.15% | 686 219 |
| Point-to-point, 2022–2025 | 24.05% | 857 922 |
| Point-to-point, 2023–2025 | 20.38% | 762 899 |

Range across the three point-to-point windows: **686 219 to 857 922 = 171 703 claims**, against the
166 268 reported on the old denominators. The primary log-linear estimate sits inside the range, as
it should.

## The full decomposition — Figure 2 Panel B

| Component | Range at 2030 | Submitted |
|---|---|---|
| Policy (response surface, τ_d 3–20) | **353 564** | ~419 000 |
| Trend estimator (growth-rate windows) | **171 703** | 166 268 |
| Market size (formal ceiling distribution) | **55 584** | 66 918 |

| Ratio | Value |
|---|---|
| Policy : market | **6.36 : 1** |
| Policy : trend | **2.06 : 1** |

The policy component remains the largest by a wide margin, so the paper's central claim is intact.
But note that the trend-estimator component is now **3.1 times** the market component, which makes
the two-way "policy versus market" framing of the Abstract look selective: the second-largest source
of uncertainty is the choice of growth estimator, not market size. Reporting all three ranges in the
Abstract, or at least naming the trend component alongside the ratio, would pre-empt the obvious
follow-up question.

## What this closes and what remains

Phase 1 is now complete: every number in the revision has been recomputed on the two decisions, and
Table S2 has no remaining gaps. The only outstanding analytical item is the **state-level
denominators** for §92 and Table S3, which are not archived and are needed before the
scale-dependence paragraph can be rewritten.

## Reproducibility

```
Rscript scripts/12_table_s2.R
```

R 4.3.3, `forecast` 8.21.1, seed 42. Runs in about a minute.
