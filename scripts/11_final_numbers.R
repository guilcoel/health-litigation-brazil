## Consolidated recomputation under the two decisions taken on 21 September 2026:
##   (1) official ANS beneficiary denominators
##   (2) the optimistic scenario follows the equation as declared in the Methods
## This script produces every headline number for the revised manuscript.
suppressMessages({library(readr); library(dplyr); library(forecast)})

d  <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  filter(scope == "National") |> arrange(date)
train <- d |> filter(date <  as.Date("2026-01-01"))
test  <- d |> filter(date >= as.Date("2026-01-01"))
bp    <- read_csv("data/ans_beneficiaries_projected.csv", show_col_types = FALSE)
pop   <- setNames(bp$pop, bp$ano)

## Decision 1: the official ANS series
benef <- c(`2020`=47939243, `2021`=49274613, `2022`=50530569,
           `2023`=51254745, `2024`=51956946, `2025`=52865947)

## ---------------------------------------------------------------------------
## 1. Rates and the base growth rate
## ---------------------------------------------------------------------------
cat("=== 1. Observed rates and base growth ===\n")
annual <- train |> mutate(year = as.integer(format(date, "%Y"))) |>
  group_by(year) |> summarise(claims = sum(new_claims), .groups = "drop") |>
  mutate(benef = benef[as.character(year)], rate = claims/benef*1000)
for (i in seq_len(nrow(annual)))
  cat(sprintf("  %d: %7.0f claims / %11.0f beneficiaries = %.3f per 1,000\n",
              annual$year[i], annual$claims[i], annual$benef[i], annual$rate[i]))

bb <- approx(seq(6, 66, by = 12), benef, xout = 1:72, rule = 2)$y
tx <- train$new_claims / bb * 1000
mm <- lm(log(tx) ~ I(1:72) + factor(rep(1:12, 6)))
th <- unname(coef(mm)[2])
g0 <- exp(th*12) - 1
se_g0 <- 12 * exp(th*12) * summary(mm)$coefficients[2, 2]
rate_2025 <- annual$rate[annual$year == 2025]
sigma_annual <- sigma(lm(log(rate) ~ year, data = annual))

cat(sprintf("\n  Base growth g0 = %.2f%% per year (delta-method SE %.2f pp)\n", g0*100, se_g0*100))
cat(sprintf("  Rate rose from %.2f to %.2f per 1,000 between 2020 and 2025\n",
            annual$rate[1], rate_2025))
cat(sprintf("  sigma of the annual log-linear model = %.4f\n", sigma_annual))

## ---------------------------------------------------------------------------
## 2. Beneficiary projection, rebuilt on the ANS coverage series
## ---------------------------------------------------------------------------
cat("\n=== 2. Beneficiary projection (logit-linear, cap 0.29) ===\n")
obs <- tibble(year = 2020:2025, cob = benef/pop[as.character(2020:2025)], t = 0:5)
lm_cob <- lm(log(cob/(1 - cob)) ~ t, data = obs)
years  <- 2026:2040
cob_free <- plogis(predict(lm_cob, newdata = data.frame(t = years - 2020)))
cob_cap  <- pmin(cob_free, 0.29)
bproj    <- setNames(cob_cap * pop[as.character(years)], years)
cat(sprintf("  observed coverage 2020 %.5f -> 2025 %.5f\n", obs$cob[1], obs$cob[6]))
for (y in c(2026, 2030, 2035, 2040))
  cat(sprintf("  %d: coverage %.5f | beneficiaries %11.0f\n", y,
              cob_cap[years == y], bproj[as.character(y)]))
cat(sprintf("  the cap binds from %d (was 2033 on the old series)\n",
            years[which(cob_free >= 0.29)[1]]))

