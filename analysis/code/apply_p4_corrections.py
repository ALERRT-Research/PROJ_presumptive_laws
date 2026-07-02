#!/usr/bin/env python3
"""
P4 Corrections — July 2026
Applies corrections and additions from the 2026-07-02 /research-states rerun
of the six pre-pipeline states (TX, CA, NY, FL, IL, PA), per
docs/lit/state_histories/{TX,CA,NY,FL,IL,PA}_timeline.md.

Run from project root:
    python3 analysis/code/apply_p4_corrections.py

Writes corrected JSON in place. Review diff before committing.
"""

import json
from pathlib import Path

JSON_PATH = Path("website/shiny-app/data/presumptive_laws.json")

with open(JSON_PATH) as f:
    data = json.load(f)

original_count = len(data)
changes = []


def patch(row, field, old_val, new_val, note):
    if row.get(field) != old_val:
        print(f"  WARN: [{row['state']}] {row['condition_category']}/{row['responder_type']}: "
              f"expected {field}={old_val!r}, got {row.get(field)!r} — skipping")
        return False
    row[field] = new_val
    changes.append(f"[{row['state']}] {row['condition_category']}/{row['responder_type']}: "
                   f"{field} {old_val!r} -> {new_val!r}  # {note}")
    return True


def prepend_note(row, text, note):
    existing = row.get("notes") or ""
    if text[:40] in existing:
        return  # already applied
    row["notes"] = text + (" " + existing if existing else "")
    changes.append(f"[{row['state']}] {row['condition_category']}/{row['responder_type']}: "
                   f"notes prepended  # {note}")


def append_note(row, text, note):
    existing = row.get("notes") or ""
    if text[:40] in existing:
        return  # already applied
    row["notes"] = (existing + " " + text).strip()
    changes.append(f"[{row['state']}] {row['condition_category']}/{row['responder_type']}: "
                   f"notes appended  # {note}")


def replace_in_note(row, old_substr, new_substr, note):
    existing = row.get("notes") or ""
    if old_substr not in existing:
        print(f"  WARN: [{row['state']}] {row['condition_category']}/{row['responder_type']}: "
              f"'{old_substr[:30]}' not found in notes — skipping")
        return False
    row["notes"] = existing.replace(old_substr, new_substr)
    changes.append(f"[{row['state']}] {row['condition_category']}/{row['responder_type']}: "
                   f"notes updated  # {note}")
    return True


def find_one(state, cond, resp, citation_contains=None):
    matches = [r for r in data if r["state"] == state
               and r["condition_category"] == cond
               and r["responder_type"] == resp
               and (citation_contains is None or citation_contains in (r.get("statute_citation") or ""))]
    if len(matches) != 1:
        print(f"  WARN: find_one({state}, {cond}, {resp}) matched {len(matches)} rows — expected 1")
        return None
    return matches[0]


# ── CA: resolve PTSD sunset-date discrepancy (2029 vs 2032) ──────────────────

ca_mental_ff = find_one("CA", "mental", "firefighter")
if ca_mental_ff:
    ok = replace_in_note(
        ca_mental_ff,
        "Government Code § 31720.91 provides parallel disability retirement presumption "
        "(county pension systems) — repealed January 1, 2032 per SB 623 extension. "
        "Sunset discrepancy: leginfo.legislature.ca.gov shows § 31720.91 repealing "
        "January 1, 2029; IAFF page shows 2032. Verify against AB 2770 (2024) enrolled "
        "text before citing either date.",
        "Government Code § 31720.91 provides parallel disability retirement presumption "
        "(county pension systems). RESOLVED (2026-07-02 research): both the WC track "
        "(§ 3212.15) and the pension track (§ 31720.91) sunset January 1, 2029, confirmed "
        "via SB 623 (2023) and AB 2770 (2024) enrolled text. IAFF's page incorrectly shows "
        "2032 for the pension track; that figure does not appear in the statutory text.",
        "CA § 31720.91 sunset discrepancy resolved: confirmed 2029, not 2032"
    )
    if ok:
        ca_mental_ff["needs_verification"] = None
        changes.append("[CA] mental/firefighter: needs_verification cleared (sunset date resolved)")


