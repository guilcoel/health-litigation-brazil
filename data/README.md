# Data

## cnj_monthly_series_national_and_states.csv
Monthly counts of new supplementary-health judicial claims, extracted from the underlying data
table of the CNJ Statistical Panel on Health Litigation, filtered to the Supplementary Health theme.
Columns: `date`, `scope`, `new_claims`. Scopes: National (77 months), SP (77), GO (77), AC (69).
Period: January 2020 to May 2026.

Validation against the panel's published annual totals: 2020 = 140,439; 2021 = 147,303;
2022 = 171,142; 2023 = 228,640; 2024 = 299,128; 2025 = 341,763. Total 2020-2025 = 1,328,415.
January to May 2026 = 154,885.

## ans_hospital_medical_beneficiaries_annual.csv
Annual counts of beneficiaries of private hospital-medical plans, used as the rate denominator.
Columns: `ano`, `benef_mh`.

PROVENANCE NOTE, open. These values are rounded to the thousand and differ from the December
position currently published by ANS: 2020 -1.68%, 2021 -1.44%, 2022 -1.64%, 2023 +0.18%,
2024 +0.49%, 2025 +0.06%. The ANS December series (extracted 21 September 2026) is
2020 = 47,939,243; 2021 = 49,274,613; 2022 = 50,530,569; 2023 = 51,254,745; 2024 = 51,956,946;
2025 = 52,865,947. The December 2025 figure was verified against the primary open-data file
(PDA, beneficiaries by geographic region, competence 2025-12, sum of NR_BENEF_M = 52,865,947).
The most plausible explanation for the 2020-2022 gap is retroactive revision of the ANS series.
To be resolved before submission.

## ans_beneficiaries_projected.csv
Projected beneficiaries and coverage share, 2026-2040, from a logit-linear model of the coverage
share with an imposed 29% ceiling, anchored to IBGE 2024 population projections.
2030 = 59,593,837 (coverage 27.47%); 2035 = 63,616,502.

## Sources
- CNJ Statistical Panel on Health Litigation: https://justica-em-numeros.cnj.jus.br/painel-saude/
- ANS open data: https://dadosabertos.ans.gov.br/FTP/PDA/
- ANS sector figures: https://www.gov.br/ans/pt-br/acesso-a-informacao/perfil-do-setor/dados-gerais
- IBGE population projections, 2024 revision: https://www.ibge.gov.br/
