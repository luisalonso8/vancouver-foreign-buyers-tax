# 05_robustness.R
# Robustness checks for the main event study.
# Check 1: drop the Alberta controls (Calgary, Edmonton).

library(dplyr)
library(fixest)
library(ggplot2)
library(broom)
library(stringr)
library(HonestDiD)

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

# ---- Check 2: extended control set ------------------------------------------
panel_ext <- readRDS(file.path("data", "processed", "panel_extended.rds"))

es_ext <- feols(
  log_nhpi ~ i(rel_month, treated, ref = -1) | cma + date,
  data    = panel_ext,
  cluster = ~cma
)

p_ext <- plot_event_study(es_ext, "Event study with extended control set")

ggsave(
  file.path("outputs", "figures", "event_study_extended.png"),
  p_ext, width = 8, height = 5, dpi = 200
)

# ---- Check 4: HonestDiD sensitivity (Rambachan and Roth) --------------------
b   <- coef(es_ext)
s   <- vcov(es_ext)
rel <- as.integer(str_extract(names(b), "-?\\d+"))

# Use the last 12 pre-periods and all post-periods (periods must be consecutive)
keep   <- which(rel >= -12)
b_k    <- b[keep]
s_k    <- s[keep, keep]
n_pre  <- sum(rel[keep] < 0)
n_post <- sum(rel[keep] >= 0)

# Target: average effect over the post-tax months
l_vec <- rep(1 / n_post, n_post)

original <- constructOriginalCS(
  betahat = b_k, sigma = s_k,
  numPrePeriods = n_pre, numPostPeriods = n_post,
  l_vec = l_vec
)

# Smoothness restriction: M = max change in slope between consecutive periods
sens <- createSensitivityResults(
  betahat = b_k, sigma = s_k,
  numPrePeriods = n_pre, numPostPeriods = n_post,
  Mvec  = seq(0, 0.01, length.out = 6),
  l_vec = l_vec
)
print(sens)

p_honest <- createSensitivityPlot(sens, original)
ggsave(
  file.path("outputs", "figures", "honest_did.png"),
  p_honest, width = 8, height = 5, dpi = 200
)
write.csv(sens, file.path("outputs", "honest_did_results.csv"), row.names = FALSE)