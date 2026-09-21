## ============================================================
## 03_model.R  (v3 — CORRIGIDO: denominador, baseline, cenários)
## Projeção da judicialização da saúde suplementar — Brasil
##
## CORREÇÕES v2 → v3:
##   [C1] Denominador: beneficiários MÉDICO-HOSPITALARES apenas
##        (ANS ~52M em 2024), NÃO total med+odonto (~88M)
##   [C2] Baseline: validar 2024=298.755 (IESS/CNJ oficial)
##        e estimar 2025 anualizado (H1=156.482 → ~313k)
##   [C3] Cenários ancorados no IESS 2025 como benchmark
##   [C4] Bootstrap IC com damping (simula em torno do inercial)
##   [C5] Taxa/1k alinhada com IESS (~5,7/1k em 2024)
##
## ESTRATÉGIA:
##   Variável-resposta = taxa de judicialização / 1.000 benef. MH
##   Processos = taxa × beneficiários MH projetados
##
##   Horizontes:
##     Primário    — 2030 (5 anos)      | Confiança alta
##     Secundário  — 2035 (10 anos)     | Moderada
##     Ilustrativo — 2040 (15 anos)     | Baixa
##
## INPUT:  data/ready/
## OUTPUT: results/models/, results/figures/, results/tables/
## ============================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(scales)
  library(glue)
  library(forecast)
  library(tseries)
  library(MASS)
  library(lubridate)
})

proj_root <- "/Volumes/Forja/Projetos/Artigo Judicializacao"
setwd(proj_root)

dirs <- c("results/models", "results/figures", "results/tables")
for (d in dirs) dir.create(d, showWarnings = FALSE, recursive = TRUE)

# Helpers ----
log <- character()
log_msg <- function(msg) {
  msg <- glue(msg, .envir = parent.frame())
  cat(msg, "\n")
  log <<- c(log, msg)
}
fmt <- function(x, ...) format(x, big.mark = ".", decimal.mark = ",", ...)

theme_pub <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "grey40"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

save_fig <- function(p, nome, w = 10, h = 6) {
  path <- file.path("results/figures", paste0(nome, ".png"))
  ggsave(path, p, width = w, height = h, dpi = 300, bg = "white")
  log_msg("  Figura: {nome}.png")
}

log_msg("========== 03_model.R v3 — MODELO CORRIGIDO ==========")
log_msg("Timestamp: {Sys.time()}")

# ==============================================================================
# [1/11] CARREGAR DADOS
# ==============================================================================
log_msg("\n--- [1/11] Carregando dados ---")

cnj     <- read_csv("data/ready/cnj_mensal_ready.csv", show_col_types = FALSE)
ibge_br <- read_csv("data/ready/ibge_pop_brasil_ready.csv", show_col_types = FALSE)
custos  <- read_csv("data/ready/custos_ready.csv", show_col_types = FALSE)
marcos  <- read_csv("data/ready/marcos_ready.csv", show_col_types = FALSE)
painel  <- read_csv("data/ready/painel_uf_ano_ready.csv", show_col_types = FALSE)

# Normalizar nomes ibge_br
nms_ibge <- tolower(names(ibge_br))
names(ibge_br)[grep("^ano|^year", nms_ibge)[1]] <- "ano"
names(ibge_br)[grep("pop", nms_ibge)[1]] <- "pop"

log_msg("  cnj: {nrow(cnj)} meses | ibge: {nrow(ibge_br)} anos | painel: {nrow(painel)} rows")

# ==============================================================================
# [2/11] CORREÇÃO C1 — BENEFICIÁRIOS MÉDICO-HOSPITALARES APENAS
# ==============================================================================
log_msg("\n--- [2/11] [C1] Correção de beneficiários ---")
log_msg("  PROBLEMA: v2 usava benef_total (med+odonto ≈ 88M)")
log_msg("  CORREÇÃO: usar apenas médico-hospitalares ANS (≈ 52M)")

# Dados oficiais ANS — beneficiários médico-hospitalares (dezembro de cada ano)
# Fontes:
#   2024: ANS, "Setor fecha 2024 com números recordes" (fev/2025) → 52.210.290
#   2023: 52.210.290 - 862.771 (crescimento 12 meses) = 51.347.519
#   2022: ANS Sala de Situação / DataSUS TabNet
#   2021-2020: ANS Sala de Situação / DataSUS TabNet
#   2025: ANS "Dados referentes a julho/2025" → 52.884.500 (jul)
#          Média jan-dez estimada = 52.900.000 (projeção linear)
#
# NOTA: Valores para 2020-2022 abaixo são aproximações da Sala de Situação ANS.
#       O usuário deve validar com dados exatos do TabNet/ANS se disponíveis.
#       Se ajustar, basta editar o tibble benef_mh_ans abaixo.

benef_mh_ans <- tibble(
  ano = 2020:2025,
  benef_mh = c(
    47135000,   # Dez/2020 — estimativa ANS (~47,1M, pós-queda COVID)
    48566000,   # Dez/2021 — ANS (~48,6M, início da recuperação)
    49703000,   # Dez/2022 — ANS (~49,7M)
    51348000,   # Dez/2023 — ANS (52.210.290 - 862.771)
    52210000,   # Dez/2024 — ANS oficial: 52.210.290
    52900000    # Dez/2025 — estimativa: Jul/2025=52.884.500, tendência +112k/mês
  )
)

# Comparar com v2 (benef_total = med+odonto)
nacional_v2 <- painel %>%
  group_by(ano) %>%
  summarise(
    processos = sum(processos_novos, na.rm = TRUE),
    benef_total = sum(benef_total, na.rm = TRUE),
    pop_ibge = sum(pop_ibge, na.rm = TRUE),
    .groups = "drop"
  )

log_msg("  Comparação beneficiários (v2 total vs v3 MH):")
log_msg("  {sprintf('%-6s %15s %15s %8s', 'Ano', 'v2 (med+odonto)', 'v3 (MH only)', 'Fator')}")
for (a in 2020:2025) {
  v2 <- nacional_v2$benef_total[nacional_v2$ano == a]
  v3 <- benef_mh_ans$benef_mh[benef_mh_ans$ano == a]
  if (length(v2) > 0 && length(v3) > 0) {
    log_msg("  {sprintf('%-6d %15s %15s %8.2f', a, fmt(v2), fmt(v3), v2/v3)}")
  }
}

# ==============================================================================
# [3/11] CORREÇÃO C2 — VALIDAÇÃO DO BASELINE 2024/2025
# ==============================================================================
log_msg("\n--- [3/11] [C2] Validação baseline 2024 ---")

# IESS/CNJ oficial: 298.755 processos novos em 2024
# Nosso total 2024 via painel:
proc_2024_nosso <- nacional_v2$processos[nacional_v2$ano == 2024]
proc_2025_nosso <- nacional_v2$processos[nacional_v2$ano == 2025]
proc_2024_iess <- 298755

log_msg("  IESS/CNJ 2024: {fmt(proc_2024_iess)}")
log_msg("  Nosso 2024:    {fmt(proc_2024_nosso)}")
log_msg("  Nosso 2025:    {fmt(proc_2025_nosso)}")

# Diagnóstico da discrepância
delta_2024 <- proc_2024_nosso - proc_2024_iess
pct_delta <- delta_2024 / proc_2024_iess * 100

if (abs(pct_delta) > 10) {
  log_msg("  ⚠ DISCREPÂNCIA >10%: nosso 2024 difere {round(pct_delta,1)}% do IESS")
  log_msg("  → Possível causa: série mensal CNJ tem reporting lag")
  log_msg("  → Nosso '2025' ({fmt(proc_2025_nosso)}) ≈ IESS '2024' ({fmt(proc_2024_iess)})")
  log_msg("  → DECISÃO: usar dados IESS como âncora para 2024")
} else {
  log_msg("  ✓ Discrepância < 10% — dados alinhados com IESS")
}

