# ---- Gap: Vancouver minus control mean --------------------------------------
gap <- panel |>
  group_by(cma) |>
  mutate(index_rebased = 100 * value / value[date == as.Date("2016-07-01")]) |>
  ungroup() |>
  group_by(date, treated) |>
  summarise(mean_index = mean(index_rebased), .groups = "drop") |>
  tidyr::pivot_wider(names_from = treated, values_from = mean_index, names_prefix = "t") |>
  mutate(gap = t1 - t0)

p_gap <- ggplot(gap, aes(date, gap)) +
  geom_line() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_vline(xintercept = as.Date("2016-08-01"), linetype = "dotted") +
  labs(y = "Vancouver minus control mean (index points)", x = NULL) +
  theme_minimal()

ggsave(
  file.path("outputs", "figures", "gap_vancouver_vs_controls.png"),
  p_gap, width = 8, height = 5, dpi = 200
)