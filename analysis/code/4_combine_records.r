# Project: PROJ_presumptive_laws
# Script:  4_combine_records.r
# Created: 2026-08-20
# Purpose: Bind the per-state research records in data/raw/state_records/ into a
#          single validated dataset. Stage 1 of the two-stage data pipeline:
#
#            data/raw/state_records/*.json   (source of truth, committed)
#              -> 4_combine_records.r        (this script: validate, coerce, bind)
#              -> data/processed/presumptive_laws_v2.rds + .csv
#              -> 5_iaff_export_json.r
#              -> website/data/ + website/shiny-app/data/ presumptive_laws.json
#
# Replaces 4_iaff_combine.r, whose input was the IAFF scrape. P8 (2026-08-07)
# formally demoted IAFF from ground truth: it is a directory of leads that was
# checked and repeatedly found wrong or stale, not a source. The record files are
# derived from independent per-state legislative research
# (docs/lit/state_histories/*_timeline.md, all 50 states QC-gated 97-100/100).
#
# Design note -- this script FAILS rather than coerces. The script it replaces
# silently mapped any unrecognized presumption_type to "none"; because its domain
# list had gone stale relative to app.R, running it would have destroyed 58 rows
# (pension, employer_benefit, lodd_only) without a warning. Out-of-domain values
# now abort with the offending rows printed.

if (!require("pacman")) install.packages("pacman")
pacman::p_load(here, jsonlite, dplyr, purrr, readr, fs, tidyr)

records_dir <- here("data", "raw", "state_records")
out_rds     <- here("data", "processed", "presumptive_laws_v2.rds")
out_csv     <- here("data", "processed", "presumptive_laws_v2.csv")

# ── Schema ────────────────────────────────────────────────────────────────────
# Domains match app.R (lines 29-92), which is authoritative for what the dashboard
# can render: its type_priority / status_labels / status_clrs lookup vectors will
# return NA for any presumption_type not listed there, silently blanking a tile.
# Keep these three vectors in sync with app.R and data/codebook.md.

valid_conditions <- c("cancer", "cardiovascular", "respiratory",
                      "infectious", "mental", "other")
valid_responders <- c("firefighter", "firefighter_volunteer", "emt_paramedic",
                      "law_enforcement", "corrections")
valid_ptype      <- c("statute", "EO", "pension", "employer_benefit",
                      "lodd_only", "expired", "none")

chr_fields <- c("state", "state_name", "condition_category", "condition_specific",
                "responder_type", "presumption_type", "post_termination_formula",
                "filing_deadline_notes", "statute_citation", "source_url",
                "notes", "needs_verification", "iaff_url", "data_retrieved")
lgl_fields <- c("presumption_exists", "rebuttable", "pre_employment_exam_required",
                "discovery_during_employment_required", "tobacco_exclusion")
int_fields <- c("years_service_required", "post_termination_months")

# Canonical column order, documented in data/codebook.md and matched by
# split_json_to_records.py. Grouped identity -> classification -> status ->
# eligibility mechanics -> authority -> annotation/provenance, so a record reads
# top-to-bottom the way a reviewer thinks about it.
field_order <- c(
  "state", "state_name",
  "condition_category", "condition_specific", "responder_type",
  "presumption_type", "presumption_exists", "rebuttable",
  "years_service_required", "pre_employment_exam_required",
  "post_termination_months", "post_termination_formula",
  "discovery_during_employment_required", "filing_deadline_notes",
  "tobacco_exclusion",
  "statute_citation", "source_url",
  "notes", "needs_verification", "iaff_url", "data_retrieved"
)
stopifnot(setequal(field_order, c(chr_fields, lgl_fields, int_fields)))

# Natural key. Needs BOTH statute_citation and condition_specific -- two legitimate
# near-duplicates exist and must not be collapsed:
#   LA / mental / law_enforcement -- two statutes, same condition
#                                    (La. R.S. 33:2581.2 and 40:1374)
#   WV / cancer / firefighter     -- one statute (W. Va. Code 23-4-1(h)), two cancer
#                                    groups, only one of which sunsets 2027-07-01.
#                                    The split is what makes the sunset expressible.
key_fields <- c("state", "condition_category", "responder_type",
                "condition_specific", "statute_citation")