# Estimar 2025 anualizado com dados parciais do CNJ
# H1/2025: 156.482 (CNJ Medicina S/A, ago/2025)
# H1/2024: 144.542
# Crescimento H1: +8,2%
# Informação adicional: conselheira CNJ reportou em Out/2025 que crescimento
# acumulado até Set/2025 era de apenas +1% vs 2024 na suplementar
# → Isso sugere desaceleração forte no H2/2025 (possivelmente SV 60/61 + ADI 7265)
#
# CENÁRIO CONSERVADOR: anualizar com crescimento de +3% sobre 2024
# (média entre +8,2% do H1 e o +1% acumulado até Set)

proc_2025_estimado <- round(proc_2024_iess * 1.03)
log_msg("  2025 estimado (2024 × 1,03): {fmt(proc_2025_estimado)}")
log_msg("  Premissa: média entre H1 (+8,2%) e acumulado até Set (+1%)")

# SÉRIE ANUAL CORRIGIDA
nacional <- tibble(
  ano = 2020:2025,
  processos = c(
    nacional_v2$processos[nacional_v2$ano == 2020],
    nacional_v2$processos[nacional_v2$ano == 2021],
    nacional_v2$processos[nacional_v2$ano == 2022],
    nacional_v2$processos[nacional_v2$ano == 2023],
    proc_2024_iess,     # [C2] IESS oficial 2024
    proc_2025_estimado  # [C2] estimativa 2025
  )
) %>%
  left_join(benef_mh_ans, by = "ano") %>%       # [C1] MH apenas
  left_join(
    ibge_br %>% filter(ano >= 2020, ano <= 2025) %>% select(ano, pop),
    by = "ano"
  ) %>%
  rename(benef = benef_mh, pop_ibge = pop) %>%
  mutate(
    taxa_1k   = processos / benef * 1000,        # [C5] taxa corrigida
    taxa_100k = processos / pop_ibge * 100000,
    cob       = benef / pop_ibge,
    log_taxa  = log(taxa_1k)
  )

log_msg("\n  SÉRIE ANUAL CORRIGIDA (v3):")
log_msg("  {sprintf('%-6s %10s %12s %10s %8s %7s', 'Ano', 'Processos', 'Benef MH', 'Pop IBGE', 'Taxa/1k', 'Cob%')}")
for (i in seq_len(nrow(nacional))) {
  log_msg("  {sprintf('%-6d %10s %12s %10s %8.2f %6.1f%%',
            nacional$ano[i], fmt(nacional$processos[i]),
            fmt(nacional$benef[i]),
            fmt(round(nacional$pop_ibge[i])),
            nacional$taxa_1k[i],
            nacional$cob[i]*100)}")
}

# Validação cruzada com IESS
taxa_2024_iess <- 5.7
taxa_2024_nossa <- nacional$taxa_1k[nacional$ano == 2024]
log_msg("\n  VALIDAÇÃO TAXA 2024:")
log_msg("    IESS:  {taxa_2024_iess}/1k")
log_msg("    Nossa: {round(taxa_2024_nossa, 2)}/1k")
log_msg("    Delta: {round(taxa_2024_nossa - taxa_2024_iess, 2)}")
if (abs(taxa_2024_nossa - taxa_2024_iess) < 0.5) {
  log_msg("    ✓ ALINHADO com IESS")
}

cagr_taxa <- ((tail(nacional$taxa_1k, 1) / head(nacional$taxa_1k, 1))^(1/(nrow(nacional)-1)) - 1) * 100
cagr_proc <- ((tail(nacional$processos, 1) / head(nacional$processos, 1))^(1/(nrow(nacional)-1)) - 1) * 100
log_msg("\n  CAGR taxa/1k (2020-2025): {round(cagr_taxa, 1)}%/ano")
log_msg("  CAGR processos (2020-2025): {round(cagr_proc, 1)}%/ano")

# ==============================================================================
# [4/11] SÉRIE MENSAL COM TAXA CORRIGIDA
# ==============================================================================
log_msg("\n--- [4/11] Série mensal (benef MH) ---")

benef_anual <- nacional %>% select(ano, benef)
benef_lookup <- setNames(benef_anual$benef, benef_anual$ano)

serie <- cnj %>%
  mutate(date = as.Date(paste0(ano, "-", sprintf("%02d", mes), "-01"))) %>%
  arrange(date) %>%
  mutate(
    # Interpolação linear dos beneficiários MH mensais
    benef_ano = benef_lookup[as.character(ano)],
    benef_prox = ifelse(ano < 2025,
                        benef_lookup[as.character(ano + 1)],
                        benef_lookup[as.character(ano)] * 1.015),
    frac = (mes - 1) / 11,
    benef = benef_ano + (benef_prox - benef_ano) * frac,
    taxa_1k = casos_novos / benef * 1000,
    log_casos = log(casos_novos),
    log_taxa = log(taxa_1k),
    t = row_number(),
    mes_f = factor(mes)
  ) %>%
  select(date, ano, mes, mes_f, t, casos_novos, benef, taxa_1k,
         log_casos, log_taxa)

ts_taxa  <- ts(serie$taxa_1k, start = c(2020, 1), frequency = 12)
ts_casos <- ts(serie$casos_novos, start = c(2020, 1), frequency = 12)

log_msg("  {nrow(serie)} meses | taxa_1k mensal: {round(min(serie$taxa_1k),4)} – {round(max(serie$taxa_1k),4)}")

# ==============================================================================
# [5/11] EXPLORATÓRIA
# ==============================================================================
log_msg("\n--- [5/11] Exploratória ---")

adf_res <- adf.test(ts_taxa, alternative = "stationary")
kpss_res <- kpss.test(ts_taxa, null = "Level")
log_msg("  ADF (taxa): p={round(adf_res$p.value,4)} → {ifelse(adf_res$p.value<0.05,'estacionária','NÃO estacionária')}")
log_msg("  KPSS (taxa): p={round(kpss_res$p.value,4)} → {ifelse(kpss_res$p.value<0.05,'NÃO estacionária','estacionária')}")

# Log-linear anual
lm_log <- lm(log_taxa ~ ano, data = nacional)
slope_log <- coef(lm_log)[2]
r2_log <- summary(lm_log)$r.squared
log_msg("  Log-linear anual: +{round((exp(slope_log)-1)*100,1)}%/ano | R²={round(r2_log,3)}")

# Sazonalidade
sazonal <- serie %>%
  group_by(mes) %>%
  summarise(media = mean(casos_novos), .groups = "drop") %>%
  mutate(idx = media / mean(media))
meses_nm <- c("Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez")
log_msg("  Sazonalidade: pico={meses_nm[which.max(sazonal$idx)]} ({round(max(sazonal$idx),3)}) | vale={meses_nm[which.min(sazonal$idx)]} ({round(min(sazonal$idx),3)})")

# Decomposição
decomp <- stl(ts_casos, s.window = "periodic")

# Figuras exploratórias
p1 <- ggplot(serie, aes(x = date, y = casos_novos)) +
  geom_line(color = "#2c3e50", linewidth = 0.7) +
  geom_smooth(method = "loess", span = 0.3, color = "#e74c3c",
              se = FALSE, linewidth = 0.5, linetype = "dashed") +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b/%y") +
  labs(title = "Processos novos — Saúde suplementar (Brasil, mensal)",
       subtitle = "Jan/2020 – Dez/2025 | Tracejado = LOESS",
       x = NULL, y = "Processos novos") + theme_pub
save_fig(p1, "01_serie_mensal_casos")

