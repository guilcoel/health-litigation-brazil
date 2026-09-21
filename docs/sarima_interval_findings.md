# The SARIMA specification: order, the drift term, and the prediction interval

Prepared 21 September 2026, in response to Reviewer 2, comments 1 and 4.
Script: `scripts/06_sarima_intervals.R`.

## 1. The order

`auto.arima` on the national rate series selects **ARIMA(0,1,1)(0,1,0)[12]**, MA(1) coefficient
−0.656 (SE 0.103). The manuscript reports the seasonal period as **[8]**, which is a transcription
error: the series is monthly and no automatic selection on monthly data returns a period of 8.
Correct to [12] in §76, Table S1 and Table S3.

## 2. The drift term does not exist and cannot exist

The selected coefficient vector contains only `ma1`. Forcing it:

```
Arima(rate, order = c(0,1,1), seasonal = c(0,1,0), include.drift = TRUE)
warning: No drift term fitted as the order of difference is 2 or more.
coefficients actually fitted: ma1
```

This is structural, not a property of this series: `forecast::Arima` never fits a drift when
d + D ≥ 2, and the published specification has d = 1, D = 1. The reported drift of **+0.119
(SE 0.019)** cannot come from this specification. Forcing (0,1,1) with drift and D = 0 gives drift
0.0036 (SE 0.0044), not significant, and MAPE 15.25% — so that is not the source either.

Every occurrence must go: §47, §76 (including the coefficient), §90, §92, §96, Table S1, Table S3.

## 3. What is lost, and what is not

**Not lost: the point forecast.** The driftless model gives **672,207** claims at 2030 against
**671,400** published — 0.12% apart. The drift was never doing the work in the headline number,
which is why the rest of the paper is unaffected.

**Lost: the stated justification for the interval.** The manuscript argues in §47 and §76 that the
drift is what "yields prediction intervals of bounded relative width over the primary horizon,
rather than intervals that widen without limit and cross zero". Measured on the driftless model:

| Year | Rate (per 1,000) | 95% interval | Relative width | Crosses zero |
|---|---|---|---|---|
| 2026 | 7.43 | 6.33 – 8.53 | 0.30 | no |
| 2028 | 9.36 | 5.71 – 13.00 | 0.78 | no |
| 2030 | 11.28 | 4.04 – 18.52 | 1.28 | no |
| 2035 | 16.09 | −3.40 – 35.58 | 2.42 | **yes** |

In claims: 2030 is 672,207 [240,658 – 1,103,757].

So "bounded relative width" is false — the width quadruples from 2026 to 2030. "Does not cross zero
over the primary horizon" happens to be true, because the crossing occurs after 2030. The
justification has to be rebuilt on grounds that survive: SARIMA is retained as the primary model
because it is the only one of the four that produces a calibrated prediction interval at all, and
because its point forecast was validated out of sample against the withheld January–May 2026 data.
The interval's own widening should be stated as a limitation on the long horizon, not presented as
a virtue.

## 4. The monthly MAPE the reviewer asks for

| Quantity | Value |
|---|---|
| Monthly MAPE, driftless (0,1,1)(0,1,0)[12] | **7.82%** (published 7.84%) |
| Range of individual monthly errors | 0.61% to 20.81% |
| Error on the 2025 annual total | 6.65% |

The 7.84% in Table S1 is a monthly figure, and the Methods should say so. The annual total is more
accurate than any single month because month-level errors partly cancel — which is the honest
explanation for why the paper's annual projections validate to within 2% while the monthly MAPE is
near 8%. That reconciliation belongs in the response letter, since the reviewer reads the two
figures as inconsistent.

## 5. The scale-dependence paragraph (§92) needs rechecking

The state series in this repository are **counts**; the published pipeline modelled the **rate per
1,000 beneficiaries**, and state-level denominators are not archived here. The MAPE and interval
widths below are therefore not comparable to the published state figures and must be recomputed
once those denominators are recovered. The drift result is structural and does not depend on the
scale.

| Court | Mean/month | Selected order | d + D | Drift | MAPE (counts) | Rel. width (counts) |
|---|---|---|---|---|---|---|
| SP | 6,119 | (0,1,1)(0,1,1)[12] | 2 | **impossible** | 7.1% | 0.4 |
| GO | 267 | (1,1,0)(2,0,0)[12] | 1 | admissible, not selected | 14.2% | 0.6 |
| AC | 19 | (2,1,1), no seasonal | 1 | admissible, not selected | 35.5% | 0.8 |

§92 states that in São Paulo "the model selected a drift term". It cannot have: the selected order
has d + D = 2. Forcing D = 0 so that a drift becomes admissible does produce a significant one
(72.70, SE 24.73, t = 2.94) under ARIMA(1,1,1)(1,0,0)[12] — but AICc rejects that specification by
**194 points** against the unrestricted selection. Automatic AICc selection, which the Methods
declares, does not choose it.

§92 also states that in Acre the interval "widened to 6.1 times the point estimate and crossed
zero". On counts the relative width is 0.8 and it does not cross zero. This is the discrepancy most
likely explained by the counts-versus-rate difference: a rate on a small state denominator is far
noisier in relative terms. Do not rewrite §92 until the state denominators are recovered — but the
drift sentence has to go regardless.

## Reproducibility

```
Rscript scripts/06_sarima_intervals.R
```

R 4.3.3, `forecast` 8.21.1 (the manuscript declares R 4.5.2; see `docs/reproduction_note.md` for
the one quantity sensitive to that difference). Runs in about two minutes.
