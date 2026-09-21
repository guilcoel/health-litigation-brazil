## Scenario engine as implemented, and the response surface as declared
## Reproduces Table 3 and produces the year-by-year optimistic trajectory (Reviewer 2, comment 2)
suppressMessages({library(readr); library(dplyr)})

bp    <- read_csv("data/ans_beneficiaries_projected.csv", show_col_types = FALSE)
benef <- setNames(bp$benef, bp$ano)
taxa_2025 <- 341763 / 52900000 * 1000   ## 6.46055 claims per 1,000
g0 <- 0.1886                            ## log-linear monthly estimate, annualised

proj <- function(rule, anos = 2026:2040) {
  tau <- anos - 2025
  g <- rule(tau, g0)
  taxa <- taxa_2025 * cumprod(1 + g)
  tibble(ano = anos, tau = tau, growth = g, rate = taxa,
         claims = round(taxa * benef[as.character(anos)] / 1000))
}

## Implemented rules, transcribed from the original pipeline
inertial    <- function(tau, g0) pmax(0, g0 * (1 - tau/12))
pessimistic <- function(tau, g0) pmax(0, g0 * (1 - tau/20))
optimistic  <- function(tau, g0) ifelse(tau <= 3, g0 * pmax(0, (1 - tau/3) * 0.4),
                                 ifelse(tau <= 8, -0.03, -0.02))
## The damping function as DECLARED in the manuscript, for any horizon
declared    <- function(td) function(tau, g0) pmax(0, g0 * (1 - tau/td))

opt <- proj(optimistic); ine <- proj(inertial); pes <- proj(pessimistic)

cat("Table 3 reproduction (published -> reproduced)\n")
cat(sprintf("  Optimistic  2030: 390 042 -> %d | 2035:   364 961 -> %d\n",
            opt$claims[opt$ano==2030], opt$claims[opt$ano==2035]))
cat(sprintf("  Inertial    2030: 745 323 -> %d | 2035: 1 078 034 -> %d\n",
            ine$claims[ine$ano==2030], ine$claims[ine$ano==2035]))
cat(sprintf("  Pessimistic 2030: 809 467 -> %d | 2035: 1 476 388 -> %d\n\n",
            pes$claims[pes$ano==2030], pes$claims[pes$ano==2035]))

cat("Optimistic trajectory, year by year\n")
print(as.data.frame(opt |> filter(ano <= 2035) |>
  mutate(growth_pct = round(growth*100, 3), rate = round(rate, 3)) |>
  select(ano, tau, growth_pct, rate, claims)))
cat(sprintf("\nYear 1 growth is %.2f%% of g0; the text implies 40%% and Table 2 states 60%%.\n",
            opt$growth[1]/g0*100))

cat("\nResponse surface from the declared damping function, 2030 claims\n")
surf <- sapply(3:20, function(td) { d <- proj(declared(td)); d$claims[d$ano == 2030] })
names(surf) <- 3:20; print(surf)
rng <- max(surf) - min(surf)
cat(sprintf("\n  range over tau_d 3-20 : %.0f  (reported policy range: 419 425)\n", rng))
cat(sprintf("  average change per year: %.0f  (reported: 18 700)\n", rng/17))
cat(sprintf("  policy-to-market ratio : %.2f:1  (reported: 6.3:1; market range 66 918)\n", rng/66918))
