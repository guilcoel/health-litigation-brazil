## Decision 2 — the optimistic scenario: implemented rule vs the declared equation
suppressMessages({library(readr); library(dplyr)})

bp    <- read_csv("data/ans_beneficiaries_projected.csv", show_col_types = FALSE)
benef <- setNames(bp$benef, bp$ano)
rate_2025 <- 341763 / 52900000 * 1000
g0    <- 0.1886
years <- 2026:2040

project <- function(rule) {
  tau  <- years - 2025
  g    <- rule(tau)
  rate <- rate_2025 * cumprod(1 + g)
  tibble(year = years, g = g, rate = rate,
         claims = round(rate * benef[as.character(years)] / 1000))
}
## exactly as coded in the legacy pipeline
implemented <- function(tau)
  ifelse(tau <= 3, g0 * pmax(0, (1 - tau/3) * 0.4),
  ifelse(tau <= 8, -0.03, -0.02))
## exactly as written in the Methods, at tau_d = 3
declared <- function(tau) pmax(0, g0 * (1 - tau/3))

imp <- project(implemented); dec <- project(declared)
at  <- function(df, y, col) df[[col]][df$year == y]

cat("=== Optimistic scenario: implemented rule vs declared equation (tau_d = 3) ===\n")
cat(sprintf("  %-34s %10s %10s %10s\n", "", "2030", "2035", "2040"))
cat(sprintf("  %-34s %10.0f %10.0f %10.0f\n", "As implemented (published figures)",
            at(imp,2030,"claims"), at(imp,2035,"claims"), at(imp,2040,"claims")))
cat(sprintf("  %-34s %10.0f %10.0f %10.0f\n", "Declared equation at tau_d = 3",
            at(dec,2030,"claims"), at(dec,2035,"claims"), at(dec,2040,"claims")))
cat(sprintf("  %-34s %10.0f %10.0f %10.0f\n", "Difference",
            at(dec,2030,"claims") - at(imp,2030,"claims"),
            at(dec,2035,"claims") - at(imp,2035,"claims"),
            at(dec,2040,"claims") - at(imp,2040,"claims")))
cat("\n  Published: 390,042 at 2030 and 364,961 at 2035.\n")
cat("  The reviewer recomputed approximately 461,000 from the equation. He is right.\n")

cat("\n=== Four descriptions of the year-1 growth rate ===\n")
cat(sprintf("  %-46s %8s\n", "source", "share of g0"))
cat(sprintf("  %-46s %7.1f%%\n", "Text of the scenarios section, 'a 60% reduction'", 40))
cat(sprintf("  %-46s %7.1f%%\n", "Table 2, 'falls to 60% of g0'", 60))
cat(sprintf("  %-46s %7.1f%%\n", "Declared equation at tau_d = 3", dec$g[1]/g0*100))
cat(sprintf("  %-46s %7.1f%%\n", "What the code does", imp$g[1]/g0*100))

cat("\n=== The shape of the two trajectories ===\n")
cat(sprintf("  Implemented: peaks at %.3f per 1,000 in %d, then declines to %.3f by 2040.\n",
            max(imp$rate), imp$year[which.max(imp$rate)], at(imp,2040,"rate")))
cat(sprintf("  Declared   : stabilises at %.3f per 1,000 from 2028 onward.\n", at(dec,2029,"rate")))
cat("  Sustained decline versus a plateau: qualitatively different stories.\n")