# ── TX: add new 2025 retiree critical-illness/health-benefit program rows ────

tx_retiree_ff = {
    "condition_category": "other",
    "condition_specific": "Retiree critical-illness/health benefit — triggered by post-retirement "
                          "diagnosis (within 3 years of retirement) of an enumerated § 607.055 "
                          "cancer, acute myocardial infarction, or stroke",
    "responder_type": "firefighter",
    "presumption_type": "employer_benefit",
    "presumption_exists": True,
    "rebuttable": None,
    "statute_citation": "Tex. Gov't Code §§ 607.151–607.153 (HB 4144, Acts 2025, 89th Leg., R.S.)",
    "years_service_required": None,
    "pre_employment_exam_required": None,
    "post_termination_months": 36,
    "post_termination_formula": "Diagnosis must occur within 3 years (36 months) of retirement",
    "discovery_during_employment_required": False,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": (
        "NOTE: This is not a workers' compensation presumption. It is a freestanding, "
        "mandatory employer-funded benefit (lump-sum or 3-month critical-illness "
        "supplemental income of the lesser of final annual salary or $100,000, "
        "CPI-adjusted every 5 years, or comparable post-retirement health coverage), "
        "structurally similar to Florida's § 112.1816 program. Effective September 1, 2025; "
        "applies only to firefighters/peace officers retiring on or after January 1, 2026 "
        "from a department/agency with 50+ personnel. Political subdivisions already "
        "providing comparable retiree health coverage are exempt. Does NOT cover EMTs. "
        "Not yet reflected on the IAFF Texas page as of this research date (2026-07-02)."
    ),
    "state": "TX",
    "state_name": "Texas",
    "iaff_url": "https://www.iaff.org/presumptive-health/tx/",
    "data_retrieved": "2026-07-02",
    "needs_verification": None,
}

tx_retiree_le = dict(tx_retiree_ff)
tx_retiree_le["responder_type"] = "law_enforcement"
tx_retiree_le["notes"] = tx_retiree_ff["notes"].replace(
    "firefighters/peace officers", "peace officers/firefighters"
)

data.append(tx_retiree_ff)
data.append(tx_retiree_le)
changes.append("[TX] other/firefighter: NEW ROW — 2025 retiree critical-illness benefit (HB 4144)")
changes.append("[TX] other/law_enforcement: NEW ROW — 2025 retiree critical-illness benefit (HB 4144)")


# ── IL: clarify cross-track cancer standard split ────────────────────────────

il_cancer_ff = find_one("IL", "cancer", "firefighter")
if il_cancer_ff:
    append_note(
        il_cancer_ff,
        "CLARIFICATION (2026-07-02 research): the IARC-linked-carcinogen requirement applies "
        "to the pension track (40 ILCS 5/4-110.1, 6-151.1) only. The parallel WC/Occupational "
        "Diseases Act track (820 ILCS 305, 310) presumes any cancer type without requiring "
        "proof of a specific IARC-classified carcinogen link — a real cross-track standard "
        "difference that the existing note above does not distinguish.",
        "IL cancer/firefighter: cross-track IARC-linkage standard clarified"
    )


# ── PA: add Occupational Disease Act § 1208(o) heart/lung row ───────────────

pa_heart_lung = {
    "condition_category": "cardiovascular",
    "condition_specific": "Heart and lung disease/impairment (firefighters)",
    "responder_type": "firefighter",
    "presumption_type": "statute",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "Pennsylvania Occupational Disease Act § 1208(o) (77 P.S. § 1208(o)), "
                        "as amended 1965",
    "years_service_required": 4,
    "pre_employment_exam_required": None,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": (
        "NOT listed on the IAFF Pennsylvania page. Distinct from the WC Act §108(r) cancer "
        "presumption and the §108/301(g) PTSI presumption — this runs through the separate "
        "1939 Occupational Disease Act. Requires 4+ years of service. Volunteer-firefighter "
        "eligibility under this section is unconfirmed (open question from 2026-07-02 "
        "research). A separate Heart and Lung Act (53 P.S. § 637 et seq.) layers a "
        "full-salary wage-continuation benefit on top of an accepted claim under this "
        "presumption. Original enactment date into the 1939 Act (as opposed to the 1965 "
        "amendment) not independently confirmed."
    ),
    "state": "PA",
    "state_name": "Pennsylvania",
    "iaff_url": "https://www.iaff.org/presumptive-health/pa/",
    "data_retrieved": "2026-07-02",
    "needs_verification": "Volunteer-firefighter eligibility under § 1208(o) not confirmed; "
                          "original 1939 Act enactment date (vs. 1965 amendment) not confirmed",
}

