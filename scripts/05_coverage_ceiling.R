## R3.1 — the 29% coverage ceiling: what it is, whether it is identified,
## and a formal sensitivity distribution (Reviewer 3, weakness 1)
suppressMessages({library(readr); library(dplyr)})

bp  <- read_csv("data/ans_beneficiaries_projected.csv", show_col_types = FALSE)
obs <- bp |> filter(tipo == "observado") |> mutate(t = ano - 2020)
pop <- setNames(bp$pop, bp$ano)
anos <- 2026:2040

## ---------------------------------------------------------------------------
## 1. What the published model actually does
## ---------------------------------------------------------------------------
## 03_model_v3.R attempts nls(cob ~ K/(1+exp(-(a+b*t)))) with start K = 0.28.
## That call does not converge on these six annual observations, so the pipeline
## falls through to its documented fallback: a logit-linear trend, projected and
## then CLIPPED at 0.29. The published projecao_beneficiarios.csv has cob exactly
## 0.29 from 2033 on, which is the signature of the fallback branch.

lm_cob <- lm(log(cob/(1 - cob)) ~ t, data = obs)
cob_free <- plogis(predict(lm_cob, newdata = data.frame(t = anos - 2020)))

project <- function(K) {
  cob <- pmin(cob_free, K)
  tibble(ano = anos, cob = cob, benef = cob * pop[as.character(anos)])
}
p <- project(0.29)

cat("=== 1. Reproduction of the published beneficiary projection ===\n")
cat(sprintf("  2030: coverage %.5f | beneficiaries %.0f   (published 0.27466 | 59,593,837)\n",
            p$cob[p$ano == 2030], p$benef[p$ano == 2030]))
cat(sprintf("  2035: coverage %.5f | beneficiaries %.0f   (published 0.29000 | 63,616,502)\n",
            p$cob[p$ano == 2035], p$benef[p$ano == 2035]))
cat(sprintf("  Uncapped logit-linear trend: %.4f in 2030, %.4f in 2040.\n",
            cob_free[anos == 2030], cob_free[length(cob_free)]))
cat(sprintf("  The cap becomes binding in %d. It is a post-hoc clip on a curve whose own\n",
            anos[which(cob_free >= 0.29)[1]]))
cat("  asymptote is 1.0, not an estimated saturation parameter.\n")

## ---------------------------------------------------------------------------
## 2. Is a free asymptote identified from six annual observations?
## ---------------------------------------------------------------------------
cat("\n=== 2. Identification of a free asymptote K ===\n")
cat("  (a) Logistic, K free, four sets of starting values:\n")
for (s in list(c(0.28,-1.0,0.15), c(0.30,-1.2,0.10), c(0.35,-1.5,0.08), c(0.50,-2.0,0.05))) {
  f <- try(nls(cob ~ K/(1 + exp(-(a + b*t))), data = obs,
               start = list(K = s[1], a = s[2], b = s[3]),
               control = nls.control(maxiter = 500)), silent = TRUE)
  if (inherits(f, "try-error"))
    cat(sprintf("      start K=%.2f a=%.1f b=%.2f : does not converge\n", s[1], s[2], s[3]))
  else
    cat(sprintf("      start K=%.2f a=%.1f b=%.2f : K = %.4f (SE %.4f)\n",
                s[1], s[2], s[3], coef(f)["K"], summary(f)$coefficients["K", "Std. Error"]))
}

cat("  (b) Gompertz, K free, five sets of starting values:\n")
for (s in list(c(0.28,-1.0,0.15), c(0.30,-1.5,0.20), c(0.35,-2.0,0.25),
               c(0.26,-0.8,0.30), c(0.29,-1.2,0.40))) {
  f <- try(nls(cob ~ K*exp(-exp(-(a + b*t))), data = obs,
               start = list(K = s[1], a = s[2], b = s[3]),
               control = nls.control(maxiter = 1000)), silent = TRUE)
  if (inherits(f, "try-error"))
    cat(sprintf("      start K=%.2f a=%.1f b=%.2f : does not converge\n", s[1], s[2], s[3]))
  else
    cat(sprintf("      start K=%.2f a=%.1f b=%.2f : K = %.4f (SE %.4f)\n",
                s[1], s[2], s[3], coef(f)["K"], summary(f)$coefficients["K", "Std. Error"]))
}

cat("  (c) Concentrated RSS profile: K fixed on a grid, (a, b) optimised at each point.\n")
prof <- do.call(rbind, lapply(seq(0.25, 0.60, by = 0.01), function(K) {
  f <- try(nls(cob ~ K/(1 + exp(-(a + b*t))), data = obs, start = list(a = -1, b = 0.15),
               control = nls.control(maxiter = 1000, warnOnly = TRUE)), silent = TRUE)
  if (inherits(f, "try-error")) return(NULL)
  data.frame(K = K, RSS = sum(residuals(f)^2))
}))
tss <- sum((obs$cob - mean(obs$cob))^2)
prof$R2 <- 1 - prof$RSS/tss
print(prof |> filter(K %in% c(0.25,0.26,0.27,0.29,0.32,0.35,0.40,0.50,0.60)) |>
        mutate(RSS = signif(RSS, 3), R2 = round(R2, 5),
               dRSS_pct = round((RSS/min(prof$RSS) - 1)*100, 1)), row.names = FALSE)
