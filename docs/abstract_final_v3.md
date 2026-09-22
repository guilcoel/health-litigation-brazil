# Abstract final da revisão v3, dentro do limite de 350 palavras

Preparado em 22 de setembro de 2026. Substitui integralmente a seção 3 de
`abstract_conclusions_rewrite.md`, que foi escrita antes das duas decisões e antes da recontagem.
Números conferidos contra `final_numbers.md`.

---

## 1. O texto

> **Background:** Health litigation against private health insurers has risen substantially in
> Brazil, whose supplementary system covers approximately 52 million beneficiaries, but has never
> been formally projected. We aimed to forecast it and to quantify how far its trajectory is
> determined by the observed dynamic of the series rather than by the regulatory response.
>
> **Methods:** We conducted an ecological time-series study of new national supplementary-health
> judicial claims from January 2020 through December 2025 (72 monthly observations), reserving
> January–May 2026 for out-of-sample validation. Claims were expressed per 1 000 beneficiaries using
> the official ANS beneficiary series. Four forecasting models were compared by temporal
> cross-validation with a 12-month holdout. Three regulatory scenarios were defined by the damping
> applied to the estimated growth rate. Because the damping horizon is not identified by the data,
> these are stress tests under stated assumptions rather than forecasts, and projections were also
> expressed as a continuous response surface over damping horizons of 3–20 years. Projection
> uncertainty was decomposed into policy, trend-estimator and market-size components.
>
> **Results:** The litigation rate rose from 2.93 to 6.46 per 1 000 beneficiaries between 2020 and
> 2025 (log-linear growth 19.4% per year). At the 2030 horizon the statistical forecast (652 002
> claims; 95% prediction interval 214 805–1 089 199) and the inertial scenario (739 191) agreed on
> the central path to within 14%, and both fell within 2% of observed cumulative claims for
> January–May 2026, although monthly accuracy differed (MAPE 7.6% and 4.8%). Uncertainty at 2030 was
> dominated by the regulatory response, which exceeded market-size uncertainty approximately sixfold
> and trend-estimator uncertainty twofold. On the curved response surface, each additional year of
> delay added approximately 19 000 claims on average, and 13 000 near the inertial trajectory.
>
> **Conclusions:** Near-term projections of supplementary-health litigation in Brazil are
> reproducible across specifications and validated against withheld data, though with wide
> prediction intervals, whereas the longer-run outcome depends chiefly on the regulatory response
> rather than on statistical or market uncertainty. Projections beyond 2030 are stress tests, not
> forecasts. Separating inertial from policy-dependent components offers a transferable approach for
> health systems facing rising coverage disputes.

**Keywords** (inalteradas, 6, dentro da faixa 3–10): health litigation; supplementary health
insurance; time-series forecasting; coverage disputes; health policy; Brazil.

## 2. Contagem

| Seção | Palavras |
|---|---|
| Background | 52 |
| Methods | 112 |
| Results | 115 |
| Conclusions | 62 |
| **Total** | **341** (345 contando os quatro rótulos) |

Contagem bruta por espaços — a mesma que o Word faz, e o pior caso: cada separador de milhar conta
como palavra. Se os milhares forem digitados com espaço fino não separável, como o BMC prefere, a
contagem cai para 332. Folga de 5 palavras no pior caso contra o limite de 350. Sem citações, como
a revista exige.

## 3. O que mudou em relação ao submetido, e por quê

| Mudança | Motivo |
|---|---|
| 2.98 → **2.93** por 1 000; crescimento 18.9% → **19.4%** | denominadores oficiais da ANS (Decisão 1) |
| 671 400 → **652 002**, agora **com o intervalo de predição** | R2 comentário 3: a convergência não pode ser lida como precisão |
| "converged to within 11%" → "**agreed on the central path to within 14%**" | os dois pontos mudaram; e "convergir" sugeria concordância que o intervalo não sustenta |
| acrescentado "**although monthly accuracy differed (MAPE 7.6% and 4.8%)**" | R2 comentário 4: a assimetria da validação é real e pesa contra o SARIMA. O abstract não podia continuar dando só a métrica em que o SARIMA ganha |
| "6.3 to 1" → "**approximately sixfold**", e acrescentado o componente de tendência | a razão oscilou entre 4.7 e 6.4 entre escolhas defensáveis (`final_numbers.md`, §7). O componente de tendência é 3,1 vezes o de mercado e estava omitido |
| "roughly 18 700" → "**~19 000 on average, and 13 000 near the inertial trajectory**" | R3 fraqueza 2: 18 700 é a inclinação de um ajuste linear a uma superfície curva (R² 0,876) |
| "conditional scenarios" → "**stress tests, not forecasts**" | R3 oferece duas saídas; tomamos a primeira |
| **removida a frase sobre os três tribunais estaduais** (do Methods e do Results) | ver abaixo |
| acrescentado "**using the official ANS beneficiary series**" | ver seção 4 |

