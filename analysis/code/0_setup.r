# Project: PROJ_presumptive_laws
# Created: 2026-05-21
# Description: Presumptive WC laws dashboard for first responders
# Data sources: NCCI (2023) brief; Brandt-Rauf et al. (2024)

if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  here,
  janitor,
  jsonlite,
  pdftools,
  rio,
  tidyverse
)

data_raw_dir  <- here("data", "raw")
data_proc_dir <- here("data", "processed")
lit_dir       <- here("docs", "lit")
web_data_dir  <- here("website", "data")
temp_dir      <- here("analysis", "temp")
