## Decision 1 — what changes if the official ANS denominators are adopted
suppressMessages({library(readr); library(dplyr); library(forecast)})

d  <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  filter(scope == "National", date < as.Date("2026-01-01")) |> arrange(date)
bp <- read_csv("data/ans_beneficiaries_projected.csv", show_col_types = FALSE)
benef_proj <- setNames(bp$benef, bp$ano)

used <- c(`2020`=47135000, `2021`=48566000, `2022`=49703000,
          `2023`=51348000, `2024`=52210000, `2025`=52900000)
ans  <- c(`2020`=47939243, `2021`=49274613, `2022`=50530569,
          `2023`=51254745, `2024`=51956946, `2025`=52865947)

cat("=== The two denominator series ===\n")
cat(sprintf("  %-6s %12s %12s %9s\n", "year", "ANS official", "used", "diff"))
for (y in names(used))
  cat(sprintf("  %-6s %12.0f %12.0f %8.2f%%\n", y, ans[y], used[y], (used[y]/ans[y] - 1)*100))

evaluate <- function(b, label) {
  bb <- approx(seq(6, 66, by = 12), b, xout = 1:72, rule = 2)$y
  tx <- d$new_claims / bb * 1000
  mm <- lm(log(tx) ~ I(1:72) + factor(rep(1:12, 6)))
  th <- unname(coef(mm)[2])
  g0 <- exp(th*12) - 1
  se <- 12 * exp(th*12) * summary(mm)$coefficients[2, 2]
  rate_25 <- 341763 / b[["2025"]] * 1000
  rate_20 <- sum(d$new_claims[1:12]) / b[["2020"]] * 1000
  rate_30 <- rate_25 * prod(1 + pmax(0, g0 * (1 - (1:5)/12)))
  inertial <- round(rate_30 * benef_proj[["2030"]] / 1000)
  fc <- forecast(Arima(ts(tx, start = c(2020,1), frequency = 12), order = c(0,1,1),
                       seasonal = list(order = c(0,1,0), period = 12)), h = 60)
  sarima <- round(sum(fc$mean[49:60]) * benef_proj[["2030"]] / 1000)
  cat(sprintf("\n  %s\n", label))
  cat(sprintf("    base growth g0     : %.4f (SE %.4f)\n", g0, se))
  cat(sprintf("    rate 2020 / 2025   : %.3f / %.3f per 1,000\n", rate_20, rate_25))
  cat(sprintf("    inertial 2030      : %.0f\n", inertial))
  cat(sprintf("    SARIMA 2030        : %.0f\n", sarima))
  c(g0 = g0, inertial = inertial, sarima = sarima)
}

cat("\n=== Downstream effect ===")
a <- evaluate(used, "Denominators as submitted")
b <- evaluate(ans,  "Official ANS series")
cat(sprintf("\n  Change in g0        : %+.2f pp (%.2f%% -> %.2f%%)\n",
            (b[["g0"]] - a[["g0"]])*100, a[["g0"]]*100, b[["g0"]]*100))
cat(sprintf("  Change in inertial  : %+.0f (%+.2f%%)\n",
            b[["inertial"]] - a[["inertial"]],
            (b[["inertial"]]/a[["inertial"]] - 1)*100))
cat(sprintf("  Change in SARIMA    : %+.0f (%+.2f%%)\n",
            b[["sarima"]] - a[["sarima"]], (b[["sarima"]]/a[["sarima"]] - 1)*100))
cat("\n  Published: g0 18.86%, rate 2.98 to 6.46, inertial 745,323, SARIMA 671,400.\n")