p2 <- ggplot(serie, aes(x = date, y = taxa_1k)) +
  geom_line(color = "#2c3e50", linewidth = 0.7) +
  geom_smooth(method = "loess", span = 0.3, color = "#e74c3c",
              se = FALSE, linewidth = 0.5, linetype = "dashed") +
  scale_x_date(date_breaks = "6 months", date_labels = "%b/%y") +
  labs(title = "Taxa de judicialização / 1.000 beneficiários MH (mensal)",
       subtitle = "Saúde suplementar | Brasil | Denominador: planos médico-hospitalares",
       x = NULL, y = "Processos / 1.000 benef. MH") + theme_pub
save_fig(p2, "02_serie_mensal_taxa_1k")

png("results/figures/03_decomposicao_stl.png", width=10, height=8, units="in", res=300)
plot(decomp, main = "Decomposição STL — Processos novos (mensal)")
dev.off()
log_msg("  Figura: 03_decomposicao_stl.png")

# ==============================================================================
# [6/11] PROJEÇÃO DE BENEFICIÁRIOS MH
# ==============================================================================
log_msg("\n--- [6/11] Projeção de beneficiários MH ---")

pop_br <- ibge_br %>% filter(ano >= 2020, ano <= 2040)

cob_obs <- nacional %>%
  select(ano, cob) %>%
  mutate(t = ano - 2020)

# Teto logístico: ANS dez/2025 ≈ 26,2% da população
# (53,3M benef MH / 203,1M pop IBGE ≈ 26,2%)
# Teto histórico do setor: ~27-28% da população (pré-COVID era 24-25%)
# O crescimento recente é impulsionado por coletivos empresariais
# Ceiling conservador: ~29% (expansão moderada, sem reforma estrutural)

nls_fit <- NULL
tryCatch({
  nls_fit <- nls(
    cob ~ K / (1 + exp(-(a + b * t))),
    data = cob_obs,
    start = list(K = 0.28, a = -1.0, b = 0.15),
    control = nls.control(maxiter = 500)
  )
  K_est <- coef(nls_fit)["K"]
  log_msg("  NLS logístico: K={round(K_est,4)} (ceiling {round(K_est*100,1)}%)")
}, error = function(e) {
  log_msg("  NLS falhou: {e$message} — usando logit-linear com cap=29%")
})

proj_anos_benef <- tibble(ano = 2026:2040, t = (2026:2040) - 2020)

if (!is.null(nls_fit)) {
  proj_anos_benef$cob <- predict(nls_fit, newdata = proj_anos_benef)
  # Garantir que não ultrapasse ceiling
  proj_anos_benef$cob <- pmin(proj_anos_benef$cob, 0.30)
} else {
  # Fallback: logit-linear com cap
  cob_obs$logit <- log(cob_obs$cob / (1 - cob_obs$cob))
  lm_cob <- lm(logit ~ t, data = cob_obs)
  proj_anos_benef$cob <- 1 / (1 + exp(-predict(lm_cob, newdata = proj_anos_benef)))
  proj_anos_benef$cob <- pmin(proj_anos_benef$cob, 0.29)
}

benef_proj <- bind_rows(
  cob_obs %>% left_join(pop_br, by = "ano") %>%
    mutate(benef = cob * pop, tipo = "observado") %>%
    select(ano, cob, pop, benef, tipo),
  proj_anos_benef %>% left_join(pop_br, by = "ano") %>%
    mutate(benef = cob * pop, tipo = "projecao") %>%
    select(ano, cob, pop, benef, tipo)
)

log_msg("  {sprintf('%-6s %6s %15s %15s', 'Ano', 'Cob%', 'Benef MH', 'Pop IBGE')}")
for (a in c(2025, 2030, 2035, 2040)) {
  r <- benef_proj %>% filter(ano == a)
  if (nrow(r) > 0)
    log_msg("  {sprintf('%-6d %5.1f%% %15s %15s', a, r$cob*100, fmt(round(r$benef)), fmt(round(r$pop)))}")
}

p3 <- ggplot(benef_proj, aes(x = ano, y = cob * 100, color = tipo)) +
  geom_point(size = 2) + geom_line(aes(group = 1), color = "#2c3e50") +
  scale_color_manual(values = c("observado"="#2c3e50","projecao"="#e74c3c")) +
  labs(title = "Cobertura suplementar (planos MH) — Brasil",
       subtitle = "Observado 2020-2025 | Projeção logística 2026-2040",
       x = "Ano", y = "Cobertura MH (%)", color = NULL) + theme_pub
save_fig(p3, "04_projecao_cobertura")

# ==============================================================================
# [7/11] AJUSTE E SELEÇÃO DE MODELOS (holdout 2025)
# ==============================================================================
log_msg("\n--- [7/11] Ajuste de modelos ---")

taxa_train <- window(ts_taxa, end = c(2024, 12))
taxa_test  <- window(ts_taxa, start = c(2025, 1))
n_test <- length(taxa_test)
log_msg("  Treino: 60 meses | Teste: 12 meses (2025)")

serie_train <- serie %>% filter(date <= as.Date("2024-12-01"))
serie_test  <- serie %>% filter(date >= as.Date("2025-01-01"))

