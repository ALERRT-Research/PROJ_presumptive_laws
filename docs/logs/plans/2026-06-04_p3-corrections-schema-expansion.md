# Plan: P3 Corrections + Schema Expansion
**Status:** APPROVED
**Date:** 2026-06-04

## Goal
Apply Priority 3 field quality corrections from `docs/admin/corrections-inventory.md`
and expand `presumption_type` schema to distinguish WC presumptions from non-WC benefits.

## Background
Several states in the JSON are coded `presumption_type: "statute"` but their benefits
are legally NOT workers' compensation presumptions. They are pension disability presumptions
(IN, KS, IA), employer death/disability benefits or insurance mandates (AL, AR, GA), or
line-of-duty death benefit statutes only (KY cancer, NC cardiovascular). The current coding
misleads users. The fix is a schema expansion + color-coded map display.

---

## Part 1: Schema Expansion (new `presumption_type` values)

### New values
| Value | Meaning | Color on map |
|---|---|---|
| `"pension"` | Pension/retirement disability presumption — not WC | muted gold `#b8890a` |
| `"employer_benefit"` | Employer-funded death/disability or insurance mandate — not WC | muted gold `#b8890a` |
| `"lodd_only"` | Line-of-duty death benefit only, no living-claimant WC coverage | muted gold `#b8890a` |

Existing values unchanged: `"statute"` (WC), `"EO"` (exec order WC), `"expired"`, `"none"`.

### JSON rows to retype
| State | Rows | Old type | New type |
|---|---|---|---|
| AL | all 6 rows (cancer, cardiovascular, respiratory, infectious ×2, other) | `statute` | `employer_benefit` |
| AR | all 2 rows (cancer/firefighter, cancer/firefighter_volunteer) | `statute` | `employer_benefit` |
| GA | all 8 rows (cancer ×2, cardiovascular ×4, mental ×4) | `statute` | `employer_benefit` |
| IN | all 13 rows (cancer ×3, cardiovascular ×3, respiratory ×3, mental ×2, other ×3) | `statute` | `pension` |
| KS | all 6 rows (cancer ×2, cardiovascular ×2, respiratory ×2) | `statute` | `pension` |
| KY | cancer/firefighter only | `statute` | `lodd_only` |
| NC | cardiovascular ×3 (firefighter, law_enforcement, emt_paramedic) | `statute` | `lodd_only` |
| IA | cancer/law_enforcement (added in P2) | `statute` | `pension` |

### Notes to add/update alongside retype
- AL: prepend "NOT a WC presumption — employer disability/death benefit system..."
- AR: prepend "NOT a WC presumption — State Claims Commission death benefit + pension..."
- GA: prepend "NOT a WC presumption — employer insurance mandate / State Indemnification Fund..."
- IN: prepend "NOT a WC presumption — pension disability presumption only..."
- KS: prepend "NOT a WC presumption — KP&F pension track..."
- KY cancer: notes already correct ("DEATH BENEFIT ONLY"); no change needed
- NC cardiovascular: notes already say "death benefit only"; no change needed

---

## Part 2: P3 Field Quality Corrections

### Field value changes
- [ ] **NC cancer** (`§ 143-166.2` row): `condition_specific` currently lists 4 types;
  update to 6: add "oral cavity cancer, pharynx cancer" (SL 2021-180)
- [ ] **VT**: statute citations missing `(11)` subdivision — update all VT rows:
  - cardiovascular → `21 V.S.A. § 601(11)(B)`
  - respiratory/lung → `21 V.S.A. § 601(11)(H)`
  - cancer → `21 V.S.A. § 601(11)(E)-(F)`
  - mental → `21 V.S.A. § 601(11)(I)`

### Notes-only updates
- [ ] **CA** mental/firefighter: update sunset note — "2029 (per current leginfo text;
  verify against AB 2770 enrolled text — IAFF shows 2032)"
- [ ] **CO** cardiovascular: strengthen notes — "employer benefit program (C.R.S.
  §§ 29-5-301, 29-5-302), NOT a WC presumption under Title 8"
- [ ] **HI** cancer/firefighter: clarify mechanism — "§ 386-21.9 does not itself create
  a presumption of compensability — it enhances the medical fee schedule once compensability
  is established by other means"
- [ ] **NV** mental rows (×4): add "This is a reduced evidentiary gateway, not a
  burden-shifting presumption. Claimant still bears burden of proof by clear and convincing
  evidence (NRS 616C.180)"
- [ ] **WV** mental rows: remove reference to "July 1, 2026" sunset; replace with
  "Sunset clause removed by HB 2797 (eff. July 11, 2025) — coverage is now permanent"

### New rows
- [ ] **KS** infectious/firefighter and infectious/law_enforcement:
  - statute: K.S.A. 74-4952 (as amended by L. 2019, ch. 50 / HB 2031)
  - condition: bloodborne pathogens (KSA 65-128 definition)
  - presumption_type: `"pension"` (KP&F track)
  - years_service_required: 5
  - rebuttable: true

---

## Part 3: app.R Dashboard Changes

### 3a. Type lookup tables (near top of file, lines ~29-48)
Add new values to:
- `type_priority`: `pension = 3L, employer_benefit = 3L, lodd_only = 2L`
- `status_labels`: readable labels for the detail table Status column
- `status_clrs`: muted gold `#b8890a` for all three non-WC types

### 3b. Base fill logic (refactor `map_fills()`, lines ~819-836)
Add `base_fills()` reactive:
- In condition mode + specific condition selected: color polygons by `status_clrs[presumption_type]`
- In "all conditions" mode or occupation mode: uniform dark blue `#3d5a73`

Refactor `map_fills()` to overlay UpSet interaction colors on top of base fills
(hover gold / selection red) instead of always starting from `#3d5a73`.

### 3c. Legend
Add `uiOutput("map_legend")` below the leaflet map in the UI.
Add `output$map_legend <- renderUI({...})` in the server that renders:
- Condition mode + specific condition: status legend (WC statute / Other benefit / Expired / No coverage)
- Occupation mode or all conditions: count legend (existing `legend_occupation_html`)

---

## Implementation order

1. Write `analysis/code/apply_p3_corrections.py` (JSON changes: retype + notes + new rows + field edits)
2. Run script, verify row count, review diff
3. Edit `website/shiny-app/app.R` (schema lookups + base_fills + legend)
4. `cp` JSON to `website/data/presumptive_laws.json`
5. Local test: `cd website && Rscript -e "shinylive::export('shiny-app', 'app', overwrite=TRUE)"` (optional — skip if no local shinylive)
6. Commit JSON + app.R together (one commit, descriptive message)
7. Confirm with Peter before pushing

## Files modified
- `analysis/code/apply_p3_corrections.py` (new)
- `website/shiny-app/data/presumptive_laws.json` (edited by script)
- `website/data/presumptive_laws.json` (synced via cp)
- `website/shiny-app/app.R` (edited directly)

## Verification
- [ ] Row count: 443 existing + 2 new KS rows = 445 total
- [ ] All non-WC states have updated `presumption_type` and notes
- [ ] All VT citation corrections applied
- [ ] app.R: new types present in all three lookup tables
- [ ] app.R: base_fills uses status_clrs when condition mode + specific condition
- [ ] app.R: legend renders correctly for both modes
- [ ] No R syntax errors (check with `Rscript --parse website/shiny-app/app.R`)
