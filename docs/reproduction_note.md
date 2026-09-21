# Reproduction note, prepared 21 September 2026

## Environment
R 4.3.3, forecast 8.21.1. The manuscript declares R 4.5.2, so the `forecast` version differs and
the ETS component selection is the one quantity sensitive to it (8.07% reported, 7.88% reproduced).

## What reproduces
The SARIMA order, the model ranking (GLM-NB < log-linear < SARIMA < ETS) and three of the four
MAPE values reproduce to within 0.03 percentage points. The base growth rate reproduces to within
0.01 percentage points once estimated over all 72 monthly observations rather than the 60-month
training window.

## What does not
The drift term. `forecast::Arima(..., include.drift = TRUE)` returns the warning "No drift term
fitted as the order of difference is 2 or more" for the reported (0,1,1)(0,1,0)[12] specification,
and `auto.arima` selects no drift on this series. Forcing (0,1,1) with drift and no seasonal
differencing yields drift = 0.0036 (SE 0.0044), not significant, and MAPE 15.25%, so that is not
the specification used either.

Consequence for the manuscript: without a drift term, the argument that the drift is what yields a
bounded prediction interval does not hold. A driftless (0,1,1)(0,1,0)[12] has an interval that
widens without bound and crosses zero. The justification for selecting SARIMA as the primary model
needs to be restated on other grounds.

## Legacy scripts
The files prefixed `00_legacy_` are the March 2026 pipeline. They run on the earlier version of the
litigation series, which was reconstructed by digitising the CNJ dashboard and carried a systematic
downward bias of approximately 9%. They are kept for provenance only and do not reproduce the
published figures. The scenario engine, bootstrap and response surface still need to be rebuilt on
the corrected series.
