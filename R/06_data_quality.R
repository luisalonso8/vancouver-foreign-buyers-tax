# 06_data_quality.R
# Data quality flags and pre/post growth table for the EDA section.

library(dplyr)
library(stringr)
library(tidyr)

nhpi_raw <- readRDS(file.path("data", "raw", "nhpi_raw.rds"))
panel    <- readRDS(file.path("data", "processed", "panel.rds"))

# ---- 1. STATUS flags in the raw table ---------------------------------------
# STATUS marks estimated ("E") or unavailable values; NA means no flag.
status_check <- nhpi_raw |>
  transmute(
    date   = as.Date(Date),
    cma    = str_extract(as.character(GEO), "^[^,]+"),
    index  = as.character(`New housing price indexes`),
    status = STATUS
  ) |>
  filter(
    index == "Total (house and land)",
    cma %in% unique(panel$cma),
    date >= min(panel$date), date <= max(panel$date)
  ) |>
  mutate(status = coalesce(status, "no flag")) |>
  count(cma, status) |>
  pivot_wider(names_from = status, values_from = n, values_fill = 0)

print(status_check)
write.csv(status_check, file.path("outputs", "status_flags.csv"), row.names = FALSE)

# ---- 2. Pre/post growth table -----------------------------------------------
# Pre: July 2014 (rel_month -25) to July 2016 (rel_month -1), 24 months.
# Post: July 2016 (rel_month -1) to March 2017 (rel_month 7), 8 months.
growth <- panel |>
  group_by(cma) |>
  summarise(
    pre_change_pct  = 100 * (value[rel_month == -1] / value[rel_month == -25] - 1),
    post_change_pct = 100 * (value[rel_month == 7]  / value[rel_month == -1]  - 1),
    .groups = "drop"
  ) |>
  arrange(desc(pre_change_pct))

controls_mean <- growth |>
  filter(cma != "Vancouver") |>
  summarise(across(-cma, mean))

print(growth)
print(controls_mean)
write.csv(growth, file.path("outputs", "growth_table.csv"), row.names = FALSE)