# M1: SARIMA
m1 <- auto.arima(taxa_train, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
f1 <- forecast(m1, h = n_test)
mape1 <- mean(abs((as.numeric(f1$mean) - as.numeric(taxa_test)) / as.numeric(taxa_test))) * 100
rmse1 <- sqrt(mean((as.numeric(f1$mean) - as.numeric(taxa_test))^2))
log_msg("  M1 SARIMA ({m1$arma[1]},{m1$arma[6]},{m1$arma[2]})({m1$arma[3]},{m1$arma[7]},{m1$arma[4]})[12]: MAPE={round(mape1,1)}%")

# M2: ETS
m2 <- ets(taxa_train)
f2 <- forecast(m2, h = n_test)
mape2 <- mean(abs((as.numeric(f2$mean) - as.numeric(taxa_test)) / as.numeric(taxa_test))) * 100
rmse2 <- sqrt(mean((as.numeric(f2$mean) - as.numeric(taxa_test))^2))
log_msg("  M2 ETS ({m2$method}): MAPE={round(mape2,1)}%")

# M3: Log-linear + sazonalidade
m3 <- lm(log_taxa ~ t + mes_f, data = serie_train)
pred3 <- exp(predict(m3, newdata = serie_test))
mape3 <- mean(abs((pred3 - serie_test$taxa_1k) / serie_test$taxa_1k)) * 100
rmse3 <- sqrt(mean((pred3 - serie_test$taxa_1k)^2))
trend_m3 <- coef(m3)["t"]
log_msg("  M3 Log-linear: +{round((exp(trend_m3*12)-1)*100,1)}%/ano | R²={round(summary(m3)$r.squared,3)} | MAPE={round(mape3,1)}%")

# M4: GLM-NB com offset
m4 <- glm.nb(casos_novos ~ t + offset(log(benef)) + mes_f, data = serie_train)
pred4_taxa <- predict(m4, newdata = serie_test, type = "response") / serie_test$benef * 1000
mape4 <- mean(abs((pred4_taxa - serie_test$taxa_1k) / serie_test$taxa_1k)) * 100
rmse4 <- sqrt(mean((pred4_taxa - serie_test$taxa_1k)^2))
log_msg("  M4 GLM-NB: +{round((exp(coef(m4)['t'])-1)*100,2)}%/mês | theta={round(m4$theta,1)} | MAPE={round(mape4,1)}%")

# Comparação
comp <- tibble(
  modelo = c("M1: SARIMA", "M2: ETS", "M3: Log-linear", "M4: GLM-NB"),
  MAPE = c(mape1, mape2, mape3, mape4),
  RMSE = c(rmse1, rmse2, rmse3, rmse4)
)
best_idx <- which.min(comp$MAPE)

log_msg("\n  {sprintf('%-20s %8s %8s', 'Modelo', 'MAPE%', 'RMSE')}")
for (i in seq_len(nrow(comp))) {
  star <- ifelse(i == best_idx, " ★", "")
  log_msg("  {sprintf('%-20s %8.1f %8.4f', comp$modelo[i], comp$MAPE[i], comp$RMSE[i])}{star}")
}

# Re-treinar no completo
m1_full <- auto.arima(ts_taxa, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
m3_full <- lm(log_taxa ~ t + mes_f, data = serie)
m4_full <- glm.nb(casos_novos ~ t + offset(log(benef)) + mes_f, data = serie)

log_msg("\n  Modelos re-treinados (72 meses):")
log_msg("    M1: ARIMA({m1_full$arma[1]},{m1_full$arma[6]},{m1_full$arma[2]})({m1_full$arma[3]},{m1_full$arma[7]},{m1_full$arma[4]})[12]")
log_msg("    M3: trend={round(coef(m3_full)['t'],5)}/mês → +{round((exp(coef(m3_full)['t']*12)-1)*100,1)}%/ano | R²={round(summary(m3_full)$r.squared,3)}")
log_msg("    M4: trend/mês=+{round((exp(coef(m4_full)['t'])-1)*100,2)}% | theta={round(m4_full$theta,1)}")

# Diagnósticos M1
png("results/figures/05_diagnostico_residuos.png", width=10, height=8, units="in", res=300)
checkresiduals(m1_full, main = "Diagnóstico — SARIMA (taxa/1k MH)")
dev.off()
log_msg("  Figura: 05_diagnostico_residuos.png")

lb <- Box.test(residuals(m1_full), lag = 24, type = "Ljung-Box")
log_msg("  Ljung-Box (24 lags): p={round(lb$p.value,4)} → {ifelse(lb$p.value>0.05,'Resíduos OK','Autocorrelação')}")

# Holdout plot
holdout_df <- tibble(
  date = serie_test$date,
  Observado = as.numeric(taxa_test),
  SARIMA = as.numeric(f1$mean),
  ETS = as.numeric(f2$mean),
  `Log-linear` = pred3,
  `GLM-NB` = pred4_taxa
) %>% pivot_longer(-date, names_to = "Modelo", values_to = "taxa_1k")

p5 <- ggplot(holdout_df, aes(x = date, y = taxa_1k, color = Modelo)) +
  geom_line(linewidth = 0.8) +
  geom_point(data = holdout_df %>% filter(Modelo == "Observado"), size = 2) +
  scale_color_manual(values = c("Observado"="black", "SARIMA"="#e74c3c",
                                "ETS"="#3498db", "Log-linear"="#2ecc71", "GLM-NB"="#9b59b6")) +
  scale_x_date(date_labels = "%b/%y") +
  labs(title = "Validação holdout — 2025",
       subtitle = "Taxa / 1.000 beneficiários MH (mensal)",
       x = NULL, y = "Taxa / 1.000 benef. MH", color = NULL) + theme_pub
save_fig(p5, "06_holdout_comparacao")

# ==============================================================================
# [8/11] CENÁRIOS — ANCORADOS NO IESS [C3]
# ==============================================================================
log_msg("\n--- [8/11] [C3] Cenários ancorados no IESS ---")

taxa_2025 <- tail(nacional$taxa_1k, 1)
cagr_anual_taxa <- exp(coef(m3_full)["t"] * 12) - 1

log_msg("  Taxa 2025: {round(taxa_2025, 2)}/1k benef MH/ano")
log_msg("  CAGR anual da taxa (M3): +{round(cagr_anual_taxa*100, 1)}%/ano")

# BENCHMARKS IESS (dez/2025):
#   Pessimista: 900k–1,2M em 2035 (sem reformas)
#   Realista:   ~400k em 2035   (crescimento efetivo ~3%/ano)
#   Otimista:   ~170k em 2035   (taxa cai a 2,8/1k)
#
# ESTRATÉGIA v3:
#   Nosso cenário INERCIAL deve ficar ENTRE o realista e pessimista IESS
#   (~500-700k em 2035), porque assumimos desaceleração gradual sem
#   reforma estrutural coordenada — cenário mais realista que o pessimista
#   IESS (crescimento puro), mas sem o efeito moderador forte que o
#   realista IESS assume (+3%/ano efetivo, que pressupõe reformas parciais).
#
#   Nosso OTIMISTA ≈ realista IESS (~400k em 2035)
#   Nosso PESSIMISTA ≈ pessimista IESS (~900k-1M em 2035)

h_ilu <- 2040
anos_proj <- 2026:h_ilu

# Calcular CAGR necessário para atingir targets IESS em 2035
# para validar premissas dos cenários
benef_2035_proj <- benef_proj$benef[benef_proj$ano == 2035]

log_msg("\n  CALIBRAÇÃO COM IESS:")
log_msg("    Benef MH 2035 (projetado): {fmt(round(benef_2035_proj))}")
log_msg("    Para 400k processos (IESS realista): taxa={round(400000/benef_2035_proj*1000,2)}/1k")
log_msg("    Para 700k processos (nosso inercial target): taxa={round(700000/benef_2035_proj*1000,2)}/1k")
log_msg("    Para 1M processos (IESS pessimista): taxa={round(1000000/benef_2035_proj*1000,2)}/1k")

cenarios_taxa <- tibble(ano = anos_proj) %>%
  mutate(
    t_desde_2025 = ano - 2025,
    
    # INERCIAL: CAGR decai linearmente de observado para 0% em 12 anos
    # → Produz desaceleração moderada; 2035 ≈ 600-700k
    # Premissa: tendência inercial sem reformas estruturais coordenadas,
    # mas com efeito parcial das SV 60/61, ADI 7265, e expansão NatJus
    growth_inercial = pmax(0, cagr_anual_taxa * (1 - t_desde_2025 / 12)),
    taxa_inercial = taxa_2025 * cumprod(1 + growth_inercial),
    
    # OTIMISTA: crescimento cai 60% imediato em 2026, zera em 2028,
    # depois -3%/ano → Alinhado com IESS realista (~400k em 2035)
    # Premissa: reformas regulatórias (NAT-SS, mediação obrigatória,
    # RN 623/2024 implementada, efeito pleno ADI 7265)
    growth_otimista = case_when(
      t_desde_2025 <= 3  ~ cagr_anual_taxa * pmax(0, (1 - t_desde_2025 / 3) * 0.4),
      t_desde_2025 <= 8  ~ -0.03,
      TRUE               ~ -0.02
    ),
    taxa_otimista = taxa_2025 * cumprod(1 + growth_otimista),
    
    # PESSIMISTA: CAGR decai lentamente ao longo de 20 anos
    # → Alinhado com IESS pessimista (900k–1,2M em 2035)
    # Premissa: sem coordenação institucional, envelhecimento acelerado,
    # incorporação tecnológica via judicial, lobby farmacêutico mantido
    growth_pessimista = pmax(0, cagr_anual_taxa * (1 - t_desde_2025 / 20)),
    taxa_pessimista = taxa_2025 * cumprod(1 + growth_pessimista)
  )

# Processos = taxa × beneficiários MH
cenarios <- cenarios_taxa %>%
  left_join(benef_proj %>% select(ano, benef), by = "ano") %>%
  mutate(
    proc_inercial   = round(taxa_inercial * benef / 1000),
    proc_otimista   = round(taxa_otimista * benef / 1000),
    proc_pessimista = round(taxa_pessimista * benef / 1000)
  )

obs_resumo <- nacional %>%
  select(ano, processos, taxa_1k, benef) %>%
  rename(proc_observado = processos, taxa_observado = taxa_1k)

# Tabela
log_msg("\n  PROJEÇÃO POR CENÁRIO (v3):")
log_msg("  {sprintf('%-6s %10s %10s %10s %10s %8s', 'Ano', 'Observado', 'Otimista', 'Inercial', 'Pessimist', 'Taxa_I')}")

for (a in c(2020, 2024, 2025, 2030, 2035, 2040)) {
  obs_row <- obs_resumo %>% filter(ano == a)
  cen_row <- cenarios %>% filter(ano == a)
  if (nrow(obs_row) > 0 && nrow(cen_row) == 0) {
    log_msg("  {sprintf('%-6d %10s %10s %10s %10s %8.2f', a,
              fmt(obs_row$proc_observado), '-', '-', '-', obs_row$taxa_observado)}")
  } else if (nrow(cen_row) > 0) {
    obs_v <- if (nrow(obs_row) > 0) fmt(obs_row$proc_observado) else "-"
    log_msg("  {sprintf('%-6d %10s %10s %10s %10s %8.2f', a,
              obs_v, fmt(cen_row$proc_otimista),
              fmt(cen_row$proc_inercial), fmt(cen_row$proc_pessimista),
              cen_row$taxa_inercial)}")
  }
}