# Bootstrap baseline, 2026-08-20. A legitimate coverage change (new law, new
# completeness fill) will move this -- update it deliberately when that happens,
# rather than deleting the check.
EXPECTED_ROWS <- 479L

# ── Read ──────────────────────────────────────────────────────────────────────
# Records are read as lists rather than auto-simplified data frames. A state file
# whose column is entirely null would otherwise simplify to the wrong type, and a
# mixed column to a list, producing type drift that varies by state.

json_files <- dir_ls(records_dir, glob = "*.json")
if (length(json_files) == 0) stop("No record files found in ", records_dir)
cat(sprintf("Reading %d record files from %s\n",
            length(json_files), path_rel(records_dir, here())))

blank_to_na <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_character_)
  x <- trimws(as.character(x)[1])
  if (x == "" || x == "null" || x == "NA") NA_character_ else x
}
as_lgl <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA)
  x <- x[1]
  if (is.logical(x)) return(as.logical(x))
  s <- tolower(trimws(as.character(x)))
  if (s %in% c("true", "t", "1"))  return(TRUE)
  if (s %in% c("false", "f", "0")) return(FALSE)
  NA
}
as_int <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_integer_)
  suppressWarnings(as.integer(x[1]))
}

read_state <- function(f) {
  recs <- fromJSON(f, simplifyDataFrame = FALSE)
  if (length(recs) == 0) {
    warning(sprintf("%s contains no records", path_file(f)))
    return(NULL)
  }
  map_dfr(recs, function(r) {
    row <- c(
      set_names(map(chr_fields, ~ blank_to_na(r[[.x]])), chr_fields),
      set_names(map(lgl_fields, ~ as_lgl(r[[.x]])),      lgl_fields),
      set_names(map(int_fields, ~ as_int(r[[.x]])),      int_fields)
    )
    as_tibble(row)
  })
}

df <- map(json_files, read_state) |> compact() |> bind_rows()
cat(sprintf("  Records read: %d\n", nrow(df)))

# ── Validate ──────────────────────────────────────────────────────────────────

cat("\n-- Validation ------------------------------------\n")
fatal <- character(0)

# Domains: abort, do not coerce.
check_domain <- function(df, field, allowed) {
  bad <- df |> filter(!is.na(.data[[field]]), !.data[[field]] %in% allowed)
  if (nrow(bad) > 0) {
    cat(sprintf("  FATAL: %d rows with out-of-domain %s:\n", nrow(bad), field))
    bad |>
      count(.data[[field]], name = "rows") |>
      as.data.frame() |>
      print(row.names = FALSE)
    cat(sprintf("         allowed: %s\n", paste(allowed, collapse = ", ")))
    return(sprintf("out-of-domain %s", field))
  }
  character(0)
}
fatal <- c(fatal,
           check_domain(df, "condition_category", valid_conditions),
           check_domain(df, "responder_type",     valid_responders),
           check_domain(df, "presumption_type",   valid_ptype))

# Required fields must be populated.
for (f in c("state", "state_name", "condition_category", "responder_type",
            "presumption_type", "presumption_exists")) {
  n_missing <- sum(is.na(df[[f]]))
  if (n_missing > 0) {
    cat(sprintf("  FATAL: %d rows with missing %s\n", n_missing, f))
    fatal <- c(fatal, sprintf("missing %s", f))
  }
}

# All 51 jurisdictions.
expected_states <- c(
  "AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN",
  "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
  "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT",
  "VT","VA","WA","WV","WI","WY"
)
missing_states <- setdiff(expected_states, unique(df$state))
extra_states   <- setdiff(unique(df$state), expected_states)
if (length(missing_states) > 0) {
  cat(sprintf("  FATAL: missing jurisdictions (%d): %s\n",
              length(missing_states), paste(missing_states, collapse = ", ")))
  fatal <- c(fatal, "missing jurisdictions")
} else {
  cat("  All 51 jurisdictions present.\n")
}
if (length(extra_states) > 0) {
  cat(sprintf("  FATAL: unexpected jurisdictions: %s\n",
              paste(extra_states, collapse = ", ")))
  fatal <- c(fatal, "unexpected jurisdictions")
}

