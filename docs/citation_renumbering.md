# Renumeração das citações: a regra uniforme está errada

22 de setembro de 2026. Corrige a seção 3 de `docs/minor_corrections.md`.

---

## 1. A regra proposta

`minor_corrections.md` §3 conclui que os dois problemas (remoção de duas referências legais,
reinserção da nota metodológica CNJ/PNUD) se compõem numa regra única:

> **Todo marcador no texto de [10] a [28] diminui em um.**

Ela é falsa, e aplicá-la corromperia dez marcadores.

## 2. O contraexemplo

A lista nova tem 28 entradas. As posições 17 a 28 **não se movem**: a remoção de duas entradas
(posições antigas 7 e 9) e a inserção de duas (Lei 14.454 em 7, nota CNJ/PNUD em 16) se cancelam
acima da posição 16.

| Parágrafo | Marcador | Obra pretendida | Posição nova | Regra uniforme daria |
|---|---|---|---|---|
| §100 | [19], [20] | Corte Constitucional da Colômbia; Defensoría del Pueblo | 19, 20 | 18, 19 — **apontaria para Hyndman** |
| §102 | [23], [24] | Painel Econômico-Financeiro da ANS; Senado dos EUA | 23, 24 | 22, 23 — errado |
| §104 | [21], [25], [26], [27] | Tocantins; e-NatJus; NAT-SS; Panorama ANS | idem | todos −1 — errado |
| §106 | [23], [28] | ANS; Paim et al. | 23, 28 | 22, 27 — errado |

O caso do §100 é o mais claro: a regra faria uma afirmação sobre tutelas na Colômbia citar o artigo
do pacote `forecast` do Hyndman.

## 3. O que realmente acontece

Os marcadores do manuscrito submetido são **internamente inconsistentes**. Três deles foram escritos
contra uma lista que incluía a nota CNJ/PNUD; os demais, contra a lista efetivamente publicada.
Apenas os três primeiros se deslocam:

| Parágrafo | Antes | Depois | Obra |
|---|---|---|---|
| §40 | [17] | **[16]** | nota metodológica CNJ/PNUD |
| §41 | [18] | **[17]** | Resolução CNS 510/2016 |
| §47 | [19] | **[18]** | Hyndman & Khandakar |

E, abaixo da posição 16, o deslocamento real por conta das duas referências legais:

| Parágrafo | Antes | Depois |
|---|---|---|
| §29 | [7–9] | **[7]** (Lei 14.454/2022) e **[8]** (ADI 7265) |
| §30 | [5, 10], [11] | **[5, 9]**, **[10]** |
| §31 | [12–14] | **[11–13]** |
| §32 | [15], [16] | **[14]**, **[15]** |

Todos os demais permanecem como estão.

## 4. Auditoria após a aplicação

No manuscrito v3: as 28 referências são citadas no texto, nenhuma órfã, nenhum marcador fora da
faixa 1–28.

Dois itens continuam abertos e estão em `PENDENCIAS_v3_20260922.md`: a citação completa da nota
CNJ/PNUD (posição 16, hoje um marcador `[A COMPLETAR]`) e a conferência dos três marcadores do
§53 contra as obras citadas.

## 5. Lição para o próximo passe

Renumeração de citações não é operação aritmética sobre marcadores; é mapeamento semântico de cada
marcador à obra que o texto pretende citar. A própria `minor_corrections.md` recomendava verificar
§53 e §100 lendo as obras — a verificação mostrou que o problema era mais amplo do que os dois
parágrafos sinalizados.
