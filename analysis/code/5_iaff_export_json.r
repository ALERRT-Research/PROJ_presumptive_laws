# =============================================================================
# RETIRED 2026-08-20 -- superseded by 5_export_json.r. DO NOT RUN.
#
# This script wrote only website/data/presumptive_laws.json. The copy the app
# actually reads at runtime, website/shiny-app/data/presumptive_laws.json, was
# kept current by hand (see docs/logs/2026-05-27_session3.md) -- a silent
# divergence risk. The replacement writes both from one data frame and
# hash-verifies them.
#
# Kept on disk as provenance. See data/codebook.md for the current pipeline.
# =============================================================================

# Project: PROJ_presumptive_laws
# Script:  5_iaff_export_json.r
# Created: 2026-05-23
# Purpose: Export presumptive_laws_v2.rds to the JSON format consumed by the
#          Shinylive dashboard. Replaces website/data/presumptive_laws.json.
#          Phase 3 (final step) of the IAFF data rebuild pipeline.

if (!require("pacman")) install.packages("pacman")
pacman::p_load(here, dplyr, jsonlite)

rds_path  <- here("data", "processed", "presumptive_laws_v2.rds")
json_path <- here("website", "data", "presumptive_laws.json")

df <- readRDS(rds_path)

cat(sprintf("Loaded: %d rows, %d states\n", nrow(df), n_distinct(df$state)))

# Convert factors to character for JSON serialization
df_out <- df |>
  mutate(across(where(is.factor), as.character)) |>
  # Replace NA with JSON null-friendly values
  mutate(across(where(is.character), ~ ifelse(is.na(.), NA_character_, .))) |>
  mutate(across(where(is.logical),  ~ ifelse(is.na(.), NA, .))) |>
  mutate(across(where(is.integer),  ~ ifelse(is.na(.), NA_integer_, .)))

# Write JSON
write_json(df_out, json_path,
           auto_unbox  = TRUE,
           pretty      = FALSE,
           na          = "null",
           null        = "null")

size_kb <- file.size(json_path) / 1024
cat(sprintf("Written: %s (%.1f KB)\n", json_path, size_kb))
cat(sprintf("Records: %d\n", nrow(df_out)))
cat("\nDone. Re-export the Shinylive app next:\n")
cat("  cd website && shinylive export shiny-app dashboard\n")