## ---------------------------------------------------------------------------
## 3. SARIMA
## ---------------------------------------------------------------------------
cat("\n=== 3. SARIMA, driftless ARIMA(0,1,1)(0,1,0)[12] ===\n")
rate_ts <- ts(tx, start = c(2020, 1), frequency = 12)
fit  <- Arima(rate_ts, order = c(0,1,1), seasonal = list(order = c(0,1,0), period = 12))
cat(sprintf("  ma1 = %.4f (SE %.4f)\n", coef(fit)[1], sqrt(fit$var.coef[1,1])))
fc <- forecast(fit, h = 180, level = 95)
for (y in c(2030, 2035)) {
  i  <- ((y - 2026)*12 + 1):((y - 2026)*12 + 12)
  bn <- bproj[as.character(y)]/1000
  cat(sprintf("  %d: %8.0f claims [%8.0f, %8.0f] | rel. width %.2f\n", y,
              sum(fc$mean[i])*bn, sum(fc$lower[i])*bn, sum(fc$upper[i])*bn,
              (sum(fc$upper[i]) - sum(fc$lower[i]))/sum(fc$mean[i])))
}

## ---------------------------------------------------------------------------
## 4. Scenarios — Decision 2: all three from the declared equation
## ---------------------------------------------------------------------------
cat("\n=== 4. Scenarios, all from g(tau|tau_d) = max{0, g0(1 - tau/tau_d)} ===\n")
claims_at <- function(tau_d, y) {
  tau  <- 1:(y - 2025)
  rate <- rate_2025 * prod(1 + pmax(0, g0 * (1 - tau/tau_d)))
  round(rate * bproj[as.character(y)] / 1000)
}
rate_at <- function(tau_d, y) {
  tau <- 1:(y - 2025)
  rate_2025 * prod(1 + pmax(0, g0 * (1 - tau/tau_d)))
}
scen <- tibble(
  scenario = c("Optimistic", "Inertial", "Pessimistic"), tau_d = c(3, 12, 20),
  claims_2030 = vapply(c(3,12,20), claims_at, numeric(1), y = 2030),
  rate_2030   = vapply(c(3,12,20), rate_at,   numeric(1), y = 2030),
  claims_2035 = vapply(c(3,12,20), claims_at, numeric(1), y = 2035),
  rate_2035   = vapply(c(3,12,20), rate_at,   numeric(1), y = 2035))
cat(sprintf("  %-12s %6s %12s %8s %12s %8s\n", "scenario", "tau_d",
            "2030 claims", "2030 rate", "2035 claims", "2035 rate"))
for (i in 1:3)
  cat(sprintf("  %-12s %6d %12.0f %8.2f %12.0f %8.2f\n", scen$scenario[i], scen$tau_d[i],
              scen$claims_2030[i], scen$rate_2030[i], scen$claims_2035[i], scen$rate_2035[i]))
cat("  (published, old denominators and the piecewise optimistic rule:\n")
cat("   390,042 / 745,323 / 809,467 at 2030; 364,961 / 1,078,034 / 1,476,388 at 2035)\n")
cat("  The optimistic scenario now stabilises rather than declining: no post-2030 kink.\n")

## ---------------------------------------------------------------------------
## 5. Response surface and its slope
## ---------------------------------------------------------------------------
cat("\n=== 5. Response surface at 2030 ===\n")
td <- 3:20
v  <- vapply(td, claims_at, numeric(1), y = 2030)
print(setNames(v, td))
policy_range <- max(v) - min(v)
slope_fit    <- unname(coef(lm(v ~ td))[2])
r2_fit       <- summary(lm(v ~ td))$r.squared
slope_12     <- (claims_at(13, 2030) - claims_at(11, 2030))/2
cat(sprintf("\n  policy range          : %.0f claims\n", policy_range))
cat(sprintf("  linear-fit slope      : %.0f per year of tau_d (R2 %.3f)\n", slope_fit, r2_fit))
cat(sprintf("  local slope at tau_d 12: %.0f per year\n", slope_12))

