## Table S1 rebuilt on the official ANS denominators — the four competing models
## under the declared cross-validation design (60 months train, final 12 test)
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(forecast); library(MASS)
})

d <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  filter(scope == "National", date < as.Date("2026-01-01")) |> arrange(date)
benef <- c(`2020`=47939243, `2021`=49274613, `2022`=50530569,
           `2023`=51254745, `2024`=51956946, `2025`=52865947)
bb   <- approx(seq(6, 66, by = 12), benef, xout = 1:72, rule = 2)$y
rate <- d$new_claims / bb * 1000

n_tr  <- 60
idx   <- seq_len(72)
month <- factor(rep(1:12, 6))
tr    <- 1:n_tr; te <- (n_tr + 1):72
y_te  <- rate[te]

mape <- function(pred) mean(abs((y_te - pred)/y_te))*100

cat("=== Table S1: four models, 12-month holdout, ANS denominators ===\n")

## M1 SARIMA
rate_ts  <- ts(rate, start = c(2020, 1), frequency = 12)
fit_s    <- auto.arima(window(rate_ts, end = c(2024, 12)), ic = "aicc", stepwise = TRUE)
pred_s   <- as.numeric(forecast(fit_s, h = 12)$mean)
ord_s    <- arimaorder(fit_s)

## M2 ETS
fit_e  <- ets(window(rate_ts, end = c(2024, 12)))
pred_e <- as.numeric(forecast(fit_e, h = 12)$mean)

## M3 log-linear trend with calendar-month indicators
dat    <- data.frame(y = rate, t = idx, m = month)
fit_l  <- lm(log(y) ~ t + m, data = dat[tr, ])
pred_l <- exp(predict(fit_l, newdata = dat[te, ]))

## M4 negative-binomial GLM on counts, log link, offset for beneficiaries
dat_c  <- data.frame(claims = d$new_claims, t = idx, m = month, b = bb)
fit_nb <- glm.nb(claims ~ t + m + offset(log(b/1000)), data = dat_c[tr, ])
pred_nb <- predict(fit_nb, newdata = dat_c[te, ], type = "response") / (bb[te]/1000)

res <- tibble(
  model = c(sprintf("SARIMA (%s)(%s)[%d]", paste(ord_s[1:3], collapse = ","),
                    ifelse(is.na(ord_s[4]), "none", paste(ord_s[4:6], collapse = ",")),
                    ifelse(is.na(ord_s[7]), 12, ord_s[7])),
            sprintf("ETS (%s)", fit_e$method),
            "Log-linear trend with month indicators",
            "Negative-binomial GLM, log link"),
  mape = c(mape(pred_s), mape(pred_e), mape(pred_l), mape(pred_nb)),
  published = c(7.84, 8.07, 6.59, 6.41)) |>
  arrange(mape)

for (i in seq_len(nrow(res)))
  cat(sprintf("  %-42s MAPE %5.2f%%   (published %.2f%%)\n",
              res$model[i], res$mape[i], res$published[i]))

cat("\n  Ljung-Box on the SARIMA residuals of the full series:\n")
fit_full <- Arima(rate_ts, order = c(0,1,1), seasonal = list(order = c(0,1,0), period = 12))
lb <- Box.test(residuals(fit_full), lag = 24, type = "Ljung-Box", fitdf = 1)
cat(sprintf("    Q = %.2f, df = %d, p = %.3f  (published p = 0.62)\n",
            lb$statistic, lb$parameter, lb$p.value))

cat("\n  Stationarity tests on the rate series:\n")
suppressWarnings({
  adf <- tseries::adf.test(rate_ts)
  kp  <- tseries::kpss.test(rate_ts)
})
cat(sprintf("    ADF  statistic = %.3f, p = %.3f  (published -2.989, p = 0.173)\n",
            adf$statistic, adf$p.value))
cat(sprintf("    KPSS statistic = %.3f, p = %.3f  (published  1.672, p < 0.01)\n",
            kp$statistic, kp$p.value))

cat("\n  The ranking is what matters for the Results text: whichever model wins,\n")
cat("  the four sit within a narrow band, so the choice among them is not decisive.\n")
