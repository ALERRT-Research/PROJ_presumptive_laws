# PROJ_presumptive_laws

**Created:** 2026-05-21

## Project Description
Interactive web dashboard mapping presumptive workers' compensation laws for first responders across all 50 US states. Covers condition type (cancer, cardiovascular, respiratory, infectious disease, COVID-19, mental health/PTSD), first responder group (firefighter, EMS, police, volunteer), and key law attributes. Built for policymakers and first responder families.

## Product Type
Quarto website with embedded Shinylive app (Shiny in WebAssembly — fully static, no server required).

## Data Sources
Primary: **IAFF Presumptive Health database** ([iaff.org/presumptive-health](https://www.iaff.org/presumptive-health/)) — all 50 states, actively maintained, scraped via `analysis/code/2_iaff_scrape.r`.

Cross-check references (PDFs in `docs/lit/`, not tracked in git):
- NCCI (2023) brief — ~38 NCCI-jurisdiction states, through Nov 2022
- Brandt-Rauf et al. (2024), *JPHP* — 50-state inventory, through Dec 2022

The active dataset is `data/processed/presumptive_laws_v2.rds` and `website/shiny-app/data/presumptive_laws.json`. The JSON is what the Shinylive app reads at runtime. Keep these in sync via the pipeline in `analysis/code/5_iaff_export_json.r`.

## Unit of Observation
One row = one state × condition category × responder type (e.g., Texas × Cancer × Firefighter).

## Known Data Issues
- A small number of entries are flagged `needs_verification: true` where active status is uncertain (currently NY cancer and respiratory — see `data/raw/iaff_extracted/ny.json`)
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

**Data update pipeline** (run in order after editing any state JSON in `data/raw/iaff_extracted/`):
```
Rscript analysis/code/4_iaff_combine.r
Rscript analysis/code/5_iaff_export_json.r
cp website/data/presumptive_laws.json website/shiny-app/data/presumptive_laws.json
cd website && Rscript -e "shinylive::export('shiny-app', 'dashboard', overwrite=TRUE)"
cd website && quarto render
bash deploy.sh   # to push live to GitHub Pages
```

**Critical constraint:** The Shinylive app reads only from `website/shiny-app/data/presumptive_laws.json`. That file must be kept in sync with `data/processed/presumptive_laws_v2.rds` via the pipeline above.

**Design principle:** Audience includes non-researchers. Plain language, minimal jargon. Every filter and label on the map should be self-explanatory without a methodology section.
