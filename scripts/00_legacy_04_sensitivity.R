## ============================================================
## 04_sensitivity_hsr.R
## Análises de sensibilidade para submissão HSR
##
## DEPENDÊNCIA: Rodar 03_model_v3.R ANTES deste script.
##   Objetos necessários: nacional, serie, ts_taxa, benef_proj,
##   cenarios, m1_full, m3_full, cagr_anual_taxa, taxa_2025,
##   taxa_ceiling, sigma_anual, se_cagr, nls_fit, ibge_br,
##   benef_mh_ans, pop_br, ic_boot
##
## OUTPUT: results/sensitivity/
## ============================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(forecast)
  library(tseries)
  library(glue)
})

sens_dir <- "results/sensitivity"
dir.create(sens_dir, showWarnings = FALSE, recursive = TRUE)

log_msg("") 
log_msg("##########################################################")
log_msg("## 04_sensitivity_hsr.R — Análises de Sensibilidade HSR ##")
log_msg("##########################################################")
log_msg("Timestamp: {Sys.time()}")

# ============================================================
# S1: SARIMA COM JANELAS ALTERNATIVAS
# ============================================================
log_msg("\n=== S1: SARIMA — Janelas alternativas de estimação ===")

run_sarima_window <- function(ts_full, start_year, start_month, end_year, end_month,
                              test_months = 12, label = "base") {
  ts_sub <- window(ts_full, start = c(start_year, start_month), end = c(end_year, end_month))
  n <- length(ts_sub)
  
  if (n <= test_months + 12) {
    log_msg("  ⚠ {label}: série muito curta ({n} obs) — pulando")
    return(NULL)
  }
  
  # Split train/test
  train_end_idx <- n - test_months
  train_time <- time(ts_sub)[train_end_idx]
  train_year <- floor(train_time)
  train_month <- round((train_time - train_year) * 12) + 1
  
  ts_train <- window(ts_sub, end = c(train_year, train_month))
  ts_test  <- window(ts_sub, start = c(train_year, train_month) + c(0, 1))
  actual_test <- min(test_months, length(ts_test))
  
  fit <- tryCatch(
    auto.arima(ts_train, seasonal = TRUE, stepwise = FALSE, approximation = FALSE),
    error = function(e) {
      log_msg("  ⚠ {label}: auto.arima falhou — {e$message}")
      return(NULL)
    }
  )
  if (is.null(fit)) return(NULL)
  
  fc <- forecast(fit, h = actual_test)
  
  actual <- as.numeric(ts_test)[1:actual_test]
  pred   <- as.numeric(fc$mean)[1:actual_test]
  mape   <- mean(abs((actual - pred) / actual)) * 100
  
  lb <- Box.test(residuals(fit), lag = min(24, length(residuals(fit)) - 5), type = "Ljung-Box")
  
  # 60-month forecast from full subseries
  fit_full <- auto.arima(ts_sub, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
  fc_60 <- forecast(fit_full, h = 60)
  
  order_str <- paste0("(", fit_full$arma[1], ",", fit_full$arma[6], ",", fit_full$arma[2], ")",
                      "(", fit_full$arma[3], ",", fit_full$arma[7], ",", fit_full$arma[4], ")[12]")
  
  # Taxa anualizada em 2030 (último mês do forecast se alcança)
  idx_2030 <- min(60, length(fc_60$mean))
  
  log_msg("  {label}: {n} obs | Ordem: {order_str} | MAPE={round(mape,1)}% | LB p={round(lb$p.value,3)}")
  
  tibble(
    Window     = label,
    N_obs      = n,
    N_train    = length(ts_train),
    Order      = order_str,
    MAPE       = round(mape, 1),
    LjungBox_p = round(lb$p.value, 3),
    Proj_2030_monthly = round(as.numeric(fc_60$mean[idx_2030]), 3),
    CI95_lo    = round(as.numeric(fc_60$lower[idx_2030, "95%"]), 3),
    CI95_hi    = round(as.numeric(fc_60$upper[idx_2030, "95%"]), 3)
  )
}

s1_results <- bind_rows(
  run_sarima_window(ts_taxa, 2020, 1, 2025, 12, label = "Full series (2020-2025, 72 obs)"),
  run_sarima_window(ts_taxa, 2022, 1, 2025, 12, label = "Post-COVID (2022-2025, 48 obs)"),
  run_sarima_window(ts_taxa, 2020, 1, 2023, 12, test_months = 12, label = "Pre-deceleration (2020-2023, 48 obs)")
)

log_msg("\n  S1 Resumo:")
if (!is.null(s1_results) && nrow(s1_results) > 0) {
  print(s1_results)
  write_csv(s1_results, file.path(sens_dir, "S1_sarima_windows.csv"))
  log_msg("  Salvo: S1_sarima_windows.csv")
}

# ============================================================
# S2: SENSIBILIDADE AO K (SATURAÇÃO DO MODELO LOGÍSTICO)
# ============================================================
log_msg("\n=== S2: Sensibilidade ao K (saturação de cobertura) ===")

K_values <- c(0.25, 0.287, 0.32)
K_labels <- c("K=25%", "K=28.7% (base)", "K=32%")

cob_obs <- nacional %>% select(ano, cob) %>% mutate(t = ano - 2020)

s2_results <- list()

for (k in seq_along(K_values)) {
  K_val <- K_values[k]
  K_lab <- K_labels[k]
  
  # Projetar cobertura com K fixo
  proj_k <- tibble(ano = 2026:2035, t = (2026:2035) - 2020)
  
  # Usar NLS com K fixo (estimar apenas a e b)
  fit_k <- tryCatch({
    nls(cob ~ K_val / (1 + exp(-(a + b * t))),
        data = cob_obs,
        start = list(a = -1.0, b = 0.15),
        control = nls.control(maxiter = 500))
  }, error = function(e) NULL)
  
  if (!is.null(fit_k)) {
    proj_k$cob <- pmin(predict(fit_k, newdata = proj_k), K_val)
  } else {
    # Fallback: logit-linear com cap
    cob_obs$logit <- log(cob_obs$cob / (1 - cob_obs$cob))
    lm_cob <- lm(logit ~ t, data = cob_obs)
    proj_k$cob <- pmin(1 / (1 + exp(-predict(lm_cob, newdata = proj_k))), K_val)
  }
  
  # Beneficiários = cobertura × pop IBGE
  proj_k <- proj_k %>%
    left_join(pop_br %>% select(ano, pop), by = "ano") %>%
    mutate(benef = cob * pop)
  
  # Aplicar cenário inercial sobre esses beneficiários
  for (cen_name in c("otimista", "inercial", "pessimista")) {
    taxa_col <- paste0("taxa_", cen_name)
    taxa_vals <- cenarios[[taxa_col]][cenarios$ano %in% 2026:2035]
    proc_vals <- round(taxa_vals * proj_k$benef / 1000)
    
    for (a in c(2030, 2035)) {
      idx <- which(proj_k$ano == a)
      s2_results <- c(s2_results, list(tibble(
        K_label   = K_lab,
        K_pct     = K_val * 100,
        Scenario  = cen_name,
        Year      = a,
        Benef_M   = round(proj_k$benef[idx] / 1e6, 1),
        Coverage  = round(proj_k$cob[idx] * 100, 1),
        Claims_k  = round(proc_vals[idx] / 1000, 0)
      )))
    }
  }
  
  log_msg("  {K_lab}: Benef 2035 = {round(proj_k$benef[proj_k$ano==2035]/1e6,1)}M | Cob = {round(proj_k$cob[proj_k$ano==2035]*100,1)}%")
}

s2_df <- bind_rows(s2_results)
log_msg("\n  S2 Resumo (processos em milhares):")
print(s2_df %>% arrange(Year, Scenario, K_pct))
write_csv(s2_df, file.path(sens_dir, "S2_K_sensitivity.csv"))
log_msg("  Salvo: S2_K_sensitivity.csv")


# ============================================================
# S3: SENSIBILIDADE AO PERÍODO DE CÁLCULO DO CAGR
# ============================================================
log_msg("\n=== S3: Sensibilidade ao CAGR base ===")

calc_cagr_period <- function(df, start_y, end_y) {
  v0 <- df$taxa_1k[df$ano == start_y]
  v1 <- df$taxa_1k[df$ano == end_y]
  n  <- end_y - start_y
  ((v1 / v0)^(1/n) - 1)
}

cagr_full   <- calc_cagr_period(nacional, 2020, 2025)
cagr_post   <- calc_cagr_period(nacional, 2022, 2025)
cagr_recent <- calc_cagr_period(nacional, 2023, 2025)

log_msg("  CAGR 2020-2025 (full):   {round(cagr_full*100,1)}%")
log_msg("  CAGR 2022-2025 (post):   {round(cagr_post*100,1)}%")
log_msg("  CAGR 2023-2025 (recent): {round(cagr_recent*100,1)}%")

# Projetar cenário inercial (damping 12 anos) com cada CAGR
project_inertial <- function(cagr_val, cagr_label, damping_years = 12) {
  anos <- 2026:2035
  taxa <- numeric(length(anos))
  taxa[1] <- taxa_2025 * (1 + cagr_val * (1 - 1/damping_years))
  
  for (j in 2:length(anos)) {
    t_d <- anos[j] - 2025
    damp <- pmax(0, 1 - t_d / damping_years)
    taxa[j] <- taxa[j-1] * (1 + cagr_val * damp)
  }
  
  benef_vals <- benef_proj$benef[match(anos, benef_proj$ano)]
  proc <- round(taxa * benef_vals / 1000)
  
  tibble(
    CAGR_label = cagr_label,
    CAGR_pct   = round(cagr_val * 100, 1),
    Year       = anos,
    Rate_1k    = round(taxa, 2),
    Claims     = proc
  )
}

s3_results <- bind_rows(
  project_inertial(cagr_full,   "2020-2025 (full)"),
  project_inertial(cagr_post,   "2022-2025 (post-COVID)"),
  project_inertial(cagr_recent, "2023-2025 (recent)")
)

s3_summary <- s3_results %>%
  filter(Year %in% c(2030, 2035)) %>%
  select(CAGR_label, CAGR_pct, Year, Rate_1k, Claims)

log_msg("\n  S3 Resumo:")
print(s3_summary)
write_csv(s3_results, file.path(sens_dir, "S3_cagr_sensitivity.csv"))
write_csv(s3_summary, file.path(sens_dir, "S3_cagr_summary.csv"))
log_msg("  Salvo: S3_cagr_sensitivity.csv / S3_cagr_summary.csv")


# ============================================================
# A4: BOOTSTRAP COM INCERTEZA NO DENOMINADOR (K)
# ============================================================
log_msg("\n=== A4: Bootstrap com incerteza no K ===")

set.seed(42)
n_boot_k   <- 2000
K_mean     <- if (!is.null(nls_fit)) as.numeric(coef(nls_fit)["K"]) else 0.287
K_sd       <- 0.02   # ~7% CV — reflete incerteza na saturação
damping_yrs <- 12
anos_proj_k <- 2026:2035

log_msg("  K_mean={round(K_mean,3)} | K_sd={K_sd} | n_sim={n_boot_k}")
log_msg("  CAGR={round(cagr_anual_taxa*100,1)}% ± {round(se_cagr*100,1)}%")

# Coeficientes do modelo logístico para recomputar beneficiários
if (!is.null(nls_fit)) {
  a_hat <- coef(nls_fit)["a"]
  b_hat <- coef(nls_fit)["b"]
} else {
  # Fallback
  a_hat <- -1.0
  b_hat <- 0.15
}

boot_k_proc <- matrix(NA, nrow = n_boot_k, ncol = length(anos_proj_k))
boot_k_taxa <- matrix(NA, nrow = n_boot_k, ncol = length(anos_proj_k))

for (b in 1:n_boot_k) {
  # (1) Sortear CAGR
  cagr_b <- rnorm(1, cagr_anual_taxa, se_cagr)
  
  # (2) Sortear taxa base
  taxa_b <- taxa_2025 * exp(rnorm(1, 0, sigma_anual * 0.5))
  
  # (3) Sortear K
  K_b <- rnorm(1, K_mean, K_sd)
  K_b <- max(K_b, 0.20)
  K_b <- min(K_b, 0.35)
  
  for (j in seq_along(anos_proj_k)) {
    a_proj <- anos_proj_k[j]
    t_d <- a_proj - 2025
    t_logistic <- a_proj - 2020
    
    # Beneficiários com K perturbado
    cob_b <- K_b / (1 + exp(-(a_hat + b_hat * t_logistic)))
    cob_b <- min(cob_b, K_b)
    pop_a <- pop_br$pop[pop_br$ano == a_proj]
    if (length(pop_a) == 0) pop_a <- tail(pop_br$pop, 1)
    benef_b <- cob_b * pop_a
    
    # Taxa com damping + ruído
    damp <- pmax(0, 1 - t_d / damping_yrs)
    noise <- exp(rnorm(1, 0, sigma_anual))
    taxa_b <- taxa_b * (1 + cagr_b * damp) * noise
    taxa_b <- pmin(taxa_b, taxa_ceiling)
    
    boot_k_taxa[b, j] <- taxa_b
    boot_k_proc[b, j] <- round(taxa_b * benef_b / 1000)
  }
}

ic_boot_k <- tibble(
  ano     = anos_proj_k,
  lo95    = apply(boot_k_proc, 2, quantile, 0.025, na.rm = TRUE),
  lo80    = apply(boot_k_proc, 2, quantile, 0.10, na.rm = TRUE),
  mediana = apply(boot_k_proc, 2, quantile, 0.50, na.rm = TRUE),
  hi80    = apply(boot_k_proc, 2, quantile, 0.90, na.rm = TRUE),
  hi95    = apply(boot_k_proc, 2, quantile, 0.975, na.rm = TRUE)
)

# Comparar com bootstrap original (sem incerteza no K)
log_msg("\n  Comparação: Bootstrap original vs com incerteza K")
log_msg("  {sprintf('%-6s %20s %20s', 'Ano', 'Original IC95%', 'Com K IC95%')}")
for (a in c(2030, 2035)) {
  orig <- ic_boot %>% filter(ano == a)
  new  <- ic_boot_k %>% filter(ano == a)
  if (nrow(orig) > 0 && nrow(new) > 0) {
    log_msg("  {sprintf('%-6d %9s – %-9s %9s – %-9s', a, 
              fmt(round(orig$lo95)), fmt(round(orig$hi95)),
              fmt(round(new$lo95)), fmt(round(new$hi95)))}")
  }
}

