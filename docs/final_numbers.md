# Final numbers for the revised manuscript

Prepared 21 September 2026, after the two decisions: **official ANS denominators** and the
**optimistic scenario computed from the declared equation**. Script: `scripts/11_final_numbers.R`.
Every figure below supersedes the corresponding figure in the submitted version. Where a number is
unchanged, it is marked so.

## 1. Observed series and base growth

| Year | Claims | Beneficiaries (ANS) | Rate per 1 000 |
|---|---|---|---|
| 2020 | 140 439 | 47 939 243 | 2.930 |
| 2021 | 147 303 | 49 274 613 | 2.989 |
| 2022 | 171 142 | 50 530 569 | 3.387 |
| 2023 | 228 640 | 51 254 745 | 4.461 |
| 2024 | 299 128 | 51 956 946 | 5.757 |
| 2025 | 341 763 | 52 865 947 | 6.465 |

| Quantity | Revised | Submitted |
|---|---|---|
| Base growth g₀ | **19.41%** per year (SE 0.91 pp) | 18.9% (SE 0.89 pp) |
| Rate, 2020 → 2025 | **2.93 → 6.46** | 2.98 → 6.46 |
| σ of the annual log-linear model | 0.0863 | 0.0829 |

## 2. Beneficiary projection

Rebuilding the coverage series on ANS figures moves the whole projection down slightly, and the
29% cap now binds from **2036** instead of 2033.

| Year | Coverage | Beneficiaries |
|---|---|---|
| 2026 | 0.25227 | 54 038 615 |
| 2030 | 0.26735 | **58 007 230** (was 59 593 837) |
| 2035 | 0.28698 | **62 954 909** (was 63 616 502) |
| 2040 | 0.29000 | 63 912 068 |

## 3. SARIMA

ARIMA(0,1,1)(0,1,0)[12], **no drift**, ma1 = −0.6419 (SE 0.1036).

| Year | Claims | 95% prediction interval | Relative width |
|---|---|---|---|
| 2030 | **652 002** (was 671 400) | 214 805 – 1 089 199 | 1.34 |
| 2035 | 1 007 608 | −273 104 – 2 288 319 | 2.54 |

## 4. Scenarios — Table 3 replacement

All three now come from the same equation, g(τ|τ_d) = max{0, g₀(1 − τ/τ_d)}.

| Scenario | τ_d | 2030 claims | 2030 rate | 2035 claims | 2035 rate |
|---|---|---|---|---|---|
| Optimistic | 3 | **450 939** | 7.77 | **489 401** | 7.77 |
| Inertial | 12 | **739 191** | 12.74 | **1 096 373** | 17.42 |
| Pessimistic | 20 | **804 503** | 13.87 | **1 514 120** | 24.05 |

Submitted: 390 042 / 745 323 / 809 467 at 2030; 364 961 / 1 078 034 / 1 476 388 at 2035.

The optimistic trajectory now **stabilises at 7.77 per 1 000 from 2028** instead of peaking and
declining. Figure 1 loses its post-2030 kink, and the optimistic scenario becomes a point on the
response surface rather than an exception to it.

Convergence of the two approaches at 2030 is now **13.4%** (652 002 against 739 191), against the
11% reported. Still close agreement, and the Abstract wording already drafted ("agreed on the
central path to within…") accommodates it — update the percentage.

## 5. Response surface — Figure 2 Panel A

| τ_d | 3 | 5 | 8 | 12 | 16 | 20 |
|---|---|---|---|---|---|---|
| 2030 claims | 450 939 | 541 499 | 663 257 | 739 191 | 779 522 | 804 503 |

| Quantity | Value |
|---|---|
| Policy range, τ_d 3–20 | **353 564** claims |
| Linear-fit slope | **19 177** per year of τ_d (R² 0.876) |
| Local slope at τ_d = 12 | **13 254** per year |

## 6. Bootstrap

| | Median | 95% interval | Width |
|---|---|---|---|
| Revised | **736 730** | 499 114 – 1 082 398 | 583 284 |
| Submitted | 742 791 | 511 204 – 1 074 782 | 563 578 |

## 7. Market size and the ratio — a correction to my earlier recommendation

`docs/abstract_conclusions_rewrite.md` recommended replacing "6.3 to 1" with "roughly fivefold".
**Under the final numbers that is wrong and should not be applied.** The ratio comes back to
**6.36 to 1**.

| Quantity | Revised | On the old coverage series |
|---|---|---|
| Ceiling binds at 2030 | 16.7% of draws | 27.0% |
| Market range (95%) | **55 584** | 74 396 |
| Policy range | 353 564 | 348 799 |
| Ratio | **6.36 : 1** | 4.69 : 1 |

The market range shrank because the cap now binds from 2036 rather than 2033, so it bites in fewer
draws at 2030. The published 6.3 and the revised 6.36 agree by coincidence of two offsetting
changes, not because the original computation was well founded.

The substantive caution therefore stands even though the number does not move: the ratio is
sensitive to how both ranges are defined, and it swung between 4.7 and 6.4 across defensible
choices during this reanalysis. Report it as an approximate magnitude — "approximately sixfold" —
with both range definitions stated in the Methods, rather than as a precise quantity. Do **not**
write "roughly fivefold".

## 8. Out-of-sample validation, January–May 2026

Observed total 154 885. Beneficiaries: the projected 2026 annual count held constant across the
five months (state this convention in the Methods).

| Model | Predicted total | Cumulative deviation | Monthly MAPE |
|---|---|---|---|
| SARIMA | 153 986 | **−0.58%** | **7.60%** |
| Inertial | 157 552 | **+1.72%** | **4.80%** |

The headline claim survives: both approaches remain within 2% of the observed cumulative total.
The ordering on monthly accuracy also survives — SARIMA is better on the aggregate and worse month
by month, which is what `docs/validation_claims_correction.md` asks the paper to report.

## 9. What must now be edited, by location

| Location | Change |
|---|---|
| Abstract, Background | 52 million → unchanged (52.9 M in 2025 rounds the same) |
| Abstract, Results | rate 2.93 → 6.46; growth 19.4%; SARIMA 652 002 with its interval; inertial 739 191; convergence 13.4%; ratio "approximately sixfold"; marginal ~19 000 average and ~13 000 local; MAPE 7.6% and 4.8% |
| §29 | rate figures, and the rewritten legal paragraph from `docs/legal_citations_correction.md` |
| §76 | order [12], drift removed, ma1 −0.6419 (SE 0.1036) |
| §78 | 652 002 with interval 214 805 – 1 089 199; zero-crossing argument removed |
| §80 | both metrics for both models, plus the denominator convention |
| §82 | 58.0 million in 2030, 63.0 million in 2035 |
| §84 | Table 3 values above |
| §86 | policy range 353 564, ratio ~6.4, marginal qualified |
| §90 | Table S2 sensitivities need rerunning on the new denominators |
| §92 | drift sentence removed; state figures still pending the state denominators |
| §96, §112 | replacement text from `docs/validation_claims_correction.md`, with the ratio wording from section 7 above |
| Table 1 | denominators |
| Table 2 | one description of the year-1 growth rate: 66.7% of g₀ at τ_d = 3 |
| Table 3 | full replacement |
| Tables S1, S3 | order [12], drift removed |
| Figures 1 and 2 | regenerate on all of the above |

## 10. Still outstanding

- Table S2 (sensitivity to growth-rate windows and coverage ceilings) has not been rerun on the new
  denominators. It is the last analytical gap before the figures.
- State-level denominators for §92 and Table S3.
