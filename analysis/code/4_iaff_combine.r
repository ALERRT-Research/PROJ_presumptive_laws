# Project: PROJ_presumptive_laws
# Script:  4_iaff_combine.r
# Created: 2026-05-23
# Purpose: Combine all per-state JSON extraction files into a single validated
#          RDS dataset. Run after all agents have finished writing to
#          data/raw/iaff_extracted/. Phase 3 of the IAFF data rebuild pipeline.

if (!require("pacman")) install.packages("pacman")
pacman::p_load(here, jsonlite, dplyr, purrr, readr, fs, tidyr)

extracted_dir <- here("data", "raw", "iaff_extracted")
out_rds       <- here("data", "processed", "presumptive_laws_v2.rds")
out_csv       <- here("data", "processed", "presumptive_laws_v2.csv")

# ── Load and bind all state JSON files ────────────────────────────────────────

json_files <- dir_ls(extracted_dir, glob = "*.json")
cat(sprintf("Loading %d state files...\n", length(json_files)))

all_rows <- map(json_files, function(f) {
  tryCatch(
    fromJSON(f, simplifyDataFrame = TRUE, flatten = TRUE),
    error = function(e) {
      warning(sprintf("Failed to parse %s: %s", path_file(f), conditionMessage(e)))
      NULL
    }
  )
}) |>
  compact() |>
  bind_rows()

cat(sprintf("Raw rows loaded: %d\n", nrow(all_rows)))

# ── Standardize and coerce types ──────────────────────────────────────────────

# Allowed factor levels
valid_conditions   <- c("cancer","cardiovascular","respiratory","infectious","mental","other")
valid_responders   <- c("firefighter","firefighter_volunteer","emt_paramedic","law_enforcement","corrections")
valid_ptype        <- c("statute","EO","expired","none")

df <- all_rows |>
  # Normalize state to uppercase 2-letter
  mutate(state = toupper(trimws(state))) |>

  # Fix any condition/responder/ptype values outside allowed set
  mutate(
    condition_category = case_when(
      condition_category %in% valid_conditions ~ condition_category,
      TRUE ~ NA_character_
    ),
    responder_type = case_when(
      responder_type %in% valid_responders ~ responder_type,
      TRUE ~ NA_character_
    ),
    presumption_type = case_when(
      presumption_type %in% valid_ptype ~ presumption_type,
      TRUE ~ "none"
    )
  ) |>

  # Coerce logicals — handle any "TRUE"/"FALSE" strings from JSON
  mutate(across(c(presumption_exists, rebuttable, pre_employment_exam_required,
                  discovery_during_employment_required, tobacco_exclusion),
                ~ case_when(
                  . %in% c(TRUE, "true", "TRUE", "True", 1) ~ TRUE,
                  . %in% c(FALSE, "false", "FALSE", "False", 0) ~ FALSE,
                  TRUE ~ NA
                ))) |>

  # Coerce integers
  mutate(
    years_service_required  = suppressWarnings(as.integer(years_service_required)),
    post_termination_months = suppressWarnings(as.integer(post_termination_months))
  ) |>

  # Apply factor levels
  mutate(
    condition_category = factor(condition_category, levels = valid_conditions),
    responder_type     = factor(responder_type,     levels = valid_responders),
    presumption_type   = factor(presumption_type,   levels = valid_ptype)
  ) |>

  # Ensure required text columns exist
  mutate(
    across(c(condition_specific, statute_citation, post_termination_formula,
             filing_deadline_notes, notes, iaff_url, data_retrieved, state_name),
           ~ ifelse(is.na(.) | trimws(.) == "" | . == "null", NA_character_, as.character(.)))
  ) |>

  # Sort
  arrange(state, condition_category, responder_type)

# ── Validation checks ──────────────────────────────────────────────────────────

cat("\n── Validation ────────────────────────────────────\n")

# Check all 51 jurisdictions present
expected_states <- c(
  "AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN",
  "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
  "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT",
  "VT","VA","WA","WV","WI","WY"
)
present_states  <- sort(unique(df$state))
missing_states  <- setdiff(expected_states, present_states)
extra_states    <- setdiff(present_states, expected_states)

if (length(missing_states) > 0) {
  cat(sprintf("  MISSING states (%d): %s\n", length(missing_states),
              paste(missing_states, collapse=", ")))
} else {
  cat("  All 51 jurisdictions present.\n")
}
if (length(extra_states) > 0) {
  cat(sprintf("  UNEXPECTED states: %s\n", paste(extra_states, collapse=", ")))
}

# Check for invalid factor levels
n_bad_condition  <- sum(is.na(df$condition_category))
n_bad_responder  <- sum(is.na(df$responder_type))
if (n_bad_condition > 0)
  cat(sprintf("  WARNING: %d rows with invalid condition_category (set to NA)\n", n_bad_condition))
if (n_bad_responder > 0)
  cat(sprintf("  WARNING: %d rows with invalid responder_type (set to NA)\n", n_bad_responder))

# Check for rows claiming presumption but type = "none"
bad_rows <- df |> filter(presumption_exists == TRUE & presumption_type == "none")
if (nrow(bad_rows) > 0) {
  cat(sprintf("  WARNING: %d rows have presumption_exists=TRUE but type='none'\n", nrow(bad_rows)))
}

# ── Summary stats ──────────────────────────────────────────────────────────────

cat(sprintf("\n── Summary ───────────────────────────────────────\n"))
cat(sprintf("  Total rows:    %d\n", nrow(df)))
cat(sprintf("  States:        %d\n", n_distinct(df$state)))

cat("\n  Rows by condition_category:\n")
df |> count(condition_category) |> as.data.frame() |> print()

cat("\n  Rows by responder_type:\n")
df |> count(responder_type) |> as.data.frame() |> print()

cat("\n  Rows by presumption_type:\n")
df |> count(presumption_type) |> as.data.frame() |> print()

cat("\n  States with post-retirement coverage (post_termination_months > 0):\n")
df |>
  filter(!is.na(post_termination_months), post_termination_months > 0) |>
  distinct(state, condition_category, post_termination_months) |>
  arrange(desc(post_termination_months)) |>
  slice_head(n = 15) |>
  print()

cat("\n  States where discovery_during_employment_required = TRUE:\n")
df |>
  filter(discovery_during_employment_required == TRUE) |>
  distinct(state) |>
  pull(state) |>
  paste(collapse = ", ") |>
  cat(); cat("\n")

cat("\n  Irrebuttable presumptions (rebuttable = FALSE):\n")
df |>
  filter(rebuttable == FALSE) |>
  select(state, condition_category, responder_type, statute_citation) |>
  print()

# ── Save ───────────────────────────────────────────────────────────────────────

saveRDS(df, out_rds)
write_csv(df, out_csv)

cat(sprintf("\n  Saved RDS:  %s\n", out_rds))
cat(sprintf("  Saved CSV:  %s\n", out_csv))
cat("\nDone. Run 5_iaff_export_json.r next to update the dashboard data file.\n")
