## 18 — State courts on a COMMON estimation window (Sep 2020 – Dec 2025, n = 64)
##
## Why this script exists: scripts/13_state_courts.R built every state series with
##   ts(s$new_claims, start = c(2020, 1), frequency = 12)
## but the Acre series begins in September 2020, not January. Acre was therefore
## mis-dated by eight months, which (a) shifted its seasonal alignment and
## (b) silently shrank its holdout from 12 months to 4. The three courts were not
## run through an identical pipeline, which is exactly what the manuscript claims.
##
## Decision taken: restrict ALL THREE courts to the common window 2020-09 .. 2025-12
## (64 observations each), so the pipeline is identical by construction.
##
## R 4.3.3, forecast 8.21.1.

suppressMessages({library(readr); library(dplyr); library(forecast)})
set.seed(42)

d <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  arrange(date)

COURTS     <- c("SP", "GO", "AC")
WIN_START  <- as.Date("2020-09-01")
WIN_END    <- as.Date("2025-12-01")
TS_START   <- c(2020, 9)
TRAIN_END  <- c(2024, 12)
TEST_START <- c(2025, 1)

## ---------------------------------------------------------------------------
## 0. Document the bug: true coverage of each raw series
## ---------------------------------------------------------------------------
cat("=== 0. Raw series coverage (through Dec 2025) ===\n")
for (uf in c("National", COURTS)) {
  s <- d |> filter(scope == uf, date <= WIN_END)
  cat(sprintf("  %-9s %s .. %s   n = %2d\n", uf,
              format(min(s$date), "%Y-%m"), format(max(s$date), "%Y-%m"), nrow(s)))
}
cat("\n  Acre begins in 2020-09. Labelling it start = c(2020,1), as script 13 did,\n")
cat("  places its last observation in 2025-04 and leaves only 4 test months.\n")

## ---------------------------------------------------------------------------
## Helper: fit on the training part, score on a 12-month holdout
## ---------------------------------------------------------------------------
assess <- function(y) {
  ytr <- window(y, end = TRAIN_END)
  yte <- window(y, start = TEST_START)
  f   <- auto.arima(ytr, ic = "aicc", stepwise = TRUE)
  fc  <- forecast(f, h = length(yte), level = 95)
  o   <- arimaorder(f)
  ord <- sprintf("(%s)(%s)", paste(o[1:3], collapse = ","),
                 if (is.na(o[4])) "none" else paste(o[4:6], collapse = ","))
  list(n_train = length(ytr), n_test = length(yte), order = ord,
       drift = "drift" %in% names(coef(f)),
       dD    = o[1 + 1] + ifelse(is.na(o[5]), 0, o[5]),
       mape  = mean(abs((yte - fc$mean) / yte)) * 100,
       width = mean((fc$upper - fc$lower) / pmax(abs(fc$mean), 1e-9)),
       zero  = any(fc$lower < 0))
}

report <- function(tag, series_list) {
  cat(sprintf("\n=== %s ===\n", tag))
  cat(sprintf("  %-3s %-7s %-7s %-20s %-6s %8s %8s %8s\n",
              "UF", "n_train", "n_test", "order", "drift", "MAPE", "width", "zero"))
  for (uf in names(series_list)) {
    r <- assess(series_list[[uf]])
    cat(sprintf("  %-3s %-7d %-7d %-20s %-6s %7.1f%% %8.2f %8s\n",
                uf, r$n_train, r$n_test, r$order, ifelse(r$drift, "yes", "no"),
                r$mape, r$width, ifelse(r$zero, "YES", "no")))
  }
}

## ---------------------------------------------------------------------------
## 1. The common window, 64 observations each — the specification now adopted
## ---------------------------------------------------------------------------
common <- list()
for (uf in COURTS) {
  s <- d |> filter(scope == uf, date >= WIN_START, date <= WIN_END) |> arrange(date)
  stopifnot(nrow(s) == 64)
  common[[uf]] <- ts(s$new_claims, start = TS_START, frequency = 12)
}
report("1. COMMON WINDOW 2020-09 .. 2025-12 (n = 64 each) — ADOPTED", common)

cat("\n  Mean monthly volume over the common window:\n")
for (uf in COURTS)
  cat(sprintf("    %-3s %8.0f claims/month\n", uf, mean(common[[uf]])))
cat(sprintf("    Spread: %.0f-fold between the largest and smallest court.\n",
            mean(common[["SP"]]) / mean(common[["AC"]])))

## ---------------------------------------------------------------------------
## 2. What script 13 actually did, for the record
## ---------------------------------------------------------------------------
buggy <- list()
for (uf in COURTS) {
  s <- d |> filter(scope == uf, date <= WIN_END) |> arrange(date)
  buggy[[uf]] <- ts(s$new_claims, start = c(2020, 1), frequency = 12)  # the bug
}
report("2. AS RUN IN SCRIPT 13 (mis-dated; SP/GO full 72, AC mis-dated 64)", buggy)

## ---------------------------------------------------------------------------
## 3. SP and GO on their full series, to isolate the cost of truncation
## ---------------------------------------------------------------------------
full <- list()
for (uf in c("SP", "GO")) {
  s <- d |> filter(scope == uf, date <= WIN_END) |> arrange(date)
  full[[uf]] <- ts(s$new_claims, start = c(2020, 1), frequency = 12)
}
report("3. SP and GO on the FULL series (n = 72) — correctly dated", full)

## ---------------------------------------------------------------------------
## 4. Projection horizon: interval behaviour at 2030 on the common window
## ---------------------------------------------------------------------------
cat("\n=== 4. Projection to 2030, fitted on the full common window (n = 64) ===\n")
cat(sprintf("  %-3s %10s %12s %12s %8s %8s\n",
            "UF", "2030 pt", "95% lower", "95% upper", "rel.w", "zero"))
for (uf in COURTS) {
  f  <- auto.arima(common[[uf]], ic = "aicc", stepwise = TRUE)
  fc <- forecast(f, h = 60, level = 95)          # 2026-01 .. 2030-12
  k  <- 49:60                                     # calendar year 2030
  pt <- sum(fc$mean[k]); lo <- sum(fc$lower[k]); hi <- sum(fc$upper[k])
  cat(sprintf("  %-3s %10.0f %12.0f %12.0f %8.2f %8s\n",
              uf, pt, lo, hi, (hi - lo) / pt, ifelse(lo < 0, "YES", "no")))
}

## ---------------------------------------------------------------------------
## 5. Acre: is the 12-month holdout itself informative at this volume?
## ---------------------------------------------------------------------------
cat("\n=== 5. Acre, holdout detail ===\n")
y   <- common[["AC"]]
ytr <- window(y, end = TRAIN_END); yte <- window(y, start = TEST_START)
f   <- auto.arima(ytr, ic = "aicc", stepwise = TRUE)
fc  <- forecast(f, h = 12, level = 95)
err <- abs((yte - fc$mean) / yte) * 100
cat(sprintf("  monthly absolute percentage errors: %s\n",
            paste(sprintf("%.0f", err), collapse = ", ")))
cat(sprintf("  min %.1f%%  max %.1f%%  mean %.1f%%\n", min(err), max(err), mean(err)))
cat(sprintf("  observed 2025 total %d, predicted %.0f (%.1f%% on the annual total)\n",
            sum(yte), sum(fc$mean), abs(sum(fc$mean) - sum(yte)) / sum(yte) * 100))

cat("\nDone.\n")
