---
project: Presumptive Laws Dashboard
type: web
status: active
priority: medium
path: /Users/PTT2/Library/CloudStorage/OneDrive-SharedLibraries-TexasStateUniversity/Martaindale, M Hunter - Research/Projects/Current Projects/PROJ_presumptive_laws
deadline: null
target: null
effort_remaining: ~20h
weekly_commitment: 2h
last_updated: 2026-05-22
blockers: null
blocking_others: null
phase: in-progress
repo: null
sync: onedrive
---

## Objectives

- Interactive Quarto website with embedded Shinylive app (fully static, no server) mapping presumptive workers' compensation laws for first responders across all 50 US states
- Covers condition type (cancer, cardiovascular, respiratory, infectious disease, COVID-19, mental health/PTSD), first responder group (firefighter, EMS, police, volunteer), and key law attributes
- Audience: policymakers and first responder families — plain language, no jargon
- Funding: ALERRT internal

## This Week

- Add responder-type filter (firefighter, EMS, police, volunteer)
- Populate year-of-adoption data
- Benchmark UI against IAFF presumptive health page (https://www.iaff.org/presumptive-health/)

## Upcoming Milestones

- Responder-type filter complete
- Year-of-adoption data populated
- UI improvements based on IAFF benchmark
- Ship when ready (no hard deadline)

## Team & Dependencies

| Name | Role | Institution |
|------|------|-------------|
| Peter Tanksley | PI (solo) | ALERRT / Texas State University |

## Notes

MVP map is working. Next steps are feature expansion (responder-type filter, year data) and UI polish.

Data source: `website/data/presumptive_laws.json` — single source of truth for the Shinylive app. Keep in sync with `data/processed/presumptive_laws.rds`.

Data current through late 2022 (NCCI brief + Brandt-Rauf 2024). Laws have likely changed; update process TBD.
