## R2.1 + R2.4 — the SARIMA order, the drift term, the prediction interval,
## and the monthly MAPE (Reviewer 2, comments 1 and 4)
suppressMessages({library(readr); library(dplyr); library(forecast)})

d  <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  filter(date < as.Date("2026-01-01"))
bo <- read_csv("data/ans_hospital_medical_beneficiaries_annual.csv", show_col_types = FALSE)
bp <- read_csv("data/ans_beneficiaries_projected.csv", show_col_types = FALSE)
benef_obs  <- setNames(bo$benef_mh, bo$ano)
benef_proj <- setNames(bp$benef, bp$ano)

nat  <- d |> filter(scope == "National") |> arrange(date)
b    <- approx(seq(6, 66, by = 12), benef_obs, xout = nrow(nat) |> seq_len(), rule = 2)$y
rate <- ts(nat$new_claims / b * 1000, start = c(2020, 1), frequency = 12)

## ---------------------------------------------------------------------------
## 1. The order and the drift term
## ---------------------------------------------------------------------------
cat("=== 1. Selected order and the drift term ===\n")
fit_auto <- auto.arima(rate, ic = "aicc", stepwise = TRUE)
o <- arimaorder(fit_auto)
cat(sprintf("  auto.arima selects ARIMA(%s)(%s)[%d]\n",
            paste(o[1:3], collapse = ","), paste(o[4:6], collapse = ","), o[7]))
cat(sprintf("  Fitted coefficients: %s\n", paste(names(coef(fit_auto)), collapse = ", ")))
cat(sprintf("  Drift among them? %s\n", ifelse("drift" %in% names(coef(fit_auto)), "YES", "NO")))
cat("  The manuscript reports the seasonal period as [8]. The selected period is [12].\n")

cat("\n  Forcing drift on the published specification (0,1,1)(0,1,0)[12]:\n")
w <- character(0)
f_drift <- withCallingHandlers(
  Arima(rate, order = c(0,1,1), seasonal = list(order = c(0,1,0), period = 12),
        include.drift = TRUE),
  warning = function(cond) { w <<- c(w, conditionMessage(cond)); invokeRestart("muffleWarning") })
for (m in unique(w)) cat(sprintf("    warning: %s\n", m))
cat(sprintf("    coefficients actually fitted: %s\n", paste(names(coef(f_drift)), collapse = ", ")))
cat("    forecast::Arima never fits a drift when d + D >= 2, on any series.\n")

## ---------------------------------------------------------------------------
## 2. Monthly MAPE (the reviewer asks for it explicitly)
## ---------------------------------------------------------------------------
cat("\n=== 2. Monthly MAPE, temporal cross-validation (60 train / 12 test) ===\n")
tr <- window(rate, end = c(2024, 12)); te <- window(rate, start = c(2025, 1))
fc_te <- forecast(Arima(tr, order = c(0,1,1),
                        seasonal = list(order = c(0,1,0), period = 12)), h = 12)
err <- abs((te - fc_te$mean)/te)*100
cat(sprintf("  Monthly MAPE, driftless (0,1,1)(0,1,0)[12]: %.2f%%  (published 7.84%%)\n", mean(err)))
cat(sprintf("  Range of individual monthly errors: %.2f%% to %.2f%%\n", min(err), max(err)))
cat(sprintf("  Error on the 2025 annual total (point vs observed): %.2f%%\n",
            abs(sum(fc_te$mean) - sum(te))/sum(te)*100))
cat("  The 7.84% in Table S1 is a monthly figure. The annual total is more accurate than\n")
cat("  any single month because month-level errors partly cancel.\n")

