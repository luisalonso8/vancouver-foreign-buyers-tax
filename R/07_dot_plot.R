# 07_dot_plot.R
# Dumbbell chart: average monthly new-home price growth before vs after the FBT.
# Descriptive only; not a causal estimate.

library(dplyr)
library(ggplot2)

panel_ext <- readRDS(file.path("data", "processed", "panel_extended.rds"))

# Before: 12 months up to July 2016 (rel_month -13 to -1)
# After:  8 months from July 2016 to March 2017 (rel_month -1 to 7)
growth <- panel_ext |>
  group_by(cma) |>
  summarise(
    before = 100 * (log_nhpi[rel_month == -1] - log_nhpi[rel_month == -13]) / 12,
    after  = 100 * (log_nhpi[rel_month == 7]  - log_nhpi[rel_month == -1]) / 8,
    .groups = "drop"
  ) |>
  mutate(
    is_vancouver = cma == "Vancouver",
    change       = after - before,
    cma_f        = factor(cma, levels = cma[order(after)])
  )

print(growth |> arrange(desc(after)))
write.csv(growth, file.path("outputs", "growth_dotplot.csv"), row.names = FALSE)

p_dot <- ggplot(growth, aes(y = cma_f)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_segment(
    aes(x = before, xend = after, yend = cma_f, linewidth = is_vancouver),
    color = "grey55"
  ) +
  geom_point(aes(x = before, color = "Before tax"), size = 3) +
  geom_point(aes(x = after,  color = "After tax"),  size = 3) +
  scale_linewidth_manual(values = c(`FALSE` = 0.6, `TRUE` = 2), guide = "none") +
  scale_color_manual(
    values = c("Before tax" = "grey40", "After tax" = "#1f5fa8"),
    breaks = c("Before tax", "After tax"),
    name   = NULL
  ) +
  labs(
    title    = "New-home price growth before and after the Foreign Buyers' Tax",
    subtitle = "Average monthly change in log NHPI (%): 12 months before vs 8 months after July 2016",
    x        = "Average monthly growth (%)",
    y        = NULL,
    caption  = "Vancouver highlighted with a thicker line. Descriptive only; not a causal estimate."
  ) +
  theme_minimal() +
  theme(legend.position = "top")

ggsave(
  file.path("outputs", "figures", "dot_plot_growth.png"),
  p_dot, width = 8, height = 5, dpi = 200
)