# 03_event_study.R
# Event study of the 2016 Foreign Buyers' Tax on log NHPI.
# One coefficient per month relative to the month before the tax (rel_month = -1).
# DRAFT: not yet run against the live data.

library(dplyr)
library(fixest)
library(ggplot2)

panel <- readRDS(file.path("data", "processed", "panel.rds"))

# ---- Main specification ------------------------------------------------------
# NOTE: with one treated CMA and few controls, cluster-robust SEs are unreliable.
# They are reported here as a starting point; see README for the inference plan.
es_main <- feols(
  log_nhpi ~ i(rel_month, treated, ref = -1) | cma + date,
  data    = panel,
  cluster = ~cma
)

print(summary(es_main))

# ---- Tidy coefficients and plot ----------------------------------------------
coefs <- broom::tidy(es_main, conf.int = TRUE) |>
  mutate(rel_month = as.integer(stringr::str_extract(term, "-?\\d+")))

write.csv(coefs, file.path("outputs", "event_study_coefs.csv"), row.names = FALSE)

p <- ggplot(coefs, aes(rel_month, estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_vline(xintercept = -0.5, linetype = "dotted") +
  geom_pointrange(aes(ymin = conf.low, ymax = conf.high), size = 0.3) +
  labs(
    title    = "Event study: Foreign Buyers' Tax and new-home prices, Vancouver",
    subtitle = "Effect on log NHPI relative to controls; reference month = July 2016",
    x        = "Months relative to August 2016",
    y        = "Coefficient (approx. % change)"
  ) +
  theme_minimal()

ggsave(
  file.path("outputs", "figures", "event_study_main.png"),
  p, width = 8, height = 5, dpi = 200
)
