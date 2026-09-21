## ============================================================
## 05_figures_hsr.R
## Figuras para submissão HSR — Todas em inglês, 300dpi
##
## DEPENDÊNCIA: Rodar 03_model_v3.R e 04_sensitivity_hsr.R ANTES
##   Objetos necessários do 03: nacional, cenarios, ic_boot,
##     ic_sarima, benef_proj, obs_resumo, comp
##   Objetos necessários do 04: s1_results, s2_df, s3_summary,
##     ic_boot_k
##
## OUTPUT:
##   output_hsr/figures/   — Main figures (corpo do artigo)
##   output_hsr/supp/      — Supplementary figures
## ============================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
  library(patchwork)
  library(glue)
})

fig_dir  <- "output_hsr/figures"
supp_dir <- "output_hsr/supplementary"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(supp_dir, showWarnings = FALSE, recursive = TRUE)

log_msg("")
log_msg("##########################################################")
log_msg("## 05_figures_hsr.R — Figuras HSR (English, 300dpi)     ##")
log_msg("##########################################################")

# ── HSR Theme ────────────────────────────────────────────────
theme_hsr <- theme_minimal(base_size = 11, base_family = "Helvetica") +
  theme(
    plot.title       = element_blank(),
    plot.subtitle    = element_blank(),
    axis.title       = element_text(size = 10),
    axis.text        = element_text(size = 9),
    legend.position  = "bottom",
    legend.title     = element_text(size = 9, face = "bold"),
    legend.text      = element_text(size = 9),
    panel.grid.minor = element_blank(),
    plot.caption     = element_text(size = 7, color = "grey50", hjust = 0)
  )

# ── Palette (colorblind-safe) ────────────────────────────────
pal_lines <- c(
  "Inertial"    = "#2C3E50",
  "Optimistic"  = "#27AE60",
  "Pessimistic" = "#E74C3C",
  "SARIMA"      = "#7F8C8D"
)
col_iess     <- "#E67E22"
col_observed <- "#2C3E50"
col_boot     <- "#3498DB"

# ── Save helper ──────────────────────────────────────────────
save_hsr <- function(plot, name, dir = fig_dir, w = 7, h = 5) {
  ggsave(file.path(dir, paste0(name, ".pdf")),  plot, width = w, height = h, dpi = 300)
  ggsave(file.path(dir, paste0(name, ".tiff")), plot, width = w, height = h, dpi = 300,
         compression = "lzw")
  # EPS via cairo for unicode support
  tryCatch(
    ggsave(file.path(dir, paste0(name, ".eps")), plot, width = w, height = h, dpi = 300,
           device = cairo_ps),
    error = function(e) log_msg("  ⚠ EPS failed for {name}: {e$message}")
  )
  log_msg("  Saved: {name} (.pdf/.tiff/.eps)")
}


# ================================================================
# FIGURE 1: Scenarios + Bootstrap CI (2020–2035, main body)
# ================================================================
log_msg("\n--- Figure 1: Scenarios + Bootstrap CI ---")

# Observed data
df_obs <- nacional %>%
  select(ano, processos) %>%
  rename(year = ano, claims = processos)

# Scenarios — pivot and translate
df_cen <- cenarios %>%
  filter(ano <= 2035) %>%
  select(ano, proc_inercial, proc_otimista, proc_pessimista) %>%
  pivot_longer(-ano, names_to = "scenario", values_to = "claims",
               names_prefix = "proc_") %>%
  mutate(
    scenario = case_when(
      scenario == "inercial"   ~ "Inertial",
      scenario == "otimista"   ~ "Optimistic",
      scenario == "pessimista" ~ "Pessimistic"
    ),
    scenario = factor(scenario, levels = c("Pessimistic", "Inertial", "Optimistic"))
  ) %>%
  rename(year = ano)

# Bootstrap CI (cut to 2035)
df_boot <- ic_boot_k %>%    # Use bootstrap WITH K uncertainty (A4)
  filter(ano <= 2035) %>%
  rename(year = ano)

# IESS benchmarks at 2035
df_iess <- tibble(
  year   = c(2035, 2035),
  claims = c(400000, 1100000),
  label  = c("IESS realistic", "IESS pessimistic")
)

