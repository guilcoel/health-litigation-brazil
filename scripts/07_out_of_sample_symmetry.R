## R2.4 — the out-of-sample test, reported symmetrically for both models
## (Reviewer 2, comment 4)
suppressMessages({library(readr); library(dplyr); library(forecast)})

d  <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  filter(scope == "National") |> arrange(date)
bo <- read_csv("data/ans_hospital_medical_beneficiaries_annual.csv", show_col_types = FALSE)
bp <- read_csv("data/ans_beneficiaries_projected.csv", show_col_types = FALSE)
benef_obs  <- setNames(bo$benef_mh, bo$ano)
benef_proj <- setNames(bp$benef, bp$ano)

train <- d |> filter(date <  as.Date("2026-01-01"))
test  <- d |> filter(date >= as.Date("2026-01-01"))   # Jan-May 2026, withheld

b    <- approx(seq(6, 66, by = 12), benef_obs, xout = seq_len(nrow(train)), rule = 2)$y
rate <- ts(train$new_claims / b * 1000, start = c(2020, 1), frequency = 12)
fc   <- forecast(Arima(rate, order = c(0,1,1),
                       seasonal = list(order = c(0,1,0), period = 12)), h = nrow(test))

## ---------------------------------------------------------------------------
## 1. Which 2026 denominator convention reproduces the published +0.35%?
## ---------------------------------------------------------------------------
cat("=== 1. The 2026 denominator convention ===\n")
variants <- list(
  "2026 projected annual count, held constant" = rep(benef_proj["2026"], nrow(test)),
  "2025 observed count, held constant"         = rep(benef_obs["2025"],  nrow(test)),
  "interpolated Dec 2025 -> Dec 2026"          = approx(c(0, 12),
      c(benef_obs["2025"], benef_proj["2026"]), xout = seq_len(nrow(test)))$y,
  "interpolated Jun 2025 -> Jun 2026"          = approx(c(-6, 6),
      c(benef_obs["2025"], benef_proj["2026"]), xout = seq_len(nrow(test)))$y)
for (nm in names(variants)) {
  pred <- as.numeric(fc$mean) * variants[[nm]] / 1000
  cat(sprintf("  %-44s total %8.0f  deviation %+6.2f%%  monthly MAPE %5.2f%%\n", nm,
              sum(pred), (sum(pred) - sum(test$new_claims))/sum(test$new_claims)*100,
              mean(abs((pred - test$new_claims)/test$new_claims))*100))
}
cat("\n  The first variant reproduces the published figures exactly: 155,431 against the\n")
cat("  reported 155,433, deviation +0.35%. That is the convention the pipeline used, and\n")
cat("  it should be stated in the Methods.\n")

## ---------------------------------------------------------------------------
## 2. The same two metrics for both models
## ---------------------------------------------------------------------------
cat("\n=== 2. Month by month, under the reproduced convention ===\n")
pred <- as.numeric(fc$mean) * rep(benef_proj["2026"], nrow(test)) / 1000
cat(sprintf("  %-9s %9s %9s %9s\n", "month", "observed", "SARIMA", "error"))
for (i in seq_len(nrow(test)))
  cat(sprintf("  %-9s %9.0f %9.0f %8.2f%%\n", format(test$date[i], "%b %Y"),
              test$new_claims[i], pred[i],
              (pred[i] - test$new_claims[i])/test$new_claims[i]*100))

mape_sarima <- mean(abs((pred - test$new_claims)/test$new_claims))*100
cum_sarima  <- (sum(pred) - sum(test$new_claims))/sum(test$new_claims)*100
cat(sprintf("\n  SARIMA   : cumulative %+.2f%%  |  monthly MAPE %.2f%%\n", cum_sarima, mape_sarima))
cat(  "  Inertial : cumulative +1.86%  |  monthly MAPE 4.60%   (as published)\n")
cat("\n  This is the asymmetry the reviewer objects to. The manuscript reports the\n")
cat("  cumulative deviation for SARIMA (the metric where monthly errors cancel) and the\n")
cat("  monthly MAPE for the inertial scenario (the metric where they do not). Reported\n")
cat("  on the same footing, SARIMA wins on the cumulative total and LOSES on the\n")
cat("  month-by-month allocation, 7.8% against 4.6%. Both metrics, both models.\n")
