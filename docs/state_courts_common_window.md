# The state-court analysis, recomputed on a common window — and three claims I withdraw

Prepared 22 September 2026. Scripts: `scripts/18_state_courts_common_window.R`,
`scripts/19_ac_denominator_check.R`. This supersedes sections 2, 3 and 4 of
`docs/state_courts_correction.md`, which were computed on a defective series.

---

## 1. The defect

`scripts/13_state_courts.R` built every state series with

```r
ts(s$new_claims, start = c(2020, 1), frequency = 12)
```

The Acre series begins in **September 2020**, not January. Coverage through December 2025:

| Series | Span | n |
|---|---|---|
| National | 2020-01 .. 2025-12 | 72 |
| SP | 2020-01 .. 2025-12 | 72 |
| GO | 2020-01 .. 2025-12 | 72 |
| **AC** | **2020-09 .. 2025-12** | **64** |

Labelling Acre as starting in January 2020 put its last observation in April 2025. Two
consequences, neither visible in the output:

1. **The holdout collapsed.** With the split at `end = c(2024,12)` / `start = c(2025,1)`, Acre was
   scored on **4 months** while São Paulo and Goiás were scored on 12. The reported 35.5% was the
   mean of four errors.
2. **The seasonal alignment shifted by eight months**, and the mis-dated fit picked up a **drift
   term** that disappears once the series is dated correctly.

So the manuscript's claim that an identical pipeline was applied to the three courts was not true
of the analysis as run. Decision taken: restrict all three courts to the **common window
2020-09 .. 2025-12, 64 observations each**, 52 for training and a 12-month holdout.

---

## 2. The corrected results

All three courts, common window, `auto.arima` with AICc, no drift fitted anywhere.

| Court | Mean/month | Selected order | Holdout MAPE | Rel. width | Crosses zero |
|---|---|---|---|---|---|
| SP | 6 355 | (1,1,0)(0,1,0)[12] | **7.8%** | **0.53** | no |
| GO | 281 | (1,1,0)(1,0,0)[12] | **13.9%** | **0.58** | no |
| AC | 19 | (0,1,1), no seasonal | **23.4%** | **1.06** | no |

Volume spans **337-fold** across the three courts on this window.

### At the 2030 projection horizon, fitted on all 64 observations

| Court | 2030 point | 95% interval | Rel. width | Crosses zero |
|---|---|---|---|---|
| SP | 183 662 | 90 576 – 276 749 | 1.01 | no |
| GO | 9 062 | 5 157 – 12 966 | 0.86 | no |
| AC | 292 | **−36** – 620 | 2.24 | **yes** |

### Acre, holdout detail

Monthly absolute percentage errors: 20, 1, 11, 21, 46, 38, 5, 11, 46, 54, 14, 15 — from 1.2% to
53.7%. But the **error on the 2025 annual total is only 7.4%** (predicted 332 against 309 observed).
The same cancellation that reconciles the national series' 7.8% monthly MAPE with its 2% annual
accuracy operates here, and it is worth saying so: even at 19 claims a month the annual aggregate is
not the problem — the monthly path and the interval are.

---

## 3. Three claims from `state_courts_correction.md` that I withdraw

**(a) "Acre does not reproduce: 33–36% against the published 26.3%."** Withdrawn. That range came
from the 4-month holdout. On the corrected window Acre gives **23.1% to 23.9%** across every
denominator assumption tested — a gap of 2.4 pp from the published 26.3%, not 7 to 10 pp. The
published figure is close to reproducible, and the response letter must **not** assert otherwise.
This was my error, not the authors'.

**(b) "MAPE and relative width are scale-invariant, so the missing state denominators cannot
explain a large discrepancy."** Half right, and the wrong half matters. A **constant** denominator
is exactly invariant — Acre gives 23.4% on counts and 23.4% on a constant denominator. A **growing**
denominator is not a rescaling, it is a partial detrending, and it can flip the order selection:

| Court | Counts | Denominator +3%/yr | Denominator +8%/yr |
|---|---|---|---|
| SP | 7.8% | 7.7% | 7.7% |
| **GO** | **13.9%** | **7.5%** | **7.4%** |
| AC | 23.4% | 23.9% | 23.2% |

São Paulo and Acre barely move. **Goiás swings by 6.4 percentage points** — because dividing by a
growing denominator changes which model AICc selects. The published 9.0% for Goiás is recoverable
under a growing denominator and not on counts.

