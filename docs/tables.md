# Tables 1, 2, 3 and S1–S3, rebuilt

Prepared 21 September 2026. Every value comes from `scripts/11_final_numbers.R`,
`scripts/12_table_s2.R`, `scripts/13_state_courts.R`, `scripts/16_model_comparison.R` and
`scripts/17_figure_s1.R`, so the tables and the text cannot drift apart.

Two cells are marked **[CONFIRMAR]**: they need a fact I do not have. Everything else is computed.

---

## Table 1. Data sources

| Source | Variable | Period | Access |
|---|---|---|---|
| National Council of Justice (CNJ), Statistical Panel on Health Litigation | Monthly counts of new judicial claims under the supplementary-health subject codes | Jan 2020 – May 2026 | Public dashboard, "show as table" export of the monthly time-series visual; extracted **[CONFIRMAR: data de extração]** |
| ANS Beneficiary Information System (SIB/ANS) | Annual counts of hospital-medical plan beneficiaries | 2020–2025 | Public; official series, extracted **[CONFIRMAR: data de extração]** |
| Brazilian Institute of Geography and Statistics (IBGE) | Population projections, 2024 revision | 2020–2040 | Public |
| Institute for Supplementary Health Studies (IESS) | Published litigation projection to 2035 | Report of December 2025 | Public; used for **comparison with an alternative projection exercise**, not as external validation |

**Two changes from the submitted version.** The ANS row now names the official series, because the
revision adopted it (`docs/open_decisions.md`, Decision 1). The IESS row no longer says "external
validation" and no longer claims the series was validated against IESS figures for 2024 — that
wording contradicted §38 and §94 and undercut the answer to Reviewer 2's comment 4.

---

## Table 2. Scenario definitions

All three scenarios apply the same damping function to the estimated base growth rate g₀ = 19.41%
per year: g(τ | τ_d) = max{0, g₀ · (1 − τ/τ_d)}, where τ is years after 2025.

| Scenario | τ_d | Year-1 growth | Growth reaches zero | Interpretation |
|---|---|---|---|---|
| Optimistic | 3 years | 66.7% of g₀ (12.94% per year) | 2028 | Rapid and effective regulatory response |
| Inertial | 12 years | 91.7% of g₀ (17.79% per year) | 2037 | Response at the observed historical pace |
| Pessimistic | 20 years | 95.0% of g₀ (18.44% per year) | 2045 | Response delayed or ineffective |

**This replaces four conflicting descriptions with one.** The submitted version described the
optimistic scenario's year-1 growth as 40% of g₀ in the text, 60% of g₀ in Table 2 and 66.7% by the
declared equation, while the code did 26.7%. The revision follows the declared equation throughout
(`docs/open_decisions.md`, Decision 2), so the single number above is the whole specification. The
anchoring language tying the inertial scenario to Colombia's post-2015 cycle is removed: §53 already
says the international experiences motivate the range rather than calibrate it.

---

## Table 3. Projected annual claims under each scenario

| Scenario | 2030 rate per 1 000 | 2030 claims | 2035 rate per 1 000 | 2035 claims |
|---|---|---|---|---|
| Optimistic | 7.77 | **450 939** | 7.77 | **489 401** |
| Inertial | 12.74 | **739 191** | 17.42 | **1 096 373** |
| Pessimistic | 13.87 | **804 503** | 24.05 | **1 514 120** |
| SARIMA (statistical forecast) | 11.24 | **652 002** (95% PI 214 805 – 1 089 199) | 16.01 | 1 007 608 |

Submitted: 390 042 / 745 323 / 809 467 at 2030 and 364 961 / 1 078 034 / 1 476 388 at 2035.

Beneficiary denominators: 58 007 230 in 2030 and 62 954 909 in 2035, from a logit-linear coverage
model on the official ANS series capped at 29%.

The optimistic rate is flat from 2028 because growth reaches zero there; claims still rise with the
beneficiary base. That is the plateau replacing the post-2030 decline of the submitted version.

---

## Table S1. Model comparison, 12-month holdout

Temporal cross-validation, 60 months for training and the final 12 months as the test set, on the
litigation rate per 1 000 beneficiaries.

| Model | MAPE | Submitted |
|---|---|---|
| Negative-binomial GLM, log link, beneficiary offset | **6.23%** | 6.41% |
| Log-linear trend with calendar-month indicators | **6.43%** | 6.59% |
| ETS(M,A,M) | **8.04%** | 8.07% |
| SARIMA (0,1,1)(0,1,0)[12] | **8.05%** | 7.84% |

**Two things to note.** The seasonal period is **[12]**, not [8], and there is **no drift term** —
see `docs/sarima_interval_findings.md`. And ETS and SARIMA now swap places, though by 0.01 percentage
points, so they are effectively tied; the Results sentence should say the four models sit within a
narrow band rather than rank them.

Diagnostics, for the Methods:

| Test | Revised | Submitted |
|---|---|---|
| Ljung-Box on SARIMA residuals (lag 24) | Q = 21.53, p = 0.549 | p = 0.62 |
| Augmented Dickey-Fuller | −2.957, p = 0.186 | −2.989, p = 0.173 |
| KPSS | 1.677, p = 0.010 | 1.672, p < 0.01 |

---

## Table S2. Sensitivity analyses