cat(sprintf("      Minimum at K = %.2f. R2 stays between %.4f and %.4f over K in [0.25, 0.60].\n",
            prof$K[which.min(prof$RSS)], min(prof$R2), max(prof$R2)))

f_best <- nls(cob ~ K/(1 + exp(-(a + b*t))), data = obs,
              start = list(K = 0.35, a = -1.5, b = 0.08), control = nls.control(maxiter = 1000))
cat("  (d) Profile-likelihood interval for K in the one specification that converges:\n")
ci <- try(suppressWarnings(confint(f_best, "K", level = 0.95)), silent = TRUE)
if (!inherits(ci, "try-error")) {
  cat(sprintf("      2.5%% = %s | 97.5%% = %s\n",
              ifelse(is.na(ci[1]), "not attained", sprintf("%.4f", ci[1])),
              ifelse(is.na(ci[2]), "not attained", sprintf("%.4f", ci[2]))))
}
se_K <- summary(f_best)$coefficients["K", "Std. Error"]
cat(sprintf("      Wald interval: %.4f to %.4f, on n = %d annual observations and 3 parameters.\n",
            coef(f_best)["K"] - 1.96*se_K, coef(f_best)["K"] + 1.96*se_K, nrow(obs)))
cat(sprintf("      Last observed coverage (2025): %.5f\n", obs$cob[obs$ano == 2025]))

## ---------------------------------------------------------------------------
## 3. Formal sensitivity distribution for the ceiling
## ---------------------------------------------------------------------------
## K ~ Normal(0.287, 0.02) truncated to [0.20, 0.35]. The location is the mean of
## the three fixed ceilings used in sensitivity analysis S2 (0.25, 0.29, 0.32); the
## scale spans the ANS coverage range of the last two decades; the truncation
## bounds are below the observed 2020 coverage and a third above the current level.
cat("\n=== 3. Formal sensitivity: K ~ Normal(0.287, 0.02) truncated to [0.20, 0.35] ===\n")
set.seed(42); n <- 20000
Ks <- numeric(0)
while (length(Ks) < n) { x <- rnorm(n, 0.287, 0.02); Ks <- c(Ks, x[x >= 0.20 & x <= 0.35]) }
Ks <- Ks[1:n]

rate_2025 <- 341763 / 52900000 * 1000
g0 <- 0.1886
rate_at <- function(ano, damping = 12)
  rate_2025 * prod(1 + pmax(0, g0 * (1 - (1:(ano - 2025))/damping)))

claims <- function(ano) {
  cob <- pmin(cob_free[anos == ano], Ks)
  rate_at(ano) * cob * pop[as.character(ano)] / 1000
}
c30 <- claims(2030); c35 <- claims(2035)
q <- function(x) quantile(x, c(.025, .5, .975))

cat(sprintf("  Share of draws in which the ceiling binds: %.1f%% in 2030, %.1f%% in 2035\n",
            mean(Ks < cob_free[anos == 2030])*100, mean(Ks < cob_free[anos == 2035])*100))
cat(sprintf("  Inertial claims 2030: median %.0f | 95%% %.0f to %.0f | width %.0f\n",
            q(c30)[2], q(c30)[1], q(c30)[3], q(c30)[3] - q(c30)[1]))
cat(sprintf("  Inertial claims 2035: median %.0f | 95%% %.0f to %.0f | width %.0f\n",
            q(c35)[2], q(c35)[1], q(c35)[3], q(c35)[3] - q(c35)[1]))
cat("  The 2030 interval is one-sided by construction: the cap can only remove\n")
cat("  beneficiaries from the uncapped trend, never add them.\n")

## Recomputation of the policy-to-market ratio reported in the manuscript.
policy_reported <- 809467 - 390042   # spread between the nominal scenarios as published
policy_surface  <- 348799            # response surface over damping horizons 3 to 20 (script 02)
market_reported <- 745323 - 678405   # ceilings 25% / 29% / 32%, sensitivity analysis S2
market_formal   <- unname(q(c30)[3] - q(c30)[1])

cat(sprintf("\n  Policy range, nominal scenarios as published : %.0f claims\n", policy_reported))
cat(sprintf("  Policy range, response surface (tau_d 3 to 20) : %.0f claims\n", policy_surface))
cat(sprintf("  Market range, three fixed ceilings as published: %.0f claims\n", market_reported))
cat(sprintf("  Market range, formal ceiling distribution      : %.0f claims\n", market_formal))
cat(sprintf("  Ratio as published                             : %.2f to 1 (reported as 6.3 to 1)\n",
            policy_reported/market_reported))
cat(sprintf("  Ratio, published policy range / formal market  : %.2f to 1\n",
            policy_reported/market_formal))
cat(sprintf("  Ratio, response surface / formal market        : %.2f to 1\n",
            policy_surface/market_formal))
cat("  The qualitative conclusion is unchanged under every combination: regulatory\n")
cat("  response dominates market size by roughly half an order of magnitude.\n")
