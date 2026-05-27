# PROJ_presumptive_laws

**Created:** 2026-05-21

## Project Description
Interactive web dashboard mapping presumptive workers' compensation laws for first responders across all 50 US states. Covers condition type (cancer, cardiovascular, respiratory, infectious disease, COVID-19, mental health/PTSD), first responder group (firefighter, EMS, police, volunteer), and key law attributes. Built for policymakers and first responder families.

## Product Type
Quarto website with embedded Shinylive app (Shiny in WebAssembly — fully static, no server required).

## Data Sources
- `docs/lit/Insights-Firefighters-First-Responders-2023-Update-Brief.pdf` — NCCI (2023), ~38 NCCI-jurisdiction states, WC presumptions through Nov 2022
- `docs/lit/s41271-024-00501-5.pdf` — Brandt-Rauf et al. (2024), 50-state mental health + physical condition presumptions through Dec 2022

The primary structured data lives in `data/processed/presumptive_laws.rds` and `website/data/presumptive_laws.json`. The JSON file is what the Shinylive app reads at runtime.

## Unit of Observation
One row = one state × condition category (e.g., Texas × Cancer, Texas × Mental Health/PTSD).

## Known Data Issues
- NCCI brief covers only NCCI-jurisdiction states (~38 of 50); Brandt-Rauf covers all 50
- Data current through late 2022; will need a defined update process for future versions
- Some states have partial or temporary coverage (executive orders, COVID-19 sunset provisions)
- Brandt-Rauf Table 1 distinguishes Fire/EMS only; police coverage data comes primarily from NCCI

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

**Priority order for implementation:**
1. Data extraction — extract Table 1 from Brandt-Rauf (2024) and the summary chart from the NCCI brief into a structured R data frame (`analysis/code/1_extract_data.r`)
2. Data cleaning and JSON export — produce `website/data/presumptive_laws.json`
3. Shinylive map prototype — basic US choropleth with condition-type filter
4. Full website — landing page, about page, methodology note

**Critical constraint:** The Shinylive app reads only from `website/data/presumptive_laws.json`. That file is the single source of truth for the dashboard. Keep it in sync with `data/processed/presumptive_laws.rds`.

**Design principle:** Audience includes non-researchers. Plain language, minimal jargon. Every filter and label on the map should be self-explanatory without a methodology section.