fig1 <- ggplot() +
  # Bootstrap CI (A4 — with K uncertainty)
  geom_ribbon(data = df_boot, aes(x = year, ymin = lo95/1000, ymax = hi95/1000),
              fill = col_boot, alpha = 0.12) +
  geom_ribbon(data = df_boot, aes(x = year, ymin = lo80/1000, ymax = hi80/1000),
              fill = col_boot, alpha = 0.22) +
  
  # Scenario lines
  geom_line(data = df_cen, aes(x = year, y = claims/1000, color = scenario, linetype = scenario),
            linewidth = 0.9) +
  
  # IESS benchmarks
  geom_point(data = df_iess, aes(x = year, y = claims/1000),
             shape = 18, size = 3.5, color = col_iess) +
  geom_text(data = df_iess, aes(x = year + 0.3, y = claims/1000, label = label),
            hjust = 0, size = 2.5, color = col_iess) +
  
  # Observed
  geom_point(data = df_obs, aes(x = year, y = claims/1000), color = col_observed, size = 2.5) +
  geom_line(data = df_obs, aes(x = year, y = claims/1000), color = col_observed, linewidth = 0.9) +
  
  # Horizon dividers
  geom_vline(xintercept = 2025.5, linetype = "dotted", color = "grey60", linewidth = 0.3) +
  geom_vline(xintercept = 2030.5, linetype = "dotted", color = "grey60", linewidth = 0.3) +
  annotate("text", x = 2028, y = Inf, label = "Primary horizon", 
           vjust = 1.5, size = 2.8, color = "grey45") +
  annotate("text", x = 2033, y = Inf, label = "Extended horizon", 
           vjust = 1.5, size = 2.8, color = "grey45") +
  
  # Scales
  scale_color_manual(values = pal_lines, name = "Scenario") +
  scale_linetype_manual(values = c("Inertial" = "solid", "Optimistic" = "longdash", 
                                   "Pessimistic" = "dotted"), name = "Scenario") +
  scale_x_continuous(breaks = seq(2020, 2035, 5)) +
  scale_y_continuous(labels = comma_format()) +
  labs(x = "Year", y = "New judicial claims (thousands)") +
  theme_hsr +
  guides(color = guide_legend(override.aes = list(linewidth = 1)))

save_hsr(fig1, "Figure_1_scenarios_bootstrap", w = 8, h = 5.5)


# ================================================================
# FIGURE 2: External Validation — This study vs IESS
# ================================================================
log_msg("\n--- Figure 2: External Validation vs IESS ---")

# This study at 2035
df_this <- tibble(
  scenario = c("Optimistic", "Inertial", "Pessimistic"),
  claims = c(
    cenarios$proc_otimista[cenarios$ano == 2035],
    cenarios$proc_inercial[cenarios$ano == 2035],
    cenarios$proc_pessimista[cenarios$ano == 2035]
  ),
  source = "This study"
)

# IESS at 2035
df_iess_comp <- tibble(
  scenario = c("Optimistic", "Inertial", "Pessimistic"),
  claims = c(170000, 400000, 1100000),  # IESS: otimista, realista, pessimista
  source = "IESS (2025)"
)

# Map: This study optimistic ↔ IESS realistic
df_compare <- bind_rows(df_this, df_iess_comp) %>%
  mutate(scenario = factor(scenario, levels = c("Pessimistic", "Inertial", "Optimistic")))

# Connecting segments
df_segments <- df_this %>%
  rename(claims_this = claims) %>%
  select(scenario, claims_this) %>%
  left_join(
    df_iess_comp %>% rename(claims_iess = claims) %>% select(scenario, claims_iess),
    by = "scenario"
  )

fig2 <- ggplot() +
  # Connecting lines
  geom_segment(data = df_segments, 
               aes(x = claims_this/1000, xend = claims_iess/1000,
                   y = scenario, yend = scenario),
               color = "grey70", linewidth = 0.6) +
  # Points
  geom_point(data = df_compare, aes(x = claims/1000, y = scenario, color = source),
             size = 4) +
  
  scale_color_manual(values = c("This study" = "#2C3E50", "IESS (2025)" = "#E67E22"),
                     name = "Source") +
  scale_x_continuous(labels = comma_format()) +
  labs(x = "Projected claims in 2035 (thousands)", y = NULL) +
  theme_hsr +
  theme(panel.grid.major.y = element_blank(),
        axis.text.y = element_text(size = 10, face = "bold"))

save_hsr(fig2, "Figure_2_external_validation", w = 7, h = 3.5)


# ================================================================
# SUPPLEMENTARY FIGURE S1: Beneficiary projection
# ================================================================
log_msg("\n--- Supp Fig S1: Beneficiary projection ---")

df_benef_en <- benef_proj %>%
  filter(ano <= 2040) %>%
  rename(year = ano) %>%
  mutate(
    type = ifelse(tipo == "observado", "Observed", "Projected"),
    benef_M = benef / 1e6,
    coverage_pct = cob * 100
  )

