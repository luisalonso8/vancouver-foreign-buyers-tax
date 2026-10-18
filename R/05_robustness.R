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