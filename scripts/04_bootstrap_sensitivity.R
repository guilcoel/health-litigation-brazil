## R2.5 — bootstrap reproduction and sensitivity (Reviewer 2, comment 5)
suppressMessages({library(readr); library(dplyr)})

d  <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  filter(scope == "National", date < as.Date("2026-01-01"))
bp <- read_csv("data/ans_beneficiaries_projected.csv", show_col_types = FALSE)
bo <- read_csv("data/ans_hospital_medical_beneficiaries_annual.csv", show_col_types = FALSE)
benef_proj <- setNames(bp$benef, bp$ano); benef_obs <- setNames(bo$benef_mh, bo$ano)

anual <- d |> mutate(ano = as.integer(format(date, "%Y"))) |> group_by(ano) |>
  summarise(casos = sum(new_claims), .groups = "drop") |>
  mutate(taxa = casos / benef_obs[as.character(ano)] * 1000)
sigma_anual <- sigma(lm(log(taxa) ~ ano, data = anual))

b  <- approx(seq(6, 66, by = 12), benef_obs, xout = 1:72, rule = 2)$y
mm <- lm(log(d$new_claims / b * 1000) ~ I(1:72) + factor(rep(1:12, 6)))
th <- coef(mm)[2]; cagr_hat <- exp(th*12) - 1
se_cagr <- 12 * exp(th*12) * summary(mm)$coefficients[2,2]
taxa_2025 <- 341763 / 52900000 * 1000
anos <- 2026:2040

run <- function(sigma_factor = 0.5, ceiling = 25, process_noise = TRUE,
                n = 2000, seed = 42, damping = 12) {
  set.seed(seed)
  claims <- matrix(NA_real_, n, length(anos)); rate <- claims
  for (i in 1:n) {
    g  <- rnorm(1, cagr_hat, se_cagr)
    tb <- taxa_2025 * exp(rnorm(1, 0, sigma_anual * sigma_factor))
    for (j in seq_along(anos)) {
      tau <- anos[j] - 2025
      tb  <- tb * (1 + g * pmax(0, 1 - tau/damping))
      if (process_noise) tb <- tb * exp(rnorm(1, 0, sigma_anual))
      tb  <- pmin(tb, ceiling)
      rate[i,j]   <- tb
      claims[i,j] <- tb * benef_proj[as.character(anos[j])] / 1000
    }
  }
  k <- which(anos == 2030); k35 <- which(anos == 2035)
  c(lo = quantile(claims[,k], .025), md = quantile(claims[,k], .5),
    hi = quantile(claims[,k], .975), width = diff(quantile(claims[,k], c(.025,.975))),
    at_ceiling = mean(rate[,k] >= ceiling*0.999)*100,
    hi2035 = quantile(claims[,k35], .975))
}

cat(sprintf("sigma_anual %.4f | g0 %.4f (SE %.4f)\n\n", sigma_anual, cagr_hat, se_cagr))
cat("Published 2030 interval: 511,204 to 1,074,782, median 742,791\n")
print(round(run()))
cat("\nSensitivity to the factor on the baseline sigma\n")
for (f in c(0, 0.25, 0.5, 1)) cat(sprintf("  %.2f: %s\n", f, paste(round(run(sigma_factor = f)), collapse = " ")))
cat("\nSensitivity to the plausibility ceiling\n")
for (c0 in c(15, 20, 25, 30, 1e6)) cat(sprintf("  %6s: %s\n", c0, paste(round(run(ceiling = c0)), collapse = " ")))
cat("\nConfidence versus predictive: width with and without annual process noise\n")
cat(sprintf("  with    %.0f\n  without %.0f\n",
            run()["width.97.5%"], run(process_noise = FALSE)["width.97.5%"]))