### A frase dos tribunais estaduais sai do abstract

O submetido terminava o Results com *"The framework replicated in high- and medium-volume state
courts and reached its limit in a low-volume court, where count noise dominated, supporting analysis
at the national scale."* Ela sai, e não é só por palavras.

É exatamente a frase que o Revisor 2 atacou: três tribunais não sustentam uma conclusão sobre limiar
de volume, e "supporting analysis at the national scale" é uma generalização que a amostra não
comporta. Descobrimos ainda que o Acre tem 64 observações mensais no período contra 72 dos outros —
o pipeline não foi aplicado a séries idênticas. Manter a análise como exploratória no material
suplementar e tirá-la do abstract é a resposta substantiva ao R2, não uma economia de espaço. A
carta deve dizer isso nesses termos.

## 4. Sobre "conseguimos dados melhores" — o que dá para afirmar e o que não dá

A parte verdadeira é esta, e ela é forte:

> A revisão passou a usar a **série oficial de beneficiários do SIB/ANS** como denominador,
> substituindo os números da submissão anterior, e o arquivo suplementar passa a trazer essa série
> junto da série mensal do CNJ, de modo que **toda taxa publicada é reconstruível a partir do
> depósito**.

O que **não** dá para escrever é que ganhamos acesso a algo antes indisponível. A série da ANS é
pública e sempre foi; o que mudou é que adotamos a fonte oficial em lugar dos números usados antes e
tornamos cada denominador rastreável. Se a carta sugerir acesso novo, um revisor que abra o portal
da ANS em trinta segundos vê que não é o caso, e aí o custo é a credibilidade de todo o resto da
resposta. A formulação acima entrega o mesmo ganho de percepção sem nada que possa ser desmentido.

Vale registrar que o efeito sobre os resultados é pequeno e favorável: o crescimento-base sobe de
18,9% para 19,41% ao ano, a abertura da série vai de 2,98 para 2,93 e o teto de 29% passa a atuar em
2036 em vez de 2033. Nenhuma conclusão do artigo muda de sinal. Isso é o melhor argumento de
qualidade que temos: **a análise é robusta à troca do denominador**, e a carta deve dizer isso
explicitamente em vez de pedir desculpa pela troca.

## 5. §94 — as duas frases quebradas do IESS

O parágrafo do IESS não está em nenhuma lista de revisor, mas quebra com os números finais: o nosso
otimista de 2035 passou de 364 961 para 489 401, e o pessimista de 1 476 388 para 1 514 120. Então
"lies near our optimistic scenario" e "marginally exceeds the IESS upper bound" deixaram de ser
verdade. Substituir o parágrafo inteiro por:

> We also compared our projections with estimates published by the IESS (Figure 2). Because the IESS
> report is itself projection-based, this is a comparison with an alternative projection exercise
> rather than external validation against observed data, which the out-of-sample test above
> provides. At the 2035 horizon, our optimistic scenario (489 401 claims) exceeds the IESS realistic
> estimate (approximately 400 000) by 22%; the IESS pessimistic range (900 000–1.2 million) brackets
> our inertial projection (1 096 373); and our pessimistic scenario (1 514 120), which assumes no
> institutional coordination, exceeds the IESS upper bound by 26%. The two exercises therefore agree
> around the centre of the range and diverge at its edges, which follows from different assumptions
> about the regulatory response rather than from any disagreement about the observed series.

Três ganhos: os números voltam a bater, a divergência passa a ser explicada em vez de minimizada, e
o parágrafo deixa de contradizer o §38 e a Table 1, que já não chamam o IESS de validação externa.

## 6. Onde isso ainda toca o manuscrito

- §29 tem "2.98 to 5.73 per 1 000" para 2020–2024. Com a série da ANS é **2,93 → 5,76**. Conferir
  junto com o parágrafo jurídico reescrito.
- §76 ainda descreve o termo de drift e o usa como justificativa da escolha do SARIMA. Sai inteiro
  (`sarima_interval_findings.md`).
- A frase do Results que ordena os quatro modelos precisa virar "os quatro ficam numa faixa
  estreita": ETS e SARIMA trocaram de posição por 0,01 ponto percentual (`tables.md`, Table S1).
