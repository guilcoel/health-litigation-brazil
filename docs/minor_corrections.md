# Minor corrections, verified against the data and the reference list

Prepared 21 September 2026. This closes Phase 2. Every figure below was recomputed from
`data/cnj_monthly_series_national_and_states.csv` or read directly from the manuscript.

## 1. The national total, and a Table S3 figure that reconciles with nothing

The supplementary series gives **1 328 415** claims across the 72 months of 2020–2025, a mean of
**18 450 per month**. §74 says "approximately 1.28 million" — replace with the exact figure.

Table S3 reports a national mean of **20 015 claims/month**, which matches no defensible basis:

| Basis | Months | Mean/month |
|---|---|---|
| 2020–2025, the study period | 72 | **18 450** |
| Full series including 2026 | 77 | 19 264 |
| Table S3 as published | — | 20 015 |

A figure of 20 015 would imply 1 441 080 claims over 72 months, 8.5% above the actual total. I
searched every contiguous window of the series of 12 months or more: the nearest match is 20 030 for
August 2020 to May 2026, a 70-month window with no methodological rationale. Replace with 18 450 and
state the basis in the table footnote.

## 2. Acre has 69 monthly observations, not 72 — a new finding

The Acre series is missing **January through August 2020**. This matters for two claims:

- §92 says the "identical pipeline" was applied to the three courts. It was not applied to identical
  series: São Paulo and Goiás have 72 observations over 2020–2025, Acre has 64 in that window and 69
  across the full series to May 2026.
- The comparison is therefore not on equal footing, and part of Acre's poorer performance may be the
  shorter series rather than the lower volume alone. This strengthens rather than weakens the
  argument in `docs/state_courts_correction.md` that no volume threshold can be read off these three
  courts — but it has to be stated, in §92 and in the Table S3 footnote.

Verified monthly means, for the text and the table to agree:

| Court | Months available | Mean/month | §92 says | Table S3 says |
|---|---|---|---|---|
| SP | 72 | 6 119 | ≈6 119 ✓ | — |
| GO | 72 | **267** | ≈270 ✓ | 288 ✗ |
| AC | 64 (to Dec 2025) | **19** | ≈19 ✓ | 20 ✗ |

The text is right and the table is wrong in both cases.

## 3. Citation renumbering — the two changes compose into one simple rule

Two separate problems interact, and doing them in sequence by hand is where errors creep in.

**Problem A (from R3.3).** Remove old ref 7 (Súmulas Vinculantes) and old ref 9 (Law 14.874/2024);
insert Law 14.454/2022 at position 7. Net: −1 from position 10 onward.

**Problem B (this section).** The CNJ/UNDP methodological note was dropped from the list, so every
in-text marker from 17 onward points one entry too high. Confirmed by reading the three affected
paragraphs:

| Paragraph | Marker | What the text means | What the list currently holds |
|---|---|---|---|
| §40 | [17] | CNJ/UNDP methodological note | CNS Resolution 510/2016 |
| §41 | [18] | CNS Resolution 510/2016 | Hyndman & Khandakar |
| §47 | [19] | Hyndman & Khandakar (forecast package) | Colombian Constitutional Court |

Reinserting the missing note restores alignment. Net: +1 from position 17 onward.

**Composed, the two cancel above position 16.** The final list keeps 28 entries:

| Final position | Content |
|---|---|
| 1–6 | unchanged |
| 7 | **Law 14.454/2022** (new) |
| 8 | ADI 7265 (unchanged number) |
| 9–15 | old 10–16, shifted down one |
| 16 | **CNJ/UNDP methodological note** (reinserted) |
| 17–28 | old 17–28, numbers unchanged |

And the in-text rule is uniform and checkable:

> **Every in-text marker from [10] to [28] decreases by one.** §29's [7–9] is replaced by [7] and
> [8] per `docs/legal_citations_correction.md`. Markers [1] to [6] are untouched.

Applying it to every marker in the manuscript:

| Paragraph | Now | Becomes |
|---|---|---|
| §30 | [11], [5, 10] | [10], [5, 9] |
| §32 | [15], [16] | [14], [15] |
| §33 | [12–14] | [11–13] |
| §40 | [17] | [16] |
| §41 | [18] | [17] |
| §47 | [19] | [18] |
| §53 | [20, 21, 22] | [19, 20, 21] |
| §100 | [19, 20] | [18, 19] |
| §102 | [23], [23], [24] | [22], [22], [23] |
| §104 | [21], [25], [26], [5, 27] | [20], [24], [25], [5, 26] |
| §106 | [23], [28] | [22], [27] |

Do this **once, at the very end**, after every other text edit, and verify §53 and §100 by reading
the cited works rather than trusting the arithmetic — §53 cites three works for three countries and
one of the three Colombian entries may need a further adjustment.

## 4. Table 1 still calls the IESS comparison "external validation"

Table 1 describes the IESS source as *external validation* and says the series was validated
*"against IESS-reported figures for 2024"*. This contradicts §38 ("used for comparison with an
alternative forecasting exercise") and §94 ("this is a comparison with an alternative forecasting
exercise rather than external validation against observed data"). It is residue from version 1, and
it directly undercuts the answer to Reviewer 2's comment 4, which is about not overselling
validation. Change Table 1 to match §38 and §94.

## 5. §94 points at the wrong figure

§94 compares the projections with the IESS estimates and cites **Figure 2**, which is the policy
response surface and the uncertainty decomposition. The IESS comparison belongs with **Figure 1**,
the trajectory plot. Correct the cross-reference.

## 6. Table 2 — two residues

**The Colombia anchor.** Table 2 still describes the inertial scenario as *"anchored to the
regulatory cycle observed in Colombia after the 2015 Statutory Health Law"*. §53 already says the
international experiences are "illustrative analogies that motivate the range of damping horizons
considered, not as empirical calibrations of the parameters". Delete the anchoring language from the
table so it agrees with the text.

**The optimistic scenario description.** Resolved by the decision to follow the declared equation:
Table 2 should carry one description only — growth in year 1 at **66.7% of g₀**, reaching zero at
year 3, with no post-year-3 decline. See `docs/open_decisions.md`, Decision 2.

## 7. §102 — remove the independence sentence

Current closing sentence: *"That the finding runs counter to the commercial interests of insurers,
including the corresponding author's employers, underscores its independence."*

Delete it. §123 already handles this properly under Competing interests, where it states that no
employer had access to the data, the code or the manuscript before submission. Arguing for one's own
independence inside the Discussion reads as defensive and invites the reviewer to weigh it, which is
the opposite of what it is trying to achieve.

## 8. §74 — figures that change with the new denominators

| Now | Becomes |
|---|---|
| "approximately 1.28 million" | 1 328 415 |
| "2.98 per 1 000 in 2020 to 6.46 in 2025" | **2.93** to **6.46** |
| "18.86% per year (SE 0.88)" | **19.41% per year (SE 0.91)** |

## 9. The τ subscript

The subscript renders correctly in the extracted text of the submitted manuscript (`τ_d` throughout
§53 and the Figure 2 legend), so whatever corruption was seen is a font or encoding artifact in the
Word file or the generated PDF rather than an error in the content. Check it in the `.docx` and in
the compiled PDF specifically, at §53 and at the Figure 2 caption, and fix by using a consistent
symbol font rather than by rewriting the text.

## Checking script

```
Rscript scripts/14_minor_checks.R
```
