---
project: Presumptive Laws Dashboard
type: web
status: active
priority: medium
path: /Users/PTT2/Documents/GitHub/PROJ_presumptive_laws
deadline: null
target: null
effort_remaining: All 50 states now QC-gated and JSON-synced (see 2026-08-07 below). Remaining: decide fate of orphaned CSV pipeline; deep-dig MA/NC cancer-standard-history dead ends (may need records request/Westlaw, not another automated pass); public-facing redesign is now scoped (see updated section below) but not started — pilot phase (5-10 states) is the next real chunk of build effort, unestimated in calendar time.
weekly_commitment: 2h (exceeded this week — see 2026-08-07 push ahead of the Vickie Speed meeting)
last_updated: 2026-08-07
blockers: null
blocking_others: null
funding_prospect: Blue Cancer Connect (BCC) — meeting with CEO Vickie Speed scheduled early next week (Mon/Tue, week of 2026-08-10). Exploratory re: what BCC would fund in the presumptive laws space. Two artifacts prepped for this meeting: `docs/admin/vickie-speed-idea-brief-2026-08.md` (cancer-standard-loosening research pitch) and `docs/admin/state-pages-redesign-scoping-2026-08.md` (public-facing redesign scoping note).
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

- **2026-08-07 — full 50-state QC-gated refresh, ahead of the Vickie Speed meeting.** Ran `/research-states`-equivalent pipeline (legislative-researcher + legislative-reviewer, parallel batches of ~7-8) across all 50 states in one push: the 8 states with dated Pending Notes items first (see resolutions below), then the 6 previously-QC'd states (TX, CA, NY, FL, IL, PA — full rerun, not spot-check), then the remaining 36 never-gated states. All 50 scored 97-100/100. `registry.md` fully updated with `[QC ##/100]` tags and 2026-08-07 verification dates for every state.
- Wrote `analysis/code/apply_p6_corrections.py`: ~30 distinct findings applied across 64 row changes (field/citation/date fixes, completeness-gap fills following the P5 lesson, false-content removal, mischaracterization fixes). Dashboard JSON grew from 465 to 479 rows. Verified both `website/data/` and `website/shiny-app/data/` copies are byte-identical and valid; spot-checked two corrections directly (Ohio's 4 new mental-health rows, Mississippi's cardiovascular row removal) against the patched JSON.
- Re-ran `shinylive::export()` and `quarto render` so the live site's embedded WASM app reflects the updated data — rendered clean, no errors. **Not yet committed, pushed, or deployed** — holding for Peter's explicit go-ahead per standing instructions.
- Drafted `docs/admin/vickie-speed-idea-brief-2026-08.md` (cancer-presumption-standard-loosening research pitch, tiered into Confirmed/Unresolved/Counter-examples) and `docs/admin/state-pages-redesign-scoping-2026-08.md` (5-phase scoping note for the public-facing redesign) — both meant as leave-behinds for the meeting.
- **Resolved the docs/lit/state_histories/ machine-sync issue** (see former open issue below, now closed): this machine's copy had been the original 2026-06-02 pre-gate drafts sitting untouched in `in-progress/` — not the 2026-07-17 QC'd versions referenced elsewhere, which lived only on a different machine and were never synced (directory is gitignored). Every state has now been independently re-researched and reviewed on this machine as of today, closing that gap for good; the old `in-progress/` drafts are left in place as historical reference only.
- Still outstanding: decide fate of the orphaned CSV pipeline; responder-type filter, year-of-adoption data, IAFF UI benchmark (all pre-existing backlog, untouched this week); MA/NC cancer-standard-history dead ends need a non-automated follow-up (records request or library/Westlaw access).

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

