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
last_updated: 2026-07-02
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

- Reran `/research-states` on the 6 pre-pipeline states (TX, CA, NY, FL, IL, PA) that predated the legislative-reviewer QC gate — all 6 scored 97/100. Fresh `XX_timeline.md` files and a recreated `registry.md` now exist at `docs/lit/state_histories/` for these six.
- Applied P4 corrections (`analysis/code/apply_p4_corrections.py`) to the live dashboard JSON: fixed CA § 31720.91 PTSD sunset (2029, not 2032), added TX's 2025 retiree critical-illness benefit, clarified IL's cross-track cancer standard, added PA's missing Occupational Disease Act § 1208(o) heart/lung presumption, added FL's missing smallpox provision (flagged its Ch. 2026-99 cancer amendment as unverified), and modeled all 5 of NY's parallel presumption tracks (previously only 1 was modeled) using a new NYC-specific labeling convention reused from IL's existing Article 4/6 pattern. Dashboard JSON grew from 445 to 461 rows.
- Committed (`fc40dfa`) and pushed to main.
- Next up: extend the QC-gated rerun to the remaining 44 states (`docs/lit/state_histories/` still empty for them — see open issue below); decide fate of the orphaned CSV pipeline; still outstanding — responder-type filter, year-of-adoption data, IAFF UI benchmark.

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

**Open issue (updated 2026-07-02):** `docs/lit/state_histories/` (all `XX_timeline.md` files + `registry.md`, all 50 states) was missing entirely from this machine/checkout as of the start of today's session. It's gitignored, so if it was ever populated (session logs confirm it was, as of 2026-06-02) it either lived only on another machine or was deleted. Today's session reran the QC-gated pipeline for the 6 states that predated the legislative-reviewer gate (TX, CA, NY, FL, IL, PA — all 97/100) and recreated their `XX_timeline.md` files plus `registry.md` at `docs/lit/state_histories/`. The other 44 states' timeline files/registry entries are still missing and unrecovered. Every dated item under "Pending Notes" below that references a state outside this set of 6 still can't be actioned until its `XX_timeline.md` is recovered or regenerated.

**Open issue (updated 2026-07-02):** `data/processed/presumptive_laws_v2.csv` has diverged from the live `website/shiny-app/data/presumptive_laws.json` (~32 rows out of sync). Corrections have been hand-patched directly into the JSON via one-off Python scripts (`apply_p1/p2/p3_corrections.py`, and now `apply_p4_corrections.py`), bypassing the CSV/RDS pipeline (`4_iaff_combine.r` / `5_iaff_export_json.r`) entirely. The CSV is effectively orphaned and now further out of sync given the P4 additions (JSON is at 461 rows). Worth deciding whether to retire the CSV pipeline or restore it as the source of truth.

**Open issue (added 2026-07-02):** The P4 patch missed a completeness gap — Peter caught it by eyeballing the live map: TX's pre-pipeline data (2026-05-23) had zero `law_enforcement` rows for cardiovascular, respiratory, or infectious/TB, despite the fresh research confirming peace officers ARE covered under those Gov't Code sections. P4 only checked for content the research explicitly flagged as *wrong*; it didn't audit for rows that were simply *missing* with nothing flagging the omission. Fixed for TX via `apply_p5_corrections.py` (461 → 465 rows). **Not yet checked for the other 5 states (CA, NY, FL, IL, PA)** — same failure mode could be present there too. Next state-data session should cross-check every condition/responder-type combination the research confirms exists against what's actually in the live JSON, not just re-verify what was already flagged as a discrepancy.

## Pending Notes

- 2026-07-07 | Verify Ohio PTSD fund transfer: ORC § 126.65 mandated $40M transfer to fund on July 1, 2026. Confirm transfer occurred, check whether claim procedures were promulgated by OBM/OP&F, and verify volunteer FF coverage question. Update OH_timeline.md Key Gaps 3 and 5 accordingly.
- 2026-09-01 | Arizona PTSD counseling sunset watch: A.R.S. § 38-673 (Officer Craig Tiger Act, expanded counseling benefit) expires January 1, 2027. The 57th Legislature's regular session ended ~June 2026 without confirmed renewal. If no special session acts, the benefit lapses on January 1. Also check status of HB 2204 (2026 PTSD WC presumption bill). Update AZ_timeline.md Expirations table accordingly.
- 2026-08-15 | Colorado SB26-184 signature verification: Bill passed legislature May 2026, sent to Governor Polis; effective date August 12, 2026 contingent on signature. Verify whether signed or vetoed. If signed: cancer list expands (adds lung, kidney, mesothelioma), Parkinson's Disease added, rebuttal standard raised to clear-and-convincing. Update CO_timeline.md Key Gap #1 and Primary Statutes table accordingly.
- 2027-01-15 | West Virginia cancer sunset watch: W.Va. Code § 23-4-1(h) bladder cancer, mesothelioma, and testicular cancer sunset July 1, 2027. HB 2197 (2025) extension failed. Legislature must act in 2027 session (Jan-Mar) to prevent lapse. Check bill status early in session. If no extension enacted, update WV_timeline.md Expirations table and flag coverage gap. Note: leukemia/lymphoma/myeloma already lapsed July 1, 2023 to March 8, 2024 — claims during that gap period remain unresolved.
- 2026-09-15 | Hawaii § 386-21.9 breast cancer amendment verification: IAFF page lists breast cancer and female reproductive organs as covered under HRS § 386-21.9, but Justia's 2024 edition of that statute does not include those types. Likely a 2025 session amendment. Confirm act number and effective date; update HI_timeline.md cancer list and Sources accordingly. Also check whether any PTSD bills were introduced in the 2021-2026 sessions.
- 2026-09-01 | Utah HB 416 signature verification: HB 416 (2026) cancer benefit trust fund passed both chambers but gubernatorial signature was unconfirmed at research date. Confirm signed or vetoed. If signed, update UT_timeline.md Key Gap #1 and add trust fund to Primary Statutes table.
- 2027-01-15 | Nebraska § 48-101.01 PTSD sunset watch: Prima facie evidence provision for mental health WC claims sunsets January 1, 2028. Legislature must act in 2027 session to renew. Also monitor LB400 reintroduction (WC cancer presumption, failed April 2026 on cloture 32-15). Update NE_timeline.md if either bill passes.
- 2027-06-01 | Montana 2027 session — PTSD and cancer: (1) SB 394 PTSD bill was vetoed June 2025 but governor indicated openness to alternative approach in 2027. Monitor for new bill. (2) Verify that Ch. 442 L. 2023 added non-Hodgkin's lymphoma and testicular cancer to MCA § 39-71-1401 — those two conditions have unverified enactment dates. Update MT_timeline.md accordingly.
