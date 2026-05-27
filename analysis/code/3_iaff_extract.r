# Project: PROJ_presumptive_laws
# Script:  3_iaff_extract.r
# Created: 2026-05-23
# Purpose: Extract structured law data from IAFF HTML files using Claude API.
#          Reads raw HTML from data/raw/iaff_html/, sends main-content text
#          to Claude (claude-haiku-4-5), parses JSON responses, saves results.
#          Phase 2 of the IAFF data rebuild pipeline.
#
# BEFORE RUNNING: Add your Anthropic API key to ~/.Renviron:
#   ANTHROPIC_API_KEY='sk-ant-...'
# Then restart R (or run readRenviron("~/.Renviron")).
#
# MODELS: Uses claude-haiku-4-5-20251001 by default (fast, cheap ~$0.003/state).
#         Change EXTRACT_MODEL below to claude-sonnet-4-6 for higher accuracy
#         on complex states (CA, FL, NY) if needed.
#
# CHECKPOINTING: Already-extracted states are skipped on re-run. Safe to
#         interrupt and resume.

if (!require("pacman")) install.packages("pacman")
pacman::p_load(here, httr2, jsonlite, fs, dplyr, readr, stringr, purrr)

# ── Config ─────────────────────────────────────────────────────────────────────

EXTRACT_MODEL  <- "claude-haiku-4-5-20251001"
ANTHROPIC_VER  <- "2023-06-01"
MAX_TOKENS     <- 4096
RETRY_DELAY_S  <- 2.0   # seconds between API calls (rate limit courtesy)

html_dir   <- here("data", "raw", "iaff_html")
out_dir    <- here("data", "raw", "iaff_extracted")
final_path <- here("data", "processed", "iaff_extracted_raw.rds")
log_path   <- here("data", "raw", "iaff_extract_log.csv")

dir_create(out_dir)
dir_create(here("data", "processed"))

# ── API key check ──────────────────────────────────────────────────────────────

api_key <- Sys.getenv("ANTHROPIC_API_KEY")
if (nchar(api_key) == 0) {
  stop(
    "ANTHROPIC_API_KEY not found in environment.\n",
    "Add it to ~/.Renviron:\n",
    "  ANTHROPIC_API_KEY='sk-ant-...'\n",
    "Then run: readRenviron('~/.Renviron')"
  )
}

# ── HTML cleaning helpers ──────────────────────────────────────────────────────

# Extract <main> block and return cleaned plain text
clean_html <- function(html) {
  # Pull the <main> block — all law content lives here
  main_match <- str_match(html, regex("<main[^>]*>(.*?)</main>", dotall = TRUE))
  if (is.na(main_match[1, 1])) {
    warning("No <main> block found — falling back to full HTML")
    content <- html
  } else {
    content <- main_match[1, 2]
  }

  # Strip all HTML tags
  content <- str_replace_all(content, "<[^>]+>", " ")

  # Decode common HTML entities
  entity_map <- c(
    "&amp;"   = "&",
    "&#8217;" = "'",
    "&#8216;" = "'",
    "&#8220;" = "\"",
    "&#8221;" = "\"",
    "&#8212;" = "—",
    "&#8211;" = "–",
    "&nbsp;"  = " ",
    "&lt;"    = "<",
    "&gt;"    = ">",
    "&#167;"  = "§",
    "&sect;"  = "§"
  )
  for (ent in names(entity_map)) {
    content <- str_replace_all(content, fixed(ent), entity_map[[ent]])
  }

  # Collapse whitespace
  content <- str_replace_all(content, "\\s+", " ")
  str_trim(content)
}

# ── Extraction prompt ──────────────────────────────────────────────────────────