data.append(pa_heart_lung)
changes.append("[PA] cardiovascular/firefighter: NEW ROW — Occupational Disease Act § 1208(o) heart/lung")


# ── FL: add missing smallpox-vaccination-injury rows ─────────────────────────

fl_smallpox_base = {
    "condition_category": "other",
    "condition_specific": "Smallpox vaccination adverse effects (deemed a compensable injury "
                          "arising out of employment)",
    "presumption_type": "statute",
    "presumption_exists": True,
    "rebuttable": None,
    "statute_citation": "Fla. Stat. § 112.1815(2)(b)",
    "years_service_required": None,
    "pre_employment_exam_required": None,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": (
        "Deems any adverse result/complication of a smallpox vaccination administered to a "
        "first responder to be an injury by accident arising out of employment. Originally "
        "enacted Ch. 2007-87 (2007), arising from federal/state smallpox pre-event "
        "vaccination programs — predates the 2018 PTSD amendment to the same section. "
        "IAFF's page shows October 1, 2018 for this provision, which is actually the "
        "PTSD-amendment date for a different part of § 112.1815, not this provision's own "
        "enactment date. Narrow in practical scope (only applies during an active smallpox "
        "vaccination program) but remains on the books, no repeal or sunset found."
    ),
    "state": "FL",
    "state_name": "Florida",
    "iaff_url": "https://www.iaff.org/presumptive-health/fl/",
    "data_retrieved": "2026-07-02",
    "needs_verification": None,
}

for resp, vol_note in [
    ("firefighter", "Also covers volunteer firefighters."),
    ("law_enforcement", "Also covers volunteer law enforcement."),
    ("emt_paramedic", "Also covers volunteer EMTs/paramedics."),
]:
    row = dict(fl_smallpox_base)
    row["responder_type"] = resp
    row["notes"] = fl_smallpox_base["notes"] + " " + vol_note
    data.append(row)
    changes.append(f"[FL] other/{resp}: NEW ROW — smallpox vaccination injury (§ 112.1815(2)(b))")


# ── FL: flag cancer row for Ch. 2026-99 (not yet codified, secondary source only) ─

fl_cancer_ff = find_one("FL", "cancer", "firefighter")
if fl_cancer_ff:
    append_note(
        fl_cancer_ff,
        "FLAG (2026-07-02 research): Ch. 2026-99 (SB 984) took effect July 1, 2026 — one "
        "day before this research date — and revises this benefit (former-employer payment "
        "conditions, death-benefit duration, removes a Fire Marshal rulemaking requirement). "
        "The only source available is secondary reporting (Insurance Journal); the enrolled/"
        "codified statute text was not independently confirmed. Content above reflects the "
        "pre-Ch. 2026-99 law and should be reverified once the 2026 codification publishes.",
        "FL cancer/firefighter: Ch. 2026-99 flagged, not yet content-verified"
    )
    fl_cancer_ff["needs_verification"] = (
        "Ch. 2026-99 (SB 984, eff. 2026-07-01) revisions not yet confirmed against codified "
        "statute text — only secondary source (Insurance Journal) available"
    )
    changes.append("[FL] cancer/firefighter: needs_verification set for Ch. 2026-99")


# ── NY: clarify existing RSSL rows are the non-NYC track ─────────────────────

NY_NON_NYC_NOTE = (
    "Applies to NYSLPFRS localities outside New York City. New York City operates its own "
    "uniformed pension funds under General Municipal Law Article 10, not RSSL — see the "
    "separate NYC-specific rows for this state."
)

for cond, resp in [("cardiovascular", "firefighter"), ("cardiovascular", "law_enforcement"),
                   ("cancer", "firefighter")]:
    row = find_one("NY", cond, resp)
    if row:
        prepend_note(row, NY_NON_NYC_NOTE, f"NY {cond}/{resp}: non-NYC scope clarified")


