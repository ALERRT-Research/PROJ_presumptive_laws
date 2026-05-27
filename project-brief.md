# Project Brief: Presumptive Laws Dashboard
Date initiated: 2026-05-21

## Overview
A web-based research product providing an interactive, publicly accessible dashboard mapping presumptive workers' compensation laws for first responders across all 50 US states. The dashboard shows which conditions are covered, which responder groups are eligible, and key law attributes. Designed to be accessible to policymakers and first responder families — not just researchers.

## Product Goal
What presumptive WC laws are currently in place for first responders across the US, what conditions do they cover, and which responder groups do they apply to?

## Study Type
Research product (data visualization / policy resource). Not a human subjects study.

## Data Plan
Primary source: the IAFF Presumptive Health database ([iaff.org/presumptive-health](https://www.iaff.org/presumptive-health/)), which covers all 50 states and is actively maintained. Data were extracted via scrape of the per-state IAFF pages (see `analysis/code/2_iaff_scrape.r`).

Two published academic reviews were used to cross-check the IAFF extraction:
1. NCCI (2023) brief — ~38 NCCI-jurisdiction states, WC presumptions through Nov 2022
2. Brandt-Rauf et al. (2024), *Journal of Public Health Policy* — 50-state inventory of WC presumption laws, current through Dec 2022

Future updates: re-run the IAFF scrape pipeline (`analysis/code/2_iaff_scrape.r` through `5_iaff_export_json.r`) and redeploy.

## Target Venue
Standalone website linked from the ALERRT research site. Audience: policymakers and first responder families — accessible and intuitive presentation required.

## Timeline
Low pressure. Lightweight prototype first; no hard deadlines.

## Collaborators
Solo project (Peter Tanksley).

## Prior Work and Context
The IAFF Presumptive Health database is the primary data source. Two academic reviews (`docs/lit/`) were used for cross-checking during initial development: the NCCI (2023) brief and Brandt-Rauf et al. (2024). An early hand-coded extraction from those reviews (`analysis/code/1_extract_data.r`) has been superseded by the IAFF scrape pipeline.

## Funding
[TBD: internal ALERRT or unfunded]

## Pre-Registration
Not applicable (research product).

## IRB Status
Not applicable (no human subjects — uses published secondary data only).
