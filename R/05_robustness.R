# 05_robustness.R
# Robustness checks for the main event study.
# Check 1: drop the Alberta controls (Calgary, Edmonton).

library(dplyr)
library(fixest)
library(ggplot2)
library(broom)
library(stringr)

panel <- readRDS(file.path("data", "processed", "panel.rds"))

# Reusable helper: tidy an event-study model and plot it
plot_event_study <- function(model, title) {
  coefs <- broom::tidy(model, conf.int = TRUE) |>
    mutate(rel_month = as.integer(str_extract(term, "-?\\d+")))
  
  ggplot(coefs, aes(rel_month, estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_vline(xintercept = -0.5, linetype = "dotted") +
    geom_pointrange(aes(ymin = conf.low, ymax = conf.high), size = 0.3) +
    labs(
      title = title,
      x     = "Months relative to August 2016",
      y     = "Coefficient (approx. % change)"
    ) +
    theme_minimal()
}

# ---- Check 1: no Alberta ----------------------------------------------------
es_no_ab <- feols(
  log_nhpi ~ i(rel_month, treated, ref = -1) | cma + date,
  data    = filter(panel, alberta == 0),
  cluster = ~cma
)

p_no_ab <- plot_event_study(es_no_ab, "Event study without Alberta controls")

ggsave(
  file.path("outputs", "figures", "event_study_no_alberta.png"),
  p_no_ab, width = 8, height = 5, dpi = 200)

# ---- Check 3: Vancouver vs Victoria (descriptive only) -----------------------
# Kelowna is not in the NHPI before December 2016, so Victoria is the only
# untaxed BC comparison. With one control there is nothing to estimate, so this
# check is descriptive: raw series and the gap between the two cities.
panel_bc <- readRDS(file.path("data", "processed", "panel_bc.rds"))

bc_rebased <- panel_bc |>
  group_by(cma) |>
  mutate(index_rebased = 100 * value / value[date == as.Date("2016-07-01")]) |>
  ungroup()

p_bc_raw <- ggplot(bc_rebased, aes(date, index_rebased, colour = cma)) +
  geom_line() +
  geom_vline(xintercept = as.Date("2016-08-01"), linetype = "dotted") +
  labs(y = "NHPI (July 2016 = 100)", x = NULL, colour = NULL) +
  theme_minimal()

ggsave(
  file.path("outputs", "figures", "raw_series_bc.png"),
  p_bc_raw, width = 8, height = 5, dpi = 200
)

gap_bc <- bc_rebased |>
  select(cma, date, index_rebased) |>
  tidyr::pivot_wider(names_from = cma, values_from = index_rebased) |>
  mutate(gap = Vancouver - Victoria)

p_gap_bc <- ggplot(gap_bc, aes(date, gap)) +
  geom_line() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_vline(xintercept = as.Date("2016-08-01"), linetype = "dotted") +
  labs(y = "Vancouver minus Victoria (index points)", x = NULL) +
  theme_minimal()

ggsave(
  file.path("outputs", "figures", "gap_vancouver_victoria.png"),
  p_gap_bc, width = 8, height = 5, dpi = 200
)