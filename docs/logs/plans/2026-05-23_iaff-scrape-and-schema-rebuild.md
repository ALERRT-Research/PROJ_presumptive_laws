# Plan: IAFF Scrape + Schema Rebuild
**Status:** APPROVED  
**Date:** 2026-05-23  
**Author:** Peter Tanksley / Claude

---

## Goal

Replace the current Brandt-Rauf (2022) flat dataset with a fully granular dataset scraped
from the IAFF Presumptive Health Initiative site (iaff.org/presumptive-health/). New schema:
one row per **state × condition_category × responder_type**. Export to `.rds` and `.json`
for the Shinylive dashboard.

---

## Background

Current data: 307 rows, 50 states, 6 conditions, no responder-type granularity, current through
late 2022.

IAFF site: 51 pages (50 states + DC), prose-heavy HTML per page, richly detailed — statute
citations, responder groups per condition, eligibility requirements, post-termination windows,
rebuttal standards. More current than Brandt-Rauf.

---

## New Data Schema

**Primary key:** `state × condition_category × responder_type`

| Field | Type | Description |
|---|---|---|
| `state` | chr | 2-letter USPS abbreviation |
| `state_name` | chr | Full state name |
| `condition_category` | factor | cancer, cardiovascular, respiratory, infectious, mental, other |
| `condition_specific` | chr | Free text detail (e.g., specific cancer types listed in statute) |
| `responder_type` | factor | firefighter, firefighter_volunteer, emt_paramedic, law_enforcement, corrections |
| `presumption_type` | factor | statute, EO, expired, none |
| `presumption_exists` | lgl | TRUE if any active presumption |
| `rebuttable` | lgl | TRUE = disputable; FALSE = irrebuttable; NA = unknown |
| `statute_citation` | chr | Primary statute(s) — e.g., "TX Gov't Code § 607.055" |
| `years_service_required` | int | Minimum service years; NA if none stated |
| `pre_employment_exam_required` | lgl | NA if not stated |
| `post_termination_months` | int | Coverage window after leaving employment; NA if not stated |
| `tobacco_exclusion` | lgl | TRUE if tobacco use disqualifies claim |
| `notes` | chr | Sunset dates, special carve-outs, screening mandates, etc. |
| `iaff_url` | chr | Source page URL |
| `data_retrieved` | date | Date scraped |

**Responder type taxonomy:**

| Code | Includes |
|---|---|
| `firefighter` | Paid/career firefighters |
| `firefighter_volunteer` | Volunteer firefighters |
| `emt_paramedic` | EMTs and paramedics (note distinctions in `notes` field if any) |
| `law_enforcement` | Police officers, peace officers, sheriffs, investigators |
| `corrections` | Correctional officers |

**Condition category taxonomy** (unchanged from current):

| Code | Includes |
|---|---|
| `cancer` | All cancers, leukemia, lymphoma, myeloma |
| `cardiovascular` | Heart disease, hypertension, acute MI, stroke |
| `respiratory` | Lung disease, tuberculosis (respiratory presentation), pneumonia |
| `infectious` | Bloodborne pathogens, hepatitis, HIV, meningitis, TB (infectious), MRSA, COVID-19 |
| `mental` | PTSD, behavioral health, mental trauma |
| `other` | Parkinson's, hernia, lower back, Lyme disease, biochemical exposure |

*Note:* Tuberculosis appears under both `respiratory` and `infectious` in different states depending
on how the statute frames it. The IAFF extraction prompt will need to handle this — flag ambiguous
cases in `notes` and make a consistent assignment.

---

## Implementation Phases

### Phase 1 — Scrape (Script: `analysis/code/2_iaff_scrape.r`)

1. Build URL list: all 50 state abbreviations + DC, lowercase, pattern:
   `https://www.iaff.org/presumptive-health/[abb]/`
2. Loop over URLs with `httr2` or `rvest`, retrieve full HTML
3. Save raw HTML to `data/raw/iaff_html/[state_abb].html` — one file per state
4. Include a polite crawl delay (~1–2 seconds between requests)
5. Log any failed fetches (non-200 responses)

**Output:** 51 `.html` files in `data/raw/iaff_html/`

---

### Phase 2 — Extract via Claude API (Script: `analysis/code/3_iaff_extract.r`)

For each state HTML file:

1. Strip boilerplate nav/footer (keep main content div only)
2. Submit to Claude API (claude-haiku-4-5 for cost; sonnet if accuracy issues arise)
   with a structured extraction prompt (see prompt template below)
3. Parse JSON response → one tibble per state
4. Bind all tibbles → single data frame
5. Save to `data/processed/iaff_extracted_raw.rds`

