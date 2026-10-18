library(dplyr)
library(ggplot2)

panel <- readRDS(file.path("data", "processed", "panel.rds"))

p_raw <- panel |>
  group_by(cma) |>
  mutate(index_rebased = 100 * value / value[date == as.Date("2016-07-01")]) |>
  ungroup() |>
  ggplot(aes(date, index_rebased, colour = cma)) +
  geom_line() +
  geom_vline(xintercept = as.Date("2016-08-01"), linetype = "dotted") +
  labs(y = "NHPI (July 2016 = 100)", x = NULL, colour = NULL) +
  theme_minimal()

ggsave(file.path("outputs", "figures", "raw_series.png"), p_raw, width = 8, height = 5, dpi = 200)
