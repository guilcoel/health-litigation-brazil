# Abstract and Conclusions: reframing the long horizon as a stress test

Prepared 21 September 2026, in response to Reviewer 2, comment 3 and Reviewer 3, weakness 2.
Script for the numbers in section 1: `scripts/08_response_surface_slope.R`.

## 1. The "18 700 claims per year" figure reconciles — as a linear fit to a curved surface

This needed settling before the Abstract could be rewritten, because the figure appears there. The
response surface at 2030, computed from the equation as declared in §53 over damping horizons of 3
to 20 years:

| τ_d | 3 | 5 | 8 | 12 | 16 | 20 |
|---|---|---|---|---|---|---|
| 2030 claims | 460 665 | 550 459 | 670 611 | 745 321 | 784 942 | 809 464 |

| Quantity | Value |
|---|---|
| Range over τ_d 3–20 | 348 799 claims |
| Slope of a linear fit to the surface | **18 896 per year of τ_d** (R² 0.875) |
| Chord average (range ÷ 17 years) | 20 518 per year |
| Local slope at the inertial scenario (τ_d = 12) | **13 027 per year** |
| Local slope at the optimistic end (τ_d = 4) | 44 897 per year |

So the published 18 700 is the linear-fit slope, and it reproduces. It is not wrong, but R² of 0.875
means the surface is visibly curved, and a single slope therefore overstates the marginal effect
near the inertial scenario — 13 000, not 19 000 — and understates it at the optimistic end. Reported
as a constant "per year of delay", it reads as a marginal effect that holds everywhere, which it does
not.

Recommendation: keep the figure, state what it is, and give the local value where the paper's central
scenario sits.

## 2. Reviewer 3 offers two exits; take the first

Reviewer 3 proposes either reframing the long-horizon projections strictly as speculative stress
tests, or formalising the damping parameter with Bayesian priors derived from historical regulatory
interventions. The first is the right choice, and not only because it is cheaper: the structural
break analysis (`docs/structural_breaks_findings.md`) found three regimes with growth of +5.26%,
+30.92% and +13.31% per year, so there is no stable historical intervention effect from which to
build a prior. Attempting one on this series would manufacture precision rather than represent it.
Say that in the response letter — it converts a resource constraint into a methodological argument,
which is the honest version.

## 3. Replacement text — Abstract

### Methods (one sentence added at the end of the existing sentence on scenarios)

Current: *"Three regulatory scenarios were defined by the damping applied to the estimated growth
rate; because the damping horizon is not identified by the data, projections were also expressed as a
continuous response surface over damping horizons of 3 to 20 years."*

> Three regulatory scenarios were defined by the damping applied to the estimated growth rate.
> Because the damping horizon is not identified by the data, these are stress tests under stated
> assumptions rather than probabilistic forecasts, and projections were also expressed as a
> continuous response surface over damping horizons of 3 to 20 years.

### Results

Current: *"At the 2030 horizon, the statistical forecast (671 400 claims) and the inertial scenario
(745 323) converged to within 11%, and both fell within 2% of observed out-of-sample claims for
January–May 2026. Projection uncertainty at 2030 was dominated by the regulatory response, which
exceeded market-size uncertainty by a ratio of about 6.3 to 1; each additional year of delay was
associated with roughly 18 700 further claims."*

> At the 2030 horizon the statistical forecast (671 400 claims, 95% prediction interval
> 240 024–1 102 776) and the inertial scenario (745 323) agreed on the central path to within 11%,
> and both fell within 2% of the observed cumulative claims for January–May 2026, although monthly
> accuracy was lower (monthly MAPE 7.8% and 4.6% respectively). Projection uncertainty at 2030 was
> dominated by the regulatory response, which exceeded market-size uncertainty by roughly fivefold;
> along the response surface, each additional year of delay in the regulatory response was
> associated with on the order of 19 000 further claims on average, and approximately 13 000 in the
> neighbourhood of the inertial scenario.

Three things change: the prediction interval is now stated in the Abstract, so the convergence cannot
be read as precision; "converged" becomes "agreed on the central path"; and the two precise ratios
become magnitudes, with the marginal effect qualified.

### Conclusions

Current: *"The near-term trajectory of supplementary-health litigation in Brazil is well identified
by the data, whereas the longer-run outcome depends chiefly on the regulatory response rather than on
statistical or market uncertainty. Projections beyond 2030 should be read as conditional scenarios."*

> Near-term projections of supplementary-health litigation in Brazil are reproducible across
> specifications and validated against withheld data, though with wide prediction intervals, whereas
> the longer-run outcome depends chiefly on the regulatory response rather than on statistical or
> market uncertainty. Projections beyond 2030 are stress tests under stated assumptions, not
> forecasts, and should be read as such. Separating the inertial from the policy-dependent component
> of a litigation projection offers a transferable approach for health systems facing rising coverage
> disputes.

## 4. Replacement text — Conclusions section (§112–§113)

§112's opening is handled in `docs/validation_claims_correction.md`, section 4. Two further edits
here:

Replace *"which in our decomposition outweighs insurance-market size by a ratio of about 6.3 to 1"*
with:

> which in our decomposition outweighs insurance-market size by roughly fivefold

Replace *"Each additional year of delay in an effective regulatory response is associated with on the
order of 18 700 additional claims at the 2030 horizon."* with:

> Along the response surface, each additional year of delay in an effective regulatory response is
> associated with on the order of 19 000 additional claims at the 2030 horizon on average; because
> the surface is curved, the marginal effect near the inertial trajectory is closer to 13 000.

In §113, *"projections beyond 2030 should be read as conditional scenarios rather than statistical
forecasts"* already says the right thing and needs no change. Strengthen it only by adding, after it:

> They are stress tests of a regulatory assumption, and their value lies in the spread they describe
> rather than in any single trajectory within it.

## 5. One item still blocked

The Abstract's *"rose from 2.98 to 6.46 per 1 000 beneficiaries"* depends on the unresolved
denominator question (see the data section of the revision plan: the revised ANS series gives 2.93 to
6.46). Do not touch that sentence until that decision is made, and then check it against §29, §76 and
Table S1 together.

## 6. Where each number in this document comes from

| Figure | Source |
|---|---|
| Response surface, slopes | `scripts/08_response_surface_slope.R` |
| 2030 prediction interval | `scripts/06_sarima_intervals.R` |
| Monthly MAPE 7.8% / 4.6% | `scripts/07_out_of_sample_symmetry.R` |
| Policy-to-market ratio, formal market range | `scripts/05_coverage_ceiling.R` |
| Three growth regimes | `docs/structural_breaks_findings.md` |