**Extraction prompt template:**

```
You are extracting structured data from a US state's presumptive workers' compensation law page.

Return a JSON array. Each element represents ONE combination of:
  - condition_category (cancer | cardiovascular | respiratory | infectious | mental | other)
  - responder_type (firefighter | firefighter_volunteer | emt_paramedic | law_enforcement | corrections)

Only include rows where coverage information is explicitly stated. Do not infer.

For each row, return:
{
  "condition_category": "...",
  "condition_specific": "...",      // free text — specific conditions/cancers listed
  "responder_type": "...",
  "presumption_type": "statute | EO | expired | none",
  "presumption_exists": true/false,
  "rebuttable": true/false/null,    // true=disputable, false=irrebuttable, null=unknown
  "statute_citation": "...",
  "years_service_required": int or null,
  "pre_employment_exam_required": true/false/null,
  "post_termination_months": int or null,
  "tobacco_exclusion": true/false/null,
  "notes": "..."                    // sunset dates, carve-outs, anything unusual
}

State page content:
[HTML CONTENT]
```

**Validation checks after extraction:**
- Every state has at least one row
- `presumption_type` values are in allowed set
- No rows with `presumption_exists = true` and `presumption_type = "none"`
- Flag states with suspiciously few rows (< 3) for manual review

---

### Phase 3 — Clean & Finalize (Script: `analysis/code/4_iaff_clean.r`)

1. Load `iaff_extracted_raw.rds`
2. Standardize factor levels (condition_category, responder_type, presumption_type)
3. Add `state_name`, `iaff_url`, `data_retrieved`
4. Spot-check a sample (~10 states) against the live IAFF pages manually
5. Flag any states where we have no `firefighter` rows (likely scrape failure)
6. Save to `data/processed/presumptive_laws_v2.rds`
7. Export to `website/data/presumptive_laws.json` (replaces old file)

---

### Phase 4 — Dashboard Update (Script: `website/shiny-app/app.R`)

The new schema adds a second filter dimension (responder type). Dashboard changes:

1. Add `selectInput("responder_type", ...)` to sidebar — choices: all 5 types + "Any"
2. Filter logic: when "Any" is selected, collapse to best available coverage per state/condition
3. Update stat cards to show counts by responder type
4. Update detail table to include responder type column
5. Re-export Shinylive app
6. Re-render Quarto website

---

## File Manifest

| File | Description |
|---|---|
| `analysis/code/2_iaff_scrape.r` | Phase 1: scrape raw HTML |
| `analysis/code/3_iaff_extract.r` | Phase 2: Claude API extraction |
| `analysis/code/4_iaff_clean.r` | Phase 3: clean + export |
| `data/raw/iaff_html/` | Raw HTML files (51 files) |
| `data/processed/iaff_extracted_raw.rds` | Unvalidated extraction output |
| `data/processed/presumptive_laws_v2.rds` | Final cleaned dataset |
| `website/data/presumptive_laws.json` | Dashboard data (updated) |
| `website/shiny-app/app.R` | Dashboard app (updated) |

---

## Open Questions / Risks

1. **IAFF bot protection:** The site may rate-limit or block automated requests. Mitigation:
   polite delay + browser-like User-Agent header. If blocked, fall back to manual download
   of the 51 HTML files.

2. **Extraction accuracy:** Prose → structured data via LLM will have errors. Manual spot-check
   of ~10 states is the minimum QC step. States with many statute sections (CA, FL, NY) are
   highest risk.

3. **Tuberculosis ambiguity:** TB appears under both respiratory and infectious in different states.
   Decision: classify as `infectious` uniformly; note in `condition_specific` if the statute
   frames it as respiratory.

4. **Missing responder types:** The IAFF site is firefighter-focused. Law enforcement and
   corrections rows will be present only where explicitly stated. Do not impute coverage.

5. **"Any" filter logic in the dashboard:** When user selects "Any responder type," the map
   should show the BEST available coverage per state/condition (statute > EO > expired > none).
   This requires a collapse step in the app reactive.

---

## Success Criteria

- All 51 state pages scraped without errors
- Extraction produces > 500 rows (old dataset had 307 at one-row-per-state-condition)
- Manual spot-check of 10 states: ≥ 90% field accuracy
- Dashboard renders with new responder-type filter
- `quarto render` succeeds on the website

---

## Dependencies

- `httr2` or `rvest` for scraping
- Claude API key (set in environment as `ANTHROPIC_API_KEY`)
- `jsonlite` for JSON parsing
- `shinylive` CLI for re-export
- `quarto` CLI for re-render
