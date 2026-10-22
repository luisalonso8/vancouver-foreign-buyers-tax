# 08_placebo_space.R
# Placebo in space: treat each city as if it had received the FBT and compare
# Vancouver's statistic with the placebo distribution.

library(dplyr)
library(fixest)
library(ggplot2)
library(stringr)

panel_ext <- readRDS(file.path("data", "processed", "panel_extended.rds"))
all_cmas  <- sort(unique(panel_ext$cma))

# Metric A: change in average monthly growth (after minus before), as in the dot plot.
# It accounts for each city's own pre-tax pace.
growth_change <- panel_ext |>
  group_by(cma) |>
  summarise(
    before = 100 * (log_nhpi[rel_month == -1] - log_nhpi[rel_month == -13]) / 12,
    after  = 100 * (log_nhpi[rel_month == 7]  - log_nhpi[rel_month == -1]) / 8,
    .groups = "drop"
  ) |>
  mutate(growth_change = after - before) |>
  select(cma, growth_change)

# Metric B: average post-tax event-study coefficient (reference month = July 2016).
# Vancouver is only kept in the data when it is the "treated" city.
avg_post_coef <- function(treated_name) {
  d <- panel_ext |>
    filter(cma == treated_name | cma != "Vancouver") |>
    mutate(treated = as.integer(cma == treated_name))
  m   <- feols(log_nhpi ~ i(rel_month, treated, ref = -1) | cma + date, data = d)
  b   <- coef(m)
  rel <- as.integer(str_extract(names(b), "-?\\d+"))
  mean(b[rel >= 0])
}

results <- tibble(cma = all_cmas) |>
  mutate(post_coef = 100 * sapply(cma, avg_post_coef)) |>
  left_join(growth_change, by = "cma") |>
  mutate(is_vancouver = cma == "Vancouver")

print(results |> arrange(growth_change))
write.csv(results, file.path("outputs", "placebo_space.csv"), row.names = FALSE)

# Permutation-style p-values: share of cities (Vancouver included) at least as extreme
van <- filter(results, is_vancouver)
p_growth <- mean(abs(results$growth_change) >= abs(van$growth_change))
p_coef   <- mean(abs(results$post_coef)     >= abs(van$post_coef))
message("Placebo p-value, growth change: ", round(p_growth, 3))
message("Placebo p-value, post coefficient: ", round(p_coef, 3))

p_placebo <- ggplot(results, aes(x = growth_change, y = reorder(cma, growth_change),
                                 color = is_vancouver)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_point(size = 3.5) +
  scale_color_manual(values = c(`FALSE` = "grey50", `TRUE` = "#1f5fa8"), guide = "none") +
  labs(
    title    = "Placebo in space: change in price growth after July 2016",
    subtitle = "Each city treated as if it had received the tax; Vancouver in blue",
    x        = "Change in average monthly growth, after minus before (pp)",
    y        = NULL,
    caption  = "With 12 cities, the smallest possible two-sided p-value is 1/12 (0.083)."
  ) +
  theme_minimal()

ggsave(
  file.path("outputs", "figures", "placebo_space.png"),
  p_placebo, width = 8, height = 5, dpi = 200
)