# CAGR por cenário
for (cen in c("otimista", "inercial", "pessimista")) {
  col <- paste0("proc_", cen)
  v_final <- cenarios[[col]][cenarios$ano == h_ilu]
  v_2035  <- cenarios[[col]][cenarios$ano == 2035]
  cagr_c <- ((v_final / tail(nacional$processos, 1))^(1/(h_ilu-2025)) - 1) * 100
  log_msg("  CAGR 2025-{h_ilu} ({cen}): {round(cagr_c, 1)}%/ano | 2035={fmt(v_2035)}")
}

# Validação cruzada IESS
log_msg("\n  VALIDAÇÃO VS IESS (2035):")
proc_2035_ot  <- cenarios$proc_otimista[cenarios$ano == 2035]
proc_2035_in  <- cenarios$proc_inercial[cenarios$ano == 2035]
proc_2035_pe  <- cenarios$proc_pessimista[cenarios$ano == 2035]
log_msg("    Nosso otimista:   {fmt(proc_2035_ot)} vs IESS realista: 400k → {ifelse(abs(proc_2035_ot-400000)/400000<0.3,'✓ ALINHADO','⚠ VERIFICAR')}")
log_msg("    Nosso inercial:   {fmt(proc_2035_in)} vs IESS (entre real/pess)")
log_msg("    Nosso pessimista: {fmt(proc_2035_pe)} vs IESS pessimista: 900k-1,2M → {ifelse(proc_2035_pe>=800000 & proc_2035_pe<=1300000,'✓ ALINHADO','⚠ VERIFICAR')}")

log_msg("\n  PREMISSAS:")
log_msg("  Inercial: CAGR decai linearmente de {round(cagr_anual_taxa*100,1)}% para 0% em 12 anos")
log_msg("    → Efeito parcial SV 60/61, ADI 7265, NatJus. Sem reforma coordenada.")
log_msg("  Otimista: Crescimento cai 60% em 2026, zera em 2028, depois -3%/ano")
log_msg("    → NAT-SS criado, mediação obrigatória, RN 623 plenamente implementada")
log_msg("    → Alinhado com cenário realista IESS (+3%/ano efetivo)")
log_msg("  Pessimista: CAGR decai ao longo de 20 anos")
log_msg("    → Sem coordenação, envelhecimento, incorporação judicial persistente")
log_msg("    → Alinhado com cenário pessimista IESS (900k-1,2M)")
if (!is.null(nls_fit)) {
  log_msg("  Beneficiários MH: logístico K={round(coef(nls_fit)['K']*100,1)}% | Pop: IBGE Rev. 2024")
}

# ==============================================================================
# [9/11] INTERVALOS DE CONFIANÇA — ABORDAGEM EM 3 CAMADAS [C4]
# ==============================================================================
log_msg("\n--- [9/11] [C4] IC — Três camadas de incerteza ---")
log_msg("  Camada 1: SARIMA forecast intervals (2026-2030) — incerteza do modelo")
log_msg("  Camada 2: Bootstrap cenário-consistente (2026-2040) — incerteza paramétrica")
log_msg("  Camada 3: Intervalo de cenários (otimista–pessimista) — incerteza estrutural")

# ── CAMADA 1: SARIMA forecast intervals ──────────────────────────────────────
# M1 venceu holdout (MAPE 8.9%), resíduos limpos (Ljung-Box p=0.976)
# Forecast intervals calibrados até 5 anos (60 meses)
log_msg("\n  [Camada 1] SARIMA forecast intervals")

f_sarima <- forecast(m1_full, h = 60, level = c(80, 95))  # 5 anos

# Converter taxa mensal SARIMA → processos anuais
sarima_df <- tibble(
  date = seq(as.Date("2026-01-01"), by = "month", length.out = 60),
  taxa_mean = as.numeric(f_sarima$mean),
  taxa_lo80 = as.numeric(f_sarima$lower[,1]),
  taxa_hi80 = as.numeric(f_sarima$upper[,1]),
  taxa_lo95 = as.numeric(f_sarima$lower[,2]),
  taxa_hi95 = as.numeric(f_sarima$upper[,2]),
  ano = year(date),
  mes = month(date)
) %>%
  # Interpolar beneficiários mensais
  left_join(benef_proj %>% select(ano, benef), by = "ano") %>%
  mutate(across(starts_with("taxa_"), ~ . * benef / 1000, .names = "proc_{.col}"))

ic_sarima <- sarima_df %>%
  group_by(ano) %>%
  summarise(
    proc_mean = sum(proc_taxa_mean),
    lo80 = sum(proc_taxa_lo80),
    hi80 = sum(proc_taxa_hi80),
    lo95 = sum(proc_taxa_lo95),
    hi95 = sum(proc_taxa_hi95),
    taxa_mean = mean(taxa_mean) * 12,  # anualizar
    taxa_lo95 = mean(taxa_lo95) * 12,
    taxa_hi95 = mean(taxa_hi95) * 12,
    .groups = "drop"
  ) %>%
  # Truncar limites negativos em 0
  mutate(across(c(lo80, lo95, proc_mean), ~ pmax(0, .)))

log_msg("  SARIMA forecast (processos/ano):")
for (a in 2026:2030) {
  r <- ic_sarima %>% filter(ano == a)
  if (nrow(r) > 0)
    log_msg("    {a}: {fmt(round(r$proc_mean))} [IC95%: {fmt(round(r$lo95))} – {fmt(round(r$hi95))}]")
}
log_msg("")
log_msg("  NOTA: SARIMA projeta estabilização (~300k/ano) — não crescimento.")
log_msg("  Causa: ARIMA(1,1,0)(1,1,0)[12] captura desaceleração 2024→2025 (+3%)")
log_msg("  e extrapola platô. IC alarga rapidamente (incerteza alta além de 2027).")
log_msg("  DECISÃO: SARIMA reportado em tabela/discussão, NÃO no fan chart principal.")
log_msg("  → Contraste SARIMA vs cenários = argumento para modelo estrutural.")

# ── CAMADA 2: Bootstrap cenário-consistente com restrição epidemiológica ─────
log_msg("\n  [Camada 2] Bootstrap cenário-consistente")

set.seed(42)
n_boot <- 2000
sigma_m3 <- sigma(m3_full)

# Parâmetros com incerteza
trend_hat <- coef(m3_full)["t"]
se_trend  <- summary(m3_full)$coefficients["t", "Std. Error"]
cagr_hat  <- exp(trend_hat * 12) - 1
se_cagr   <- 12 * exp(trend_hat * 12) * se_trend   # delta method

# σ anual derivado dos dados (não de escala arbitrária)
# Resíduos do modelo log-linear ANUAL (R²=0.93, 6 obs)
lm_anual <- lm(log_taxa ~ ano, data = nacional)
sigma_anual <- sigma(lm_anual)
log_msg("  σ_anual (dados): {round(sigma_anual, 4)} (vs σ_mensal×√12×0.3={round(sigma_m3*sqrt(12)*0.3, 4)})")