make_prompt <- function(state_name_full, state_abb, page_text) {
  paste0(
'You are a legal data extraction assistant. Extract structured information from
the following US state presumptive workers\' compensation law page for ',
state_name_full, ' (', toupper(state_abb), ').

Return ONLY a valid JSON array — no explanation, no markdown, no code fences.
Each element in the array represents ONE unique combination of:
  - condition_category
  - responder_type

Only include rows where coverage information is EXPLICITLY stated on the page.
Do not infer or assume coverage that is not stated.

For each row, return an object with EXACTLY these fields:

{
  "condition_category": one of: "cancer" | "cardiovascular" | "respiratory" | "infectious" | "mental" | "other",
  "condition_specific": "free text — list specific conditions/cancer types exactly as named in the statute, or null if not specified beyond the category",
  "responder_type": one of: "firefighter" | "firefighter_volunteer" | "emt_paramedic" | "law_enforcement" | "corrections",
  "presumption_type": one of: "statute" | "EO" | "expired" | "none",
  "presumption_exists": true or false,
  "rebuttable": true (disputable/rebuttable) | false (irrebuttable) | null (not stated),
  "statute_citation": "primary statute citation(s) as written on the page, or null",
  "years_service_required": integer minimum years of service, or null if none stated,
  "pre_employment_exam_required": true | false | null,
  "post_termination_months": integer — the MAXIMUM months of post-employment coverage, or null if not stated or if coverage requires active employment only,
  "post_termination_formula": "string describing how the window is calculated if it is not a flat number (e.g., \'3 months per year of service, max 60 months\'), or null if it is a flat number or not stated",
  "discovery_during_employment_required": true (disease must be discovered WHILE employed) | false | null (not stated),
  "filing_deadline_notes": "any language about deadlines for filing claims after leaving employment or after diagnosis, or null",
  "tobacco_exclusion": true | false | null,
  "notes": "any other notable timing language, sunset/expiration dates, special carve-outs, or unusual provisions — be concise"
}

TIMING FIELDS — pay special attention:
- post_termination_months: if the statute says "60 months after termination," set to 60. If it says "3 months per year of service up to 60 months," set post_termination_months to 60 AND post_termination_formula to the formula string.
- discovery_during_employment_required: set to true if the statute says the disease must be found/discovered DURING employment (not after retirement). Set to false if coverage explicitly extends post-retirement. Null if not stated.
- filing_deadline_notes: capture any language like "must file within X years of leaving employment" or "claim must be made within Y months of diagnosis."

RESPONDER TYPE RULES:
- "firefighter" = paid/career firefighters only
- "firefighter_volunteer" = volunteer firefighters (often same statute section but noted separately)
- "emt_paramedic" = EMTs, paramedics, emergency care attendants
- "law_enforcement" = police officers, peace officers, sheriffs, investigators, highway patrol
- "corrections" = correctional officers, jail officers

If the same statute section covers firefighters AND EMTs with identical terms, create TWO rows.
If volunteers are covered under the same terms as paid firefighters, create a separate "firefighter_volunteer" row.
If a condition category has no coverage for a given responder type, do NOT include a row for it.

CONDITION CATEGORY RULES:
- "cancer" = all cancers, leukemia, lymphoma, myeloma, melanoma
- "cardiovascular" = heart disease, hypertension, acute MI, stroke, cardiac events
- "respiratory" = lung disease, pneumonia, respiratory illness (NOT tuberculosis — see infectious)
- "infectious" = tuberculosis, hepatitis, HIV, meningitis, bloodborne pathogens, MRSA, COVID-19
- "mental" = PTSD, behavioral health, mental trauma, stress disorders
- "other" = Parkinson\'s, hernia, lower back, Lyme disease, biochemical/WMD exposure, smallpox/immunization, any condition not fitting above

If a statute covers both cardiovascular AND respiratory (e.g., "heart disease and lung disease"), create separate rows for each category.

Page content:
', page_text
  )
}

# ── State name lookup ──────────────────────────────────────────────────────────