# Largura relativa dos ICs
for (a in c(2030, 2035)) {
  orig <- ic_boot %>% filter(ano == a)
  new  <- ic_boot_k %>% filter(ano == a)
  if (nrow(orig) > 0 && nrow(new) > 0) {
    width_orig <- orig$hi95 - orig$lo95
    width_new  <- new$hi95 - new$lo95
    pct_wider <- (width_new / width_orig - 1) * 100
    log_msg("  {a}: IC com K é {round(pct_wider,1)}% mais largo")
  }
}

write_csv(ic_boot_k, file.path(sens_dir, "A4_bootstrap_with_K.csv"))
log_msg("  Salvo: A4_bootstrap_with_K.csv")


# ============================================================
# TABELA CONSOLIDADA DE SENSIBILIDADE
# ============================================================
log_msg("\n=== Tabela consolidada ===")

# Base case values for comparison
base_2030 <- cenarios$proc_inercial[cenarios$ano == 2030]
base_2035 <- cenarios$proc_inercial[cenarios$ano == 2035]

sens_consolidated <- bind_rows(
  # S1
  s1_results %>%
    mutate(Analysis = "S1: Series window",
           Parameter = Window,
           Metric = paste0("MAPE=", MAPE, "%")) %>%
    select(Analysis, Parameter, Metric),
  
  # S2 (inertial only, 2030 and 2035)
  s2_df %>%
    filter(Scenario == "inercial") %>%
    mutate(Analysis = "S2: Saturation (K)",
           Parameter = K_label,
           Metric = paste0(Year, ": ", Claims_k, "k claims")) %>%
    select(Analysis, Parameter, Metric),
  
  # S3 (2030 and 2035)
  s3_summary %>%
    mutate(Analysis = "S3: CAGR period",
           Parameter = paste0(CAGR_label, " (", CAGR_pct, "%)"),
           Metric = paste0(Year, ": ", fmt(Claims), " claims")) %>%
    select(Analysis, Parameter, Metric),
  
  # A4
  tibble(
    Analysis = rep("A4: Bootstrap + K uncertainty", 2),
    Parameter = c("2030", "2035"),
    Metric = c(
      paste0("IC95%=[", fmt(round(ic_boot_k$lo95[ic_boot_k$ano==2030])), "–", 
             fmt(round(ic_boot_k$hi95[ic_boot_k$ano==2030])), "]"),
      paste0("IC95%=[", fmt(round(ic_boot_k$lo95[ic_boot_k$ano==2035])), "–", 
             fmt(round(ic_boot_k$hi95[ic_boot_k$ano==2035])), "]")
    )
  )
)

write_csv(sens_consolidated, file.path(sens_dir, "sensitivity_consolidated.csv"))

log_msg("\n  Tabela consolidada salva: sensitivity_consolidated.csv")
log_msg("\n=== 04_sensitivity_hsr.R — CONCLUÍDO ===")
log_msg("  Arquivos em {sens_dir}:")
log_msg("  {paste(list.files(sens_dir), collapse = ', ')}")