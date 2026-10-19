# 02_clean.R
# Build the analysis panel: one row per CMA and month, with treatment
# indicator and months relative to the Foreign Buyers' Tax (FBT).

library(dplyr)
library(lubridate)
library(stringr)

# ---- Design parameters -------------------------------------------------------
fbt_date     <- ymd("2016-08-01")   # FBT took effect 2 Aug 2016; month 0
window_start <- ymd("2013-01-01")
window_end   <- ymd("2017-03-01")   # before Ontario's tax (Apr 2017)

treated_cma  <- "Vancouver"

# Controls: outside BC and Ontario. Edit here for robustness checks.
control_cmas <- c(
  "Calgary", "Edmonton", "Saskatoon", "Regina", "Winnipeg", "Halifax"
)
alberta_cmas <- c("Calgary", "Edmonton")

# Series to use: house and land combined
index_label <- "Total (house and land)"

# ---- Load and filter ---------------------------------------------------------
nhpi_raw <- readRDS(file.path("data", "raw", "nhpi_raw.rds"))

nhpi <- nhpi_raw |>
  transmute(
    date  = as.Date(Date),
    geo   = GEO,
    index = `New housing price indexes`,
    value = VALUE
  ) |>
  filter(index == index_label) |>
  mutate(cma = str_extract(geo, "^[^,]+"))   # "Vancouver, British Columbia" -> "Vancouver"

panel <- nhpi |>
  filter(cma %in% c(treated_cma, control_cmas)) |>
  filter(date >= window_start, date <= window_end) |>
  mutate(
    treated   = as.integer(cma == treated_cma),
    alberta   = as.integer(cma %in% alberta_cmas),
    log_nhpi  = log(value),
    rel_month = (year(date) - year(fbt_date)) * 12 + (month(date) - month(fbt_date)),
    post      = as.integer(rel_month >= 0)
  ) |>
  select(cma, date, value, log_nhpi, treated, alberta, rel_month, post)

# ---- Sanity checks -----------------------------------------------------------
found <- sort(unique(panel$cma))
expected <- sort(c(treated_cma, control_cmas))
missing_cmas <- setdiff(expected, found)
if (length(missing_cmas) > 0) {
  warning("CMAs not found in the table (check names in 01_download.R output): ",
          paste(missing_cmas, collapse = ", "))
}

stopifnot(
  treated_cma %in% found,
  !anyNA(panel$value),
  min(panel$rel_month) < 0,
  max(panel$rel_month) > 0
)

# Balanced panel check: every CMA should have the same number of months
print(count(panel, cma))

saveRDS(panel, file.path("data", "processed", "panel.rds"))
message("Saved analysis panel with ", nrow(panel), " rows.")

# ---- BC-only comparison (used in 05_robustness.R) ----------------------------
bc_cmas <- c("Victoria", "Kelowna")

panel_bc <- nhpi |>
  filter(cma %in% c(treated_cma, bc_cmas)) |>
  filter(date >= window_start, date <= window_end) |>
  mutate(
    treated   = as.integer(cma == treated_cma),
    alberta   = 0L,
    log_nhpi  = log(value),
    rel_month = (year(date) - year(fbt_date)) * 12 + (month(date) - month(fbt_date)),
    post      = as.integer(rel_month >= 0)
  ) |>
  select(cma, date, value, log_nhpi, treated, alberta, rel_month, post)

# Keep only CMAs with a complete series in the window
panel_bc <- panel_bc |>
  group_by(cma) |>
  filter(!anyNA(value)) |>
  ungroup()

print(count(panel_bc, cma))
saveRDS(panel_bc, file.path("data", "processed", "panel_bc.rds"))