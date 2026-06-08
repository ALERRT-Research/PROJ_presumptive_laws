---
project: Presumptive Laws Dashboard
type: web
status: active
priority: medium
path: /Users/PTT2/Documents/GitHub/PROJ_presumptive_laws
deadline: null
target: null
effort_remaining: ~10h
weekly_commitment: 2h
last_updated: 2026-06-09
blockers: null
blocking_others: null
funding_prospect: Blue Cancer Connect (BCC) — meeting with CEO Vickie Speed scheduled Thu or Fri June 12-13; may include JC Barnes; exploratory re: what BCC would fund in the presumptive laws space
phase: in-progress
repo: https://github.com/ALERRT-Research/PROJ_presumptive_laws
sync: github
---

## Objectives

- Interactive Quarto website with embedded Shinylive app (fully static, no server) mapping presumptive workers' compensation laws for first responders across all 50 US states
- Covers condition type (cancer, cardiovascular, respiratory, infectious disease, COVID-19, mental health/PTSD), first responder group (firefighter, EMS, police, volunteer), and key law attributes
- Audience: policymakers and first responder families — plain language, no jargon
- Funding: ALERRT internal

## This Week

- Meeting with Vickie Speed (Blue Cancer Connect CEO), possibly JC Barnes — Thu or Fri June 12-13. Exploratory: what is BCC interested in funding in the presumptive laws space? Come prepared with a one-paragraph description of the project and a sense of what external funding could unlock (data updates, expanded coverage, dissemination).
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

## Pending Notes

- 2026-07-07 | Verify Ohio PTSD fund transfer: ORC § 126.65 mandated $40M transfer to fund on July 1, 2026. Confirm transfer occurred, check whether claim procedures were promulgated by OBM/OP&F, and verify volunteer FF coverage question. Update OH_timeline.md Key Gaps 3 and 5 accordingly.
- 2026-09-01 | Arizona PTSD counseling sunset watch: A.R.S. § 38-673 (Officer Craig Tiger Act, expanded counseling benefit) expires January 1, 2027. The 57th Legislature's regular session ended ~June 2026 without confirmed renewal. If no special session acts, the benefit lapses on January 1. Also check status of HB 2204 (2026 PTSD WC presumption bill). Update AZ_timeline.md Expirations table accordingly.
- 2026-08-15 | Colorado SB26-184 signature verification: Bill passed legislature May 2026, sent to Governor Polis; effective date August 12, 2026 contingent on signature. Verify whether signed or vetoed. If signed: cancer list expands (adds lung, kidney, mesothelioma), Parkinson's Disease added, rebuttal standard raised to clear-and-convincing. Update CO_timeline.md Key Gap #1 and Primary Statutes table accordingly.
- 2027-01-15 | West Virginia cancer sunset watch: W.Va. Code § 23-4-1(h) bladder cancer, mesothelioma, and testicular cancer sunset July 1, 2027. HB 2197 (2025) extension failed. Legislature must act in 2027 session (Jan-Mar) to prevent lapse. Check bill status early in session. If no extension enacted, update WV_timeline.md Expirations table and flag coverage gap. Note: leukemia/lymphoma/myeloma already lapsed July 1, 2023 to March 8, 2024 — claims during that gap period remain unresolved.
- 2026-09-15 | Hawaii § 386-21.9 breast cancer amendment verification: IAFF page lists breast cancer and female reproductive organs as covered under HRS § 386-21.9, but Justia's 2024 edition of that statute does not include those types. Likely a 2025 session amendment. Confirm act number and effective date; update HI_timeline.md cancer list and Sources accordingly. Also check whether any PTSD bills were introduced in the 2021-2026 sessions.
- 2026-09-01 | Utah HB 416 signature verification: HB 416 (2026) cancer benefit trust fund passed both chambers but gubernatorial signature was unconfirmed at research date. Confirm signed or vetoed. If signed, update UT_timeline.md Key Gap #1 and add trust fund to Primary Statutes table.
- 2027-01-15 | Nebraska § 48-101.01 PTSD sunset watch: Prima facie evidence provision for mental health WC claims sunsets January 1, 2028. Legislature must act in 2027 session to renew. Also monitor LB400 reintroduction (WC cancer presumption, failed April 2026 on cloture 32-15). Update NE_timeline.md if either bill passes.
- 2027-06-01 | Montana 2027 session — PTSD and cancer: (1) SB 394 PTSD bill was vetoed June 2025 but governor indicated openness to alternative approach in 2027. Monitor for new bill. (2) Verify that Ch. 442 L. 2023 added non-Hodgkin's lymphoma and testicular cancer to MCA § 39-71-1401 — those two conditions have unverified enactment dates. Update MT_timeline.md accordingly.
