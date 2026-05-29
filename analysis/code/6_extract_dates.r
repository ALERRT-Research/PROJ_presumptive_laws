# Project: PROJ_presumptive_laws
# Script:  6_extract_dates.r
# Created: 2026-05-29
# Purpose: Extract law implementation (effective) dates and sunset/expiration
#          dates from notes fields across all state JSON files.
#          Outputs data/processed/date_review.csv for manual QA — does NOT
#          modify any source files.

if (!require("pacman")) install.packages("pacman")
pacman::p_load(here, jsonlite, dplyr, purrr, readr, fs, stringr, lubridate, tidyr)

extracted_dir <- here("data", "raw", "iaff_extracted")
out_csv       <- here("data", "processed", "date_review.csv")

# ── Date pattern ──────────────────────────────────────────────────────────────

MONTH_PAT <- paste(
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
  sep = "|"
)
DATE_PAT <- sprintf("(?:%s)\\s+\\d{1,2},?\\s+\\d{4}", MONTH_PAT)

# ── Helpers ───────────────────────────────────────────────────────────────────

find_all_dates <- function(text) {
  if (is.na(text) || nchar(trimws(text)) == 0) return(NULL)

  positions <- str_locate_all(text, DATE_PAT)[[1]]
  raw_dates <- str_extract_all(text, DATE_PAT)[[1]]
  if (length(raw_dates) == 0) return(NULL)

  pmap_dfr(list(raw_dates, positions[, 1], positions[, 2]), function(raw, s, e) {
    iso <- tryCatch(
      format(mdy(raw), "%Y-%m-%d"),
      warning = function(w) NA_character_,
      error   = function(e) NA_character_
    )
    ctx_start <- max(1L, s - 70L)
    ctx_end   <- min(nchar(text), e + 20L)
    tibble(
      date_raw = raw,
      date_iso = iso,
      pos      = s,
      context  = str_sub(text, ctx_start, ctx_end)
    )
  })
}

classify_date <- function(ctx) {
  if (is.na(ctx)) return(NA_character_)
  lo <- tolower(ctx)

  if (str_detect(lo, "repealed|(?<![a-z])expires |sunset of |sunset:.*expires|originally had a sunset|nominally expired"))
    return("date_sunset")

  if (str_detect(lo, "(?<![a-z])effective(?! for dates)|(?<![a-z])enacted"))
    return("date_effective")

  NA_character_   # ignore everything else
}

# ── Load JSON files ───────────────────────────────────────────────────────────

json_files <- dir_ls(extracted_dir, glob = "*.json")
cat(sprintf("Loading %d state files...\n", length(json_files)))

all_rows <- map(json_files, \(f) {
  tryCatch(
    fromJSON(f, simplifyDataFrame = TRUE, flatten = TRUE),
    error = \(e) { warning(sprintf("Failed: %s — %s", path_file(f), conditionMessage(e))); NULL }
  )
}) |> compact() |> bind_rows() |>
  mutate(row_id = row_number())

cat(sprintf("Total rows: %d\n", nrow(all_rows)))

# ── Extract and classify ───────────────────────────────────────────────────────

cat("Extracting dates...\n")

date_long <- all_rows |>
  select(row_id, state, condition_category, responder_type, statute_citation, notes) |>
  rowwise() |>
  mutate(found = list(find_all_dates(notes))) |>
  ungroup() |>
  unnest(found, keep_empty = TRUE) |>
  mutate(date_type = map_chr(context, classify_date)) |>
  filter(!is.na(date_type), !is.na(date_iso))

# ── Pivot wide: one row per original record ───────────────────────────────────

collapse_field <- function(x) {
  vals <- unique(x[!is.na(x)])
  if (length(vals) == 0) NA_character_ else paste(vals, collapse = " | ")
}

date_wide <- date_long |>
  group_by(row_id, date_type) |>
  summarise(
    date_value   = collapse_field(date_iso),
    date_snippet = collapse_field(context),
    .groups = "drop"
  ) |>
  pivot_wider(
    names_from  = date_type,
    values_from = c(date_value, date_snippet),
    names_glue  = "{date_type}_{.value}"
  ) |>
  rename_with(\(x) str_replace(x, "_date_value$", ""), ends_with("_date_value")) |>
  rename_with(\(x) str_replace(x, "_date_snippet$", "_snippet"), ends_with("_date_snippet"))

for (col in c("date_effective", "date_effective_snippet", "date_sunset", "date_sunset_snippet")) {
  if (!col %in% names(date_wide)) date_wide[[col]] <- NA_character_
}

# ── Join back to full row metadata ────────────────────────────────────────────

review <- all_rows |>
  select(row_id, state, condition_category, responder_type, statute_citation, notes) |>
  left_join(date_wide, by = "row_id") |>
  select(
    row_id, state, condition_category, responder_type, statute_citation,
    date_effective, date_effective_snippet,
    date_sunset,    date_sunset_snippet,
    notes
  ) |>
  mutate(
    any_date     = !is.na(date_effective) | !is.na(date_sunset),
    needs_review = str_detect(coalesce(date_effective, ""), "\\|") |
                   str_detect(coalesce(date_sunset, ""), "\\|")
  )

# ── Summary ────────────────────────────────────────────────────────────────────

cat("\n── Extraction summary ────────────────────────────────────\n")
cat(sprintf("  date_effective:      %d rows\n", sum(!is.na(review$date_effective))))
cat(sprintf("  date_sunset:         %d rows\n", sum(!is.na(review$date_sunset))))
cat(sprintf("  rows with any date:  %d / %d\n", sum(review$any_date), nrow(review)))
cat(sprintf("  multiple dates (needs review): %d\n", sum(review$needs_review, na.rm = TRUE)))

cat("\n  Rows with multiple effective dates:\n")
review |>
  filter(str_detect(coalesce(date_effective, ""), "\\|")) |>
  select(state, statute_citation, date_effective) |>
  print(width = 120)

cat("\n  Rows with multiple sunset dates:\n")
review |>
  filter(str_detect(coalesce(date_sunset, ""), "\\|")) |>
  select(state, statute_citation, date_sunset) |>
  print(width = 120)

# ── Save ───────────────────────────────────────────────────────────────────────

write_csv(review, out_csv)
cat(sprintf("\nReview CSV saved to: %s\n", out_csv))
cat("Review and correct in Excel, then run 7_write_dates_to_json.r.\n")
