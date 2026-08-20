# PROJ_presumptive_laws

**Created:** 2026-05-21

## Project Description
Interactive web dashboard mapping presumptive workers' compensation laws for first responders across all 50 US states. Covers condition type (cancer, cardiovascular, respiratory, infectious disease, COVID-19, mental health/PTSD), first responder group (firefighter, EMS, police, volunteer), and key law attributes. Built for policymakers and first responder families.

## Product Type
Quarto website with embedded Shinylive app (Shiny in WebAssembly — fully static, no server required).

## Data Sources
Primary: **independent per-state legislative research**, recorded in `docs/lit/state_histories/*_timeline.md` with per-state status and QC scores in `docs/lit/state_histories/registry.md`. All 50 states were QC-gated 97–100/100 on 2026-08-07.

**IAFF is not a source.** The IAFF Presumptive Health directory ([iaff.org/presumptive-health](https://www.iaff.org/presumptive-health/)) seeded the original dataset and was repeatedly found wrong, stale, or incomplete — omitted statutes, wrong effective dates, mischaracterized provisions. P8 (2026-08-07) removed it as the dashboard's benchmark. Treat it as a directory of leads to verify, never as an authority. The `iaff_url` column is a per-state back-link only.

Cross-check references (PDFs in `docs/lit/`, not tracked in git):
- NCCI (2023) brief — ~38 NCCI-jurisdiction states, through Nov 2022
- Brandt-Rauf et al. (2024), *JPHP* — 50-state inventory, through Dec 2022

**Source of truth is `data/raw/state_records/{AL..WY,DC}.json`** — 51 committed files, one per jurisdiction. Everything downstream is a build artifact: `data/processed/presumptive_laws_v2.rds`/`.csv`, and the two dashboard copies at `website/data/` and `website/shiny-app/data/presumptive_laws.json`. Edit the record files, never the JSON. Full field documentation in `data/codebook.md`.

## Unit of Observation
One row = one state × condition category × responder type (e.g., Texas × Cancer × Firefighter).

## Known Data Issues
- 17 rows carry a `needs_verification` note describing what is unresolved (NY 6, OH 4, AR 3, then HI/IA/KY/PA one each). The field takes explanatory text or null — never a bare boolean, since a flag with no explanation is not reviewable.
- `data_retrieved` is stale: 411 of 479 rows still read `2026-05-23` though the research behind them was re-verified 2026-08-07. Fix from the `Last Verified` column in `docs/lit/state_histories/registry.md`.
- DC is in the data but was outside the 2026-08-07 QC pass, which covered the 50 states. Its 8 rows carry lower confidence.
- Some states have partial or temporary coverage (executive orders, COVID-19 sunset provisions)
- DC is present in the data but absent from the map (not in `maps::map("state")`)

## Data Sensitivity
No restricted data. All sources are publicly available published reviews.

## File Structure

| Path | Purpose |
|------|---------|
| `analysis/code/` | R scripts: data extraction, cleaning, JSON export |
| `data/raw/` | Original source files (non-PDF versions if obtained) |
| `data/processed/` | Cleaned .rds files |
| `website/` | Quarto website source |
| `website/data/` | Precomputed JSON bundled with the static site |
| `website/_quarto.yml` | Quarto project configuration |
| `docs/admin/` | Product spec and admin docs |
| `docs/lit/` | Background PDFs |
| `docs/logs/` | Session logs and plans |

## Collaborators
Solo project. No external collaborators.

## IRB Status
Not applicable (research product using published secondary data only).

## Pre-Registration
Not applicable.

## Key Documents
- `project-brief.md` — project overview
- `docs/admin/product-spec.md` — dashboard feature spec, data model, and tech decisions

## Claude Instructions

This is a research product, not a research paper. The standard paper pipeline (Writer, Peer Review, Submission) does not apply here.

**Data update pipeline** (run in order after editing any record file in `data/raw/state_records/`):
```
Rscript analysis/code/4_combine_records.r    # validate + bind -> v2.rds/.csv
Rscript analysis/code/5_export_json.r        # write BOTH dashboard JSON copies
cd website && Rscript -e "shinylive::export('shiny-app', 'app', overwrite=TRUE)"
cd website && quarto render
bash deploy.sh   # to push live to GitHub Pages
```

No `cp` step any more — `5_export_json.r` writes both dashboard copies from one data frame and hash-verifies they match. The old manual copy is how they could silently diverge.

**`4_combine_records.r` aborts rather than coercing.** An out-of-domain `condition_category`, `responder_type`, or `presumption_type` stops the build with the offending rows printed. Do not "fix" this by widening the domain without also updating `website/shiny-app/app.R` (lines 29–92) and `data/codebook.md` — `app.R` builds its colour/label/priority lookups by name and silently renders a blank tile for a value it does not know.

**Retired, do not run:** `2_iaff_scrape.r`, `3_iaff_extract.r`, `4_iaff_combine.r`, `5_iaff_export_json.r`, and `apply_p1`–`apply_p8`. Each carries a header explaining why. `4_iaff_combine.r` in particular is destructive: its stale `valid_ptype` would silently blank the 58 `pension`/`employer_benefit`/`lodd_only` rows.

**Design principle:** Audience includes non-researchers. Plain language, minimal jargon. Every filter and label on the map should be self-explanatory without a methodology section.