# ── NY: add PTSD/mental-health track (WCL § 10(3)(c), statewide) ────────────

ny_ptsd_base = {
    "condition_category": "mental",
    "condition_specific": "Post-traumatic stress disorder, acute stress disorder, or major "
                          "depressive disorder resulting from a distinct work-related "
                          "emergency event",
    "presumption_type": "statute",
    "presumption_exists": True,
    "rebuttable": None,
    "statute_citation": "N.Y. Workers' Compensation Law § 10(3)(c)",
    "years_service_required": None,
    "pre_employment_exam_required": None,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": (
        "Not listed on the IAFF New York page at all. 2017 reform (WCB Subject No. 046-936) "
        "removed the 'no greater than similarly situated workers' bar for first-responder "
        "mental-injury claims arising from extraordinary work-related stress during "
        "emergencies. Expanded to all covered employees by Ch. 546, Laws of 2024 "
        "(eff. 2024-12-06), then narrowed back toward named first-responder categories "
        "(police, fire, EMT/paramedic, emergency dispatcher) by Ch. 79, Laws of 2025 "
        "(eff. 2025-02-14). Diagnosis must be by a licensed psychiatrist/psychologist using "
        "DSM criteria, tied to a distinct work-related event (not general cumulative stress)."
    ),
    "state": "NY",
    "state_name": "New York",
    "iaff_url": "https://www.iaff.org/presumptive-health/ny/",
    "data_retrieved": "2026-07-02",
    "needs_verification": "Whether the February 2025 amendment (Ch. 79) retains any coverage "
                          "for non-first-responder 'covered employees' is unresolved — "
                          "secondary sources disagree; needs a direct read of enacted bill text",
}

for resp in ["firefighter", "law_enforcement", "emt_paramedic"]:
    row = dict(ny_ptsd_base)
    row["responder_type"] = resp
    data.append(row)
    changes.append(f"[NY] mental/{resp}: NEW ROW — WCL § 10(3)(c) PTSD/mental-health pathway")


# ── NY: add NYC-specific heart presumption (GML § 207-k) ────────────────────

ny_nyc_heart_base = {
    "condition_category": "cardiovascular",
    "condition_specific": "Diseases of the heart (NYC only — City of New York uniformed "
                          "police/fire force)",
    "presumption_type": "pension",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "N.Y. Gen. Mun. Law § 207-k",
    "years_service_required": None,
    "pre_employment_exam_required": True,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": (
        "Not listed on the IAFF New York page. Applies to paid members of the uniformed "
        "force of a paid police or fire department drawn from competitive civil-service "
        "lists, in cities meeting the statute's population/civil-service criteria "
        "(functionally NYC only) — parallel to, and separate from, the statewide RSSL "
        "§ 363-a track. Requires a clean pre-entry physical. Statute text carries a nominal "
        "'NB Expired July 1, 1973' notation with no RSSL § 480-equivalent extension "
        "mechanism identified — current force-and-effect status is MORE uncertain than the "
        "statewide RSSL provisions. Explicitly does not apply to WC Law or Labor Law claims "
        "— operates purely as a pension-disability determination."
    ),
    "state": "NY",
    "state_name": "New York",
    "iaff_url": "https://www.iaff.org/presumptive-health/ny/",
    "data_retrieved": "2026-07-02",
    "needs_verification": "GML § 207-k carries a nominal 1973 expiration with no identified "
                          "extension mechanism — current legal force is unconfirmed and needs "
                          "independent verification before being treated as settled",
}

for resp in ["firefighter", "law_enforcement"]:
    row = dict(ny_nyc_heart_base)
    row["responder_type"] = resp
    data.append(row)
    changes.append(f"[NY] cardiovascular/{resp}: NEW ROW — GML § 207-k (NYC only)")


# ── NY: add NYC-specific cancer presumption (GML § 207-kk, firefighter only) ─