## ---------------------------------------------------------------------------
## 3. Is the driftless prediction interval bounded?
## ---------------------------------------------------------------------------
cat("\n=== 3. The driftless prediction interval ===\n")
fit_full <- Arima(rate, order = c(0,1,1), seasonal = list(order = c(0,1,0), period = 12))
fc <- forecast(fit_full, h = 180, level = 95)
for (ano in c(2026, 2028, 2030, 2035)) {
  i  <- ((ano - 2026)*12 + 1):((ano - 2026)*12 + 12)
  pt <- sum(fc$mean[i]); lo <- sum(fc$lower[i]); hi <- sum(fc$upper[i])
  bn <- benef_proj[as.character(ano)]/1000
  cat(sprintf("  %d  rate %6.2f [%7.2f, %6.2f]  rel. width %5.2f  crosses zero: %-3s  claims %8.0f [%8.0f, %8.0f]\n",
              ano, pt, lo, hi, (hi - lo)/pt, ifelse(lo < 0, "YES", "no"), pt*bn, lo*bn, hi*bn))
}
cat("\n  The 2030 point forecast is 672,207 against 671,400 published: 0.12% apart.\n")
cat("  The drift term was never doing the work in the point forecast.\n")
cat("  But the relative width goes from 0.30 in 2026 to 1.28 in 2030 and 2.42 in 2035,\n")
cat("  and the lower limit crosses zero before 2035. 'Bounded relative width' is wrong;\n")
cat("  'does not cross zero over the primary horizon (to 2030)' happens to be true.\n")

## ---------------------------------------------------------------------------
## 4. The state courts and the drift claim in the scale-dependence paragraph
## ---------------------------------------------------------------------------
cat("\n=== 4. State courts: order, drift, and whether drift is even admissible ===\n")
cat("  CAVEAT: these series are COUNTS. The published pipeline modelled the RATE per\n")
cat("  1,000 beneficiaries, and state-level denominators are not in this repository.\n")
cat("  The MAPE and interval widths below are therefore not directly comparable to\n")
cat("  the published state figures and must be rechecked with those denominators.\n")
cat("  The drift result, however, is structural and does not depend on the scale.\n\n")
for (uf in setdiff(unique(d$scope), "National")) {
  s <- d |> filter(scope == uf) |> arrange(date)
  y <- ts(s$new_claims, start = c(2020, 1), frequency = 12)
  f <- auto.arima(y, ic = "aicc", stepwise = TRUE)
  oo <- arimaorder(f); dd <- oo[2]; DD <- ifelse(is.na(oo[5]), 0, oo[5])
  ftr <- auto.arima(window(y, end = c(2024,12)), ic = "aicc", stepwise = TRUE)
  fc2 <- forecast(ftr, h = 12, level = 95)
  yte <- window(y, start = c(2025,1))
  cat(sprintf("  %-4s mean %6.0f/mo  order (%s)(%s)  d+D = %d -> drift %-10s  MAPE %5.1f%%  rel. width %4.1f\n",
              uf, mean(s$new_claims),
              paste(oo[1:3], collapse = ","),
              ifelse(is.na(oo[4]), "none", paste(oo[4:6], collapse = ",")),
              dd + DD, ifelse(dd + DD >= 2, "IMPOSSIBLE", "admissible"),
              mean(abs((yte - fc2$mean)/yte))*100,
              mean((fc2$upper - fc2$lower)/pmax(abs(fc2$mean), 1e-9))))
}

cat("\n  Sao Paulo, forcing D = 0 so that a drift becomes admissible:\n")
ysp <- ts((d |> filter(scope == "SP") |> arrange(date))$new_claims, start = c(2020,1), frequency = 12)
fsp  <- auto.arima(ysp, D = 0, ic = "aicc", stepwise = TRUE, allowdrift = TRUE)
fsp0 <- auto.arima(ysp, ic = "aicc", stepwise = TRUE)
cf <- coef(fsp); se <- sqrt(diag(fsp$var.coef))
cat(sprintf("    order (%s)(%s)[%d], drift = %.2f (SE %.2f), t = %.2f\n",
            paste(arimaorder(fsp)[1:3], collapse = ","),
            paste(arimaorder(fsp)[4:6], collapse = ","), arimaorder(fsp)[7],
            cf["drift"], se["drift"], cf["drift"]/se["drift"]))
cat(sprintf("    AICc with D = 0: %.2f | unrestricted: %.2f | penalty for forcing drift: %.2f\n",
            fsp$aicc, fsp0$aicc, fsp$aicc - fsp0$aicc))
cat("    So a significant drift exists for Sao Paulo only under a specification that\n")
cat("    AICc rejects by roughly 194 points. Automatic selection, which the Methods\n")
cat("    declares, does not choose it.\n")