fig_s1 <- ggplot(df_benef_en, aes(x = year)) +
  geom_col(aes(y = benef_M), fill = "#AED6F1", color = NA, width = 0.7) +
  geom_line(aes(y = coverage_pct * max(benef_M) / 30), color = "#C0392B", linewidth = 0.9) +
  geom_point(aes(y = coverage_pct * max(benef_M) / 30, shape = type), 
             color = "#C0392B", size = 2) +
  scale_y_continuous(
    name = "Hospital-medical beneficiaries (millions)",
    sec.axis = sec_axis(~ . * 30 / max(df_benef_en$benef_M), 
                        name = "Hospital-medical coverage (%)")
  ) +
  scale_shape_manual(values = c("Observed" = 16, "Projected" = 1), name = NULL) +
  scale_x_continuous(breaks = seq(2020, 2040, 5)) +
  labs(x = "Year",
       caption = paste0("Source: ANS/SIB (observed), logistic model (K=",
                        round(coef(nls_fit)["K"]*100, 1), "%), IBGE Rev. 2024.")) +
  theme_hsr

save_hsr(fig_s1, "Figure_S1_beneficiaries", dir = supp_dir)


# ================================================================
# SUPPLEMENTARY FIGURE S2: Sensitivity forest plot
# ================================================================
log_msg("\n--- Supp Fig S2: Sensitivity analysis ---")

# Build sensitivity comparison at 2030 (inertial scenario)
base_2030 <- cenarios$proc_inercial[cenarios$ano == 2030]
base_2035 <- cenarios$proc_inercial[cenarios$ano == 2035]

df_sens <- bind_rows(
  # S2: K sensitivity at 2030, inertial
  s2_df %>%
    filter(Scenario == "inercial", Year == 2030) %>%
    mutate(
      label = paste0("K = ", K_pct, "%"),
      analysis = "Saturation (K)",
      value = Claims_k * 1000
    ) %>%
    select(analysis, label, value),
  
  # S3: CAGR sensitivity at 2030
  s3_summary %>%
    filter(Year == 2030) %>%
    mutate(
      label = paste0("CAGR ", CAGR_label),
      analysis = "CAGR period",
      value = Claims
    ) %>%
    select(analysis, label, value),
  
  # A4: Bootstrap width comparison at 2030
  tibble(
    analysis = c("Bootstrap CI (2030)", "Bootstrap CI (2030)"),
    label    = c("Without K uncertainty", "With K uncertainty"),
    value    = c(
      ic_boot$mediana[ic_boot$ano == 2030],
      ic_boot_k$mediana[ic_boot_k$ano == 2030]
    )
  )
) %>%
  mutate(label = factor(label, levels = rev(unique(label))))

fig_s2 <- ggplot(df_sens, aes(x = value/1000, y = label)) +
  geom_point(size = 3, color = "#2C3E50") +
  geom_vline(xintercept = base_2030/1000, linetype = "dashed", color = "#E74C3C", linewidth = 0.5) +
  annotate("text", x = base_2030/1000, y = 0.5, label = "Base case", 
           hjust = -0.1, size = 2.5, color = "#E74C3C") +
  facet_grid(analysis ~ ., scales = "free_y", space = "free_y") +
  scale_x_continuous(labels = comma_format()) +
  labs(x = "Projected claims in 2030 (thousands)", y = NULL,
       caption = "Dashed line = base case inertial scenario.") +
  theme_hsr +
  theme(strip.text.y = element_text(angle = 0, hjust = 0, face = "bold"),
        panel.grid.major.y = element_blank())

save_hsr(fig_s2, "Figure_S2_sensitivity", dir = supp_dir, w = 7, h = 5)


# ================================================================
# SUPPLEMENTARY FIGURE S3: Rate per 1,000 by scenario
# ================================================================
log_msg("\n--- Supp Fig S3: Rate per 1,000 ---")

df_taxa_en <- cenarios %>%
  filter(ano <= 2035) %>%
  select(ano, Inertial = taxa_inercial, Optimistic = taxa_otimista, 
         Pessimistic = taxa_pessimista) %>%
  pivot_longer(-ano, names_to = "Scenario", values_to = "rate") %>%
  rename(year = ano) %>%
  mutate(Scenario = factor(Scenario, levels = c("Pessimistic", "Inertial", "Optimistic")))

df_taxa_obs <- nacional %>%
  select(ano, taxa_1k) %>%
  rename(year = ano, rate = taxa_1k)

fig_s3 <- ggplot() +
  geom_hline(yintercept = 25, linetype = "dashed", color = "grey70", linewidth = 0.4) +
  annotate("text", x = 2035, y = 25, label = "Plausibility ceiling: 25/1,000",
           vjust = -0.5, hjust = 1, size = 2.5, color = "grey50") +
  geom_line(data = df_taxa_en, aes(x = year, y = rate, color = Scenario), linewidth = 0.8) +
  geom_point(data = df_taxa_obs, aes(x = year, y = rate), color = "black", size = 2.5) +
  geom_line(data = df_taxa_obs, aes(x = year, y = rate), color = "black", linewidth = 0.8) +
  # IESS validation
  annotate("point", x = 2024, y = 5.7, shape = 18, size = 3, color = col_iess) +
  annotate("text", x = 2024.3, y = 5.7, label = "IESS 5.7", hjust = 0, size = 2.5, color = col_iess) +
  geom_vline(xintercept = 2030.5, linetype = "dotted", color = "grey60", linewidth = 0.3) +
  scale_color_manual(values = pal_lines, name = "Scenario") +
  scale_x_continuous(breaks = seq(2020, 2035, 5)) +
  labs(x = "Year", y = "Claims per 1,000 hospital-medical beneficiaries per year",
       caption = "Source: CNJ, ANS (hospital-medical beneficiaries), IBGE Rev. 2024.") +
  theme_hsr