ny_nyc_cancer = {
    "condition_category": "cancer",
    "condition_specific": "Melanoma; cancers of the lymphatic, digestive, hematological, "
                          "urinary, neurological, breast, reproductive, and endocrine/thyroid "
                          "systems, and prostate cancer (NYC only — City of New York uniformed "
                          "fire force, including retirees within 5 years of retirement)",
    "responder_type": "firefighter",
    "presumption_type": "pension",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "N.Y. Gen. Mun. Law § 207-kk",
    "years_service_required": None,
    "pre_employment_exam_required": None,
    "post_termination_months": 60,
    "post_termination_formula": "Retirees within 5 years of retirement remain eligible",
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": (
        "Not listed on the IAFF New York page. Parallel to, and separate from, the statewide "
        "RSSL § 363-d track (which explicitly does not apply to NYC). Same cancer list as "
        "§ 363-d. A 2003 NY Comptroller opinion noted this provision was 'scheduled to "
        "expire' July 1, 2005, like § 363-d, but unlike the § 207-k heart provision, § 207-kk "
        "has clearly been kept alive and actively amended since (Ch. 531, Laws of 2003; and "
        "2023-2024 amendment S.7289-A/A.1999 adding endocrine/thyroid cancers) — good "
        "evidence this provision is currently active."
    ),
    "state": "NY",
    "state_name": "New York",
    "iaff_url": "https://www.iaff.org/presumptive-health/ny/",
    "data_retrieved": "2026-07-02",
    "needs_verification": None,
}

data.append(ny_nyc_cancer)
changes.append("[NY] cancer/firefighter: NEW ROW — GML § 207-kk (NYC only)")


# ── NY: add volunteer firefighter tracks (VFBL § 61 heart; GML § 205-cc cancer) ─

ny_vfbl_heart = {
    "condition_category": "cardiovascular",
    "condition_specific": "Coronary artery disease / heart disease (volunteer firefighters, "
                          "statewide)",
    "responder_type": "firefighter_volunteer",
    "presumption_type": "statute",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "N.Y. Volunteer Firefighters' Benefit Law § 61",
    "years_service_required": None,
    "pre_employment_exam_required": None,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": (
        "Not listed on the IAFF New York page. Original enactment 1977. Rebuttable "
        "presumption: claim must be paid unless there is 'substantial evidence' the "
        "firefighter's duties did not cause the condition. Carries a recurring 5-year sunset "
        "clause — most recently extended to June 30, 2030 by Chapter 143, Laws of 2025 "
        "(S.8011, signed 2025-06-18); prior renewals in 2003, 2010, 2015, 2020. A companion "
        "2025 bill (S.1663) proposed making the presumption permanent instead of subject to "
        "further 5-year renewals; final disposition not confirmed."
    ),
    "state": "NY",
    "state_name": "New York",
    "iaff_url": "https://www.iaff.org/presumptive-health/ny/",
    "data_retrieved": "2026-07-02",
    "needs_verification": None,
}

ny_gml205cc_cancer = {
    "condition_category": "cancer",
    "condition_specific": "Prostate, breast, lymphatic, hematological, digestive, urinary, "
                          "neurological, and reproductive-system cancers, and melanoma "
                          "(volunteer firefighters, statewide)",
    "responder_type": "firefighter_volunteer",
    "presumption_type": "employer_benefit",
    "presumption_exists": True,
    "rebuttable": None,
    "statute_citation": "N.Y. Gen. Mun. Law § 205-cc (Volunteer Firefighter Enhanced Cancer "
                        "Disability Benefits Program)",
    "years_service_required": 5,
    "pre_employment_exam_required": True,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": (
        "NOTE: This is not a workers' compensation or pension presumption — it is a "
        "mandatory employer-purchased insurance benefit program (lump-sum, income-"
        "protection, and death benefits on qualifying diagnosis), structurally similar to "
        "Florida's § 112.1816 program. Enacted 2017; implementing regulations (9 NYCRR Part "
        "210) adopted 2018-10-17; fire districts/departments had to show proof of qualifying "
        "coverage by 2019-01-01. Requires 5+ years of 'faithful and actual' interior "
        "structural firefighting service, a clean entry physical, and annual certified "
        "mask-fit testing. Coverage must run until 60 months after a district/department no "
        "longer has any volunteer firefighter who could qualify."
    ),
    "state": "NY",
    "state_name": "New York",
    "iaff_url": "https://www.iaff.org/presumptive-health/ny/",
    "data_retrieved": "2026-07-02",
    "needs_verification": None,
}

