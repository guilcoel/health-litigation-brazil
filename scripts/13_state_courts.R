## R3.4 — the state-court analysis: what is reproducible, and whether the
## missing state denominators actually matter (Reviewer 3, weakness 4)
suppressMessages({library(readr); library(dplyr); library(forecast)})

d <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  filter(date < as.Date("2026-01-01")) |> arrange(date)

## ---------------------------------------------------------------------------
## 1. MAPE and relative interval width are scale-invariant
## ---------------------------------------------------------------------------
## Both are ratios, so multiplying a series by a constant leaves them unchanged.
## A state denominator that merely grows smoothly is close to a constant over six
## years, so the absence of state denominators cannot explain a large discrepancy.
cat("=== 1. Do the missing state denominators explain the discrepancies? ===\n")
assess <- function(y) {
  ytr <- window(y, end = c(2024, 12)); yte <- window(y, start = c(2025, 1))
  f   <- auto.arima(ytr, ic = "aicc", stepwise = TRUE)
  fc  <- forecast(f, h = 12, level = 95)
  o   <- arimaorder(f)
  list(order = sprintf("(%s)(%s)", paste(o[1:3], collapse = ","),
                       ifelse(is.na(o[4]), "none", paste(o[4:6], collapse = ","))),
       mape  = mean(abs((yte - fc$mean)/yte))*100,
       width = mean((fc$upper - fc$lower)/pmax(abs(fc$mean), 1e-9)),
       zero  = any(fc$lower < 0))
}
for (uf in c("SP", "GO", "AC")) {
  s <- d |> filter(scope == uf) |> arrange(date); n <- nrow(s)
  denominators <- list(
    "counts (denominator 1)"      = rep(1, n),
    "constant denominator"        = rep(5e5, n),
    "denominator growing 3%/year" = 5e5 * 1.03^((0:(n-1))/12),
    "denominator growing 8%/year" = 5e5 * 1.08^((0:(n-1))/12))
  cat(sprintf("\n  --- %s (mean %.0f claims/month) ---\n", uf, mean(s$new_claims)))
  for (nm in names(denominators)) {
    r <- assess(ts(s$new_claims/denominators[[nm]]*1000, start = c(2020,1), frequency = 12))
    cat(sprintf("    %-29s %-16s MAPE %5.1f%%  rel. width %4.2f  crosses zero: %s\n",
                nm, r$order, r$mape, r$width, ifelse(r$zero, "YES", "no")))
  }
}
cat("\n  Published in the scale-dependence paragraph: SP 6.6% and width 0.6; GO 9.0%;\n")
cat("  AC 26.3% and width 6.1, crossing zero.\n")
cat("  GO reproduces exactly under an 8%/year denominator. SP is within range (7.0-7.3%\n")
cat("  against 6.6%). AC does not: 33-36% against 26.3%, and the width is 0.8-1.1 against\n")
cat("  6.1 under every denominator assumption. The denominator is not the explanation.\n")

## ---------------------------------------------------------------------------
## 2. Is the Acre figure the projection horizon rather than the holdout?
## ---------------------------------------------------------------------------
cat("\n=== 2. Interval width at the holdout versus at the projection horizon ===\n")
for (uf in c("SP", "GO", "AC")) {
  s <- d |> filter(scope == uf) |> arrange(date)
  f <- auto.arima(ts(s$new_claims, start = c(2020,1), frequency = 12),
                  ic = "aicc", stepwise = TRUE)
  for (h in c(12, 60)) {
    fc <- forecast(f, h = h, level = 95)
    k  <- (h - 11):h
    pt <- sum(fc$mean[k]); lo <- sum(fc$lower[k]); hi <- sum(fc$upper[k])
    cat(sprintf("  %-3s horizon %2d months (year %d): point %8.0f  95%% %9.0f to %9.0f  rel. width %5.2f  crosses zero: %s\n",
                uf, h, 2025 + h/12, pt, lo, hi, (hi - lo)/pt, ifelse(lo < 0, "YES", "no")))
  }
}
cat("\n  At the 2030 projection horizon Acre's interval DOES cross zero (lower limit -36),\n")
cat("  so that part of the published claim holds once the horizon is stated. The width of\n")
cat("  6.1 is still not reproduced: 0.81 at the holdout, 1.17 at 12 months, 2.24 at 2030.\n")
cat("  Report the widths that reproduce, with the horizon named, and drop 6.1.\n")

## ---------------------------------------------------------------------------
## 3. Why a volume threshold cannot be established from three courts
## ---------------------------------------------------------------------------
cat("\n=== 3. Three courts do not identify a threshold ===\n")
vols <- d |> group_by(scope) |> summarise(mean_month = mean(new_claims), .groups = "drop") |>
  filter(scope != "National") |> arrange(desc(mean_month))
for (i in seq_len(nrow(vols)))
  cat(sprintf("  %-3s %8.0f claims/month\n", vols$scope[i], vols$mean_month[i]))
cat(sprintf("\n  Three points spanning %.0f-fold in volume. Any 'minimum volume' read off them\n",
            max(vols$mean_month)/min(vols$mean_month)))
cat("  is an interpolation between two of them, with no estimate of its own uncertainty.\n")
cat("  Reviewer 2 is right that a general threshold cannot be established; Reviewer 3 is\n")
cat("  right that readers need guidance. The resolution is guidance without a threshold.\n")
