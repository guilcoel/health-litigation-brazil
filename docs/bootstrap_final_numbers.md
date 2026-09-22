# Bootstrap refeito nos números finais — e uma afirmação invertida no §57 e no §88

22 de setembro de 2026. Script: `scripts/21_bootstrap_final.R`. Supersede `docs/bootstrap_findings.md`,
que foi calculado nos denominadores antigos.

---

## 1. A afirmação que estava errada

O §57 dizia que o bootstrap "is not intended to capture this structural component, **which is the
larger of the two**", e o §88 repetia a ideia. Com os números finais:

| Quantidade | Largura em 2030 |
|---|---|
| Intervalo do bootstrap (preditivo completo) | **590 874** |
| Faixa de política (τ_d de 3 a 20) | **353 564** |

A incerteza estrutural é a **menor** das duas nessa comparação. O Revisor 2 apontou isso no
comentário 5 e a v3 inicial não havia corrigido.

## 2. Por que a comparação é que estava errada, não a afirmação

O termo anual `exp(rnorm(1, 0, sigma))` é redesenhado a cada ano e multiplica a taxa acumulada. Ele
compõe ao longo do horizonte: é **ruído de processo**, não erro de estimação. Os cenários, por
construção, não carregam esse termo. Comparar o intervalo do bootstrap com a faixa de cenários é
comparar coisas de naturezas diferentes.

Separando os componentes (20 000 iterações, média de quatro sementes):

| Componente | Largura em 2030 | Participação |
|---|---|---|
| Intervalo de predição completo | 590 874 | 100% |
| Só incerteza de parâmetro (taxa de crescimento e âncora de 2025) | **152 249** | 26% |
| Ruído de processo anual | 438 625 | 74% |

Comparação equivalente: **353 564 / 152 249 = 2,3**. A afirmação do artigo sobrevive, desde que se
declare qual comparação está sendo feita e se reportem as duas larguras.

Consequência de redação: os limites são **intervalos de predição**, não de confiança. Rotulados
assim no §57, no §88 e nas Tabelas S4–S6.

## 3. Estabilidade

20 000 iterações (eram 2 000), quatro sementes:

| Semente | Intervalo 2030 | Mediana | Largura |
|---|---|---|---|
| 42 | 500 654 – 1 089 369 | 737 929 | 588 715 |
| 1 | 498 661 – 1 094 630 | 740 484 | 595 968 |
| 7 | 502 472 – 1 089 891 | 737 518 | 587 419 |
| 2026 | 499 687 – 1 091 080 | 740 185 | 591 393 |
| **média** | **500 369 – 1 091 242** | **739 029** | **590 874** |

Variação de largura entre sementes: **1,5%**. A mediana (739 029) bate com a projeção inercial
determinística (739 191).

## 4. As duas sensibilidades que o R2.5 pediu

### Fator sobre o sigma da âncora (o `sigma_anual * 0.5` questionado)

| Fator | Intervalo 2030 | Largura |
|---|---|---|
| 0 (sem incerteza na âncora) | 505 928 – 1 084 165 | 578 236 |
| 0,25 | 503 071 – 1 079 664 | 576 593 |
| **0,50 (publicado)** | **500 654 – 1 089 369** | **588 715** |
| 1,00 (sigma cheio) | 487 245 – 1 119 664 | 632 419 |

Zerar ou dobrar move a largura em cerca de 9%. A escolha publicada não é consequente, porque o
intervalo de 2030 é dominado pelo choque anual composto, não pela incerteza no ano-âncora.

### Teto de plausibilidade

| Teto | Intervalo 2030 | Largura |
|---|---|---|
| 15 | 500 654 – 870 108 | 369 454 |
| 20 | 500 654 – 1 089 369 | 588 715 |
| **25 (publicado)** | **500 654 – 1 089 369** | **588 715** |
| 30 | 500 654 – 1 089 369 | 588 715 |
| sem teto | 500 654 – 1 089 369 | 588 715 |

O teto **não morde** no horizonte primário: o intervalo é idêntico com 20, 25, 30 ou sem teto. Só um
teto de 15 por 1 000 muda alguma coisa — e 15 é abaixo do nível que o próprio cenário pessimista
alcança.

Justificativa do teto, que existia apenas em comentário de código e foi movida para o §57: 25 por
1 000 é uma ação nova para cada 40 beneficiários, cerca de **quatro vezes** o nível de 2025 (6,46 por
1 000). Nota: `bootstrap_findings.md` dizia "cinco vezes"; são 3,9.

## 5. Validação do pipeline

A projeção de beneficiários foi reconstruída do zero na série oficial da ANS (modelo logit-linear
da cobertura sobre as projeções do IBGE, teto de 29%) e reproduz `final_numbers.md` exatamente:
54 038 615 em 2026, 58 007 230 em 2030, 62 954 909 em 2035, com o teto passando a valer em 2036. A
trajetória inercial determinística dá taxa 12,742 e 739 155 casos em 2030, contra os 739 191
publicados — diferença de arredondamento na taxa-âncora.

## Reprodutibilidade

```
Rscript scripts/21_bootstrap_final.R
```

R 4.3.3. Roda em cerca de um minuto.
