## Table S2 rebuilt on the official ANS denominators — the three sensitivity
## analyses S1 (SARIMA windows), S2 (coverage ceilings), S3 (growth-rate windows)
suppressMessages({library(readr); library(dplyr); library(forecast)})

d  <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  filter(scope == "National", date < as.Date("2026-01-01")) |> arrange(date)
bp  <- read_csv("data/ans_beneficiaries_projected.csv", show_col_types = FALSE)
pop <- setNames(bp$pop, bp$ano)

benef <- c(`2020`=47939243, `2021`=49274613, `2022`=50530569,
           `2023`=51254745, `2024`=51956946, `2025`=52865947)
bb <- approx(seq(6, 66, by = 12), benef, xout = 1:72, rule = 2)$y
tx <- d$new_claims / bb * 1000
rate_ts <- ts(tx, start = c(2020, 1), frequency = 12)

annual <- d |> mutate(year = as.integer(format(date, "%Y"))) |>
  group_by(year) |> summarise(claims = sum(new_claims), .groups = "drop") |>
  mutate(rate = claims / benef[as.character(year)] * 1000)
rate_2025 <- annual$rate[annual$year == 2025]

## beneficiary projection, as in scripts/11
obs      <- tibble(t = 0:5, cob = benef/pop[as.character(2020:2025)])
lm_cob   <- lm(log(cob/(1 - cob)) ~ t, data = obs)
years    <- 2026:2040
cob_free <- plogis(predict(lm_cob, newdata = data.frame(t = years - 2020)))

project <- function(g0, cap = 0.29, tau_d = 12, y = 2030) {
  cob  <- pmin(cob_free, cap)
  bn   <- cob[years == y] * pop[as.character(y)]
  rate <- rate_2025 * prod(1 + pmax(0, g0 * (1 - (1:(y - 2025))/tau_d)))
  round(rate * bn / 1000)
}

## ---------------------------------------------------------------------------
## S1 — SARIMA over alternative estimation windows
## ---------------------------------------------------------------------------
cat("=== S1. SARIMA over alternative estimation windows ===\n")
windows <- list("full series, 2020-2025" = c(2020, 1),
                "from 2022"              = c(2022, 1),
                "from 2023"              = c(2023, 1))
for (nm in names(windows)) {
  y  <- window(rate_ts, start = windows[[nm]])
  f  <- auto.arima(y, ic = "aicc", stepwise = TRUE)
  o  <- arimaorder(f)
  dd <- o[2]; DD <- ifelse(is.na(o[5]), 0, o[5])
  fc <- forecast(f, h = (2030 - 2025)*12)
  bn <- pmin(cob_free, 0.29)[years == 2030] * pop["2030"] / 1000
  cat(sprintf("  %-24s n=%2d  order (%s)(%s)  drift %-3s  2030 %8.0f claims\n",
              nm, length(y), paste(o[1:3], collapse = ","),
              ifelse(is.na(o[4]), "none", paste(o[4:6], collapse = ",")),
              ifelse("drift" %in% names(coef(f)), "YES", "no"),
              sum(tail(fc$mean, 12)) * bn))
}
cat("  NOTE: the submitted Table S2 says shorter windows 'replaced non-seasonal\n")
cat("  differencing with a drift term'. Check the orders above against that claim;\n")
cat("  a drift is only admissible where d + D < 2.\n")

## ---------------------------------------------------------------------------
## S2 — alternative coverage ceilings, plus the formal distribution
## ---------------------------------------------------------------------------
cat("\n=== S2. Coverage ceilings, inertial 2030 ===\n")
g0 <- {
  mm <- lm(log(tx) ~ I(1:72) + factor(rep(1:12, 6)))
  exp(unname(coef(mm)[2])*12) - 1
}
for (cap in c(0.25, 0.29, 0.32)) {
  cob <- pmin(cob_free, cap)[years == 2030]
  cat(sprintf("  ceiling %4.0f%%: coverage %.5f | 2030 %8.0f claims%s\n", cap*100, cob,
              project(g0, cap = cap),
              ifelse(cap >= 0.29, "   (cap not reached at 2030)", "")))
}
cat(sprintf("  projected 2030 coverage without any cap: %.5f\n", cob_free[years == 2030]))

set.seed(42); nk <- 20000
Ks <- numeric(0)
while (length(Ks) < nk) { x <- rnorm(nk, 0.287, 0.02); Ks <- c(Ks, x[x >= 0.20 & x <= 0.35]) }
Ks <- Ks[1:nk]
rate30 <- rate_2025 * prod(1 + pmax(0, g0 * (1 - (1:5)/12)))
c30 <- rate30 * pmin(cob_free[years == 2030], Ks) * pop["2030"]/1000
qk  <- quantile(c30, c(.025, .5, .975))
cat(sprintf("\n  Formal distribution K ~ N(0.287, 0.02) truncated [0.20, 0.35]:\n"))
cat(sprintf("    median %.0f | 95%% %.0f to %.0f | width %.0f | cap binds in %.1f%% of draws\n",
            qk[2], qk[1], qk[3], qk[3] - qk[1], mean(Ks < cob_free[years == 2030])*100))

## ---------------------------------------------------------------------------
## S3 — base growth rate over alternative reference periods
## ---------------------------------------------------------------------------
cat("\n=== S3. Base growth rate over alternative reference periods ===\n")
p2p <- function(y0, y1) {
  r0 <- annual$rate[annual$year == y0]; r1 <- annual$rate[annual$year == y1]
  (r1/r0)^(1/(y1 - y0)) - 1
}
rows <- list("log-linear, 2020-2025 (primary)" = g0,
             "point-to-point, 2020-2025"       = p2p(2020, 2025),
             "point-to-point, 2022-2025"       = p2p(2022, 2025),
             "point-to-point, 2023-2025"       = p2p(2023, 2025))
vals <- numeric(0)
for (nm in names(rows)) {
  v <- project(rows[[nm]])
  vals <- c(vals, v)
  cat(sprintf("  %-34s g0 = %6.2f%%  ->  2030 %8.0f claims\n", nm, rows[[nm]]*100, v))
}
alt <- vals[-1]
cat(sprintf("\n  Range across the three point-to-point windows: %.0f to %.0f = %.0f claims\n",
            min(alt), max(alt), max(alt) - min(alt)))
cat("  (submitted: 694,995 to 861,263, range 166,268, on the old denominators)\n")
cat("  This range is the trend-estimator component of the uncertainty decomposition,\n")
cat("  so section 5 of docs/final_numbers.md and the Figure 2 Panel B bars both change.\n")

cat("\n=== Decomposition, all three components on the new denominators ===\n")
td <- 3:20
surf <- vapply(td, function(x) project(g0, tau_d = x), numeric(1))
cat(sprintf("  policy (response surface, tau_d 3 to 20) : %8.0f\n", max(surf) - min(surf)))
cat(sprintf("  trend estimator (growth-rate windows)    : %8.0f\n", max(alt) - min(alt)))
cat(sprintf("  market size (formal ceiling distribution): %8.0f\n", qk[3] - qk[1]))
cat(sprintf("  policy / market                          : %.2f to 1\n",
            (max(surf) - min(surf))/(qk[3] - qk[1])))
cat(sprintf("  policy / trend                           : %.2f to 1\n",
            (max(surf) - min(surf))/(max(alt) - min(alt))))
