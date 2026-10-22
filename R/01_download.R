# 01_download.R
# Pull the monthly New Housing Price Index (NHPI) from Statistics Canada
# and store the raw table locally.

library(cansim)
library(dplyr)

raw_path <- file.path("data", "raw", "nhpi_raw.rds")

nhpi_raw <- get_cansim("18-10-0205-01")

# Quick look at the structure so the cleaning script can be checked against it
glimpse(nhpi_raw)
print(unique(nhpi_raw$GEO))
print(unique(nhpi_raw$`New housing price indexes`))

saveRDS(nhpi_raw, raw_path)
message("Saved raw NHPI table to ", raw_path)
