## Table S1 reproduction: four forecasting models, 60-month training, 12-month holdout
## Projecting Health Litigation in Supplementary Health Insurance (BMC Health Services Research)
suppressMessages({library(forecast); library(readr); library(dplyr); library(MASS)})
set.seed(42)

serie <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  filter(scope == "National", date < as.Date("2026-01-01")) |> arrange(date)
stopifnot(nrow(serie) == 72, sum(serie$new_claims) == 1328415)

benef <- read_csv("data/ans_hospital_medical_beneficiaries_annual.csv", show_col_types = FALSE)
## monthly denominator by linear interpolation between annual (December) positions
b <- approx(x = seq(6, 66, by = 12), y = benef$benef_mh, xout = 1:72, rule = 2)$y
taxa <- ts(serie$new_claims / b * 1000, start = c(2020, 1), frequency = 12)

tr <- window(taxa, end = c(2024, 12)); te <- window(taxa, start = c(2025, 1))
mape <- function(a, f) mean(abs((a - f)/a)) * 100

## M1 SARIMA, automatic order selection by AICc
m1 <- auto.arima(tr, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
cat("M1 SARIMA call :", deparse(m1$call), "\n")
cat("   order       : ", sprintf("(%d,%d,%d)(%d,%d,%d)[%d]",
    m1$arma[1], m1$arma[6], m1$arma[2], m1$arma[3], m1$arma[7], m1$arma[4], m1$arma[5]), "\n")
cat("   coefficients: ", paste(names(coef(m1)), collapse = ", "), "\n")
cat("   drift fitted: ", "drift" %in% names(coef(m1)), "\n")
cat("   MAPE holdout: ", sprintf("%.2f%%", mape(te, forecast(m1, h = 12)$mean)), "\n\n")
print(summary(m1))

## Documented check: the specification reported in Supplementary Table S1 cannot carry a drift term.
cat("\n-- attempting the reported (0,1,1)(0,1,0)[12] WITH drift --\n")
print(tryCatch(Arima(tr, order = c(0,1,1), seasonal = c(0,1,0), include.drift = TRUE),
               warning = function(w) conditionMessage(w)))

## M2 ETS, M3 log-linear with calendar-month indicators, M4 negative-binomial GLM with offset
cat("\nM2 ETS        MAPE:", sprintf("%.2f%%", mape(te, forecast(ets(tr), h = 12)$mean)), "\n")
tt <- 1:60; mes <- factor(cycle(tr))
m3 <- lm(log(as.numeric(tr)) ~ tt + mes)
nd <- data.frame(tt = 61:72, mes = factor(1:12, levels = levels(mes)))
cat("M3 log-linear MAPE:", sprintf("%.2f%%", mape(te, exp(predict(m3, newdata = nd)))), "\n")
dd <- data.frame(y = serie$new_claims, tt = 1:72, mes = factor(rep(1:12, 6)), lb = log(b))
m4 <- glm.nb(y ~ tt + mes + offset(lb), data = dd[1:60, ])
cat("M4 GLM-NB     MAPE:", sprintf("%.2f%%",
    mape(dd$y[61:72], predict(m4, newdata = dd[61:72, ], type = "response"))), "\n")

## Base growth rate for the scenarios: log-linear on all 72 monthly observations, annualised
g <- lm(log(as.numeric(taxa)) ~ I(1:72) + factor(rep(1:12, 6)))
cat(sprintf("\nBase growth rate: %.2f%%/year (SE %.2f pp)\n",
    (exp(coef(g)[2]*12) - 1)*100, summary(g)$coefficients[2,2]*12*100))