save_hsr(fig_s3, "Figure_S3_rate_per_1k", dir = supp_dir)


# ================================================================
# SUPPLEMENTARY FIGURE S4: Extended horizon 2020–2040
# ================================================================
log_msg("\n--- Supp Fig S4: Extended horizon (2020-2040) ---")

df_cen_full <- cenarios %>%
  select(ano, proc_inercial, proc_otimista, proc_pessimista) %>%
  pivot_longer(-ano, names_to = "scenario", values_to = "claims", names_prefix = "proc_") %>%
  mutate(scenario = case_when(
    scenario == "inercial"   ~ "Inertial",
    scenario == "otimista"   ~ "Optimistic",
    scenario == "pessimista" ~ "Pessimistic"
  )) %>%
  rename(year = ano)

df_boot_full <- ic_boot %>%   # Original bootstrap (full horizon)
  rename(year = ano)

fig_s4 <- ggplot() +
  geom_ribbon(data = df_boot_full, aes(x = year, ymin = lo95/1000, ymax = hi95/1000),
              fill = col_boot, alpha = 0.12) +
  geom_ribbon(data = df_boot_full, aes(x = year, ymin = lo80/1000, ymax = hi80/1000),
              fill = col_boot, alpha = 0.22) +
  geom_line(data = df_cen_full, aes(x = year, y = claims/1000, color = scenario, linetype = scenario),
            linewidth = 0.9) +
  geom_point(data = df_obs, aes(x = year, y = claims/1000), color = col_observed, size = 2.5) +
  geom_line(data = df_obs, aes(x = year, y = claims/1000), color = col_observed, linewidth = 0.9) +
  # IESS
  geom_point(data = df_iess, aes(x = year, y = claims/1000),
             shape = 18, size = 3.5, color = col_iess) +
  # Horizons
  geom_vline(xintercept = c(2025.5, 2030.5, 2035.5), linetype = "dotted", color = "grey60") +
  annotate("text", x = 2028, y = Inf, label = "Primary", vjust = 1.5, size = 2.5, color = "grey45") +
  annotate("text", x = 2033, y = Inf, label = "Extended", vjust = 1.5, size = 2.5, color = "grey45") +
  annotate("text", x = 2038, y = Inf, label = "Illustrative", vjust = 1.5, size = 2.5, 
           color = "grey45", fontface = "italic") +
  scale_color_manual(values = pal_lines, name = "Scenario") +
  scale_linetype_manual(values = c("Inertial"="solid", "Optimistic"="longdash", "Pessimistic"="dotted"),
                        name = "Scenario") +
  scale_x_continuous(breaks = seq(2020, 2040, 5)) +
  scale_y_continuous(labels = comma_format()) +
  labs(x = "Year", y = "New judicial claims (thousands)",
       caption = "Shaded: 80%/95% bootstrap CI (2,000 sim). Diamonds: IESS benchmarks.") +
  theme_hsr

save_hsr(fig_s4, "Figure_S4_extended_2040", dir = supp_dir, w = 8, h = 5.5)


# ================================================================
# SUMMARY
# ================================================================
log_msg("\n=== 05_figures_hsr.R — CONCLUÍDO ===")
log_msg("  Main figures ({fig_dir}):")
for (f in list.files(fig_dir, pattern = "\\.pdf$")) log_msg("    {f}")
log_msg("  Supplementary ({supp_dir}):")
for (f in list.files(supp_dir, pattern = "\\.pdf$")) log_msg("    {f}")

log_msg("\n  FIGURE LEGEND TEXT (for manuscript):")
log_msg("  Figure 1. Projected health litigation in Brazil's supplementary health system:")
log_msg("    scenarios and bootstrap confidence intervals, 2020-2035.")
log_msg("  Figure 2. External validation: projected claims in 2035 compared with IESS benchmarks.")
log_msg("  Figure S1. Projected hospital-medical beneficiaries and coverage, 2020-2040.")
log_msg("  Figure S2. Sensitivity of 2030 inertial projection to key assumptions.")
log_msg("  Figure S3. Projected litigation rate per 1,000 hospital-medical beneficiaries by scenario.")
log_msg("  Figure S4. Extended projection horizon including illustrative period (2036-2040).")
