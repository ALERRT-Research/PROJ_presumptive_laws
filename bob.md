---
card_schema: bob/2
project: Presumptive Laws Dashboard
type: web
status: active
priority: medium
importance: medium  # set by Bob 2026-10-16: public advocacy asset tied to the Vickie Speed / BCC relationship, no deadline — Peter may override
path: /Users/PTT2/Documents/GitHub/PROJ_presumptive_laws
deadline: null
target: null
effort_remaining: Federal-coverage layer (P.L. 119-60 § 8205) not started; then responder-type filter, year-of-adoption data, UI polish; public-facing redesign scoped, not started
weekly_commitment: 2h
last_updated: 2026-10-16
blockers: null
blocking_others: null
funding_prospect: Blue Cancer Connect (Vickie Speed) — relationship active via the PA FOP summary, Cancer Map and IACP guest spot; no funding ask yet
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

- none scheduled. Next build item is the federal-coverage layer (schema decision first). Not before 10-28 (Peter's directive through 10-23: IACP and red items only).

## Upcoming Milestones

- Federal-coverage layer designed and built (P.L. 119-60 § 8205 / 34 U.S.C. § 10281(q)) — schema decision required first, see `docs/admin/federal-psob-cancer-presumption-2025.md`
- Responder-type filter complete
- Year-of-adoption data populated
- UI polish pass (now independent of IAFF — see 2026-08-07 P7/P8 work, which removed IAFF as the dashboard's benchmark/source of truth entirely)
- Ship when ready (no hard deadline)

## Team & Dependencies

| Name | Role | Institution |
|------|------|-------------|
| Peter Tanksley | PI (solo) | ALERRT / Texas State University |

## Notes

MVP map is working. Next steps are feature expansion (responder-type filter, year data) and UI polish.

Data source: `website/data/presumptive_laws.json` — single source of truth for the Shinylive app, and currently the *only* authoritative copy (see the pipeline note below). The `website/shiny-app/data/` copy must match it byte-for-byte. Note the older instruction to "keep in sync with `data/processed/presumptive_laws.rds`" was pointing at the v1 file written by `1_extract_data.r`; the v2 pipeline's artifact is `presumptive_laws_v2.rds`, and both are stale as of 2026-05-27.

Data current through 2026-08-07 for all 50 states. All states are re-reviewed on the quarterly cadence (first week of Jan/Apr/Jul/Oct; next 2027-01-04); `registry.md` Next Review column updated to match 2026-10-16.

**Open:**

- **`data_retrieved` is stale** — 411 of 479 rows read `2026-05-23` though the research was re-verified 2026-08-07. Deliberately excluded from the rebuild so it would not contaminate that change's regression test. Fix from the `Last Verified` column in `docs/lit/state_histories/registry.md`.
- **IAFF change-detection not built.** `2_iaff_scrape.r` / `3_iaff_extract.r` are marked out of the data path, but the intended scrape-and-diff (flag which state pages moved, as a trigger for the per-state review cadence) does not exist. As written, `2_` only fetches and stores HTML.
- **`app.R` still renders a state-level "IAFF source ↗" link** (~line 1326), inconsistent with P8's demotion of IAFF and worse once federal coverage exists.
- **DC** is in the data but was outside the 2026-08-07 QC pass, which covered the 50 states. Its 8 rows carry lower confidence.

## New Direction — Public-Facing Redesign (flagged 2026-07-17; SCOPED 2026-08-07, not yet started)

Peter wants to substantially redesign the public-facing side of this project. No hard deadline. **Scoping note now exists:** `docs/admin/state-pages-redesign-scoping-2026-08.md` — covers template structure (built from data already in the timeline files, no new data collection needed), a static-site generation approach (one script + template, fits the existing Quarto/no-server model), an update-cadence plan tied to `registry.md`'s per-state review dates, and a 5-phase build plan (template → generation pipeline → 5-10 state pilot → full rollout → cadence handoff). **Next step is the pilot phase, if/when Peter wants to start building** — this remains scoping only, no implementation done.

- Front-end dashboard that passes through to a series of static pages, one per state (at least 50 pages).
- All state pages follow one common template containing: a text-based description of that state's presumptive laws, links to the actual legislative source pages, and an infographic showing which groups are covered for which conditions plus a timeline of laws including upcoming/pending legislation.
- Needs a regular update schedule (recurring maintenance), not a one-time build.
- **Motivation:** Peter wants to follow up with contact Vickie Speed at Blue Cancer Connect to keep her interested in ALERRT's research-infrastructure capabilities. No hard deadline, but the goal is "something positive to show" — see the scoping note above, prepped as a meeting leave-behind.

**Cross-reference — police-vs-firefighter mortality comparison idea:** Peter explicitly flagged this redesign as dovetailing with a backlog idea comparing leading causes of death for firefighters vs. police officers in NOMS data (rationale: demonstrates the need to extend presumptive-law protections to law enforcement, mirroring firefighter presumptive laws). That idea already existed in the backlog as "LEO vs. Firefighter Mortality and the Presumptive Law Coverage Gap" (`~/.claude/bob/future-projects.md`, added 2026-07-03) — not duplicated here. If/when that idea is developed into a project, its findings would help make the case for why this dashboard's infrastructure should expand to cover law enforcement, not just firefighters.

**New companion idea (2026-08-07) — cancer presumption standard loosening over time:** During the full 50-state refresh, Peter asked for a second research-idea thread: identifying states where the cancer presumption *standard* loosened (narrow enumerated list → broad IARC/dynamic or unrestricted standard) over time, with precise mechanisms and dates. Confirmed cases with exact bill citations: **New Hampshire** (SB71/2023 struck an IARC gate added by SB541/2018, leaving a fully unrestricted "all types" standard — the strongest, most precisely-documented case), **Iowa** (HF969/2025 replaced a closed 14-type list with an open clinical definition), **Louisiana** (Act 287/2017 added a "statistically significant risk" catch-all on top of an existing IARC clause). Two useful counter-examples/falsification checks: **Texas** (SB2551/2019, IARC→enumerated, a tightening) and **Nevada** (SB153/2015, narrowed eligibility timing). Still-unresolved leads: Massachusetts (DPH catch-all origin year) and North Carolina (pre-2024 pilot-program standard couldn't be located despite extensive attempts — likely needs a records request, not another automated search). Full writeup: `docs/admin/vickie-speed-idea-brief-2026-08.md`. This pairs naturally with the LEO/FF mortality-gap idea above — both are about presumptive-coverage policy dynamics and could plausibly interest Blue Cancer Connect as a funder.

- Resolved issues (state-history sync, completeness gaps, CSV/JSON pipeline) and the 2026-08 work narrative: docs/logs/2026-10-16_bob-prune.md, docs/logs/2026-08-20_session9.md.

## Pending Notes

Legislative watches, re-checked 2026-08-07 (three closed watches moved to docs/logs/2026-10-16_bob-prune.md).

**Still open, updated status:**
- 2026-08-07 (was 2026-07-07) | Ohio PTSD fund transfer: claim procedures **still not promulgated** as of today. Administration restructured — a new First Responder PTSI Fund Commission (Dept. of Behavioral Health, created by HB 479) now owns this, not OBM/OP&F as previously assumed. $40M transfer statutorily mandated July 1, 2026; actual execution unconfirmed. Volunteer FF and volunteer/paid peace officer coverage under § 126.65 is confirmed. Re-check next cycle (2027-01-01).
- 2026-09-01 | Arizona PTSD counseling sunset watch: **confirmed still unrenewed** as of 2026-08-07 — real, live risk of lapse Jan 1, 2027. HB 2204 (2026 WC PTSD presumption bill) appears stalled in committee, final disposition unconfirmed.
- 2027-01-15 | West Virginia cancer sunset watch: **confirmed still unaddressed** — HB 2197 (2025 extension) died in committee, no 2026 fix found. 2027 session (Jan-Mar) remains the last chance to act before the July 2027 lapse. New gap also flagged this cycle: no bill addresses female-specific cancers despite public advocacy raised Feb 2026.
- 2027-01-15 | Nebraska § 48-101.01 PTSD sunset watch: unchanged, still sunsets Jan 1, 2028. LB400 (WC cancer presumption) confirmed dead — cloture failed 32-15 March 30, 2026, formally indefinitely postponed April 17, 2026. Watch the 110th Legislature (Jan 2027) for reintroduction.
- 2027-09-01 (was 2027-06-01, corrected to standard biennial cadence) | Montana 2027 session — PTSD and cancer: Ch. 442 L. 2023's addition of non-Hodgkin's lymphoma and testicular cancer to MCA § 39-71-1401 is now **confirmed** (exact effective-date clause still inferred, not directly confirmed from bill text). SB 394 PTSD bill remains vetoed (June 2025); sponsor reportedly reworking a new approach for 2027, no draft yet.

**Standing cadence (Peter, 2026-10-16):** full 50-state search/update the first week of Jan, Apr, Jul and Oct; next run 2027-01-04. Arizona PTSD sunset gets a one-off check 2026-12-01 (lapses Jan 1, 2027, before the January run); every other watch folds into the nearest quarterly run. Per-state Sept/January cadence in `registry.md` retired. Reminders in Bob notes.md + macOS Reminders.

## Start Here Next Session

1. Arizona PTSD sunset: one-off check 2026-12-01; full quarterly run 2027-01-04.
2. Federal-coverage layer: make the schema decision (`docs/admin/federal-psob-cancer-presumption-2025.md`), then build.
3. Fix `data_retrieved` from the `Last Verified` column.