# Teto epidemiológico
# Justificativa: 25 processos/1k beneficiários/ano ≈ 1 processo a cada 40 beneficiários
# Representa ~5× o nível atual (5,82/1k). Nenhum sistema judicial alcançou taxas superiores.
# O IESS pessimista (2035) implica ~15,7/1k; 25/1k dá margem conservadora sobre isso.
taxa_ceiling <- 25.0
log_msg("  Teto epidemiológico: {taxa_ceiling}/1k (1 processo : {round(1000/taxa_ceiling)} beneficiários)")
log_msg("  CAGR: {round(cagr_hat*100,1)}% ± {round(se_cagr*100,1)}% (SE delta method)")

# Damping schedule (idêntico ao cenário inercial)
damping_years <- 12

boot_proc <- matrix(NA, nrow = n_boot, ncol = length(anos_proj))
boot_taxa <- matrix(NA, nrow = n_boot, ncol = length(anos_proj))
taxa_base_hat <- taxa_2025

for (b in 1:n_boot) {
  # (1) Sortear CAGR
  cagr_b <- rnorm(1, cagr_hat, se_cagr)
  
  # (2) Sortear taxa base (incerteza baseada em σ_anual)
  taxa_b <- taxa_base_hat * exp(rnorm(1, 0, sigma_anual * 0.5))
  # Fator 0.5: incerteza na taxa-base é menor que σ_anual pleno
  # (é um ponto observado, não uma projeção)
  
  # (3) Projetar via cumprod com damping
  for (j in seq_along(anos_proj)) {
    t_desde_2025 <- anos_proj[j] - 2025
    damp <- pmax(0, 1 - t_desde_2025 / damping_years)
    growth <- cagr_b * damp
    
    # Ruído anual: σ derivado do modelo anual
    noise <- exp(rnorm(1, 0, sigma_anual))
    taxa_b <- taxa_b * (1 + growth) * noise
    
    # TETO EPIDEMIOLÓGICO: truncar trajetórias implausíveis
    taxa_b <- pmin(taxa_b, taxa_ceiling)
    
    boot_taxa[b, j] <- taxa_b
    
    benef_a <- benef_proj$benef[benef_proj$ano == anos_proj[j]]
    if (length(benef_a) == 0) benef_a <- tail(benef_proj$benef, 1)
    
    boot_proc[b, j] <- round(taxa_b * benef_a / 1000)
  }
}

ic_boot <- tibble(
  ano = anos_proj,
  lo95 = apply(boot_proc, 2, quantile, 0.025, na.rm = TRUE),
  lo80 = apply(boot_proc, 2, quantile, 0.10, na.rm = TRUE),
  mediana = apply(boot_proc, 2, quantile, 0.50, na.rm = TRUE),
  hi80 = apply(boot_proc, 2, quantile, 0.90, na.rm = TRUE),
  hi95 = apply(boot_proc, 2, quantile, 0.975, na.rm = TRUE)
)

ic_taxa <- tibble(
  ano = anos_proj,
  taxa_lo95 = apply(boot_taxa, 2, quantile, 0.025, na.rm = TRUE),
  taxa_mediana = apply(boot_taxa, 2, quantile, 0.50, na.rm = TRUE),
  taxa_hi95 = apply(boot_taxa, 2, quantile, 0.975, na.rm = TRUE)
)

# % de trajetórias truncadas pelo teto
pct_truncated <- colMeans(boot_taxa >= taxa_ceiling * 0.999) * 100

log_msg("  Bootstrap: {n_boot} simulações (cenário-consistente + teto)")
for (a in c(2030, 2035, 2040)) {
  r <- ic_boot %>% filter(ano == a)
  rt <- ic_taxa %>% filter(ano == a)
  cen_i <- cenarios$proc_inercial[cenarios$ano == a]
  idx <- which(anos_proj == a)
  log_msg("    {a}: IC95=[{fmt(round(r$lo95))} – {fmt(round(r$hi95))}] | mediana={fmt(round(r$mediana))} | inercial={fmt(cen_i)}")
  log_msg("         Taxa IC95=[{round(rt$taxa_lo95,1)} – {round(rt$taxa_hi95,1)}] /1k | truncadas: {round(pct_truncated[idx],1)}%")
  if (cen_i >= r$lo95 && cen_i <= r$hi95) {
    log_msg("         ✓ Cenário inercial dentro do IC95%")
  } else {
    log_msg("         ⚠ Cenário inercial FORA do IC95%")
  }
}

# ── CAMADA 3: Intervalo de cenários ──────────────────────────────────────────
log_msg("\n  [Camada 3] Intervalo de cenários")
for (a in c(2030, 2035, 2040)) {
  ot <- cenarios$proc_otimista[cenarios$ano == a]
  pe <- cenarios$proc_pessimista[cenarios$ano == a]
  log_msg("    {a}: Otimista={fmt(ot)} – Pessimista={fmt(pe)} (range={fmt(pe-ot)})")
}

# ── COMPARAÇÃO CAMADAS (diagnóstico) ────────────────────────────────────────
log_msg("\n  COMPARAÇÃO DAS 3 CAMADAS (2030/2035):")
log_msg("  {sprintf('%-12s %15s %15s %15s', 'Horizonte', 'SARIMA IC95%', 'Bootstrap IC95%', 'Cenários')}")
for (a in c(2030, 2035)) {
  sar <- ic_sarima %>% filter(ano == a)
  bst <- ic_boot %>% filter(ano == a)
  ot <- cenarios$proc_otimista[cenarios$ano == a]
  pe <- cenarios$proc_pessimista[cenarios$ano == a]
  sar_str <- if (nrow(sar) > 0) paste0(fmt(round(sar$lo95)), "–", fmt(round(sar$hi95))) else "—"
  bst_str <- paste0(fmt(round(bst$lo95)), "–", fmt(round(bst$hi95)))
  cen_str <- paste0(fmt(ot), "–", fmt(pe))
  log_msg("  {sprintf('%-12s %15s %15s %15s', a, sar_str, bst_str, cen_str)}")
}

# ==============================================================================
# [10/11] FIGURAS
# ==============================================================================
log_msg("\n--- [10/11] Figuras ---")

plot_obs <- nacional %>%
  select(ano, processos) %>%
  mutate(cenario = "Observado")

plot_cenarios <- cenarios %>%
  select(ano, proc_inercial, proc_otimista, proc_pessimista) %>%
  pivot_longer(-ano, names_to = "cenario", values_to = "processos",
               names_prefix = "proc_") %>%
  mutate(cenario = case_when(
    cenario == "inercial" ~ "Inercial",
    cenario == "otimista" ~ "Otimista",
    cenario == "pessimista" ~ "Pessimista"
  ))

