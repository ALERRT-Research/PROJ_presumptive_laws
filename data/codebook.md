# Codebook: presumptive_laws

**File:** `data/processed/presumptive_laws.rds`  
**Exported to:** `website/data/presumptive_laws.json`  
**Unit of observation:** One row = state × condition category  
**Data current through:** 2022-12 (Brandt-Rauf 2024); 2022-11 (NCCI 2023)

| Variable | Type | Values / Notes |
|----------|------|----------------|
| `state` | chr | Two-letter abbreviation (e.g., "TX") |
| `state_name` | chr | Full state name (e.g., "Texas") |
| `condition` | chr | One of: cancer, cardiovascular, respiratory, infectious, covid19, mental |
| `presumption_exists` | lgl | TRUE if any presumption law exists for this state × condition |
| `responder_groups` | chr | Semicolon-separated: fire, ems, police, volunteer (or combinations) |
| `rebuttable` | lgl | TRUE = employer can contest; FALSE = irrebuttable; NA = not specified |
| `statute_citation` | chr | E.g., "OR § 656.802" — blank if not coded |
| `notes` | chr | Restrictions, service requirements, age limits, sunset clauses |
| `source` | chr | "NCCI_2023", "BrandtRauf_2024", or "both" |
| `data_current_through` | chr | ISO year-month string |

## Condition category codes

| Code | Full label | Notes |
|------|-----------|-------|
| `cancer` | Cancer | Includes all cancers or specific listed cancers depending on state |
| `cardiovascular` | Cardiovascular Disease | Heart disease, vascular conditions |
| `respiratory` | Respiratory Disease | Lung conditions, breathing disorders |
| `infectious` | Infectious Disease | Blood-borne and infectious diseases (non-COVID) |
| `covid19` | COVID-19 | Many states added via executive order; check sunset status |
| `mental` | Mental Health / PTSD | PTSD and related conditions; only 9 states as of 2022 |

## Responder group codes

| Code | Full label |
|------|-----------|
| `fire` | Career firefighters |
| `ems` | EMS / paramedics / emergency medical personnel |
| `police` | Law enforcement officers |
| `volunteer` | Volunteer firefighters |