## ---------------------------------------------------------------------------
## 6. Bootstrap
## ---------------------------------------------------------------------------
cat("\n=== 6. Parametric bootstrap, inertial 2030 ===\n")
set.seed(42); n <- 2000; proj_years <- 2026:2040
M <- numeric(n)
for (i in 1:n) {
  g  <- rnorm(1, g0, se_g0)
  tb <- rate_2025 * exp(rnorm(1, 0, sigma_annual * 0.5))
  for (j in seq_along(proj_years)) {
    tau <- proj_years[j] - 2025
    tb  <- min(tb * (1 + g*max(0, 1 - tau/12)) * exp(rnorm(1, 0, sigma_annual)), 25)
    if (proj_years[j] == 2030) M[i] <- tb * bproj["2030"]/1000
  }
}
q <- quantile(M, c(.025, .5, .975))
cat(sprintf("  median %.0f | 95%% %.0f to %.0f | width %.0f\n", q[2], q[1], q[3], q[3] - q[1]))
cat("  (published: 511,204 to 1,074,782, median 742,791)\n")

## ---------------------------------------------------------------------------
## 7. Market-size range and the policy-to-market ratio
## ---------------------------------------------------------------------------
cat("\n=== 7. Market size and the ratio ===\n")
set.seed(42); nk <- 20000
Ks <- numeric(0)
while (length(Ks) < nk) { x <- rnorm(nk, 0.287, 0.02); Ks <- c(Ks, x[x >= 0.20 & x <= 0.35]) }
Ks <- Ks[1:nk]
c30 <- rate_at(12, 2030) * pmin(cob_free[years == 2030], Ks) * pop["2030"]/1000
qk  <- quantile(c30, c(.025, .5, .975))
market_range <- unname(qk[3] - qk[1])
cat(sprintf("  ceiling binds in %.1f%% of draws at 2030\n", mean(Ks < cob_free[years == 2030])*100))
cat(sprintf("  inertial 2030: median %.0f | 95%% %.0f to %.0f | width %.0f\n",
            qk[2], qk[1], qk[3], market_range))
cat(sprintf("  policy %.0f / market %.0f = %.2f to 1\n",
            policy_range, market_range, policy_range/market_range))
cat("  NOTE: under the final numbers the ratio returns to roughly 6.4 to 1, close to the\n")
cat("  published 6.3. The market range shrank (55,584 against 74,396 on the old coverage\n")
cat("  series) because the cap now binds from 2036 rather than 2033, so it bites in 16.7%\n")
cat("  of draws at 2030 instead of 27.0%. The caution stands even though the number does\n")
cat("  not move: the ratio depends on how both ranges are defined, so report it as an\n")
cat("  approximate magnitude with both definitions stated, not as a precise quantity.\n")

## ---------------------------------------------------------------------------
## 8. Out-of-sample validation, January to May 2026
## ---------------------------------------------------------------------------
cat("\n=== 8. Out-of-sample, Jan-May 2026 ===\n")
fc5  <- forecast(fit, h = nrow(test))
pred <- as.numeric(fc5$mean) * rep(bproj["2026"], nrow(test)) / 1000
inert <- rate_at(12, 2026) * bproj["2026"] / 1000
seas  <- train |> mutate(m = as.integer(format(date, "%m")), y = as.integer(format(date, "%Y"))) |>
  group_by(y) |> mutate(sh = new_claims/sum(new_claims)) |> group_by(m) |>
  summarise(sh = mean(sh), .groups = "drop")
pred_i <- inert * seas$sh[1:nrow(test)]
cat(sprintf("  observed total      : %.0f\n", sum(test$new_claims)))
cat(sprintf("  SARIMA   : total %.0f | cumulative %+.2f%% | monthly MAPE %.2f%%\n",
            sum(pred), (sum(pred)/sum(test$new_claims) - 1)*100,
            mean(abs((pred - test$new_claims)/test$new_claims))*100))
cat(sprintf("  Inertial : total %.0f | cumulative %+.2f%% | monthly MAPE %.2f%%\n",
            sum(pred_i), (sum(pred_i)/sum(test$new_claims) - 1)*100,
            mean(abs((pred_i - test$new_claims)/test$new_claims))*100))
cat("  Beneficiaries for these months: projected 2026 annual count held constant.\n")
