## R2.3 — the response surface and what "18 700 claims per year of delay" actually is
## (Reviewer 2, comment 3)
suppressMessages({library(readr)})

bp    <- read_csv("data/ans_beneficiaries_projected.csv", show_col_types = FALSE)
benef <- setNames(bp$benef, bp$ano)

rate_2025 <- 341763 / 52900000 * 1000
g0        <- 0.1886

## The damping rule exactly as DECLARED in the manuscript, equation in section on scenarios:
##   g(tau | tau_d) = max{0, g0 * (1 - tau/tau_d)}
claims_2030 <- function(tau_d) {
  tau  <- 1:5                                   # 2026..2030
  rate <- rate_2025 * prod(1 + pmax(0, g0 * (1 - tau/tau_d)))
  round(rate * benef["2030"] / 1000)
}

td <- 3:20
v  <- vapply(td, claims_2030, numeric(1))

cat("=== Response surface at 2030, from the declared equation ===\n")
print(setNames(v, td))

rng <- max(v) - min(v)
fit <- lm(v ~ td)
local_12 <- (claims_2030(13) - claims_2030(11))/2

cat(sprintf("\n  Range over tau_d 3 to 20              : %.0f claims\n", rng))
cat(sprintf("  Slope of a linear fit to the surface  : %.0f per year of tau_d (R2 %.3f)\n",
            coef(fit)[2], summary(fit)$r.squared))
cat(sprintf("  Chord average (range / 17 years)      : %.0f per year\n", rng/(max(td) - min(td))))
cat(sprintf("  Local slope at the inertial scenario  : %.0f per year (tau_d = 12)\n", local_12))
cat(sprintf("  Local slope at the optimistic end     : %.0f per year (tau_d = 4)\n",
            (claims_2030(5) - claims_2030(3))/2))

cat("\n  The published figure of 18,700 is the linear-fit slope, and it reproduces.\n")
cat("  But R2 = 0.875 means the surface is visibly curved, so a single slope overstates\n")
cat("  the marginal effect near the inertial scenario (13,000, not 19,000) and understates\n")
cat("  it at the optimistic end. Reported as a constant 'per year of delay' it reads as a\n")
cat("  marginal effect that holds everywhere, which it does not.\n")

cat("\n=== For the policy-to-market ratio ===\n")
cat(sprintf("  Policy range, response surface (declared equation) : %.0f\n", rng))
cat(sprintf("  Policy range, spread between nominal scenarios     : %.0f\n", 809467 - 390042))
cat("  Market range, formal ceiling distribution          : 74396  (scripts/05)\n")
cat(sprintf("  Ratio, surface / formal market                     : %.2f to 1\n", rng/74396))
cat("  Hence 'roughly fivefold' rather than '6.3 to 1' in the Abstract.\n")
