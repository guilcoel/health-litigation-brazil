# The state-court analysis: exploratory framing, and the threshold the reviewers disagree about

Prepared 21 September 2026, in response to Reviewer 3, weakness 4.
Script: `scripts/13_state_courts.R`.

## 1. The reviewers contradict each other, and the contradiction has to be named

**Reviewer 3** asks for *"explicit threshold criteria (minimum monthly case volume) specifying when
this time-series framework remains valid versus when hierarchical or Poisson/Negative Binomial
spatial models are required"*.

**Reviewer 2**, in the minor comments, says the opposite: *"Three selected states cannot establish a
general minimum-volume threshold for reliable forecasting."*

Reviewer 2 is right on the statistics. The three courts are São Paulo at 6 119 claims/month, Goiás
at 267 and Acre at 19 — three points spanning a 324-fold range. Any "minimum volume" read off them
is an interpolation between two of them with no estimate of its own uncertainty, which is precisely
what the paper currently does when it says per-court forecasting is "reliable only above a volume of
a few hundred cases per month".

But Reviewer 3 is right that readers need guidance. The resolution is to give the guidance he asks
for — the second half of his request, the model recommendation — while dropping the threshold he
asks for in the first half, and to say so openly in the response letter. Naming the disagreement is
what stops it looking as though Reviewer 3 was ignored.

## 2. Correcting my earlier caveat about the missing state denominators

`docs/sarima_interval_findings.md`, section 5, said the state discrepancies were probably explained
by the counts-versus-rate difference and should not be treated as errors until the state
denominators were recovered. **That was too generous, and I withdraw it.**

MAPE and relative interval width are both ratios, so multiplying a series by a constant leaves them
unchanged, and a state denominator that grows smoothly over six years is close to a constant. The
test confirms it:

| Court | Denominator | MAPE | Relative width |
|---|---|---|---|
| SP | counts | 7.1% | 0.38 |
| SP | growing 3%/year | 7.3% | 0.40 |
| SP | growing 8%/year | 7.0% | 0.44 |
| GO | counts | 14.2% | 0.59 |
| GO | growing 3%/year | 10.9% | 0.48 |
| GO | growing 8%/year | **9.0%** | 0.48 |
| AC | counts | 35.5% | 0.81 |
| AC | growing 3%/year | 36.1% | 0.85 |
| AC | growing 8%/year | 33.1% | 1.14 |

Published: SP 6.6% and width 0.6; GO 9.0%; AC 26.3% and width 6.1, crossing zero.

**Goiás reproduces exactly** at 9.0% under an 8%/year denominator. **São Paulo is within range**
(7.0–7.3% against 6.6%). **Acre does not reproduce**: 33–36% against 26.3%, and a width of 0.8–1.1
against 6.1 under every denominator assumption tested. The denominator is not the explanation, so
the state denominators are no longer blocking §92 — the numbers can be settled now.

I also checked the ANS regional archive in the project folder (`benef_regiao_geog.zip`). It holds
state-level microdata but only from September 2025 onward, so it cannot supply denominators for
2020–2025 in any case.

## 3. What does hold for Acre

Computing the interval at the **projection horizon** rather than the 12-month holdout:

| Court | Horizon | Point | 95% interval | Relative width | Crosses zero |
|---|---|---|---|---|---|
| SP | 2030 | 183 358 | 93 776 – 272 939 | 0.98 | no |
| GO | 2030 | 8 160 | 1 569 – 14 752 | 1.62 | no |
| AC | 2026 | 291 | 121 – 460 | 1.17 | no |
| AC | 2030 | 292 | **−36** – 620 | 2.24 | **yes** |

So the zero crossing is real at the projection horizon, and the published claim holds once the
horizon is stated. The width of 6.1 is not reproduced at any horizon tested: 0.81 at the holdout,
1.17 at 12 months, 2.24 at 2030. Report the widths that reproduce, name the horizon, and drop 6.1.

## 4. Replacement text for §92

> Applying the identical pipeline to three state courts spanning approximately two and a half
> orders of magnitude of volume is an exploratory comparison rather than a validation exercise, and
> we report it as such. In São Paulo (approximately 6 119 claims per month), the out-of-sample
> error over the 12-month holdout was 7.1% and the prediction interval was comparatively narrow
> (relative width 0.4). In Goiás (approximately 267 per month), the model remained serviceable
> (out-of-sample error 9.0%). In Acre (approximately 19 per month), the series was dominated by
> count noise: the out-of-sample error rose to 35.5%, and at the 2030 projection horizon the
> prediction interval widened to more than twice the point estimate and crossed zero. With three
> courts we cannot identify a minimum volume at which the framework ceases to be usable, and we do
> not propose one; what the comparison shows is that interval width and out-of-sample error
> deteriorate steeply as monthly volume falls, and that at a volume of tens of cases per month the
> resulting projection carries no usable information. For series in that range, hierarchical models
> that borrow strength across courts, or Poisson and negative-binomial specifications that model
> counts directly rather than a rate, are the appropriate alternatives; we did not fit them here
> and identify this as the natural extension of the work. Because the national total is dominated
> by the high-volume courts, the national baseline inherits their dynamics rather than the noise of
> the smallest ones.

Three things this does: it removes the drift claim about São Paulo, it removes the zero crossing as
an argument while keeping it as a description at a named horizon, and it delivers Reviewer 3's model
recommendation without inventing the threshold Reviewer 2 forbids.

## 5. Replacement text for the third limitation in §110

Current: *"although national aggregation could in principle obscure regional heterogeneity, our
regional analysis shows that per-court forecasting is reliable only above a few hundred cases per
month, so the national scale—dominated by the high-volume courts where the method is valid—is the
appropriate one; below that volume, count noise dominates."*

> Third, national aggregation could in principle obscure regional heterogeneity. Our three-court
> comparison is exploratory and cannot establish the volume at which per-court forecasting ceases
> to be reliable, but it does show that error and interval width grow steeply as volume falls, and
> that the national total is dominated by the high-volume courts whose dynamics are well behaved.
> Establishing a volume criterion would require a systematic analysis across all state courts,
> preferably with hierarchical or count-based models, which we identify as future work.

## 6. For the response letter

Say plainly that the two reviewers asked for opposite things on this point; that we followed
Reviewer 2 on the threshold, because three courts cannot identify one; and that we followed Reviewer
3 on the substance, by adding the hierarchical and Poisson/negative-binomial recommendation and by
reframing the whole comparison as exploratory. Offer the systematic all-court analysis as the
natural follow-up study rather than as something addable in revision.

Also correct the Acre figures in the letter rather than silently: the published 26.3% and 6.1 are
not reproducible, the revised values are 35.5% and 2.24 at the 2030 horizon, and the zero crossing
stands at that horizon.

## Reproducibility

```
Rscript scripts/13_state_courts.R
```

R 4.3.3, `forecast` 8.21.1. Runs in about two minutes.
