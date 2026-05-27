# Project: PROJ_presumptive_laws
# Script:  2_iaff_scrape.r
# Created: 2026-05-23
# Purpose: Scrape raw HTML from IAFF Presumptive Health Initiative pages,
#          one page per US state + DC. Saves to data/raw/iaff_html/.
#          Phase 1 of the IAFF data rebuild pipeline.

if (!require("pacman")) install.packages("pacman")
pacman::p_load(here, httr2, fs, tibble, dplyr, readr)

# ── Directories ────────────────────────────────────────────────────────────────

html_dir <- here("data", "raw", "iaff_html")
log_path <- here("data", "raw", "iaff_scrape_log.csv")
dir_create(html_dir)

# ── State list ─────────────────────────────────────────────────────────────────

# All 50 states + DC; IAFF uses lowercase 2-letter abbreviations
state_abbs <- c(
  "al", "ak", "az", "ar", "ca", "co", "ct", "de", "dc", "fl",
  "ga", "hi", "id", "il", "in", "ia", "ks", "ky", "la", "me",
  "md", "ma", "mi", "mn", "ms", "mo", "mt", "ne", "nv", "nh",
  "nj", "nm", "ny", "nc", "nd", "oh", "ok", "or", "pa", "ri",
  "sc", "sd", "tn", "tx", "ut", "vt", "va", "wa", "wv", "wi", "wy"
)

base_url <- "https://www.iaff.org/presumptive-health/"

# ── Scrape loop ────────────────────────────────────────────────────────────────

results <- vector("list", length(state_abbs))

for (i in seq_along(state_abbs)) {
  abb <- state_abbs[i]
  url <- paste0(base_url, abb, "/")
  out_path <- path(html_dir, paste0(abb, ".html"))

  cat(sprintf("[%02d/%02d] %s ... ", i, length(state_abbs), toupper(abb)))

  # Skip if already downloaded (allows resuming interrupted runs)
  if (file_exists(out_path)) {
    cat("already exists, skipping\n")
    results[[i]] <- tibble(
      state_abb = abb,
      url       = url,
      status    = "skipped",
      http_code = NA_integer_,
      file_size_kb = file_size(out_path) / 1024,
      retrieved_at = NA_character_
    )
    next
  }

  # Fetch with browser-like headers to avoid bot detection
  resp <- tryCatch(
    request(url) |>
      req_headers(
        `User-Agent`      = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        `Accept`          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        `Accept-Language` = "en-US,en;q=0.9"
      ) |>
      req_timeout(30) |>
      req_perform(),
    error = function(e) {
      message(sprintf("ERROR: %s", conditionMessage(e)))
      NULL
    }
  )

  if (is.null(resp)) {
    cat("FAILED (request error)\n")
    results[[i]] <- tibble(
      state_abb    = abb,
      url          = url,
      status       = "error",
      http_code    = NA_integer_,
      file_size_kb = NA_real_,
      retrieved_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    )
  } else {
    code <- resp_status(resp)

    if (code == 200) {
      html_text <- resp_body_string(resp)
      write_file(html_text, out_path)
      size_kb <- file_size(out_path) / 1024
      cat(sprintf("OK  (%d KB)\n", round(size_kb)))
      results[[i]] <- tibble(
        state_abb    = abb,
        url          = url,
        status       = "ok",
        http_code    = code,
        file_size_kb = size_kb,
        retrieved_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      )
    } else {
      cat(sprintf("HTTP %d\n", code))
      results[[i]] <- tibble(
        state_abb    = abb,
        url          = url,
        status       = "http_error",
        http_code    = code,
        file_size_kb = NA_real_,
        retrieved_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      )
    }
  }

  # Polite delay: 1.5–3 seconds, randomized
  if (i < length(state_abbs)) Sys.sleep(runif(1, 1.5, 3.0))
}

# ── Log results ────────────────────────────────────────────────────────────────

log_df <- bind_rows(results)
write_csv(log_df, log_path)

# ── Summary ────────────────────────────────────────────────────────────────────

cat("\n── Scrape summary ───────────────────────────────\n")
cat(sprintf("  Total states:  %d\n", nrow(log_df)))
cat(sprintf("  OK:            %d\n", sum(log_df$status == "ok")))
cat(sprintf("  Skipped:       %d\n", sum(log_df$status == "skipped")))
cat(sprintf("  HTTP errors:   %d\n", sum(log_df$status == "http_error")))
cat(sprintf("  Request errors:%d\n", sum(log_df$status == "error")))
cat(sprintf("  Log saved to:  %s\n", log_path))

failures <- log_df[log_df$status %in% c("http_error", "error"), ]
if (nrow(failures) > 0) {
  cat("\n  FAILED STATES:\n")
  for (j in seq_len(nrow(failures))) {
    cat(sprintf("    %s — %s (HTTP %s)\n",
                toupper(failures$state_abb[j]),
                failures$status[j],
                ifelse(is.na(failures$http_code[j]), "N/A",
                       as.character(failures$http_code[j]))))
  }
  cat("\n  Re-run the script to retry failed states (already-downloaded files are skipped).\n")
} else {
  cat("\n  All states downloaded successfully.\n")
}
