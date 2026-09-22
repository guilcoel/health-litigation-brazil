## Figure S1 — the three state courts, as an exploratory comparison
## Plotted as COUNTS: ANS state denominators for 2020-2025 are not available, and
## MAPE and relative interval width are ratios, so the model comparison is
## unaffected by the scale (see docs/state_courts_correction.md).
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(ggplot2)
  library(scales); library(forecast); library(ragg)
})
## Two encoding precautions, both needed because the accented court names would
## otherwise be corrupted:
##  - the devices are named explicitly (ragg for PNG and TIFF, cairo for PDF);
##  - the labels use Unicode escapes rather than literal accented bytes, so the
##    script renders correctly even where the locale is not UTF-8 (a C/POSIX
##    locale makes R read its own source as single-byte and mangles the names).

STAMP   <- "v3_20260921"
fig_dir <- "figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

INK <- "#0b0b0b"; INK_SOFT <- "#52514e"; SERIES <- "#2a78d6"; BAND <- "#2a78d6"

theme_pub <- theme_minimal(base_size = 11) +
  theme(plot.title = element_blank(),
        axis.title = element_text(size = 10, colour = INK),
        axis.text  = element_text(size = 9,  colour = INK_SOFT),
        strip.text = element_text(size = 10, colour = INK, face = "bold"),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(linewidth = 0.25, colour = "grey88"),
        legend.position = "none")

d <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  arrange(date)

courts <- tibble(
  scope = c("SP", "GO", "AC"),
  label = c("São Paulo — high volume",
            "Goiás — medium volume",
            "Acre — low volume"))

obs <- d |> filter(scope %in% courts$scope) |>
  left_join(courts, by = "scope") |>
  mutate(label = factor(label, levels = courts$label))

## fit on the observations up to Dec 2025, forecast the 12 months of 2026
fc_all <- lapply(courts$scope, function(uf) {
  s  <- d |> filter(scope == uf, date < as.Date("2026-01-01")) |> arrange(date)
  y  <- ts(s$new_claims, start = c(as.integer(format(min(s$date), "%Y")),
                                   as.integer(format(min(s$date), "%m"))), frequency = 12)
  f  <- auto.arima(y, ic = "aicc", stepwise = TRUE)
  fc <- forecast(f, h = 12, level = 95)
  tibble(scope = uf,
         date  = seq(as.Date("2026-01-01"), by = "month", length.out = 12),
         mean  = as.numeric(fc$mean),
         lo    = pmax(0, as.numeric(fc$lower)),
         hi    = as.numeric(fc$upper),
         n_obs = length(y),
         order = sprintf("(%s)(%s)", paste(arimaorder(f)[1:3], collapse = ","),
                         ifelse(is.na(arimaorder(f)[4]), "none",
                                paste(arimaorder(f)[4:6], collapse = ","))))
}) |> bind_rows() |> left_join(courts, by = "scope") |>
  mutate(label = factor(label, levels = courts$label))

figS1 <- ggplot() +
  geom_ribbon(data = fc_all, aes(date, ymin = lo, ymax = hi), fill = BAND, alpha = 0.16) +
  geom_line(data = fc_all, aes(date, mean), colour = SERIES, linewidth = 0.6,
            linetype = "longdash") +
  geom_line(data = obs, aes(date, new_claims), colour = INK, linewidth = 0.5) +
  geom_vline(xintercept = as.Date("2026-01-01"), linetype = "dotted",
             linewidth = 0.4, colour = INK_SOFT) +
  facet_wrap(~ label, ncol = 1, scales = "free_y") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = label_number(big.mark = " "), limits = c(0, NA)) +
  labs(x = NULL, y = "New judicial claims per month") +
  theme_pub

ggsave(file.path(fig_dir, paste0("figS1_state_courts_", STAMP, ".png")), figS1,
       width = 6.8, height = 7.2, dpi = 300, bg = "white", device = ragg::agg_png)
ggsave(file.path(fig_dir, paste0("figS1_state_courts_", STAMP, ".pdf")), figS1,
       width = 6.8, height = 7.2, device = cairo_pdf)
ggsave(file.path(fig_dir, paste0("figS1_state_courts_", STAMP, ".tiff")), figS1,
       width = 6.8, height = 7.2, dpi = 300, bg = "white",
       device = function(filename, ...) ragg::agg_tiff(filename, ..., compression = "lzw"))
cat(sprintf("  saved figS1_state_courts_%s (.png/.pdf/.tiff)\n", STAMP))

cat("\n=== values for the Table S3 footnote and the legend ===\n")
summ <- fc_all |> distinct(scope, n_obs, order) |>
  left_join(d |> filter(scope %in% courts$scope, date < as.Date("2026-01-01")) |>
              group_by(scope) |> summarise(mean_month = mean(new_claims), .groups = "drop"),
            by = "scope")
for (i in seq_len(nrow(summ)))
  cat(sprintf("  %-3s %2d monthly observations to Dec 2025 | mean %7.0f/month | order %s\n",
              summ$scope[i], summ$n_obs[i], summ$mean_month[i], summ$order[i]))
cat("\n  Acre has fewer observations than the other two, so the pipeline was not applied\n")
cat("  to identical series. The legend must not say 'identical modeling pipeline'.\n")