# Natural-key uniqueness.
dupes <- df |> count(across(all_of(key_fields)), name = "n") |> filter(n > 1)
if (nrow(dupes) > 0) {
  cat(sprintf("  FATAL: %d duplicate records on the natural key:\n", nrow(dupes)))
  dupes |> select(state, condition_category, responder_type, n) |>
    as.data.frame() |> print(row.names = FALSE)
  fatal <- c(fatal, "duplicate natural key")
} else {
  cat("  Natural key unique.\n")
}

if (length(fatal) > 0) {
  stop("Validation failed: ", paste(unique(fatal), collapse = "; "),
       ".\n  Fix the record files in data/raw/state_records/ and re-run. ",
       "This script does not silently repair data.")
}

# Non-fatal advisories.
if (nrow(df) != EXPECTED_ROWS) {
  cat(sprintf(paste0("  ADVISORY: %d rows, baseline is %d (delta %+d). Expected if ",
                     "coverage changed;\n            update EXPECTED_ROWS in this ",
                     "script if the change is intended.\n"),
              nrow(df), EXPECTED_ROWS, nrow(df) - EXPECTED_ROWS))
} else {
  cat(sprintf("  Row count matches baseline (%d).\n", EXPECTED_ROWS))
}

contradictory <- df |> filter(presumption_exists == TRUE, presumption_type == "none")
if (nrow(contradictory) > 0) {
  cat(sprintf("  ADVISORY: %d rows have presumption_exists=TRUE but type='none'\n",
              nrow(contradictory)))
}
n_no_source <- sum(is.na(df$source_url))
cat(sprintf("  Rows without a source_url: %d of %d\n", n_no_source, nrow(df)))

# ── Type + order ──────────────────────────────────────────────────────────────
# Factors are applied only after validation, so an out-of-domain value can never be
# converted to NA before it has been reported.

df <- df |>
  mutate(
    condition_category = factor(condition_category, levels = valid_conditions),
    responder_type     = factor(responder_type,     levels = valid_responders),
    presumption_type   = factor(presumption_type,   levels = valid_ptype)
  ) |>
  relocate(all_of(field_order)) |>
  arrange(state, condition_category, responder_type,
          condition_specific, statute_citation)

# ── Summary ───────────────────────────────────────────────────────────────────

cat("\n-- Summary ---------------------------------------\n")
cat(sprintf("  Total rows:    %d\n", nrow(df)))
cat(sprintf("  Jurisdictions: %d\n", n_distinct(df$state)))

cat("\n  Rows by condition_category:\n")
df |> count(condition_category, .drop = FALSE) |> as.data.frame() |> print(row.names = FALSE)

cat("\n  Rows by responder_type:\n")
df |> count(responder_type, .drop = FALSE) |> as.data.frame() |> print(row.names = FALSE)

cat("\n  Rows by presumption_type:\n")
df |> count(presumption_type, .drop = FALSE) |> as.data.frame() |> print(row.names = FALSE)

cat("\n  Longest post-termination coverage:\n")
df |>
  filter(!is.na(post_termination_months), post_termination_months > 0) |>
  distinct(state, condition_category, post_termination_months) |>
  arrange(desc(post_termination_months)) |>
  slice_head(n = 10) |>
  as.data.frame() |> print(row.names = FALSE)

cat("\n  Irrebuttable presumptions (rebuttable = FALSE):\n")
irr <- df |> filter(rebuttable == FALSE) |>
  select(state, condition_category, responder_type, statute_citation)
if (nrow(irr) == 0) cat("    none\n") else
  irr |> as.data.frame() |> print(row.names = FALSE)

cat("\n  Rows carrying a needs_verification flag:\n")
nv <- df |> filter(!is.na(needs_verification)) |>
  count(state, name = "flags") |> arrange(desc(flags))
if (nrow(nv) == 0) cat("    none\n") else
  nv |> as.data.frame() |> print(row.names = FALSE)

# ── Save ──────────────────────────────────────────────────────────────────────

saveRDS(df, out_rds)
write_csv(df, out_csv)

cat(sprintf("\n  Saved RDS: %s\n", path_rel(out_rds, here())))
cat(sprintf("  Saved CSV: %s\n", path_rel(out_csv, here())))
cat("\nDone. Run 5_export_json.r next to update the dashboard data files.\n")