### S1 — SARIMA over alternative estimation windows

| Window | n | Selected order | Drift | 2030 claims |
|---|---|---|---|---|
| Full series, 2020–2025 | 72 | (0,1,1)(0,1,0)[12] | no | 652 002 |
| From 2022 | 48 | (0,0,0)(0,1,1)[12] | yes | 686 596 |
| From 2023 | 36 | (0,0,0)(1,1,0)[12] | yes | 674 419 |

The shorter windows admit a drift because d = 0 there, so d + D = 1. The full series has
d + D = 2, where `forecast::Arima` never fits one. The submitted sentence about shorter windows
replacing non-seasonal differencing with a drift is therefore **correct**, and it is also the
explanation for the drift reported in error in §76.

### S2 — Alternative coverage ceilings, inertial 2030

| Ceiling | 2030 coverage | 2030 claims |
|---|---|---|
| 25% | 0.25000 | 691 226 |
| 29% (primary) | 0.26735 | 739 191 |
| 32% | 0.26735 | 739 191 |

Uncapped 2030 coverage is 0.26735, so ceilings of 29% and above are not reached at that horizon.
Replacing the three fixed values with K ~ Normal(0.287, 0.02) truncated to [0.20, 0.35] gives a
median of 739 191 and a 95% range of 683 607 – 739 191, width 55 584, with the ceiling binding in
16.7% of draws. The interval is one-sided by construction: a ceiling can only remove beneficiaries.

### S3 — Base growth rate over alternative reference periods

| Estimator | g₀ | 2030 claims |
|---|---|---|
| Log-linear, 2020–2025 (primary) | 19.41% | 739 191 |
| Point-to-point, 2020–2025 | 17.15% | 686 219 |
| Point-to-point, 2022–2025 | 24.05% | 857 922 |
| Point-to-point, 2023–2025 | 20.38% | 762 899 |

Range across the three point-to-point windows: 171 703 claims. Submitted: 166 268.

### Decomposition of the 2030 uncertainty

| Component | Range | Submitted |
|---|---|---|
| Policy response (τ_d 3–20) | **353 564** | ~419 000 |
| Trend estimator | **171 703** | 166 268 |
| Market size | **55 584** | 66 918 |

Policy : market = 6.36 : 1. Policy : trend = 2.06 : 1. The trend component is 3.1 times the market
component, which is why the Abstract should name all three rather than only the policy-to-market
ratio.

---

## Table S3. State courts, exploratory comparison

Series in **counts**: ANS state-level denominators for 2020–2025 are not available. MAPE and
relative interval width are ratios, so they are unaffected by the scale
(`docs/state_courts_correction.md`, section 2).

| Court | Monthly observations to Dec 2025 | Mean claims/month | Selected order | MAPE, 12-month holdout | Relative interval width |
|---|---|---|---|---|---|
| São Paulo | 72 | **6 119** | (0,1,1)(0,1,1)[12] | 7.1% | 0.38 |
| Goiás | 72 | **267** | (1,1,0)(2,0,0)[12] | 14.2% | 0.59 |
| Acre | **64** | **19** | (2,1,1), no seasonal | 35.5% | 0.81 |

Submitted: SP mean ~6 119, MAPE 6.6%, width 0.6; GO mean 288, MAPE 9.0%; AC mean 20, MAPE 26.3%,
width 6.1 crossing zero.

**Three corrections.** Goiás is 267 claims/month, not 288, and Acre is 19, not 20 — the text was
right and the table wrong. Acre has **64 monthly observations in 2020–2025, not 72** (January to
August 2020 are missing), so the pipeline was not applied to identical series and the footnote must
say so. And Acre's relative width of 6.1 does not reproduce at any horizon tested: 0.81 at the
holdout, 1.17 over 12 months, 2.24 at the 2030 projection horizon — where the interval does cross
zero, so that part of the claim holds once the horizon is stated.

The national row of the submitted Table S3 reported 20 015 claims/month. The study period gives
**18 450**/month, matching the total of 1 328 415 over 72 months. No contiguous window of the series
corresponds to 20 015; replace it and state the basis in the footnote.

---

## Replacement legend for Figure S1

> **Figure S1 (Supplementary). Exploratory application of the forecasting framework to three state
> courts.** Monthly new judicial claims in São Paulo, Goiás and Acre, spanning approximately two and
> a half orders of magnitude of case volume, with free y-axis scales. Black line: observed counts.
> Dashed line and shaded band: forecast and 95% prediction interval for 2026 from a model selected
> automatically by corrected AIC on the observations through December 2025. Dotted vertical line:
> start of 2026. Counts rather than rates are shown because state-level beneficiary denominators are
> not available for the study period; out-of-sample error and relative interval width are ratios and
> so are unaffected by this choice. The Acre series begins in September 2020 and has 64 monthly
> observations in 2020–2025, against 72 for the other two courts, so the comparison is not on
> identical series.

The phrase "the identical modeling pipeline" must go, for that last reason.

---

## What each table still needs from you

- The **two extraction dates** marked [CONFIRMAR] in Table 1.
- A decision on whether Table S3 keeps the national row at all: it mixes a national aggregate with
  three state courts in a table about state-level scale dependence, and dropping it would remove the
  20 015 problem rather than fix it.
