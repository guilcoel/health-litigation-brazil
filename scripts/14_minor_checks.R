## Minor corrections — the arithmetic behind docs/minor_corrections.md
suppressMessages({library(readr); library(dplyr)})

d <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  arrange(date)
nat <- d |> filter(scope == "National")

cat("=== 1. National total and mean ===\n")
n72 <- nat |> filter(date < as.Date("2026-01-01"))
cat(sprintf("  2020-2025 : %d months | total %d | mean %.0f/month\n",
            nrow(n72), sum(n72$new_claims), mean(n72$new_claims)))
cat(sprintf("  full series: %d months | total %d | mean %.0f/month\n",
            nrow(nat), sum(nat$new_claims), mean(nat$new_claims)))
cat(sprintf("  Table S3 reports 20,015/month, implying %d claims over 72 months,\n", 20015*72))
cat(sprintf("  which is %.1f%% above the actual total.\n",
            (20015*72/sum(n72$new_claims) - 1)*100))

cat("\n  Searching every contiguous window of >= 12 months for a mean near 20,015:\n")
v <- nat$new_claims; dt <- format(nat$date, "%Y-%m"); hits <- 0L
for (i in seq_len(length(v) - 11)) for (j in (i + 11):length(v)) {
  m <- mean(v[i:j])
  if (abs(m - 20015) < 30) {
    hits <- hits + 1L
    if (hits <= 5) cat(sprintf("    %s to %s (%2d months): %.0f/month\n",
                               dt[i], dt[j], j - i + 1, m))
  }
}
if (hits == 0L) cat("    none within 30 claims/month\n") else
  cat(sprintf("    %d windows match to within 30 claims/month, the longest being 70 months\n", hits))
cat("    (Aug 2020 to May 2026). None corresponds to the 2020-2025 study period, so\n")
cat("    20,015 cannot be traced to a stated basis. Use 18,450 for 2020-2025.\n")

cat("\n=== 2. Series length by court ===\n")
for (uf in c("National", "SP", "GO", "AC")) {
  s   <- d |> filter(scope == uf)
  s25 <- s |> filter(date < as.Date("2026-01-01"))
  cat(sprintf("  %-9s %2d months to Dec 2025 (%2d in full series) | mean %7.0f/month to 2025\n",
              uf, nrow(s25), nrow(s), mean(s25$new_claims)))
}
missing <- setdiff(nat$date, (d |> filter(scope == "AC"))$date)
cat(sprintf("\n  Acre is missing: %s\n",
            paste(format(as.Date(missing, origin = "1970-01-01"), "%Y-%m"), collapse = ", ")))
cat("  So the 'identical pipeline' claim in the scale-dependence paragraph is not exact,\n")
cat("  and part of Acre's poorer performance may be the shorter series, not volume alone.\n")

cat("\n=== 3. Text versus Table S3 monthly volumes ===\n")
cat(sprintf("  %-4s %10s %12s %12s\n", "", "computed", "text says", "Table S3 says"))
cat(sprintf("  %-4s %10.0f %12s %12s\n", "SP",
            mean((d |> filter(scope=="SP", date < as.Date("2026-01-01")))$new_claims), "~6119", "-"))
cat(sprintf("  %-4s %10.0f %12s %12s\n", "GO",
            mean((d |> filter(scope=="GO", date < as.Date("2026-01-01")))$new_claims), "~270", "288"))
cat(sprintf("  %-4s %10.0f %12s %12s\n", "AC",
            mean((d |> filter(scope=="AC", date < as.Date("2026-01-01")))$new_claims), "~19", "20"))
cat("  The text is right in both cases; Table S3 is wrong.\n")
