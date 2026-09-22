## 20 — Figure S1 regenerated on the COMMON window (Sep 2020 – Dec 2025, n = 64)
## Supersedes figS1_state_courts_v3_20260921.*, which was produced from the
## mis-dated Acre series (see docs/state_courts_common_window.md).
## Output: figures/figS1_state_courts_v4_20260922.{png,pdf,tiff} at 300 dpi.

suppressMessages({library(readr); library(dplyr); library(ggplot2); library(forecast); library(ragg)})
set.seed(42)
dir.create("figures", showWarnings = FALSE)

WIN_START <- as.Date("2020-09-01"); WIN_END <- as.Date("2025-12-01")
TS_START  <- c(2020, 9); TRAIN_END <- c(2024, 12)
COURTS <- c(SP = "São Paulo (~6 355/month)",
            GO = "Goiás (~281/month)",
            AC = "Acre (~19/month)")

d <- read_csv("data/cnj_monthly_series_national_and_states.csv", show_col_types = FALSE) |>
  filter(date >= WIN_START, date <= WIN_END) |> arrange(date)

obs <- list(); fc_df <- list()
for (uf in names(COURTS)) {
  s <- d |> filter(scope == uf) |> arrange(date)
  stopifnot(nrow(s) == 64)
  y   <- ts(s$new_claims, start = TS_START, frequency = 12)
  ytr <- window(y, end = TRAIN_END)
  f   <- auto.arima(ytr, ic = "aicc", stepwise = TRUE)
  fc  <- forecast(f, h = 12, level = 95)

  obs[[uf]] <- tibble(court = COURTS[[uf]], date = s$date, claims = s$new_claims)
  fc_df[[uf]] <- tibble(court = COURTS[[uf]],
                        date  = seq(as.Date("2025-01-01"), by = "month", length.out = 12),
                        mean  = as.numeric(fc$mean),
                        lo    = pmax(as.numeric(fc$lower), 0),
                        hi    = as.numeric(fc$upper))
}
obs   <- bind_rows(obs)   |> mutate(court = factor(court, levels = unname(COURTS)))
fc_df <- bind_rows(fc_df) |> mutate(court = factor(court, levels = unname(COURTS)))

p <- ggplot() +
  geom_ribbon(data = fc_df, aes(date, ymin = lo, ymax = hi),
              fill = "#4C72B0", alpha = 0.18) +
  geom_line(data = obs, aes(date, claims), colour = "grey15", linewidth = 0.45) +
  geom_line(data = fc_df, aes(date, mean), colour = "#4C72B0",
            linetype = "22", linewidth = 0.55) +
  geom_vline(xintercept = as.numeric(as.Date("2025-01-01")),
             linetype = "dotted", colour = "grey45", linewidth = 0.4) +
  facet_wrap(~court, ncol = 1, scales = "free_y") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y",
               expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(expand = expansion(mult = c(0.04, 0.10))) +
  labs(x = NULL, y = "New judicial claims per month") +
  theme_minimal(base_size = 9, base_family = "DejaVu Sans") +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0, size = 9),
        axis.title.y = element_text(size = 8.5),
        plot.margin = margin(6, 10, 4, 6))

base <- "figures/figS1_state_courts_v4_20260922"
ggsave(paste0(base, ".png"),  p, width = 6.5, height = 6.2, dpi = 300, device = ragg::agg_png)
ggsave(paste0(base, ".pdf"),  p, width = 6.5, height = 6.2, device = cairo_pdf)
ggsave(paste0(base, ".tiff"), p, width = 6.5, height = 6.2, dpi = 300,
       device = ragg::agg_tiff, compression = "lzw")

cat("gravado:\n"); print(list.files("figures", pattern = "v4_20260922", full.names = TRUE))
cat("\nholdout: jan-dez 2025 (12 meses) nos três tribunais; n = 64 cada.\n")