state_names <- c(
  al = "Alabama", ak = "Alaska", az = "Arizona", ar = "Arkansas",
  ca = "California", co = "Colorado", ct = "Connecticut", de = "Delaware",
  dc = "District of Columbia", fl = "Florida", ga = "Georgia", hi = "Hawaii",
  id = "Idaho", il = "Illinois", `in` = "Indiana", ia = "Iowa",
  ks = "Kansas", ky = "Kentucky", la = "Louisiana", me = "Maine",
  md = "Maryland", ma = "Massachusetts", mi = "Michigan", mn = "Minnesota",
  ms = "Mississippi", mo = "Missouri", mt = "Montana", ne = "Nebraska",
  nv = "Nevada", nh = "New Hampshire", nj = "New Jersey", nm = "New Mexico",
  ny = "New York", nc = "North Carolina", nd = "North Dakota", oh = "Ohio",
  ok = "Oklahoma", or = "Oregon", pa = "Pennsylvania", ri = "Rhode Island",
  sc = "South Carolina", sd = "South Dakota", tn = "Tennessee", tx = "Texas",
  ut = "Utah", vt = "Vermont", va = "Virginia", wa = "Washington",
  wv = "West Virginia", wi = "Wisconsin", wy = "Wyoming"
)

# ── API call ───────────────────────────────────────────────────────────────────

call_claude <- function(prompt_text, state_abb) {
  resp <- tryCatch(
    request("https://api.anthropic.com/v1/messages") |>
      req_headers(
        `x-api-key`         = api_key,
        `anthropic-version` = ANTHROPIC_VER,
        `content-type`      = "application/json"
      ) |>
      req_body_json(list(
        model      = EXTRACT_MODEL,
        max_tokens = MAX_TOKENS,
        messages   = list(
          list(role = "user", content = prompt_text)
        )
      )) |>
      req_timeout(60) |>
      req_perform(),
    error = function(e) {
      message(sprintf("  API request error for %s: %s", toupper(state_abb), conditionMessage(e)))
      NULL
    }
  )

  if (is.null(resp)) return(NULL)

  code <- resp_status(resp)
  if (code != 200) {
    message(sprintf("  HTTP %d for %s", code, toupper(state_abb)))
    return(NULL)
  }

  body <- resp_body_json(resp)
  raw_text <- body$content[[1]]$text

  # Strip markdown code fences if Claude wrapped the JSON
  raw_text <- str_replace_all(raw_text, "^```json\\s*|^```\\s*|```\\s*$", "")
  raw_text <- str_trim(raw_text)

  tryCatch(
    fromJSON(raw_text, simplifyVector = FALSE),
    error = function(e) {
      message(sprintf("  JSON parse error for %s: %s", toupper(state_abb), conditionMessage(e)))
      message(sprintf("  Raw response (first 500 chars): %s", substr(raw_text, 1, 500)))
      NULL
    }
  )
}

# ── Main extraction loop ───────────────────────────────────────────────────────

html_files <- dir_ls(html_dir, glob = "*.html")
state_abbs <- path_ext_remove(path_file(html_files))

log_rows <- vector("list", length(state_abbs))

cat(sprintf("Extracting %d states using %s\n\n", length(state_abbs), EXTRACT_MODEL))