Data now current through 2026-08-07 for all 50 states (was "late 2022" through 2026-07; see this week's full refresh above). Next scheduled review dates are tracked per-state in `registry.md` (5 biennial states: TX/NV/MT/ND/OR reviewed ~Sept of session years; all others reviewed each January).

**Resolved 2026-08-07 (was open since 2026-07-02):** `docs/lit/state_histories/` machine-sync issue. See This Week above — every state now independently re-researched and QC'd on this machine.

**Resolved 2026-08-07 (was open since 2026-07-02):** the P4/P5 completeness-gap issue (research confirming a condition/responder-type combo exists, but the JSON missing the row) has now been explicitly checked for **all 50 states**, not just TX — see `apply_p6_corrections.py`. This should be standing practice for every future correction pass, not a one-off fix.

**Open issue (updated 2026-07-02, still open):** `data/processed/presumptive_laws_v2.csv` has diverged from the live JSON (now at 479 rows post-P6; CSV last touched at a much earlier row count). Corrections continue to be hand-patched directly into the JSON via one-off Python scripts (`apply_p1` through `apply_p6_corrections.py`), bypassing the CSV/RDS pipeline (`4_iaff_combine.r` / `5_iaff_export_json.r`) entirely. Still worth deciding whether to retire the CSV pipeline or restore it as the source of truth — untouched this week, same open question as before.

## New Direction — Public-Facing Redesign (flagged 2026-07-17; SCOPED 2026-08-07, not yet started)

Peter wants to substantially redesign the public-facing side of this project. No hard deadline. **Scoping note now exists:** `docs/admin/state-pages-redesign-scoping-2026-08.md` — covers template structure (built from data already in the timeline files, no new data collection needed), a static-site generation approach (one script + template, fits the existing Quarto/no-server model), an update-cadence plan tied to `registry.md`'s per-state review dates, and a 5-phase build plan (template → generation pipeline → 5-10 state pilot → full rollout → cadence handoff). **Next step is the pilot phase, if/when Peter wants to start building** — this remains scoping only, no implementation done.

- Front-end dashboard that passes through to a series of static pages, one per state (at least 50 pages).
- All state pages follow one common template containing: a text-based description of that state's presumptive laws, links to the actual legislative source pages, and an infographic showing which groups are covered for which conditions plus a timeline of laws including upcoming/pending legislation.
- Needs a regular update schedule (recurring maintenance), not a one-time build.
- **Motivation:** Peter wants to follow up with contact Vickie Speed at Blue Cancer Connect to keep her interested in ALERRT's research-infrastructure capabilities. No hard deadline, but the goal is "something positive to show" — see the scoping note above, prepped as a meeting leave-behind.

**Cross-reference — police-vs-firefighter mortality comparison idea:** Peter explicitly flagged this redesign as dovetailing with a backlog idea comparing leading causes of death for firefighters vs. police officers in NOMS data (rationale: demonstrates the need to extend presumptive-law protections to law enforcement, mirroring firefighter presumptive laws). That idea already existed in the backlog as "LEO vs. Firefighter Mortality and the Presumptive Law Coverage Gap" (`~/.claude/bob/future-projects.md`, added 2026-07-03) — not duplicated here. If/when that idea is developed into a project, its findings would help make the case for why this dashboard's infrastructure should expand to cover law enforcement, not just firefighters.

**New companion idea (2026-08-07) — cancer presumption standard loosening over time:** During the full 50-state refresh, Peter asked for a second research-idea thread: identifying states where the cancer presumption *standard* loosened (narrow enumerated list → broad IARC/dynamic or unrestricted standard) over time, with precise mechanisms and dates. Confirmed cases with exact bill citations: **New Hampshire** (SB71/2023 struck an IARC gate added by SB541/2018, leaving a fully unrestricted "all types" standard — the strongest, most precisely-documented case), **Iowa** (HF969/2025 replaced a closed 14-type list with an open clinical definition), **Louisiana** (Act 287/2017 added a "statistically significant risk" catch-all on top of an existing IARC clause). Two useful counter-examples/falsification checks: **Texas** (SB2551/2019, IARC→enumerated, a tightening) and **Nevada** (SB153/2015, narrowed eligibility timing). Still-unresolved leads: Massachusetts (DPH catch-all origin year) and North Carolina (pre-2024 pilot-program standard couldn't be located despite extensive attempts — likely needs a records request, not another automated search). Full writeup: `docs/admin/vickie-speed-idea-brief-2026-08.md`. This pairs naturally with the LEO/FF mortality-gap idea above — both are about presumptive-coverage policy dynamics and could plausibly interest Blue Cancer Connect as a funder.

## Pending Notes

All eight items below were re-checked during the 2026-08-07 full refresh. Three are now fully resolved and closed out; the other five are updated with confirmed status and remain open.

**Closed 2026-08-07:**
- Colorado SB26-184 — **vetoed** by Gov. Polis June 3, 2026 (funding/stakeholder-engagement concerns). Current law unchanged; no override or reintroduction reported. No further watch needed unless a 2027 successor bill appears.
- Hawaii § 386-21.9 breast cancer amendment — confirmed **Act 101 (2024)**, HB1889, eff. June 27, 2024 (not a 2025 amendment as previously guessed). No PTSD bill found in any 2021-2026 session — treated as settled absence, not an open gap.
- Utah HB 416 — confirmed **signed** (Ch. 469), Firefighter Cancer Benefit Trust Fund created. Also corrected: the 15-cancer-type expansion took effect **July 1, 2025**, not Jan 1, 2026 as previously stated.

**Still open, updated status:**
- 2026-08-07 (was 2026-07-07) | Ohio PTSD fund transfer: claim procedures **still not promulgated** as of today. Administration restructured — a new First Responder PTSI Fund Commission (Dept. of Behavioral Health, created by HB 479) now owns this, not OBM/OP&F as previously assumed. $40M transfer statutorily mandated July 1, 2026; actual execution unconfirmed. Volunteer FF and volunteer/paid peace officer coverage under § 126.65 is confirmed. Re-check next cycle (2027-01-01).
- 2026-09-01 | Arizona PTSD counseling sunset watch: **confirmed still unrenewed** as of 2026-08-07 — real, live risk of lapse Jan 1, 2027. HB 2204 (2026 WC PTSD presumption bill) appears stalled in committee, final disposition unconfirmed.
- 2027-01-15 | West Virginia cancer sunset watch: **confirmed still unaddressed** — HB 2197 (2025 extension) died in committee, no 2026 fix found. 2027 session (Jan-Mar) remains the last chance to act before the July 2027 lapse. New gap also flagged this cycle: no bill addresses female-specific cancers despite public advocacy raised Feb 2026.
- 2027-01-15 | Nebraska § 48-101.01 PTSD sunset watch: unchanged, still sunsets Jan 1, 2028. LB400 (WC cancer presumption) confirmed dead — cloture failed 32-15 March 30, 2026, formally indefinitely postponed April 17, 2026. Watch the 110th Legislature (Jan 2027) for reintroduction.
- 2027-09-01 (was 2027-06-01, corrected to standard biennial cadence) | Montana 2027 session — PTSD and cancer: Ch. 442 L. 2023's addition of non-Hodgkin's lymphoma and testicular cancer to MCA § 39-71-1401 is now **confirmed** (exact effective-date clause still inferred, not directly confirmed from bill text). SB 394 PTSD bill remains vetoed (June 2025); sponsor reportedly reworking a new approach for 2027, no draft yet.
