# [STATE NAME] Presumptive Laws — Legislative History

**Research started:** YYYY-MM-DD  
**Research completed:** YYYY-MM-DD  
**Last verified:** YYYY-MM-DD  
**Next review:** YYYY-MM-DD  
**IAFF source:** https://www.iaff.org/presumptive-health/[abbrev]/  
**Legislative session type:** [Annual / Biennial-odd / Biennial-even]  
**Session schedule note:** [e.g., "Meets Jan–June each year" or "Meets odd years only, Jan–June"]

---

## IAFF-Listed Conditions (as of last verified date)

List what the IAFF page shows for this state. This is the canonical "what's covered" view.
Note any discrepancies with the actual statutory language found below.

| Condition | Covered Groups | Statute | IAFF Effective Date Listed | Actual Enactment Date |
|-----------|---------------|---------|---------------------------|----------------------|
| Cancer | | | | |
| Cardiovascular | | | | |
| Respiratory | | | | |
| PTSD / Mental Health | | | | |
| Infectious Disease | | | | |
| [Other] | | | | |

**IAFF date discrepancies:** [Note here if IAFF shows dates that differ from statutory source notes]

---

## Primary Statutes

List the main statutes that implement these presumptions. If a state uses workers' comp code vs. a separate occupational disease chapter, note it.

**Source URL is required for every row** — the direct link to the actual statutory text (official state code/legislature site preferred; a reputable full-text mirror like public.law/Justia/FindLaw is acceptable if no official page is reachable). This is what the dashboard links each table entry to — never IAFF, which is only a directory and has repeatedly been found wrong or stale. If no direct source can be found for a statute, write "none found" rather than leaving it blank or substituting the IAFF page.

| Statute | Title | Conditions | Groups Covered | Source URL |
|---------|-------|------------|----------------|------------|
| | | | | |

---

## Legislative History (Chronological)

### [BILL NAME] ([YEAR])
**[Legislature Session] | Chapter [X] | Effective [DATE]**

What it created or changed. Which groups were covered. What conditions. Key definitions and thresholds.

---

### [BILL NAME] ([YEAR])
**[Legislature Session] | Chapter [X] | Effective [DATE]**

---

## Summary Timeline Table

| Year | Bill | What Changed |
|------|------|-------------|
| | | |

---

## Expirations and Sunsets

| Provision | Description | Expiration Date | Status |
|-----------|-------------|-----------------|--------|
| | | | |

If no provisions have expiration dates, note: "No current expiration provisions."

---

## Key Gaps and Open Questions

Numbered list of things that need follow-up, discrepancies between IAFF page and actual law, or coverage gaps.

1. 
2. 

---

## Structured Records

The machine-readable twin of everything above. These records are what the dashboard is built
from — write them to `[project_root]/data/raw/state_records/[ABBREV].json` as a JSON array,
and reproduce them here so prose and data can be reviewed against each other in one pass.

One record per **condition category x responder type x statute**. A researched absence is a
record too (`presumption_exists: false`), not an omission. Split into two records when one
statute covers two groups of conditions on different terms — that is the only way a
partial sunset can be expressed (see WV cancer in `data/codebook.md`).

Field definitions, allowed values, and the editing rules are in **`data/codebook.md`**. Read it
before writing records. Values outside the documented domains will abort the build.

Quick reference — these three domains are closed:

- `condition_category`: `cancer` | `cardiovascular` | `respiratory` | `infectious` | `mental` | `other`
- `responder_type`: `firefighter` | `firefighter_volunteer` | `emt_paramedic` | `law_enforcement` | `corrections`
- `presumption_type`: `statute` | `EO` | `pension` | `employer_benefit` | `lodd_only` | `expired` | `none`

`presumption_type` records the legal *mechanism*, not just whether something exists. A pension
track, a mandated employer benefit, and a line-of-duty-death-only benefit are each distinct
from a workers'-comp presumption, and collapsing them misrepresents what a claimant gets.

```json
[
  {
    "state": "XX",
    "state_name": "[State Name]",
    "condition_category": "cancer",
    "condition_specific": "[the conditions the statute actually names, verbatim where enumerated]",
    "responder_type": "firefighter",
    "presumption_type": "statute",
    "presumption_exists": true,
    "rebuttable": true,
    "years_service_required": null,
    "pre_employment_exam_required": null,
    "post_termination_months": null,
    "post_termination_formula": null,
    "discovery_during_employment_required": null,
    "filing_deadline_notes": null,
    "tobacco_exclusion": null,
    "statute_citation": "[citation as it should display]",
    "source_url": "[direct link to statutory text — never IAFF; null if none found]",
    "notes": "[plain user-facing language: restrictions, service requirements, sunsets, effective dates. No research-audit commentary — that belongs in the prose above.]",
    "needs_verification": null,
    "iaff_url": "https://www.iaff.org/presumptive-health/[abbrev]/",
    "data_retrieved": "YYYY-MM-DD"
  }
]
```

**Consistency requirements, checked by `legislative-reviewer`:**

- Every statute in the Primary Statutes table above appears in at least one record, with a
  matching `statute_citation` and the same `source_url`.
- Every record's `statute_citation` traces back to a row in that table.
- Every sunset in the Expirations and Sunsets table is reflected in the `notes` of the records
  it affects.
- `data_retrieved` matches the Last verified date in the header.
- `needs_verification` carries explanatory text or `null` — never a bare `true`. A flag nobody
  can act on is not a flag.

---

## Sources

- [State statutory source with section-level URLs]
- IAFF Presumptive Health — [State]: https://www.iaff.org/presumptive-health/[abbrev]/
- [Enrolled bill text URLs]
- [Any secondary sources used]