for (i in seq_along(state_abbs)) {
  abb        <- state_abbs[i]
  state_name <- state_names[abb]
  if (is.na(state_name)) state_name <- toupper(abb)  # DC fallback

  out_path <- path(out_dir, paste0(abb, ".json"))

  cat(sprintf("[%02d/%02d] %s (%s) ... ", i, length(state_abbs), state_name, toupper(abb)))

  # Checkpoint: skip if already extracted
  if (file_exists(out_path)) {
    cat("already extracted, skipping\n")
    log_rows[[i]] <- tibble(
      state_abb = abb, status = "skipped", rows_extracted = NA_integer_,
      model = EXTRACT_MODEL, extracted_at = NA_character_
    )
    next
  }

  # Read and clean HTML
  html_text <- read_file(path(html_dir, paste0(abb, ".html")))
  page_text <- clean_html(html_text)

  # Build prompt and call API
  prompt <- make_prompt(state_name, abb, page_text)
  result <- call_claude(prompt, abb)

  if (is.null(result)) {
    cat("FAILED\n")
    log_rows[[i]] <- tibble(
      state_abb = abb, status = "failed", rows_extracted = 0L,
      model = EXTRACT_MODEL, extracted_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    )
    next
  }

  # Add state metadata to each row
  result_with_meta <- lapply(result, function(row) {
    row$state           <- toupper(abb)
    row$state_name      <- state_name
    row$iaff_url        <- paste0("https://www.iaff.org/presumptive-health/", abb, "/")
    row$data_retrieved  <- as.character(Sys.Date())
    row
  })

  # Save individual state JSON (checkpoint)
  write_json(result_with_meta, out_path, auto_unbox = TRUE, pretty = TRUE)

  n_rows <- length(result_with_meta)
  cat(sprintf("OK  (%d rows)\n", n_rows))

  log_rows[[i]] <- tibble(
    state_abb = abb, status = "ok", rows_extracted = n_rows,
    model = EXTRACT_MODEL, extracted_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )

  # Polite delay
  if (i < length(state_abbs)) Sys.sleep(RETRY_DELAY_S)
}

# ── Combine and save ───────────────────────────────────────────────────────────

log_df <- bind_rows(log_rows)
write_csv(log_df, log_path)

cat("\n── Combining extracted JSON files ───────────────\n")

json_files <- dir_ls(out_dir, glob = "*.json")
all_rows <- map(json_files, ~ fromJSON(.x, simplifyDataFrame = TRUE)) |>
  bind_rows()

# Coerce types
all_rows <- all_rows |>
  mutate(
    presumption_exists                   = as.logical(presumption_exists),
    rebuttable                           = as.logical(rebuttable),
    pre_employment_exam_required         = as.logical(pre_employment_exam_required),
    discovery_during_employment_required = as.logical(discovery_during_employment_required),
    tobacco_exclusion                    = as.logical(tobacco_exclusion),
    years_service_required               = as.integer(years_service_required),
    post_termination_months              = as.integer(post_termination_months),
    condition_category = factor(condition_category,
      levels = c("cancer", "cardiovascular", "respiratory", "infectious", "mental", "other")),
    responder_type = factor(responder_type,
      levels = c("firefighter", "firefighter_volunteer", "emt_paramedic",
                 "law_enforcement", "corrections")),
    presumption_type = factor(presumption_type,
      levels = c("statute", "EO", "expired", "none"))
  )

saveRDS(all_rows, final_path)

# ── Summary ────────────────────────────────────────────────────────────────────

cat(sprintf("\n── Extraction summary ───────────────────────────\n"))
cat(sprintf("  Total states processed: %d\n",  nrow(log_df)))
cat(sprintf("  Successful:             %d\n",  sum(log_df$status == "ok")))
cat(sprintf("  Skipped (cached):       %d\n",  sum(log_df$status == "skipped")))
cat(sprintf("  Failed:                 %d\n",  sum(log_df$status == "failed")))
cat(sprintf("  Total rows extracted:   %d\n",  nrow(all_rows)))
cat(sprintf("  Saved to:               %s\n",  final_path))

cat("\n  Rows by condition:\n")
print(table(all_rows$condition_category))
cat("\n  Rows by responder type:\n")
print(table(all_rows$responder_type))

# Flag low-row states for manual review
low_row_states <- log_df |> filter(status == "ok", rows_extracted < 3)
if (nrow(low_row_states) > 0) {
  cat("\n  WARNING — states with < 3 rows (check manually):\n")
  for (j in seq_len(nrow(low_row_states))) {
    cat(sprintf("    %s (%d rows)\n",
                toupper(low_row_states$state_abb[j]),
                low_row_states$rows_extracted[j]))
  }
}

failures <- log_df |> filter(status == "failed")
if (nrow(failures) > 0) {
  cat("\n  FAILED states (re-run script to retry):\n")
  for (j in seq_len(nrow(failures))) {
    cat(sprintf("    %s\n", toupper(failures$state_abb[j])))
  }
}
