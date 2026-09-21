## R3.3 — structural break tests (Reviewer 3, weakness 3)
## Bai-Perron on the seasonally adjusted series, plus Chow tests at candidate policy dates.
suppressMessages({library(readr); library(dplyr); library(strucchange)})

d <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  filter(scope == "National") |> arrange(date)

y   <- log(d$new_claims)
mes <- factor(as.integer(format(d$date, "%m")))
tt  <- seq_along(y)
## the seasonal component is removed first, so each candidate segment needs only two parameters
sa  <- residuals(lm(y ~ mes)) + mean(y)
z   <- ts(sa, start = c(2020, 1), frequency = 12)

cat("== Bai-Perron ==\n"); print(summary(breakpoints(z ~ tt, h = 0.15)))
bp <- breakpoints(z ~ tt, h = 0.15)
cat("\nBIC-selected breakdates:\n")
for (i in bp$breakpoints) cat(sprintf("  %s\n", format(d$date[i], "%b %Y")))
print(confint(bp))

cat("\n== Andrews supF, unknown breakdate ==\n")
print(sctest(z ~ tt, type = "supF", from = 0.15, to = 0.85))

cat("\n== Chow tests at candidate policy dates ==\n")
cand <- c("2022-09-01" = "Law 14.454/2022, exemplificative ROL",
          "2024-02-01" = "date the manuscript assigns to Binding Precedents 60/61",
          "2024-09-01" = "actual publication of Binding Precedents 60/61",
          "2025-09-01" = "ADI 7265 judgment")
for (k in names(cand)) {
  i <- which(d$date == as.Date(k))
  s <- sctest(z ~ tt, type = "Chow", point = i)
  cat(sprintf("  %-10s %-52s F = %7.3f  p = %.4f\n", k, cand[[k]],
              unname(s$statistic), s$p.value))
}

cat("\n== annualised growth by segment ==\n")
lim <- c(0, bp$breakpoints, nrow(d))
for (k in seq_len(length(lim) - 1)) {
  ii <- (lim[k]+1):lim[k+1]
  b <- coef(lm(sa[ii] ~ ii))[2]
  cat(sprintf("  %s to %s (%2d months): %+6.2f%%/year\n",
      format(d$date[min(ii)], "%b %Y"), format(d$date[max(ii)], "%b %Y"),
      length(ii), (exp(b*12)-1)*100))
}