data.append(ny_vfbl_heart)
data.append(ny_gml205cc_cancer)
changes.append("[NY] cardiovascular/firefighter_volunteer: NEW ROW — VFBL § 61 heart presumption")
changes.append("[NY] cancer/firefighter_volunteer: NEW ROW — GML § 205-cc cancer benefit")


# ── NY: add volunteer EMS tracks (VAWBL heart; VAWBL enhanced cancer benefit) ─
# Lumped into the existing "emt_paramedic" responder_type rather than adding a
# new "emt_volunteer" category — only 2 rows use it, doesn't justify a new
# filter category in the Shiny app (app.R hardcodes GROUPS/responder_choices).
# Volunteer-only scope is called out explicitly in condition_specific/notes
# instead, since responder_type itself no longer signals it.

ny_vawbl_heart = {
    "condition_category": "cardiovascular",
    "condition_specific": "Coronary artery disease / heart disease (volunteer EMS members "
                          "only, statewide; expedited 90-day claim decision)",
    "responder_type": "emt_paramedic",
    "presumption_type": "statute",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "N.Y. Volunteer Ambulance Workers' Benefit Law (heart presumption "
                        "provision)",
    "years_service_required": None,
    "pre_employment_exam_required": True,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": "Expedited 90-day claim decision requirement",
    "tobacco_exclusion": None,
    "notes": (
        "IMPORTANT: applies to VOLUNTEER EMS members only — tagged under the shared "
        "emt_paramedic category because this dataset has no separate volunteer-EMS "
        "responder type (unlike firefighter/firefighter_volunteer). Not listed on the IAFF "
        "New York page. This is the only EMS disease presumption identified for New York — "
        "career (non-volunteer) EMS/paramedics have no identified disease presumption in "
        "New York outside the WCL § 10(3)(c) PTSD pathway. Requires a clean entry physical."
    ),
    "state": "NY",
    "state_name": "New York",
    "iaff_url": "https://www.iaff.org/presumptive-health/ny/",
    "data_retrieved": "2026-07-02",
    "needs_verification": None,
}

ny_vawbl_cancer = {
    "condition_category": "cancer",
    "condition_specific": "Enhanced cancer disability and death benefit (volunteer EMS "
                          "members only, statewide)",
    "responder_type": "emt_paramedic",
    "presumption_type": "employer_benefit",
    "presumption_exists": True,
    "rebuttable": None,
    "statute_citation": "N.Y. Volunteer Ambulance Workers' Benefit Law (enhanced cancer "
                        "benefit provision)",
    "years_service_required": 5,
    "pre_employment_exam_required": True,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": (
        "IMPORTANT: applies to VOLUNTEER EMS members only — tagged under the shared "
        "emt_paramedic category because this dataset has no separate volunteer-EMS "
        "responder type. NOTE: This is a mandatory benefit program, not a presumption — "
        "parallel in structure to the volunteer-firefighter GML § 205-cc benefit. Includes "
        "a $50,000 enhanced cancer death benefit. Requires 5+ years of service and a clean "
        "entry physical."
    ),
    "state": "NY",
    "state_name": "New York",
    "iaff_url": "https://www.iaff.org/presumptive-health/ny/",
    "data_retrieved": "2026-07-02",
    "needs_verification": None,
}

data.append(ny_vawbl_heart)
data.append(ny_vawbl_cancer)
changes.append("[NY] cardiovascular/emt_paramedic: NEW ROW — VAWBL heart presumption (volunteer only)")
changes.append("[NY] cancer/emt_paramedic: NEW ROW — VAWBL enhanced cancer benefit (volunteer only)")


# ── Report ────────────────────────────────────────────────────────────────────

print(f"\n{'='*60}")
print(f"P4 CORRECTIONS APPLIED: {len(changes)} changes")
print(f"{'='*60}")
for c in changes:
    print(f"  {c}")

print(f"\nRow count: {original_count} -> {len(data)} ({len(data) - original_count} new rows)")

# Write output
with open(JSON_PATH, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"\nWritten to {JSON_PATH}")
print("Review with: git diff website/shiny-app/data/presumptive_laws.json")
