# Structural breaks and the regulatory milestones
Prepared 21 September 2026, in response to Reviewer 3, weakness 3.

Series: national monthly new claims, January 2020 to May 2026 (77 observations), log scale,
seasonally adjusted by removing calendar-month effects. Minimum segment 15% of the sample.

## The series is not structurally stable

Andrews supF test for a break at an unknown date: **supF = 48.19, p = 1.25e-09**. Stability is
rejected decisively. The framework as published assumes structural stability, which is the
assumption Reviewer 3 questions.

## Bai-Perron: two breaks, selected by BIC

| Break | 95% confidence interval |
|---|---|
| **September 2021** | August to November 2021 |
| **March 2024** | December 2023 to April 2024 |

BIC across partitions: m=0 -125.0, m=1 -151.0, **m=2 -159.3**, m=3 -153.2, m=4 -142.9, m=5 -130.2.

### Growth by regime

| Segment | Months | Annualised growth |
|---|---|---|
| Jan 2021 to Sep 2021 | 21 | **+5.26%** |
| Oct 2021 to Mar 2024 | 30 | **+30.92%** |
| Apr 2024 to May 2026 | 26 | **+13.31%** |

This is the substantive finding, and it cuts at the heart of the scenario parameterisation. The base
growth rate of 18.86% that drives every scenario is an average across three regimes and corresponds
to none of them. **The current regime grows at 13.3% per year**, well below the rate used to project.
Projecting from the most recent regime would give materially lower figures, and the reviewer's
concern about structural stability is therefore not merely formal.

## Chow tests at the candidate policy dates

| Date | Milestone | F | p |
|---|---|---|---|
| Sep 2022 | Law 14.454/2022, exemplificative ROL | 19.479 | <0.0001 |
| Feb 2024 | date the manuscript assigns to Binding Precedents 60/61 | 8.279 | 0.0006 |
| **Sep 2024** | **actual publication of Binding Precedents 60/61** | 0.482 | 0.620 |
| **Sep 2025** | **ADI 7265 judgment** | 0.094 | 0.910 |

Read with care. A Chow test at a pre-specified date in a series that contains genuine breaks
elsewhere rejects easily, so the Bai-Perron result is the more reliable guide. The rejection at
September 2022 sits inside the high-growth regime and cannot be attributed to Law 14.454 without an
interrupted-time-series model that controls for the other breaks. The rejection at February 2024 is
an artefact of proximity to the genuine March 2024 break.

The two milestones actually cited in the manuscript, at their correct dates, show **no** break.

## The legal citations, verified at the primary source

Both Binding Precedents concern medicines in the **public** system, not private insurance, and both
postdate February 2024. Text and publication dates taken from the STF portal on 21 September 2026.

**Binding Precedent 60** (DJE of 16 September 2024; underlying RE 1.366.243 judged 16 September
2024, Theme 1234):
> "O pedido e a análise administrativos de fármacos na rede pública de saúde, a judicialização do
> caso, bem ainda seus desdobramentos (administrativos e jurisdicionais), devem observar os termos
> dos 3 (três) acordos interfederativos (e seus fluxos) homologados pelo Supremo Tribunal Federal,
> em governança judicial colaborativa, no tema 1.234 da sistemática da repercussão geral RE
> 1.366.243."

**Binding Precedent 61** (DJE of 3 October 2024; Theme 6, RE 566.471):
> "A concessão judicial de medicamento registrado na ANVISA, mas não incorporado às listas de
> dispensação do Sistema Único de Saúde, deve observar as teses firmadas no julgamento do Tema 6 da
> Repercussão Geral (RE 566.471)."

Consequences for reference 7: the date of 23 February 2024 is wrong for both, and neither bears on
supplementary health insurance.

Reference 9, Law 14.874/2024, governs research involving human subjects
("Dispõe sobre a pesquisa com seres humanos e institui o Sistema Nacional de Ética em Pesquisa com
Seres Humanos") and is unrelated to the subject of this paper. It must be removed, and with it the
claim of "new legislation in 2024" in the Background.

The relevant statute, absent from the manuscript, is **Law 14.454 of 21 September 2022**, which
inserted paragraph 13 into article 10 of Law 9.656/1998 and made the ANS benefit package
exemplificative rather than exhaustive.

## What to report in the revision
1. The supF result and the two Bai-Perron breaks, with confidence intervals.
2. The three growth regimes, and an explicit acknowledgement that the base growth rate averages
   across them. This belongs in the Limitations and, arguably, in a sensitivity analysis projecting
   from the post-March-2024 regime alone.
3. That the cited milestones show no break at their correct dates, correcting references 7 and 9.
4. Law 14.454/2022 as the pertinent statute, with the September 2022 Chow result reported and
   interpreted cautiously.

## Sources
- Binding Precedent 60: https://portal.stf.jus.br/jurisprudencia/sumariosumulas.asp?base=26&sumula=9260
- Binding Precedent 61: https://portal.stf.jus.br/jurisprudencia/sumariosumulas.asp?base=26&sumula=9296
- Law 14.454/2022: https://www.planalto.gov.br/ccivil_03/_ato2019-2022/2022/lei/l14454.htm
- Law 14.874/2024: https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2024/lei/l14874.htm
