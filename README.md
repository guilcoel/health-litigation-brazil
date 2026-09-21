# Projecting Health Litigation in Supplementary Health Insurance

Replication data and code for the manuscript *Projecting Health Litigation in Supplementary Health
Insurance: Time-Series Forecasting and Regulatory Scenarios from Brazil*, under revision at
BMC Health Services Research (submission 31a9839e-8157-46b5-9364-ed3285344176).

## Contents

    data/      litigation series, beneficiary denominators and projections (see data/README.md)
    scripts/   analysis scripts, numbered in execution order
    docs/      provenance and reproduction notes

## Reproducing the model comparison

    Rscript scripts/01_refit_models.R

Run from the repository root. Requires R with `forecast`, `MASS`, `readr` and `dplyr`.

## Model specification

The litigation rate is monthly new claims per 1,000 hospital-medical beneficiaries. The denominator
is interpolated linearly between the annual (December) positions. Model selection used temporal
cross-validation with 60 months for training (January 2020 to December 2024) and the final 12 months
as the test set.

Reproduced with R 4.3.3 and forecast 8.21.1:

| Quantity | Reported in the manuscript | Reproduced |
|---|---|---|
| SARIMA order | (0,1,1)(0,1,0)[12] | (0,1,1)(0,1,0)[12] |
| Drift term | +0.119 (SE 0.019) | not fitted |
| MAPE, SARIMA | 7.84% | 7.82% |
| MAPE, GLM-NB | 6.41% | 6.44% |
| MAPE, log-linear | 6.59% | 6.62% |
| MAPE, ETS | 8.07% | 7.88% |
| Base growth rate | 18.86%/year (SE 0.88) | 18.87%/year (SE 0.75) |

The drift term reported in the manuscript is not reproduced: `forecast::Arima` declines to fit a
drift when the combined order of differencing is two or more, and `auto.arima` selects no drift on
this series. See `docs/` for the full note.

## Citation

To be completed on publication.