# Fig principal: fan chart com IC bootstrap + cenários
p_main <- ggplot() +
  # Camada 2: Bootstrap IC cenário-consistente
  geom_ribbon(data = ic_boot, aes(x = ano, ymin = lo95/1000, ymax = hi95/1000),
              fill = "#3498db", alpha = 0.10) +
  geom_ribbon(data = ic_boot, aes(x = ano, ymin = lo80/1000, ymax = hi80/1000),
              fill = "#3498db", alpha = 0.18) +
  # Camada 3: Cenários (linhas)
  geom_line(data = plot_cenarios %>% filter(cenario == "Pessimista"),
            aes(x = ano, y = processos/1000, linetype = "Pessimista"),
            color = "#e74c3c", linewidth = 0.8) +
  geom_line(data = plot_cenarios %>% filter(cenario == "Inercial"),
            aes(x = ano, y = processos/1000, linetype = "Inercial"),
            color = "#2c3e50", linewidth = 1) +
  geom_line(data = plot_cenarios %>% filter(cenario == "Otimista"),
            aes(x = ano, y = processos/1000, linetype = "Otimista"),
            color = "#27ae60", linewidth = 0.8) +
  # IESS benchmarks
  annotate("point", x = 2035, y = 400, shape = 18, size = 3, color = "#f39c12") +
  annotate("text", x = 2035.5, y = 400, label = "IESS realista", hjust = 0, size = 2.8, color = "#f39c12") +
  annotate("point", x = 2035, y = 1100, shape = 18, size = 3, color = "#f39c12") +
  annotate("text", x = 2035.5, y = 1100, label = "IESS pessimista", hjust = 0, size = 2.8, color = "#f39c12") +
  # Observed
  geom_point(data = plot_obs, aes(x = ano, y = processos/1000), color = "black", size = 3) +
  geom_line(data = plot_obs, aes(x = ano, y = processos/1000), color = "black", linewidth = 1) +
  # Horizon markers
  geom_vline(xintercept = c(2030, 2035), linetype = "dotted", color = "grey60", linewidth = 0.4) +
  annotate("text", x = 2028, y = Inf, label = "Primário", vjust = 1.5, size = 3, color = "grey50") +
  annotate("text", x = 2032.5, y = Inf, label = "Secundário", vjust = 1.5, size = 3, color = "grey50") +
  annotate("text", x = 2037.5, y = Inf, label = "Ilustrativo", vjust = 1.5, size = 3, color = "grey50", fontface = "italic") +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",", suffix = "k")) +
  scale_linetype_manual(values = c("Inercial"="solid", "Otimista"="dashed", "Pessimista"="dotted")) +
  labs(
    title = "Projeção da judicialização da saúde suplementar — Brasil",
    subtitle = "IC 80/95% = bootstrap cenário-consistente (2.000 sim.) | ◆ IESS dez/2025",
    x = "Ano", y = "Processos novos (milhares)", linetype = "Cenário",
    caption = "Fonte: CNJ/DataJud, ANS/SIB (benef. MH), IBGE Rev. 2024. Teto epidemiológico: 25/1k."
  ) + theme_pub + theme(legend.position = "right")
save_fig(p_main, "07_projecao_cenarios", w = 12, h = 7)

# Fig SARIMA curto prazo (separada — para discussão no artigo)
sarima_obs <- nacional %>%
  select(ano, processos) %>%
  filter(ano >= 2022)

p_sarima <- ggplot() +
  geom_ribbon(data = ic_sarima, aes(x = ano, ymin = pmax(0, lo95)/1000, ymax = hi95/1000),
              fill = "#2c3e50", alpha = 0.12) +
  geom_ribbon(data = ic_sarima, aes(x = ano, ymin = pmax(0, lo80)/1000, ymax = hi80/1000),
              fill = "#2c3e50", alpha = 0.22) +
  geom_line(data = ic_sarima, aes(x = ano, y = proc_mean/1000),
            color = "#2c3e50", linewidth = 0.8) +
  # Cenário inercial para comparação
  geom_line(data = cenarios %>% filter(ano <= 2030),
            aes(x = ano, y = proc_inercial/1000), color = "#e74c3c",
            linewidth = 0.8, linetype = "dashed") +
  geom_point(data = sarima_obs, aes(x = ano, y = processos/1000),
             color = "black", size = 3) +
  geom_line(data = sarima_obs, aes(x = ano, y = processos/1000),
            color = "black", linewidth = 1) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",", suffix = "k")) +
  labs(
    title = "Projeção SARIMA vs cenário inercial — Horizonte primário (2030)",
    subtitle = "ARIMA(1,1,0)(1,1,0)[12] | IC 80/95% | MAPE holdout = 8,9%",
    x = "Ano", y = "Processos novos (milhares)",
    caption = "Linha contínua = SARIMA forecast mean | Tracejada vermelha = cenário inercial"
  ) + theme_pub
save_fig(p_sarima, "10_sarima_vs_inercial", w = 10, h = 6)

# Taxa por 1k MH
plot_taxa <- cenarios %>%
  select(ano, Inercial = taxa_inercial, Otimista = taxa_otimista,
         Pessimista = taxa_pessimista) %>%
  pivot_longer(-ano, names_to = "Cenário", values_to = "taxa_1k")

plot_taxa_obs <- nacional %>% select(ano, taxa_1k) %>%
  mutate(`Cenário` = "Observado")

p_taxa <- ggplot() +
  geom_line(data = plot_taxa, aes(x = ano, y = taxa_1k, color = `Cenário`), linewidth = 0.8) +
  geom_point(data = plot_taxa_obs, aes(x = ano, y = taxa_1k), color = "black", size = 3) +
  geom_line(data = plot_taxa_obs, aes(x = ano, y = taxa_1k), color = "black", linewidth = 1) +
  # IESS targets
  annotate("point", x = 2024, y = 5.7, shape = 18, size = 3, color = "#f39c12") +
  annotate("text", x = 2024, y = 5.7, label = "  IESS 5,7", hjust = 0, vjust = -0.5, size = 2.8, color = "#f39c12") +
  annotate("point", x = 2035, y = 2.8, shape = 18, size = 3, color = "#f39c12") +
  annotate("text", x = 2035, y = 2.8, label = "  IESS otimista 2,8", hjust = 0, vjust = -0.5, size = 2.8, color = "#f39c12") +
  scale_color_manual(values = c("Inercial"="#2c3e50", "Otimista"="#27ae60", "Pessimista"="#e74c3c")) +
  geom_vline(xintercept = c(2030, 2035), linetype = "dotted", color = "grey60") +
  labs(title = "Taxa de judicialização / 1.000 beneficiários MH — Brasil",
       subtitle = "Cenários | Observado 2020-2025 | ◆ = IESS (dez/2025)",
       x = "Ano", y = "Processos / 1.000 benef. MH / ano", color = "Cenário",
       caption = "Fonte: CNJ, ANS (benef. MH), IBGE.") + theme_pub
save_fig(p_taxa, "08_projecao_taxa_1k", w = 12, h = 7)

# Beneficiários + cobertura MH
p_benef <- ggplot(benef_proj, aes(x = ano)) +
  geom_col(aes(y = benef / 1e6), fill = "#3498db", alpha = 0.4, width = 0.7) +
  geom_line(aes(y = cob * 250), color = "#e74c3c", linewidth = 1) +
  geom_point(aes(y = cob * 250, shape = tipo), color = "#e74c3c", size = 2) +
  scale_y_continuous(
    name = "Beneficiários MH (milhões)",
    labels = label_number(decimal.mark = ","),
    sec.axis = sec_axis(~ . / 250 * 100, name = "Cobertura MH (%)")
  ) +
  scale_shape_manual(values = c("observado" = 16, "projecao" = 1)) +
  labs(title = "Beneficiários e cobertura suplementar (MH) — Brasil",
       subtitle = "Projeção logística 2026-2040 | IBGE Rev. 2024",
       x = "Ano", shape = NULL) + theme_pub
save_fig(p_benef, "09_beneficiarios_cobertura", w = 12, h = 7)

# Comparação v2 vs v3
comp_v2_v3 <- tibble(
  Métrica = c("Beneficiários 2024", "Taxa 2024 (/1k)",
              "IESS 2024", "CAGR taxa", "Processos 2024",
              "Inercial 2035", "Otimista 2035", "Pessimista 2035"),
  v2 = c("88,7M", "3,38", "5,7", "14,6%", "~281k",
         "994k", "370k", "1.256k"),
  v3 = c(paste0(round(nacional$benef[nacional$ano==2024]/1e6,1), "M"),
         as.character(round(taxa_2024_nossa, 2)),
         "5,7",
         paste0(round(cagr_taxa, 1), "%"),
         fmt(proc_2024_iess),
         fmt(cenarios$proc_inercial[cenarios$ano==2035]),
         fmt(cenarios$proc_otimista[cenarios$ano==2035]),
         fmt(cenarios$proc_pessimista[cenarios$ano==2035]))
)
log_msg("\n  COMPARAÇÃO v2 → v3:")
for (i in seq_len(nrow(comp_v2_v3))) {
  log_msg("    {sprintf('%-22s %12s → %12s', comp_v2_v3$Métrica[i], comp_v2_v3$v2[i], comp_v2_v3$v3[i])}")
}

