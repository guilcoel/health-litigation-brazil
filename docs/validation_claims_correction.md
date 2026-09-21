# The validation claims: what has to go, and the replacement text

Prepared 21 September 2026, in response to Reviewer 2, comment 4.
Script: `scripts/07_out_of_sample_symmetry.R`.

## 1. A finding that settles the drift question completely

§78 reports the SARIMA 2030 interval as **240 024 – 1 102 776**, with a relative width of 1.3. The
**driftless** model gives **240 658 – 1 103 757**, relative width 1.28 — a match to within 0.3%.
Together with the point forecast (671 400 published against 672 207 driftless), this means the
published analysis *was already driftless*. The drift exists only in the prose of §47 and §76 and in
the labels of Tables S1 and S3. Nothing was estimated with it.

This is the cleanest possible answer to Reviewer 2's comment 1: it is a reporting error in the text,
not a defect in the analysis, and removing the word changes no number in the paper. It also means
§78's own reported width of 1.3 is correct as it stands — the false claim is confined to §47 and §76,
where the drift is credited with producing a bounded interval.

## 2. The asymmetry in the out-of-sample test is real, and it cuts against SARIMA

The manuscript reports, for the same five withheld months, the **cumulative** deviation for SARIMA
(+0.35%) and the **monthly MAPE** for the inertial scenario (4.6%). Those are different metrics, and
the first is the one in which month-level errors cancel. Reported on the same footing:

| Model | Cumulative deviation | Monthly MAPE |
|---|---|---|
| SARIMA | +0.35% | **7.76%** |
| Inertial scenario | +1.86% | 4.60% |

SARIMA wins on the annual aggregate and **loses** on the month-by-month allocation. The reviewer is
right that the reporting flattered the statistical model, and the fix is to give both metrics for
both models rather than to soften the language.

Month by month:

| Month | Observed | SARIMA | Error |
|---|---|---|---|
| Jan 2026 | 23 461 | 25 279 | +7.75% |
| Feb 2026 | 28 440 | 32 604 | +14.64% |
| Mar 2026 | 36 478 | 31 210 | −14.44% |
| Apr 2026 | 32 288 | 32 531 | +0.75% |
| May 2026 | 34 218 | 33 806 | −1.20% |

## 3. A Methods gap this uncovered

The reproduction pinned down the 2026 denominator convention: the pipeline held the **projected 2026
annual beneficiary count constant across all five months**. That convention gives 155 431 against
the reported 155 433. The three plausible alternatives give cumulative deviations of −2.68%, −1.90%
and −0.38% — so the headline "+0.35%, within 2% of observed" depends on a convention the Methods
never states. It must be stated.

| 2026 denominator convention | Predicted total | Cumulative deviation | Monthly MAPE |
|---|---|---|---|
| **2026 projected annual count, held constant** | **155 431** | **+0.35%** | 7.76% |
| 2025 observed count, held constant | 150 733 | −2.68% | 7.84% |
| Interpolated Dec 2025 → Dec 2026 | 151 950 | −1.90% | 7.42% |
| Interpolated Jun 2025 → Jun 2026 | 154 299 | −0.38% | 7.33% |

## 4. Replacement text

### §78 — remove the zero-crossing argument

Current final sentence: *"The SARIMA prediction interval has a relative width of 1.3 times the point
estimate and does not cross zero, indicating that the primary horizon is statistically supported."*

> The SARIMA prediction interval is wide: its width at 2030 is 1.3 times the point estimate, having
> grown from 0.3 times at 2026, and it reaches 2.4 times by 2035. The agreement between the two
> approaches is therefore a statement about their point projections, not evidence that the 2030
> level is tightly determined.

An interval that does not contain zero supports no conclusion, and the argument should simply go
rather than be rephrased.

### §80 — report both metrics for both models

Current: *"Both projections thus fell within 2% of the observed cumulative total, with the SARIMA
model closer on the aggregate and the inertial scenario closer on the month-by-month allocation
(monthly MAPE 4.6%)."*

> Both projections fell within 2% of the observed cumulative total. Because cumulative and monthly
> accuracy are different quantities, we report both for each approach: on the cumulative total the
> SARIMA model deviated by +0.35% and the inertial scenario by +1.86%; on the month-by-month
> allocation the monthly MAPE was 7.8% for the SARIMA model and 4.6% for the inertial scenario.
> Cumulative accuracy is the better of the two for both approaches because month-level errors partly
> cancel in the annual aggregate, and the cumulative figure should not be read as a monthly error
> rate. Beneficiary counts for these five months were taken as the projected 2026 annual figure held
> constant; the cumulative deviation is sensitive to this choice, ranging from −2.7% to +0.4% across
> plausible alternatives.

### §96 — drop "three independent methods"

Current: *"The near-term trajectory is well identified—three independent methods (a SARIMA model
with drift, a negative-binomial GLM, and out-of-sample validation against 2026 data) converge on an
inertial path of roughly 670 000 to 750 000 claims by 2030—whereas the longer-run outcome is
governed largely by the regulatory response."*

> Near-term point projections are reproducible across specifications: a SARIMA model and a
> negative-binomial GLM, fitted to the same series over the same period and therefore not
> independent of one another, both imply an inertial path of roughly 670 000 to 750 000 claims by
> 2030, and that path was confirmed against five months of 2026 data withheld from fitting. The
> prediction interval around it remains wide. The longer-run outcome, by contrast, is governed
> largely by the regulatory response.

Three corrections in one: out-of-sample validation is a check on a model, not a third method; the two
models share a series and a period and so are not independent; and "well identified" overstates a
short-term point agreement.

### §112 — the same fix in the Conclusions

Current opening: *"Supplementary-health litigation in Brazil is on a well-identified near-term
trajectory: independent statistical and scenario-based methods converge on roughly 670 000 to
750 000 claims by 2030…"*

> Statistical and scenario-based projections of supplementary-health litigation in Brazil converge
> on roughly 670 000 to 750 000 claims by 2030, and that range was confirmed against observed 2026
> data withheld from model fitting, with both approaches falling within 2% of the observed
> cumulative total. The interval around the statistical forecast is nonetheless wide, so the
> convergence should be read as agreement on the central path rather than as a narrow determination
> of the 2030 level.

Also replace the ratio "about 6.3 to 1" with an approximate magnitude, per
`docs/coverage_ceiling_findings.md`.

### §92 — the Acre sentence

*"the prediction interval widened to 6.1 times the point estimate and crossed zero"* — the zero
crossing is being used as evidence here too, and should be dropped in favour of the width alone. The
width itself is pending recomputation with the state denominators (see
`docs/sarima_interval_findings.md`, section 5).

## 5. What §110 gets right

The limitation *"ratio 0.7:1"* checks out: 55 months from the end of the out-of-sample window to
December 2030, against a 72-month fitting series, gives 0.76. No change needed.

## Reproducibility

```
Rscript scripts/07_out_of_sample_symmetry.R
```

R 4.3.3, `forecast` 8.21.1. Runs in a few seconds.
