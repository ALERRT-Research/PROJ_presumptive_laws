# Project: PROJ_presumptive_laws
# Script:  5_export_json.r
# Created: 2026-05-23 (as 5_iaff_export_json.r; renamed 2026-08-20)
# Purpose: Export the combined dataset to the JSON the Shinylive dashboard reads.
#          Stage 2 (final) of the data pipeline -- run after 4_combine_records.r.
#
# Renamed from 5_iaff_export_json.r: IAFF is no longer the data's source (P8,
# 2026-08-07), so the old name was misleading.
#
# Writes BOTH dashboard copies. The app reads website/shiny-app/data/ at runtime;
# website/data/ is the copy the Quarto site serves. Until 2026-08-20 this script
# wrote only the latter and the former was kept current by hand (see
# docs/logs/2026-05-27_session3.md), which is a silent-divergence risk: the app
# would keep serving stale data while the exported file looked fresh. Both paths
# are now written from the same data frame and hash-verified.

if (!require("pacman")) install.packages("pacman")
pacman::p_load(here, dplyr, jsonlite, digest, fs)

rds_path   <- here("data", "processed", "presumptive_laws_v2.rds")
json_paths <- c(
  here("website", "data", "presumptive_laws.json"),
  here("website", "shiny-app", "data", "presumptive_laws.json")
)

df <- readRDS(rds_path)
cat(sprintf("Loaded: %d rows, %d jurisdictions\n", nrow(df), n_distinct(df$state)))

# Factors back to character for JSON. Integer and logical columns serialize as
# native JSON numbers and booleans; NA becomes null via na = "null" below.
df_out <- df |> mutate(across(where(is.factor), as.character))

for (p in json_paths) {
  dir_create(path_dir(p))
  write_json(df_out, p,
             auto_unbox = TRUE,
             pretty     = FALSE,
             na         = "null",
             null       = "null")
  cat(sprintf("  Wrote %s (%.1f KB)\n", path_rel(p, here()), file.size(p) / 1024))
}

# ── Verify the two copies are identical ───────────────────────────────────────

hashes <- vapply(json_paths, function(p) digest(p, algo = "sha256", file = TRUE), "")
if (length(unique(hashes)) != 1L) {
  cat("\n  Hashes:\n")
  for (i in seq_along(json_paths))
    cat(sprintf("    %s  %s\n", substr(hashes[i], 1, 16), path_rel(json_paths[i], here())))
  stop("The two dashboard JSON copies differ. They are written from the same data ",
       "frame, so this indicates a write failure or a permissions problem.")
}
cat(sprintf("\n  Both copies identical (sha256 %s...)\n", substr(hashes[1], 1, 16)))

# ── Sanity report ─────────────────────────────────────────────────────────────

roundtrip <- fromJSON(json_paths[1], simplifyDataFrame = TRUE)
cat(sprintf("  Round-trip check: %d rows, %d columns\n",
            nrow(roundtrip), ncol(roundtrip)))
if (nrow(roundtrip) != nrow(df))
  stop("Round-trip row count mismatch: wrote ", nrow(df), ", read ", nrow(roundtrip))
cat(sprintf("  Rows with a source_url: %d of %d\n",
            sum(!is.na(roundtrip$source_url)), nrow(roundtrip)))

cat("\nDone. Re-export the Shinylive app next:\n")
cat("  cd website && Rscript -e \"shinylive::export('shiny-app', 'app', overwrite=TRUE)\"\n")
cat("  cd website && quarto render\n")
# Target is website/app/ -- that is what coverage-map.qmd embeds (src="app/index.html")
# and what git tracks (242 files). The old script said "dashboard", which is an untracked,
# gitignored leftover that nothing reads. Exporting there looks like success and changes
# nothing on the site.