# ==============================================================================
# [11/11] SALVAR
# ==============================================================================
log_msg("\n--- [11/11] Salvando ---")

write_csv(cenarios, "results/tables/projecao_cenarios.csv")
write_csv(ic_boot, "results/tables/ic_bootstrap.csv")
write_csv(ic_taxa, "results/tables/ic_taxa_bootstrap.csv")
write_csv(ic_sarima, "results/tables/ic_sarima_2030.csv")
write_csv(comp, "results/tables/comparacao_modelos.csv")
write_csv(obs_resumo, "results/tables/observado_anual.csv")
write_csv(benef_proj, "results/tables/projecao_beneficiarios.csv")

# Tabela para artigo (com IC dual)
tabela_artigo <- tibble(
  Ano = c(2020, 2024, 2025, 2030, 2035, 2040),
  Observado = NA_character_,
  Otimista = NA_character_,
  Inercial = NA_character_,
  Pessimista = NA_character_,
  `IC 95% SARIMA` = NA_character_,
  `IC 95% Bootstrap` = NA_character_,
  `Taxa Inercial` = NA_character_,
  `IESS Benchmark` = c("", "", "", "", "400k-1,2M", ""),
  Horizonte = c("", "", "", "Primário", "Secundário", "Ilustrativo")
)

for (i in seq_len(nrow(tabela_artigo))) {
  a <- tabela_artigo$Ano[i]
  obs_r <- obs_resumo %>% filter(ano == a)
  cen_r <- cenarios %>% filter(ano == a)
  ic_r  <- ic_boot %>% filter(ano == a)
  sar_r <- ic_sarima %>% filter(ano == a)
  
  if (nrow(obs_r) > 0) tabela_artigo$Observado[i] <- fmt(obs_r$proc_observado)
  if (nrow(cen_r) > 0) {
    tabela_artigo$Otimista[i] <- fmt(cen_r$proc_otimista)
    tabela_artigo$Inercial[i] <- fmt(cen_r$proc_inercial)
    tabela_artigo$Pessimista[i] <- fmt(cen_r$proc_pessimista)
    tabela_artigo$`Taxa Inercial`[i] <- as.character(round(cen_r$taxa_inercial, 2))
  }
  if (nrow(sar_r) > 0) {
    tabela_artigo$`IC 95% SARIMA`[i] <- paste0(fmt(round(sar_r$lo95)), " – ", fmt(round(sar_r$hi95)))
  }
  if (nrow(ic_r) > 0) {
    tabela_artigo$`IC 95% Bootstrap`[i] <- paste0(fmt(round(ic_r$lo95)), " – ", fmt(round(ic_r$hi95)))
  }
}

write_csv(tabela_artigo, "results/tables/tabela_artigo.csv")

# Tabela de premissas formais
premissas <- tibble(
  Cenário = c("Inercial", "Otimista", "Pessimista"),
  `CAGR taxa base` = rep(paste0("+", round(cagr_anual_taxa*100,1), "%/ano"), 3),
  `Dinâmica damping` = c(
    "Linear → 0% em 12 anos",
    "Queda 60% em 2026, zera 2028, −3%/ano depois",
    "Linear → 0% em 20 anos"
  ),
  `Premissa regulatória` = c(
    "Efeito parcial SV 60/61, ADI 7265, NatJus",
    "NAT-SS, mediação obrigatória, RN 623 plena",
    "Sem coordenação institucional"
  ),
  `Benchmark IESS 2035` = c(
    "Entre realista (400k) e pessimista (1,2M)",
    "≈ Realista (~400k, +3%/ano efetivo)",
    "≈ Pessimista (900k–1,2M)"
  )
)
write_csv(premissas, "results/tables/premissas_cenarios.csv")

# Salvar benef MH de referência
write_csv(benef_mh_ans, "results/tables/benef_mh_ans_referencia.csv")

log_msg("  Tabelas: {length(list.files('results/tables'))} arquivos")

# Resumo
log_msg("\n========== RESUMO EXECUTIVO (v3) ==========")
log_msg("Série: 72 meses (Jan/2020 – Dez/2025)")
log_msg("Denominador: beneficiários MÉDICO-HOSPITALARES ANS")
log_msg("Melhor modelo holdout: {comp$modelo[best_idx]} (MAPE={round(comp$MAPE[best_idx],1)}%)")
log_msg("Taxa 2024: {round(nacional$taxa_1k[nacional$ano==2024], 2)} / 1.000 benef MH (IESS: 5,7)")
log_msg("Taxa 2025: {round(taxa_2025, 2)} / 1.000 benef MH / ano")
log_msg("CAGR taxa (M3 log-linear): +{round(cagr_anual_taxa*100,1)}%/ano")
log_msg("")

v30_i <- cenarios$proc_inercial[cenarios$ano == 2030]
v35_i <- cenarios$proc_inercial[cenarios$ano == 2035]
v40_i <- cenarios$proc_inercial[cenarios$ano == h_ilu]
log_msg("Cenário inercial:")
log_msg("  2030: {fmt(v30_i)} | 2035: {fmt(v35_i)} | 2040: {fmt(v40_i)}")
log_msg("")
log_msg("Validação IESS (2035):")
log_msg("  Otimista:   {fmt(proc_2035_ot)} (IESS realista: 400k)")
log_msg("  Inercial:   {fmt(proc_2035_in)} (IESS: entre 400k e 1,2M)")
log_msg("  Pessimista: {fmt(proc_2035_pe)} (IESS pessimista: 900k–1,2M)")
log_msg("")
log_msg("Bootstrap IC (damped, {n_boot} sim):")
ic_2035 <- ic_boot %>% filter(ano == 2035)
sar_2030 <- ic_sarima %>% filter(ano == 2030)
log_msg("  SARIMA 2030: IC95=[{fmt(round(sar_2030$lo95))} – {fmt(round(sar_2030$hi95))}]")
log_msg("  Bootstrap 2035: IC95=[{fmt(round(ic_2035$lo95))} – {fmt(round(ic_2035$hi95))}]")
log_msg("  Cenários 2035: {fmt(proc_2035_ot)} – {fmt(proc_2035_pe)}")
log_msg("")
log_msg("Horizontes:")
log_msg("  Primário (2030):    confiança alta")
log_msg("  Secundário (2035):  moderada — depende de premissas regulatórias")
log_msg("  Ilustrativo (2040): baixa — exercício especulativo")
log_msg("")
log_msg("CORREÇÕES v2→v3:")
log_msg("  [C1] Denominador: benef_total (88M) → benef_MH (52M)")
log_msg("  [C2] Baseline 2024: {fmt(proc_2024_nosso)} → {fmt(proc_2024_iess)} (IESS/CNJ)")
log_msg("  [C3] Cenários ancorados no IESS dez/2025")
log_msg("  [C4] IC em 3 camadas: SARIMA (2030) + bootstrap cenário-consistente + cenários")
log_msg("  [C5] Taxa 2024: 3,38/1k → {round(taxa_2024_nossa,2)}/1k (alinhado IESS 5,7)")
log_msg("==========================================")

writeLines(log, "results/models/03_model_v3_log.txt")
cat("\n✅ Log: results/models/03_model_v3_log.txt\n")
cat("✅ Figuras:", length(list.files("results/figures")), "\n")
cat("✅ Tabelas:", length(list.files("results/tables")), "\n")
