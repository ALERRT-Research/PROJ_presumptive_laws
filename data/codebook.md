# Codebook: presumptive_laws

**Source of truth:** `data/raw/state_records/{AL..WY,DC}.json` — 51 committed files, one per
jurisdiction, maintained by per-state legislative research.
**Built artifacts:** `data/processed/presumptive_laws_v2.rds` and `.csv`
**Dashboard files:** `website/data/presumptive_laws.json` and
`website/shiny-app/data/presumptive_laws.json` (must be identical; `5_export_json.r` writes both)
**Unit of observation:** one row = jurisdiction × condition category × responder type × statute
**Rows:** 479 across 51 jurisdictions (50 states + DC), as of 2026-08-20
**Last full research verification:** 2026-08-07, all 50 states QC-gated 97–100/100
(DC not covered by that pass)

## Provenance

Primary source is independent per-state legislative research recorded in
`docs/lit/state_histories/*_timeline.md`, with per-state status and QC scores in
`docs/lit/state_histories/registry.md`.

**IAFF is not a source.** The IAFF Presumptive Health directory
([iaff.org/presumptive-health](https://www.iaff.org/presumptive-health/)) was the original
seed for this dataset and was repeatedly found wrong, stale, or incomplete — omitted statutes,
wrong effective dates, mischaracterized provisions. P8 (2026-08-07) removed it as the
dashboard's benchmark. The `iaff_url` column is retained only as a per-state directory
back-link, not as an authority for any value in the row.

## Pipeline

```
data/raw/state_records/*.json          source of truth, committed
    │   Rscript analysis/code/4_combine_records.r      validate, coerce, bind
    ▼
data/processed/presumptive_laws_v2.rds + .csv          regenerated output
    │   Rscript analysis/code/5_export_json.r          write both dashboard copies
    ▼
website/data/ + website/shiny-app/data/ presumptive_laws.json
    │   cd website && Rscript -e "shinylive::export('shiny-app', 'app', overwrite=TRUE)"
    ▼
website/app/                                           tracked build artifact, embedded by
                                                       coverage-map.qmd as "app/index.html"
    │   cd website && quarto render
    ▼
website/_site/                                         gitignored; deploy.sh publishes it
```

Retired, kept on disk for provenance only — do not run:

- `2_iaff_scrape.r`, `3_iaff_extract.r` — the old IAFF scrape and extraction. No longer in the
  data path.
- `4_iaff_combine.r` — superseded by `4_combine_records.r`. **Actively destructive if run:**
  its `valid_ptype` list is stale and silently maps `pension`, `employer_benefit`, and
  `lodd_only` to `none`, which would blank 58 rows.
- `5_iaff_export_json.r` — superseded by `5_export_json.r`. Wrote only one of the two
  dashboard copies.
- `apply_p1_corrections.py` … `apply_p8_notes_rewrite.py` — the eight correction passes that
  produced the 2026-08-07 dataset by patching the JSON directly. Historical audit trail. Their
  results are baked into the record files; re-running them would double-apply.
- `split_json_to_records.py` — one-shot bootstrap that created the record files from the
  QC-gated JSON on 2026-08-20. Re-running it would overwrite research-maintained records with
  whatever is in the dashboard JSON.

## Schema

21 fields, in canonical order. `field_order` in `4_combine_records.r` and `FIELD_ORDER` in
`split_json_to_records.py` must match this table.

### Identity

| Field | Type | Null | Notes |
|---|---|---|---|
| `state` | chr | 0 | Two-letter USPS abbreviation, uppercase. 51 values incl. `DC` |
| `state_name` | chr | 0 | Full jurisdiction name |

### Classification

| Field | Type | Null | Notes |
|---|---|---|---|
| `condition_category` | fct | 0 | One of 6 — see domain table below |
| `condition_specific` | chr | 0 | Free text: the conditions the statute actually names. 221 distinct values. This is where an enumerated cancer list lives verbatim |
| `responder_type` | fct | 0 | One of 5 — see domain table below |

### Status

| Field | Type | Null | Notes |
|---|---|---|---|
| `presumption_type` | fct | 0 | One of 7 — see domain table below. **Not all values are workers' comp** |
| `presumption_exists` | lgl | 0 | `TRUE` 462, `FALSE` 17. `FALSE` records a researched absence, not missing data |
| `rebuttable` | lgl | 89 | `TRUE` 362 (employer may contest), `FALSE` 28 (conclusive). Null = statute silent |

### Eligibility mechanics

| Field | Type | Null | Notes |
|---|---|---|---|
| `years_service_required` | int | 312 | Minimum service before the presumption attaches. Observed: 1–8, 10 |
| `pre_employment_exam_required` | lgl | 190 | `TRUE` 208, `FALSE` 81. A baseline exam showing the condition absent at hire |
| `post_termination_months` | int | 347 | Months after separation the presumption survives. Observed: 3, 12, 24, 36, 60, 84, 120, 180, 240 |
| `post_termination_formula` | chr | 416 | Free text where coverage is computed rather than fixed, e.g. "3 calendar months per year of requisite service, max 60 months". When populated, it governs and `post_termination_months` holds the cap |
| `discovery_during_employment_required` | lgl | 267 | `TRUE` 65 — diagnosis must occur while still employed |
| `filing_deadline_notes` | chr | 328 | Free text: claim-filing windows and limitation periods |
| `tobacco_exclusion` | lgl | 370 | `TRUE` 76 — presumption is void or reduced for tobacco users, typically for smoking-linked cancers only |

### Authority

| Field | Type | Null | Notes |
|---|---|---|---|
| `statute_citation` | chr | 0 | Citation as it should be displayed. 213 distinct |
| `source_url` | chr | 24 | Direct link to the statutory text — official state code preferred, reputable full-text mirror acceptable. **Never an IAFF URL.** 455 of 479 populated; the 24 nulls render as plain text in the dashboard rather than falling back to a wrong link |

### Annotation and provenance

| Field | Type | Null | Notes |
|---|---|---|---|
| `notes` | chr | 0 | User-facing plain language: restrictions, service requirements, sunsets, effective dates. P8 rewrote these to remove research-audit commentary — the audit trail belongs in `docs/lit/state_histories/`, not in the dashboard |
| `needs_verification` | chr | 462 | Free text describing what is unresolved about the row. **Character or null only — never a bare boolean.** A flag with no explanation is not reviewable |
| `iaff_url` | chr | 0 | IAFF state directory page. Back-link only, not an authority (see Provenance) |
| `data_retrieved` | chr | 0 | ISO date the row's value was last set. **Currently stale** — 411 rows still read `2026-05-23` despite the 2026-08-07 re-research. Known issue, see Open issues |

## Domains

These three vectors must stay in sync across `4_combine_records.r`,
`split_json_to_records.py`, and `website/shiny-app/app.R` (lines 29–92). `app.R` builds its
colour, label, and priority lookups by name — a value it does not know silently renders blank.

### `condition_category`

| Code | Label | Rows |
|---|---|---|
| `cancer` | Cancer | 92 |
| `cardiovascular` | Cardiovascular disease | 106 |
| `respiratory` | Respiratory disease | 60 |
| `infectious` | Infectious disease | 89 |
| `mental` | Mental health / PTSD | 103 |
| `other` | Other | 29 |

There is no `covid19` category. COVID-era provisions are classified under `infectious`, or
`other` where the provision was a standalone temporary program. Most have since expired; a
COVID row with `presumption_type = "expired"` is normal.

### `responder_type`

| Code | Label | Rows |
|---|---|---|
| `firefighter` | Firefighter (career) | 226 |
| `firefighter_volunteer` | Firefighter (volunteer) | 55 |
| `emt_paramedic` | EMT / paramedic | 70 |
| `law_enforcement` | Law enforcement | 110 |
| `corrections` | Corrections | 18 |

### `presumption_type`

Records the legal *mechanism*, which is not always workers' compensation. Collapsing these
would misrepresent what a claimant actually gets.

| Code | Label | Rows | Meaning |
|---|---|---|---|
| `statute` | Active statute (WC presumption) | 417 | A workers'-comp presumption in force |
| `EO` | Executive order | 0 | Reserved; all COVID-era EOs have lapsed |
| `pension` | Pension / retirement benefit | 28 | Runs through a retirement system, not the WC system |
| `employer_benefit` | Employer benefit | 26 | Mandated employer-funded benefit outside WC, e.g. Fla. Stat. § 112.1816 |
| `lodd_only` | Death benefit only (LODD) | 4 | Line-of-duty death benefit; no disability or treatment coverage |
| `expired` | Expired / lapsed | 2 | Existed and has sunset |
| `none` | No law found | 2 | Researched absence |

## Keys and known duplicates

The natural key is **(`state`, `condition_category`, `responder_type`, `condition_specific`,
`statute_citation`)**. Both narrower keys admit false collisions, and two legitimate
near-duplicate pairs exist. Neither is an error; do not collapse them.

| Rows | Why they are distinct |
|---|---|
| LA / mental / law_enforcement | Two separate statutes covering the same condition — `La. R.S. 33:2581.2` and `La. R.S. 40:1374`. Distinguished by `statute_citation` |
| WV / cancer / firefighter | One statute, `W. Va. Code § 23-4-1(h)`, two cancer groups: leukemia/lymphoma/myeloma is permanent; bladder/mesothelioma/testicular was added in 2024 and **sunsets 2027-07-01**. Distinguished by `condition_specific` — splitting the row is what makes the sunset expressible at all |

`4_combine_records.r` asserts uniqueness on the full key and aborts on a violation.

## Editing rules

- **Edit the record files, never the JSON.** `data/raw/state_records/XX.json` is the source of
  truth; the JSON is a build artifact and will be overwritten. Patching the JSON directly is
  what made this dataset unreproducible in the first place.
- **Values must stay inside the documented domains.** `4_combine_records.r` aborts rather than
  coercing — an out-of-domain value stops the build with the offending rows printed.
- **`needs_verification` takes explanatory text or null.** Never a bare `true`.
- **Every populated `statute_citation` should carry a `source_url`** pointing at the statutory
  text. If no direct source can be found, leave `source_url` null so the dashboard shows plain
  text; do not substitute an IAFF link.
- **A researched absence is data.** Record it as `presumption_exists: false` with a note, not
  by omitting the row.

## Open issues

- **`data_retrieved` is stale.** 411 of 479 rows still read `2026-05-23`; the research behind
  them was re-verified 2026-08-07. Fix from the per-state `Last Verified` dates in
  `docs/lit/state_histories/registry.md`. Deliberately deferred from the 2026-08-20 pipeline
  rebuild so it would not contaminate that change's regression test.
- **DC is in the data but outside the 2026-08-07 QC pass**, which covered the 50 states. Its
  8 rows carry lower confidence than the rest.
- **Federal coverage is not in this dataset.** The federal PSOB cancer presumption
  (P.L. 119-60 § 8205, 34 U.S.C. § 10281(q)) is a death/permanent-total-disability benefit, not
  workers' compensation, and will live in a separate file with its own schema. See
  `docs/admin/federal-psob-cancer-presumption-2025.md`.
