# Product Spec: First Responder Presumptive Laws Dashboard
Created: 2026-05-21

## Product Goal
A publicly accessible, interactive web dashboard showing what presumptive workers' compensation laws exist for first responders across the US — what conditions are covered, which responder groups are eligible, and where laws exist or are absent.

## Target Audience
- Policymakers (state legislators, agency administrators, policy advocates)
- First responder families navigating a WC claim
- Researchers (secondary audience)

Design implication: plain language, no jargon, self-explanatory UI. A family member with no legal background should be able to find their state and understand what protections exist.

---

## Data Model

### Unit of observation
One row = one **state × condition category**.

### Condition categories (from Brandt-Rauf 2024 + NCCI 2023)
| Code | Label |
|------|-------|
| `cancer` | Cancer |
| `cardiovascular` | Cardiovascular Disease |
| `respiratory` | Respiratory Disease |
| `infectious` | Infectious Disease |
| `covid19` | COVID-19 |
| `mental` | Mental Health / PTSD |

### Responder groups
| Code | Label |
|------|-------|
| `fire` | Firefighters |
| `ems` | EMS / Paramedics |
| `police` | Law Enforcement |
| `volunteer` | Volunteer Firefighters |

### Key variables per row
| Variable | Type | Description |
|----------|------|-------------|
| `state` | chr | Two-letter state abbreviation |
| `state_name` | chr | Full state name |
| `condition` | chr | Condition category code (see above) |
| `presumption_exists` | lgl | TRUE if any presumption law exists for this state × condition |
| `responder_groups` | chr | Comma-separated list of eligible groups |
| `rebuttable` | lgl | TRUE if presumption is rebuttable (employer can contest) |
| `statute_citation` | chr | Statute or code citation (e.g., "OR § 656.802") |
| `notes` | chr | Restrictions, service requirements, age limits, sunset clauses |
| `source` | chr | "NCCI_2023" or "BrandtRauf_2024" or both |
| `data_current_through` | chr | "2022-12" or similar |

### Data files
- `data/processed/presumptive_laws.rds` — master R data frame
- `website/data/presumptive_laws.json` — exported for Shinylive (keep in sync)

---

## Dashboard Features (MVP)

### Map view (primary)
- Choropleth map of the 50 US states
- Filter by **condition category** (dropdown or button group)
- Filter by **responder group** (dropdown or button group)
- Color encoding: law exists (green) / no law (light gray) / partial/executive order (amber)
- Click a state → sidebar or tooltip showing:
  - Which conditions are covered
  - Which responder groups are eligible
  - Whether presumption is rebuttable
  - Statute citation
  - Notes on restrictions

### Summary stats (secondary, optional for MVP)
- Count of states with laws by condition category
- Simple bar or table — helps policymakers see the landscape quickly

---

## Dashboard Features (Post-MVP)

- Search by state name
- "Compare states" view
- Timeline of when laws were enacted (if data are available)
- Flag for "law introduced but not yet enacted"
- Update history / last-updated date displayed prominently

---

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Site framework | Quarto website | Familiar to Peter; markdown authoring |
| Interactivity | Shinylive (Shiny in WebAssembly) | No server required; data bundled statically |
| Map library | `leaflet` or `plotly` (R) | Both work inside Shinylive |
| Data format | JSON (served with static site) | Lightweight; directly readable by Shinylive |
| Hosting | TBD (GitHub Pages, Netlify, or ALERRT web server) | All viable for static output |

---

## Data Pipeline

```
PDFs (docs/lit/)
  → analysis/code/1_extract_data.r   # manual extraction + cleaning
  → data/processed/presumptive_laws.rds
  → analysis/code/2_export_json.r    # jsonlite::write_json()
  → website/data/presumptive_laws.json
  → Shinylive app reads at runtime
```

---

## Future Update Strategy (TBD)
Options to explore:
- IAFF presumptive health tracking (iaff.org/presumptive-health)
- NCCI update releases
- Annual Westlaw pull (requires subscription)
- Manual state legislature monitoring for target states

---

## Open Questions
- [ ] Does ALERRT have a preferred hosting platform for the standalone site?
- [ ] Should the site carry ALERRT branding / logo?
- [ ] Do we want a "suggest a correction" mechanism for visitors who spot outdated data?
- [ ] Will police officer coverage data be sourced separately (NCCI brief has some; Brandt-Rauf focuses on fire/EMS)?