**(c) The implied claim that the three courts show a clean monotone degradation.** At the holdout
they do (7.8 → 13.9 → 23.4 on error; 0.53 → 0.58 → 1.06 on width). At the **2030 horizon they do
not**: Goiás's relative width (0.86) is *narrower* than São Paulo's (1.01), because São Paulo's
selected model carries seasonal differencing and Goiás's a stationary seasonal AR. Horizon interval
width reflects model structure as much as volume, and the text must not present it as a volume
gradient.

---

## 4. What this does to the argument — it improves it

The original story was "error grows as volume falls". The corrected story is sharper and harder to
attack: **as volume falls, it is the stability of the analysis that degrades, not merely its
accuracy.** At 6 355 claims a month the result is insensitive to how the series is scaled; at 281 a
month the same pipeline returns either 7.5% or 13.9% depending on a modelling choice that is
immaterial at higher volume; at 19 a month the projection interval crosses zero. That is a stronger
answer to Reviewer 3 than a threshold would have been, and it is the concrete form of Reviewer 2's
objection that three courts cannot identify one.

---

## 5. Replacement text for §92

> Applying the same pipeline to three state courts spanning approximately two and a half orders of
> magnitude of monthly volume is an exploratory comparison rather than a validation exercise, and we
> report it as such. To make the comparison internally consistent we restricted all three series to
> a common window (September 2020 to December 2025, 64 monthly observations each), because the Acre
> series begins in September 2020; results are therefore not directly comparable with the national
> analysis, which uses the full 72-month series. In São Paulo (approximately 6 355 claims per
> month), the out-of-sample error over a 12-month holdout was 7.8% with a comparatively narrow
> prediction interval (mean relative width 0.53), and both were insensitive to whether the series
> was modelled as counts or as a rate. In Goiás (approximately 281 per month), the error ranged from
> 7.5% to 13.9% across those same specifications, because at this volume the automatic order
> selection is no longer stable to the choice. In Acre (approximately 19 per month), the error was
> 23.4% and the monthly errors ranged from 1% to 54%; at the 2030 projection horizon the prediction
> interval widened to more than twice the point estimate and crossed zero. With three courts we
> cannot identify a minimum volume at which the framework ceases to be usable, and we do not propose
> one. What the comparison shows is that as volume falls it is first the stability of the
> specification and then the informativeness of the interval that give way, before the point
> forecast itself becomes unusable; we note that even in Acre the error on the annual total was
> 7.4%, so the degradation is concentrated in the monthly path and the interval rather than in the
> annual aggregate. For series in this range, hierarchical models that borrow strength across courts,
> or Poisson and negative-binomial specifications that model counts directly, are the appropriate
> alternatives; we did not fit them here and identify this as the natural extension of the work.
> Because the national total is dominated by the high-volume courts, the national baseline inherits
> their dynamics rather than the noise of the smallest ones.

## 6. Replacement text for the third limitation in §110

> Third, national aggregation could in principle obscure regional heterogeneity. Our three-court
> comparison is exploratory and cannot establish the volume at which per-court forecasting ceases to
> be reliable, but it does show that both the stability of the selected specification and the width
> of the prediction interval degrade steeply as volume falls, and that the national total is
> dominated by the high-volume courts whose dynamics are well behaved. Establishing a volume
> criterion would require a systematic analysis across all state courts, preferably with
> hierarchical or count-based models, which we identify as future work.

---

## 7. For the response letter

- State that the state-level comparison was recomputed on a common 64-month window, and say why:
  the Acre series begins in September 2020 and the three courts had not previously been placed on
  the same footing. Declaring this is what makes the "same pipeline" claim true.
- The revised state figures therefore differ from those in the submitted version. Present this as a
  correction we made, with the reason given, rather than waiting to be asked.
- Do **not** claim the published Acre figure is irreproducible. It is within about 2 percentage
  points of the recomputed value.
- The published relative width of **6.1** for Acre still does not reproduce anywhere: 1.06 at the
  holdout, 2.24 at the 2030 horizon. Report the reproducible widths with the horizon named, and drop
  6.1. The zero crossing is real, but only at the projection horizon — say which.
- Keep the point from `state_courts_correction.md` §1 and §6 unchanged: the two reviewers asked for
  opposite things, we follow Reviewer 2 on refusing a threshold and Reviewer 3 on the model
  recommendation, and we say so openly.

---

## Reproducibility

```
Rscript scripts/18_state_courts_common_window.R
Rscript scripts/19_ac_denominator_check.R
```

R 4.3.3, `forecast` 8.21.1, seed 42. Together they run in under three minutes.
