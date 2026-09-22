# Quebras estruturais na série de TAXA

22 de setembro de 2026. Script: `scripts/22_structural_breaks_rate.R`. Supersede
`docs/structural_breaks_findings.md` nas partes quantitativas.

---

## 1. Por que refazer

O documento anterior rodou supF, Bai-Perron e Chow sobre as **contagens mensais**. Todo modelo do
artigo é ajustado à **taxa por 1 000 beneficiários**, e a taxa-base que parametriza os cenários
(19,41% ao ano) é um crescimento de taxa. Comparar um crescimento de regime medido em contagens com
uma taxa-base medida em taxa mistura duas quantidades: as contagens carregam também o crescimento do
número de beneficiários, de cerca de 2% ao ano.

A série de taxa usa a convenção agora declarada no Methods: posição de dezembro de cada ano na série
oficial do SIB/ANS, com interpolação linear entre dezembros.

## 2. Resultados

### Estabilidade

| Teste | Estatística | p |
|---|---|---|
| Andrews supF, quebra em data desconhecida (trimming 15%) | **52,37** | < 0,0001 |

Estabilidade rejeitada decisivamente.

### Bai-Perron

BIC por número de quebras: −124,1 (m=0), −152,8 (m=1), **−161,6 (m=2, mínimo)**, −155,7 (m=3),
−145,3 (m=4), −132,4 (m=5).

> Cuidado de implementação: `BIC(bp)` num objeto `breakpointsfull` devolve **só o BIC da partição
> ótima**, um único número. O vetor sobre m = 0..5 está em `summary(bp)$RSS["BIC", ]`. Usar o
> primeiro leva a concluir, erradamente, que o mínimo é m = 0.

| Quebra | IC 95% |
|---|---|
| **Setembro de 2021** | agosto a novembro de 2021 |
| **Março de 2024** | dezembro de 2023 a abril de 2024 |

As datas coincidem com as obtidas nas contagens; os **crescimentos por regime, não**.

### Crescimento anualizado da taxa por regime

| Regime | Meses | Taxa (este doc) | Contagens (doc anterior) |
|---|---|---|---|
| jan/2020 – set/2021 | 21 | **3,35%** | 5,26% |
| out/2021 – mar/2024 | 30 | **28,36%** | 30,92% |
| abr/2024 – mai/2026 (atual) | 26 | **11,46%** | 13,31% |
| Série completa (especificação primária) | 77 | **19,41%** | 18,86% |

A diferença de cerca de 2 pontos entre as duas colunas é o crescimento do número de beneficiários,
como esperado.

### Chow nos marcos regulatórios

| Data | Marco | F | p |
|---|---|---|---|
| set/2022 | Lei 14.454/2022 (rol exemplificativo) | 21,58 | < 0,0001 |
| fev/2024 | data que o manuscrito atribuía às SV 60/61 | 9,29 | 0,0003 |
| **set/2024** | **publicação real da SV 60** | 0,69 | 0,50 |
| **set/2025** | **julgamento da ADI 7265** | 0,10 | 0,90 |

Os dois marcos efetivamente citados no manuscrito, nas datas corretas, **não mostram quebra**. Um
teste de Chow numa data pré-especificada, numa série que contém quebras genuínas em outros pontos,
rejeita com facilidade; e fev/2024 está a um mês da quebra de mar/2024. Bai-Perron é o guia mais
confiável, e nenhuma rejeição é atribuída a um instrumento específico.

## 3. A consequência que importa

| Base | 2030 | 2035 |
|---|---|---|
| Série completa, 19,41% (primária) | 739 155 | 1 096 270 |
| Regime atual, 11,46% | **566 226** | **740 945** |
| Diferença | −23% | −32% |

A taxa-base é uma média sobre três regimes e não corresponde a nenhum deles. Mantivemos a estimativa
de período completo como especificação primária — um único regime de 26 meses é base mais fraca para
uma projeção de dez anos do que a série inteira — mas a escolha é consequente e passa a constar das
Limitations e da Tabela S4.

## 4. Onde entrou no manuscrito

| Local | Conteúdo |
|---|---|
| §65 (Methods) | análise de sensibilidade S4: supF, Bai-Perron, Chow |
| §90 (Results) | resultados completos, com a leitura cautelosa dos Chow |
| §110 (Limitations) | sexta limitação: a série não é estruturalmente estável |
| Tabela S4 | tabela completa |

## Reprodutibilidade

```
Rscript scripts/22_structural_breaks_rate.R
```

R 4.3.3, strucchange 1.5.3, seed 42.
