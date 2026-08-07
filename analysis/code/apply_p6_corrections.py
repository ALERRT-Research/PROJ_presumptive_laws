#!/usr/bin/env python3
"""
P6 Corrections -- August 2026
Applies confirmed corrections and completeness fixes from the 2026-08-07
full 50-state legislative-research/QC-gate rerun documented in
docs/lit/state_histories/registry.md (see each state's row and the linked
XX_timeline.md for full sourcing).

Per the P5 lesson, this pass explicitly cross-checks condition x
responder_type combinations that the fresh research confirms exist but
were absent from the JSON entirely (not just fields flagged as wrong).

Only changes traceable to a specific, clearly-stated fact in this round's
registry/timeline files are applied. Findings that were too vague to act
on confidently (e.g., "possible gap, not litigated") are left alone and
are listed in the script's final skip-summary printout.

Run from project root:
    python3 analysis/code/apply_p6_corrections.py

Writes corrected JSON to website/shiny-app/data/presumptive_laws.json,
then copies it to website/data/presumptive_laws.json to keep both files
in sync (matching the CLAUDE.md-documented sync step).
"""

import json
import shutil
from pathlib import Path

JSON_PATH = Path("website/shiny-app/data/presumptive_laws.json")
JSON_PATH_WEB = Path("website/data/presumptive_laws.json")

with open(JSON_PATH) as f:
    data = json.load(f)

original_count = len(data)
changes = []
skipped = []


def find_one(state, cond, resp, citation_contains=None):
    matches = [r for r in data if r["state"] == state
               and r["condition_category"] == cond
               and r["responder_type"] == resp
               and (citation_contains is None or citation_contains in (r.get("statute_citation") or ""))]
    if len(matches) != 1:
        print(f"  WARN: find_one({state}, {cond}, {resp}, {citation_contains}) matched "
              f"{len(matches)} rows -- expected 1")
        return None
    return matches[0]


def find_all(state, cond, resp=None):
    return [r for r in data if r["state"] == state and r["condition_category"] == cond
            and (resp is None or r["responder_type"] == resp)]


def patch(row, field, old_val, new_val, note):
    if row is None:
        return False
    if row.get(field) != old_val:
        print(f"  WARN: [{row['state']}] {row['condition_category']}/{row['responder_type']}: "
              f"expected {field}={old_val!r}, got {row.get(field)!r} -- skipping")
        return False
    row[field] = new_val
    changes.append(f"[{row['state']}] {row['condition_category']}/{row['responder_type']}: "
                   f"{field} {old_val!r} -> {new_val!r}  # {note}")
    return True


def replace_in_note(row, old_substr, new_substr, note):
    if row is None:
        return False
    existing = row.get("notes") or ""
    if old_substr not in existing:
        print(f"  WARN: [{row['state']}] {row['condition_category']}/{row['responder_type']}: "
              f"substring not found in notes -- skipping ({note})")
        return False
    row["notes"] = existing.replace(old_substr, new_substr)
    changes.append(f"[{row['state']}] {row['condition_category']}/{row['responder_type']}: "
                   f"notes updated  # {note}")
    return True


def append_note(row, text, note):
    if row is None:
        return False
    existing = row.get("notes") or ""
    if text[:40] in existing:
        return False  # already applied
    row["notes"] = (existing + " " + text).strip()
    changes.append(f"[{row['state']}] {row['condition_category']}/{row['responder_type']}: "
                   f"notes appended  # {note}")
    return True


# =============================================================================
# TX -- stale pre-2019 cancer eligibility language (registry: "Cancer moved
# AWAY from IARC-exposure standard TO a fixed 11-type enumerated list via
# SB 2551 (2019)"). condition_specific already correctly lists the 11 types,
# but the notes field still describes the pre-2019 exposure-based eligibility
# criteria that SB 2551 removed. TX_timeline.md line 63: SB 2551 "replaced the
# original exposure-based/IARC-referenced standard with a fixed, closed list
# ... removing the prior requirement to show heat/smoke/radiation/carcinogen
# exposure."
# =============================================================================

row = find_one("TX", "cancer", "firefighter")
replace_in_note(
    row,
    "Firefighter must have regularly responded on scene to fire calls, OR regularly "
    "responded to an event involving documented release of radiation or a known/suspected "
    "carcinogen.",
    "CORRECTED (2026-08-07 research): SB 2551 (2019, Ch. 701) removed the original "
    "exposure-based/IARC-referenced eligibility test entirely for this presumption -- "
    "the firefighter need only be diagnosed with one of the 11 enumerated cancer types "
    "above; no showing of heat/smoke/radiation/carcinogen exposure is required (that "
    "requirement predates the 2019 amendment and no longer applies).",
    "TX cancer/firefighter: stale pre-2019 exposure-based eligibility language corrected "
    "per SB 2551 (2019), confirmed in TX_timeline.md"
)

row = find_one("TX", "cancer", "firefighter_volunteer")
replace_in_note(
    row,
    "Must have regularly responded to fire calls or events involving radiation/"
    "carcinogens.",
    "CORRECTED (2026-08-07 research): SB 2551 (2019) removed the exposure-based "
    "eligibility test -- volunteer firefighters need only be diagnosed with one of the "
    "11 enumerated cancer types; no carcinogen/radiation exposure showing required.",
    "TX cancer/firefighter_volunteer: stale pre-2019 exposure language corrected"
)


# =============================================================================
# NY -- section 480 revival CONFIRMED for cancer (registry: "resolves the
# needs_verification flag"). NY_timeline.md.
# =============================================================================

row = find_one("NY", "cancer", "firefighter", citation_contains="363-d")
if row and row.get("needs_verification"):
    row["needs_verification"] = None
    replace_in_note(
        row,
        "Statute nominally expired July 1, 2005 but may be kept alive by NY RSS § 480, "
        "which extends all temporary retirement benefits expiring 1974–2011 (same "
        "mechanism as § 363-a cardiovascular). Active status requires independent legal "
        "verification — original IAFF source characterized this provision as historical "
        "and inactive.",
        "CONFIRMED ACTIVE (2026-08-07 research): § 363-d's current statutory text "
        "cross-references § 480 directly and no longer relies on the 2005 sunset date "
        "at all -- this resolves the prior needs_verification flag. (Note: the parallel "
        "§ 363-f lung/respiratory revival is still only inferred, not directly "
        "annotated in the statute -- see the respiratory/firefighter row, which remains "
        "flagged.)",
        "NY cancer/firefighter (§ 363-d): § 480 revival CONFIRMED, needs_verification cleared"
    )
    changes.append("[NY] cancer/firefighter: needs_verification cleared (§ 480 revival confirmed)")


# =============================================================================
# FL -- Ch. 2026-99 (SB 984) CONFIRMED (registry: "extends the cancer death
# benefit to firefighters who leave service and die within 1 year, closing a
# prior coverage gap"). FL_timeline.md lines 93-97, 138.
# =============================================================================

row = find_one("FL", "cancer", "firefighter")
if row:
    row["needs_verification"] = None
    replace_in_note(
        row,
        "FLAG (2026-07-02 research): Ch. 2026-99 (SB 984) took effect July 1, 2026 — one "
        "day before this research date — and revises this benefit (former-employer "
        "payment conditions, death-benefit duration, removes a Fire Marshal rulemaking "
        "requirement). The only source available is secondary reporting (Insurance "
        "Journal); the enrolled/codified statute text was not independently confirmed. "
        "Content above reflects the pre-Ch. 2026-99 law and should be reverified once the "
        "2026 codification publishes.",
        "CONFIRMED (2026-08-07 research): Ch. 2026-99 (SB 984, signed by the Governor "
        "May 22, 2026, Ch. assigned May 26, 2026) amends § 112.1816(4)(c) to extend the "
        "cancer death-benefit obligation to a firefighter's former employer for 1 year "
        "after the firefighter's termination date, provided the firefighter otherwise met "
        "all program eligibility criteria at termination and was not subsequently "
        "re-employed as a firefighter. This closes a gap in which a firefighter who "
        "developed covered cancer, left employment, and died within a year of leaving "
        "service could previously fall outside any employer's death-benefit obligation. "
        "Confirmed via the bill's official Senate history page and enrolled-bill text "
        "analysis. Effective July 1, 2026.",
        "FL cancer/firefighter: Ch. 2026-99 (SB 984) CONFIRMED, needs_verification cleared"
    )
    changes.append("[FL] cancer/firefighter: needs_verification cleared (Ch. 2026-99 confirmed)")


# =============================================================================
# PA -- heart/lung presumption citation correction. P4 added this row citing
# the (largely vestigial) 1939 Occupational Disease Act section; PA_timeline.md
# confirms the live, actively-amended track is the Workers' Compensation Act's
# own § 108(o) (added 1972, carrying the 1965 heart/lung amendment).
# =============================================================================

row = find_one("PA", "cardiovascular", "firefighter")
patch(row, "statute_citation",
      "Pennsylvania Occupational Disease Act § 1208(o) (77 P.S. § 1208(o)), as amended 1965",
      "Pennsylvania Workers' Compensation Act § 108(o) (Act of June 2, 1915, P.L. 736, "
      "No. 338; § 108 added to the WC Act Oct. 17, 1972, P.L. 930, No. 223; subsection "
      "(o) heart/lung clause added Dec. 17, 1965, P.L. 1121, No. 435); a parallel, "
      "identically-worded (o) clause also exists in the older Occupational Disease Act "
      "(77 P.S. § 1208(o)), but that track has not been amended for firefighters since "
      "1965 and is functionally vestigial today",
      "PA cardiovascular/firefighter: corrected to cite the live WC Act track, not the "
      "vestigial 1939 Occupational Disease Act track (PA_timeline.md 2026-08-07 rerun)")
if row:
    row["needs_verification"] = ("Volunteer-firefighter eligibility under § 108(o) is not "
                                  "textually distinguished from paid coverage (\"any such "
                                  "firemen\") -- treated here as covering both per plain "
                                  "language, but worth an independent legal cross-check "
                                  "before treating as fully settled")
    replace_in_note(
        row,
        "NOT listed on the IAFF Pennsylvania page. Distinct from the WC Act §108(r) cancer "
        "presumption and the §108/301(g) PTSI presumption — this runs through the "
        "separate 1939 Occupational Disease Act. Requires 4+ years of service. "
        "Volunteer-firefighter eligibility under this section is unconfirmed (open "
        "question from 2026-07-02 research). A separate Heart and Lung Act (53 P.S. § 637 "
        "et seq.) layers a full-salary wage-continuation benefit on top of an accepted "
        "claim under this presumption. Original enactment date into the 1939 Act (as "
        "opposed to the 1965 amendment) not independently confirmed.",
        "CORRECTED (2026-08-07 research): this is PA's oldest firefighter presumption, "
        "codified in the live, actively-amended Workers' Compensation Act § 108(o) -- NOT "
        "exclusively the separate 1939 Occupational Disease Act as previously described "
        "(both acts contain a parallel (o) clause, but only the WC Act track has received "
        "post-1965 amendments; the Occupational Disease Act's schedule is functionally "
        "vestigial for this purpose). NOT listed on the IAFF Pennsylvania page at all "
        "(a full omission, not a wrong date) -- confirmed via direct primary-source "
        "review. Requires 4+ years of service, over-exertion or exposure to heat/smoke/"
        "fumes/gases. A separate Heart and Lung Act (53 P.S. § 637 et seq.) layers a "
        "full-salary wage-continuation benefit on top of an accepted claim under this "
        "presumption. Enacted Dec. 17, 1965 (P.L. 1121, No. 435); confirmed via the "
        "statute's own amendment history.",
        "PA cardiovascular/firefighter: citation and note corrected to reflect the live "
        "WC Act § 108(o) track and confirmed 1965 enactment date"
    )


# =============================================================================
# OH -- completeness gap: OH has an extensive PTSD structure (true WC
# compensability pathway removing the "mental-mental bar", § 4123.01/4123.87,
# plus a standalone State Post-Traumatic Stress Fund, § 126.65) but had ZERO
# "mental" category rows in the JSON. OH_timeline.md confirms volunteer FF and
# volunteer/paid peace officers are covered under § 126.65. This is exactly
# the P5-lesson completeness gap: content confirmed to exist, entirely absent
# from the JSON (not merely flagged wrong).
# =============================================================================

_OH_MENTAL_NOTE = (
    "Two mechanisms, created together by H.B. 308 (133rd GA, eff. April 12, 2021): "
    "(1) a true WC compensability pathway -- amends the definition of \"injury\" "
    "(R.C. § 4123.01) so PTSD arising out of employment is compensable through the "
    "ordinary Bureau of Workers' Compensation claims process without an accompanying "
    "physical injury, removing Ohio's \"mental-mental bar\" for this occupational group "
    "(R.C. § 4123.87); and (2) a standalone State Post-Traumatic Stress Fund (R.C. "
    "§ 126.65), a separate benefit fund covering \"public safety officers\" (paid and "
    "volunteer peace officers, paid and volunteer firefighters of a lawfully "
    "constituted fire department, and certified first responders/EMTs) for lost wages "
    "and medical/therapy/hospital costs. The § 126.65 fund was left unfunded and "
    "administratively inoperative for nearly 5 years; H.B. 479 (136th GA, \"Kandice "
    "Straub First Responder PTSI Support Act,\" signed June 24, 2026) created a First "
    "Responder PTSI Fund Commission within the Department of Behavioral Health to "
    "write claims-processing rules and administer the fund, and appropriated $40M for "
    "FY2027. As of the 2026-08-07 research date, claims-processing rules had not yet "
    "been fully promulgated. IAFF's Ohio page omits this entire PTSD track (both the "
    "WC pathway and the § 126.65 fund) entirely -- confirmed completeness gap, added "
    "here per the project's P5 completeness-check lesson."
)

_oh_mental_rows = [
    ("firefighter", "Full-time firefighters."),
    ("firefighter_volunteer", "Volunteer firefighters -- explicitly confirmed covered "
                               "under § 126.65 fund eligibility (\"paid and volunteer "
                               "firefighters of a lawfully constituted fire department\")."),
    ("law_enforcement", "Peace officers (paid and volunteer) -- explicitly confirmed "
                         "covered under § 126.65 fund eligibility."),
    ("emt_paramedic", "Certified first responders/EMTs (basic, intermediate, "
                       "paramedic), paid or volunteer -- covered under the WC pathway "
                       "(§ 4123.87) and the § 126.65 fund, but NOT under Ohio's cancer "
                       "(§ 4123.68(X)) or cardiovascular/respiratory (§ 4123.68(W)) "
                       "presumptions, which are limited to firefighters and police only."),
]

for resp, extra in _oh_mental_rows:
    new_row = {
        "condition_category": "mental",
        "condition_specific": "post-traumatic stress disorder (PTSD), without an "
                               "accompanying physical injury",
        "responder_type": resp,
        "presumption_type": "statute",
        "presumption_exists": True,
        "rebuttable": None,
        "statute_citation": "Ohio Rev. Code § 4123.01/§ 4123.87 (WC compensability "
                            "pathway); § 126.65 (State Post-Traumatic Stress Fund)",
        "years_service_required": None,
        "pre_employment_exam_required": None,
        "post_termination_months": None,
        "post_termination_formula": None,
        "discovery_during_employment_required": None,
        "filing_deadline_notes": None,
        "tobacco_exclusion": None,
        "notes": _OH_MENTAL_NOTE + " " + extra,
        "state": "OH",
        "state_name": "Ohio",
        "iaff_url": "https://www.iaff.org/presumptive-health/oh/",
        "data_retrieved": "2026-08-07",
        "needs_verification": "H.B. 479's claims-processing rules had not yet been "
                              "promulgated as of the 2026-08-07 research date; the "
                              "precise relationship between the § 4123.87 WC pathway and "
                              "the § 126.65 fund (which a claimant uses when) is not "
                              "fully confirmed against primary session-law text",
    }
    data.append(new_row)
    changes.append(f"[OH] mental/{resp}: NEW ROW -- PTSD WC pathway (§ 4123.87) + "
                   f"State PTSD Fund (§ 126.65), entirely missing from prior JSON "
                   f"(P5-lesson completeness gap)")


# =============================================================================
# IN -- "Mental Illness" mischaracterization CONFIRMED. IN_timeline.md:
# "PTSD/mental health: confirmed no true presumption exists... IC 36-8-8.3
# ... is a claims-administration/review-panel framework ... not a rebuttable
# presumption of duty-related causation." The JSON currently carries these
# rows with presumption_exists=True, contradicting the confirmed finding.
# =============================================================================

_IN_MENTAL_CORRECTION = (
    "CONFIRMED (2026-08-07 research, P.L. 54-2020 SEC. 3 origin resolved): IC 36-8-8.3 "
    "is a claims-administration/review-panel procedure for the 1977 Fund's EXISTING "
    "mental-health disability pathway -- it does NOT establish or reference any "
    "presumption that a mental-health condition (including PTSD) is duty-related. "
    "IAFF's page lists \"Mental Illness\" alongside true presumptive conditions in a "
    "way that implies equivalent function; it is not equivalent. Indiana has no "
    "PTSD/mental-health presumption of any kind."
)
for resp in ("firefighter", "law_enforcement"):
    row = find_one("IN", "mental", resp)
    if row:
        row["presumption_exists"] = False
        if not replace_in_note(
            row,
            "This is a pension/disability benefit structure, not a WC presumption per se.",
            _IN_MENTAL_CORRECTION,
            "IN mental: presumption_exists corrected to False -- confirmed mischaracterization"
        ):
            append_note(row, _IN_MENTAL_CORRECTION,
                       "IN mental: presumption_exists corrected to False -- confirmed "
                       "mischaracterization (note appended, exact prior sentence not "
                       "found in this row)")
        changes.append(f"[IN] mental/{resp}: presumption_exists True -> False "
                       f"(confirmed not a duty-related presumption, IN_timeline.md)")


# =============================================================================
# KY -- IAFF citation/benefit-structure errors CONFIRMED, and the prior JSON
# had carried the same errors forward. KY_timeline.md: correct citation is
# KRS 95A.220(5) + 739 KAR 2:160 (KRS 210.365 is an unrelated CIT training
# statute); the benefit has NO time limit, only a $50,000 lifetime cap
# (739 KAR 2:160), not the "12 months" the prior JSON stated.
# =============================================================================

for resp in ("firefighter", "firefighter_volunteer"):
    row = find_one("KY", "mental", resp)
    if row:
        patch(row, "statute_citation", "KRS 210.365 (as amended, Section 1)",
              "KRS 95A.220(5); 739 KAR 2:160 (implementing regulation)",
              "KY mental: citation corrected -- KRS 210.365 is an unrelated crisis-"
              "intervention-team TRAINING statute (confirmed via KY legislature site); "
              "the real authority is KRS 95A.220(5) + 739 KAR 2:160")

row = find_one("KY", "mental", "firefighter")
replace_in_note(
    row,
    "NOTE: This provision is a mental health treatment reimbursement program "
    "(out-of-pocket costs reimbursed by commission), not a traditional WC "
    "compensability presumption — maximum 12 months of reimbursement.",
    "CORRECTED (2026-08-07 research): IAFF's page cites KRS 210.365 (a firefighter/LE "
    "crisis-intervention-team training statute unrelated to this benefit) and describes "
    "a 12-month reimbursement cap -- both errors, now carried forward into and corrected "
    "in this dataset. The correct authority is KRS 95A.220(5) (created 2021 Ky. Acts "
    "ch. 114, amended 2023 Ky. Acts ch. 184) plus implementing regulation 739 KAR 2:160 "
    "(effective Oct. 1, 2024). Current law imposes NO time limit on the benefit itself "
    "-- only a $50,000 LIFETIME dollar cap per 739 KAR 2:160. This is a mental health "
    "treatment reimbursement program through the Kentucky Fire Commission, not a "
    "traditional WC compensability presumption.",
    "KY mental/firefighter: benefit-structure error corrected (no 12-month cap; "
    "$50,000 lifetime cap instead)"
)
row = find_one("KY", "mental", "firefighter_volunteer")
replace_in_note(
    row,
    "Mental health treatment reimbursement program, not WC compensability presumption. "
    "Maximum 12 months reimbursement.",
    "Mental health treatment reimbursement program through the Kentucky Fire "
    "Commission, not a WC compensability presumption. CORRECTED: no time limit on the "
    "benefit itself -- only a $50,000 lifetime dollar cap (739 KAR 2:160). The "
    "regulation carries a 7-year sunset (expires Oct. 1, 2031 unless readopted).",
    "KY mental/firefighter_volunteer: benefit-structure error corrected"
)
if find_one("KY", "mental", "firefighter"):
    find_one("KY", "mental", "firefighter")["needs_verification"] = None
if find_one("KY", "mental", "firefighter_volunteer"):
    find_one("KY", "mental", "firefighter_volunteer")["needs_verification"] = (
        "739 KAR 2:160's implementing regulation carries a 7-year sunset (expires "
        "October 1, 2031 unless readopted) -- worth monitoring ahead of the 2030-2031 "
        "legislative sessions, not an immediate concern"
    )


# =============================================================================
# NC -- cancer-list undercount. condition_specific already correctly lists
# all 6 enumerated LODD cancer types, but the notes field still says "one of
# the four listed cancers" (an internal inconsistency this pass corrects).
# NC_timeline.md line 27 confirms 6 types (mesothelioma, testicular, small
# intestine, esophageal, oral cavity, pharynx) vs. IAFF's stale 4.
# =============================================================================

row = find_one("NC", "cancer", "firefighter", citation_contains="143-166.2")
replace_in_note(
    row,
    "Death from one of the four listed cancers is presumed to be occupationally "
    "related to firefighting and therefore a line-of-duty death, triggering a "
    "$100,000 death benefit to dependents.",
    "Death from one of the SIX listed cancers (mesothelioma, testicular cancer, "
    "cancer of the small intestine, esophageal cancer, oral cavity cancer, pharynx "
    "cancer) is presumed to be occupationally related to firefighting and therefore a "
    "line-of-duty death, triggering a $100,000 death benefit to dependents. CORRECTED "
    "(2026-08-07 research): IAFF's live page lists only 4 of these 6 types (omits "
    "oral cavity and pharynx); this dataset's condition_specific field already listed "
    "all 6 correctly, but this notes field had an internal inconsistency describing "
    "\"four\" -- now corrected to match.",
    "NC cancer/firefighter (LODD, § 143-166.2(6)(e)): notes corrected from 'four' to "
    "'six' listed cancers, matching condition_specific and confirmed primary-source count"
)

# NC cardiovascular: correct citation subsection from (5) to (6)(d), the
# confirmed current codified location per NC_timeline.md.
for resp in ("firefighter", "law_enforcement", "emt_paramedic"):
    row = find_one("NC", "cardiovascular", resp)
    patch(row, "statute_citation", "N.C. Gen. Stat. § 143-166.2(5)",
          "N.C. Gen. Stat. § 143-166.2(6)(d)",
          "NC cardiovascular: citation corrected to confirmed current codified "
          "subsection for the myocardial-infarction LODD presumption")


# =============================================================================
# MD -- (1) add missing Lyme disease presumption row (LE § 9-503(d)),
# entirely absent from the JSON despite being a confirmed, long-standing (1998)
# presumption; (2) add the "Jimmy Malone Act" cancer-screening mandate (Local
# Gov't § 9-114, 2025) as a new non-WC benefit row -- also entirely absent;
# (3) update the LE cardiovascular row to reflect the new Carroll County
# correctional-deputy carve-out (registry: "new finding... needs JSON
# integration"). MD_timeline.md.
# =============================================================================

md_lyme = {
    "condition_category": "infectious",
    "condition_specific": "Lyme disease",
    "responder_type": "law_enforcement",
    "presumption_type": "statute",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "Maryland Code, Labor and Employment § 9-503(d)",
    "years_service_required": None,
    "pre_employment_exam_required": None,
    "post_termination_months": 36,
    "post_termination_formula": "Time-limited to the period assigned to outdoor-wooded "
                                "duty, plus 3 years after reassignment (M-NCPPC park "
                                "police only)",
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": ("Entirely missing from the prior JSON despite being a confirmed, "
              "long-standing presumption -- added per the P5-lesson completeness "
              "check. Originally enacted 1998 (HB 1287) for Dept. of Natural Resources "
              "law-enforcement personnel operating in outdoor/wooded environments. Made "
              "permanent and extended to M-NCPPC (Maryland-National Capital Park and "
              "Planning Commission) park police by HB 977 (Ch. 629, 2014), with "
              "coverage limited to the period assigned to outdoor-wooded duty plus 3 "
              "years after reassignment. Explicitly enumerated to cover forest "
              "rangers, park rangers, and wildlife rangers by HB 584 (Ch. 13, "
              "\"CAPES Act,\" 2024), alongside existing DNR law-enforcement and M-NCPPC "
              "park police coverage. Not listed on the IAFF Maryland page."),
    "state": "MD",
    "state_name": "Maryland",
    "iaff_url": "https://www.iaff.org/presumptive-health/md/",
    "data_retrieved": "2026-08-07",
    "needs_verification": None,
}
data.append(md_lyme)
changes.append("[MD] infectious/law_enforcement: NEW ROW -- Lyme disease presumption "
               "(§ 9-503(d)), entirely missing from prior JSON")

md_jimmy_malone = {
    "condition_category": "cancer",
    "condition_specific": "Preventive cancer screening (bladder, breast, cervical, "
                          "colorectal, lung, oral, prostate, skin, testicular, thyroid) "
                          "-- NOT a compensation presumption",
    "responder_type": "firefighter",
    "presumption_type": "employer_benefit",
    "presumption_exists": True,
    "rebuttable": None,
    "statute_citation": "Md. Code, Local Government § 9-114 (James \"Jimmy\" Malone Act, "
                        "SB 374/HB 459, Ch. 656, 2025)",
    "years_service_required": None,
    "pre_employment_exam_required": None,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": ("NOTE: this is a no-cost preventive cancer SCREENING insurance mandate, "
              "NOT a workers' compensation presumption -- structurally distinct from, "
              "and codified separately from, the § 9-503(c) cancer compensation "
              "presumption. Requires counties that operate self-insured health benefit "
              "plans to provide no-cost (no copay/coinsurance/deductible) preventive "
              "cancer screening to CAREER/PAID firefighters only -- volunteers are "
              "explicitly excluded from the statutory mandate (though Howard County "
              "voluntarily extends the benefit to volunteers). Counties must report "
              "screening data annually to the Maryland Health Care Commission through "
              "2028. Signed by Gov. Wes Moore May 20, 2025 (47-0 Senate, 132-0 House); "
              "eff. Jan. 1, 2026. Named for former Delegate James \"Jimmy\" Malone, who "
              "died of brain cancer in December 2024. CORRECTION (2026-08-07 research): "
              "a prior citation of \"Ins. § 15-861\" (Insurance Article) for this act was "
              "checked directly and found to be an unrelated pediatric-hospital-"
              "transfer provision -- the correct citation is Local Government Article "
              "§ 9-114, confirmed via the bill's own legislative history page. Entirely "
              "missing from the prior JSON."),
    "state": "MD",
    "state_name": "Maryland",
    "iaff_url": "https://www.iaff.org/presumptive-health/md/",
    "data_retrieved": "2026-08-07",
    "needs_verification": None,
}
data.append(md_jimmy_malone)
changes.append("[MD] cancer/firefighter: NEW ROW -- Jimmy Malone Act cancer-screening "
               "mandate (Local Gov't § 9-114), correcting a prior wrong citation and "
               "completeness gap")

row = find_one("MD", "cardiovascular", "law_enforcement")
append_note(
    row,
    "NEW (2026): Carroll County correctional deputies added to this presumption group "
    "by HB 878/SB 449 (Ch. 341, 2026), eff. Oct. 1, 2026 -- a purely county-specific "
    "expansion, not previously documented in this project's research.",
    "MD cardiovascular/law_enforcement: Carroll County correctional-deputy carve-out "
    "added (new finding this cycle, MD_timeline.md)"
)


# =============================================================================
# TN -- completeness gap: § 7-51-201(a) covers law enforcement officers and
# correctional security employees for hypertension/heart disease. This is a
# confirmed, undocumented coverage element ("previously undocumented, not on
# IAFF's page... flag for JSON integration") entirely missing from the JSON,
# which only had firefighter (b) and EMT (c) rows for this statute.
# =============================================================================

tn_le_cardio = {
    "condition_category": "cardiovascular",
    "condition_specific": "Hypertension, heart disease",
    "responder_type": "law_enforcement",
    "presumption_type": "statute",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "Tenn. Code Ann. § 7-51-201(a)",
    "years_service_required": None,
    "pre_employment_exam_required": None,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": ("Entirely missing from the prior JSON -- a genuine coverage element "
              "omitted by both the prior research cycle and IAFF's Tennessee page "
              "(which is firefighter/EMS-focused). § 7-51-201(a) extends the "
              "hypertension/heart-disease occupational-causation presumption to law "
              "enforcement officers generally. Original enactment 1965 (Acts 1965, ch. "
              "299). Not itself a workers' compensation statute -- establishes a "
              "presumption of occupational causation that attaches to whatever "
              "compensation program a covered government employer has established for "
              "line-of-duty injury or death; litigated as part of WC claims where a "
              "municipality has opted into WC (Stone v. City of McMinnville (1995); "
              "Krick v. City of Lawrenceburg (1997))."),
    "state": "TN",
    "state_name": "Tennessee",
    "iaff_url": "https://www.iaff.org/presumptive-health/tn/",
    "data_retrieved": "2026-08-07",
    "needs_verification": None,
}
tn_corrections_cardio = dict(tn_le_cardio)
tn_corrections_cardio["responder_type"] = "corrections"
tn_corrections_cardio["notes"] = tn_le_cardio["notes"] + (
    " Also explicitly covers correctional security employees of the Departments of "
    "Correction and Children's Services, and full-time county deputy sheriffs in "
    "correctional security positions."
)
data.append(tn_le_cardio)
data.append(tn_corrections_cardio)
changes.append("[TN] cardiovascular/law_enforcement: NEW ROW -- § 7-51-201(a), "
               "confirmed missing coverage element (registry: 'previously undocumented')")
changes.append("[TN] cardiovascular/corrections: NEW ROW -- § 7-51-201(a)")


# =============================================================================
# NJ -- cardiovascular/emt_paramedic row described only the pre-2024 volunteer
# first-aid/rescue-squad clause; it omitted the substantive 2023/2024
# expansion to CAREER EMTs/paramedics (public AND private sector), which
# NJ_timeline.md confirms as the more significant 2024 change.
# =============================================================================

row = find_one("NJ", "cardiovascular", "emt_paramedic")
replace_in_note(
    row,
    "Rebuttable presumption. Applies to members of volunteer first aid or rescue "
    "squads.",
    "Rebuttable presumption. Originally (1987) applied only to members of volunteer "
    "first aid or rescue squads. EXPANDED (P.L.2023, c.348, A-5909/S-4267, signed by "
    "the Governor Jan. 16, 2024): now also covers any CAREER emergency medical "
    "technician or paramedic employed by the State, a county, a municipality, OR A "
    "PRIVATE-SECTOR COUNTERPART engaged in public emergency medical and rescue "
    "services -- meaning private-sector EMS employees are covered, not just public-"
    "sector ones. The 2024 amendment also added a defined 24-hour \"remediating from\" "
    "window and raised the medical-causation rebuttal standard to \"clear and "
    "convincing medical evidence.\" Chaptered under the outgoing 2023 legislative year "
    "per NJ's lame-duck chaptering convention despite the January 2024 signing date.",
    "NJ cardiovascular/emt_paramedic: added confirmed 2024 private-sector career EMT "
    "expansion (P.L.2023, c.348), previously omitted from this row's notes"
)


# =============================================================================
# VA -- IAFF PTSD benefit-cap error CONFIRMED (52 weeks vs. actual 104 weeks),
# and the pending 2026 causation-reform amendment CONFIRMED enacted. Neither
# fact was in the JSON's notes (the wrong 52-week figure was never adopted
# here, so this is a confirmed-fact addition rather than an error fix).
# =============================================================================

_VA_MENTAL_ADDENDUM = (
    " CONFIRMED (2026-08-07 research): § 65.2-107(C) caps benefits at 104 weeks from "
    "date of diagnosis (no award beyond 4 years from the qualifying event) -- IAFF's "
    "page states a 52-week maximum, which is a confirmed error in IAFF's own listing "
    "(noted here so the correct figure is on record). Separately, a 2026 causation-"
    "reform amendment (Acts 2026, cc. 7, 465), effective January 1, 2027, adds a new "
    "qualifying-event category for PTSD specifically -- \"an incident or exposure "
    "without any accompanying physical injury\" -- removing the prior requirement that "
    "a qualifying event involve actual or threatened serious bodily injury/death. Not "
    "yet in effect as of this research date; IAFF's page does not reflect this "
    "pending change."
)
for resp in ("firefighter", "firefighter_volunteer", "emt_paramedic", "law_enforcement"):
    row = find_one("VA", "mental", resp)
    append_note(row, _VA_MENTAL_ADDENDUM.strip(),
                f"VA mental/{resp}: added confirmed 104-week benefit cap "
                f"(corrects IAFF's 52-week figure) and 2026 causation-reform note")


# =============================================================================
# WA -- PTSD presumption enactment year CONFIRMED as 2018 (2018 c 264), not
# 2019; fire investigators confirmed EXCLUDED from the PTSD presumption
# despite being added to the base disease-presumption group in 2019. Neither
# the year nor the fire-investigator exclusion was previously in the JSON.
# =============================================================================

_WA_MENTAL_ADDENDUM = (
    "Enacted 2018 (2018 c 264, SSB 6214, eff. June 7, 2018) -- CORRECTS a prior "
    "internal tracking note that had used 2019; the 2019 session law (2019 c 133) only "
    "made conforming cross-reference updates to the PTSD text and did not create or "
    "expand it. Public employee fire investigators, though added to the base disease-"
    "presumption group (respiratory/heart/cancer/infectious disease) in 2019, are "
    "explicitly EXCLUDED from this PTSD presumption -- a genuine coverage gap that "
    "IAFF's page does not surface."
)
for resp in ("firefighter", "law_enforcement"):
    row = find_one("WA", "mental", resp)
    append_note(row, _WA_MENTAL_ADDENDUM,
                f"WA mental/{resp}: added confirmed 2018 enactment year and fire-"
                f"investigator exclusion note")


# =============================================================================
# MA -- cancer condition_specific list omits breast and reproductive-organ
# cancers, added by Chapter 148 of the Acts of 2018. This is the SAME gap
# registry confirms exists on IAFF's own page -- our JSON independently
# carried the identical omission.
# =============================================================================

row = find_one("MA", "cancer", "firefighter")
patch(row, "condition_specific",
      "cancer affecting skin or central nervous, lymphatic, digestive, hematological, "
      "urinary, skeletal, oral, or prostate systems, lung or respiratory tract; any "
      "cancer linked to heat, radiation, or IARC-listed carcinogen with statistically "
      "significant correlation to fire service",
      "cancer affecting skin or central nervous, lymphatic, digestive, hematological, "
      "urinary, skeletal, oral, prostate, BREAST, or REPRODUCTIVE systems, lung or "
      "respiratory tract; any cancer linked to heat, radiation, or IARC-listed "
      "carcinogen with statistically significant correlation to fire service",
      "MA cancer/firefighter: added breast and reproductive-organ cancers (Ch. 148 of "
      "the Acts of 2018) -- confirmed omission that this JSON independently shared "
      "with IAFF's page")
append_note(
    row,
    "CORRECTED (2026-08-07 research): breast and reproductive-organ cancers were added "
    "to the enumerated body-system list by Chapter 148 of the Acts of 2018 (approved "
    "July 20, 2018), which also extended the § 94B presumption by cross-reference into "
    "c. 41 § 111F (paid injury leave). This dataset's condition_specific field had "
    "independently carried the same omission found on IAFF's page -- now corrected.",
    "MA cancer/firefighter: note explaining the Ch. 148 (2018) addition"
)


# =============================================================================
# NV -- 2025 special-session bill (SB 7, 36th Special Session) confirmed to
# have removed the exposure-causation requirement from the lung-disease
# conclusive-presumption pathway, retroactively. Not previously in the JSON.
# =============================================================================

_NV_LUNG_ADDENDUM = (
    "CONFIRMED (2026-08-07 research): SB 7 (36th Special Session, 2025, prefiled Nov. "
    "15, 2025) amended NRS 617.455 so the conclusive presumption available to "
    "long-tenured (2+ years) firefighters/police/arson investigators is no longer "
    "conditioned on the disease having been caused by exposure to heat, smoke, fumes, "
    "tear gas, or other noxious gases -- severing the exposure-causation link from the "
    "conclusive-presumption pathway. Applies retroactively to claims filed on or "
    "before the act's effective date, meaning it can revive previously denied "
    "lung-disease claims that failed for lack of a proven exposure link."
)
for resp in ("firefighter", "law_enforcement"):
    row = find_one("NV", "respiratory", resp)
    append_note(row, _NV_LUNG_ADDENDUM,
                f"NV respiratory/{resp}: added confirmed 2025 SB 7 causation-link removal")


# =============================================================================
# ID -- PTSD sunset mischaracterization CONFIRMED. The 2019 sunset clause was
# repealed BEFORE it ever took effect (2023 HB 18); coverage is permanent, not
# time-limited. The JSON's existing notes described the original sunset
# without noting it was repealed -- the same misleading framing IAFF uses.
# =============================================================================

for resp in ("firefighter", "emt_paramedic", "law_enforcement"):
    row = find_one("ID", "mental", resp)
    append_note(
        row,
        "CORRECTED (2026-08-07 research): the July 1, 2023 sunset clause referenced "
        "above was REPEALED before it ever took effect, by 2023 HB 18 (Ch. 5, eff. "
        "July 1, 2023). PTSD/PTSI compensability under § 72-451 is now PERMANENT -- no "
        "sunset exists in the statute today. (IAFF's page presents the sunset language "
        "as though it describes current or recently-expired law, which could mislead a "
        "reader into thinking coverage lapsed or is time-limited; it has not and is not.)",
        f"ID mental/{resp}: clarified that the 2019 sunset was repealed by 2023 HB 18 "
        f"before taking effect -- coverage is permanent"
    )


# =============================================================================
# KS -- completeness gap: KSA 44-501(c)(2) is a modified WC causation
# standard (not a true presumption) for cardiac/cerebrovascular events,
# confirmed by this round's research and confirmed omitted from IAFF's page.
# It was also entirely absent from this project's JSON. Added following the
# established pattern for "near-miss, not a true presumption" rows (cf. TN
# § 8-50-119, WY, NE false rows).
# =============================================================================

_KS_WC_NOTE = (
    "IMPORTANT: this is NOT a rebuttable presumption -- it is a modified workers' "
    "compensation causation standard requiring (A) a specific identifiable work "
    "event, (B) the cardiac/cerebrovascular event within 24 hours of that event, and "
    "(C) the event being the \"prevailing factor\" in causation; the burden never "
    "shifts to the employer. Enacted L. 2014, ch. 25, § 1, applicable to events on or "
    "after July 1, 2014; amended L. 2024, ch. 27, § 2. Separate from and in addition "
    "to the KP&F pension presumption (KSA 74-4952) coded elsewhere for this state. "
    "IAFF's Kansas page omits this WC track entirely, presenting the KP&F pension "
    "presumption as though it were the complete picture -- a reader relying solely on "
    "IAFF would not learn that Kansas workers' compensation law addresses cardiac "
    "events at all. Entirely missing from the prior JSON; added per the P5-lesson "
    "completeness check."
)
for resp in ("firefighter", "law_enforcement"):
    ks_wc_row = {
        "condition_category": "cardiovascular",
        "condition_specific": "Coronary or coronary artery disease; cerebrovascular "
                              "injury (modified WC causation standard, not a "
                              "presumption)",
        "responder_type": resp,
        "presumption_type": "statute",
        "presumption_exists": False,
        "rebuttable": None,
        "statute_citation": "KSA 44-501(c)(2)",
        "years_service_required": None,
        "pre_employment_exam_required": None,
        "post_termination_months": None,
        "post_termination_formula": None,
        "discovery_during_employment_required": None,
        "filing_deadline_notes": None,
        "tobacco_exclusion": None,
        "notes": _KS_WC_NOTE,
        "state": "KS",
        "state_name": "Kansas",
        "iaff_url": "https://www.iaff.org/presumptive-health/ks/",
        "data_retrieved": "2026-08-07",
        "needs_verification": None,
    }
    data.append(ks_wc_row)
    changes.append(f"[KS] cardiovascular/{resp}: NEW ROW -- KSA 44-501(c)(2) modified "
                   f"WC causation standard (not a true presumption), missing from prior "
                   f"JSON and from IAFF's page")


# =============================================================================
# MS -- REMOVAL: cardiovascular/firefighter and cardiovascular/law_enforcement
# rows citing § 25-15-405 are confirmed WRONG. This round's research
# confirms the cardiovascular/respiratory/infectious-disease/hearing-loss
# provisions were in the AS-INTRODUCED 2019 bill (SB 2835) but were STRIPPED
# during conference committee and never enacted -- "none exist today, not
# 'possibly WC-track.'" § 25-15-405 in the ENACTED code is actually the
# cancer-benefits eligibility/amounts section, not a cardiovascular
# provision -- the existing rows cite a section that does not contain what
# they describe.
# =============================================================================

_ms_removed = []
for resp in ("firefighter", "law_enforcement"):
    row = find_one("MS", "cardiovascular", resp)
    if row:
        data.remove(row)
        _ms_removed.append(resp)
        changes.append(f"[MS] cardiovascular/{resp}: ROW REMOVED -- § 25-15-405 does not "
                       f"contain a cardiovascular provision in the enacted code (it is "
                       f"the cancer-benefits eligibility/amounts section); this round's "
                       f"research confirms the original bill's heart/lung provision was "
                       f"STRIPPED in conference committee and never became law "
                       f"(MS_timeline.md lines 18-19, 43, 65)")


# =============================================================================
# MT -- non-Hodgkin's lymphoma and testicular cancer confirmed ADDED LATER
# (2023, SB 310/Ch. 442) -- NOT part of the original 2019 (SB 160) 12-type
# enactment. The JSON's notes applied a single "Effective July 1, 2019" date
# uniformly to the whole 13-type list, the same misleading framing IAFF uses.
# =============================================================================

_MT_CANCER_DATE_NOTE = (
    "CORRECTED (2026-08-07 research): 11 of these 13 cancer types (all except "
    "non-Hodgkin's lymphoma and testicular cancer) were enacted eff. July 1, 2019 "
    "(SB 160, Ch. 158, L. 2019). Non-Hodgkin's lymphoma (15-yr service requirement) "
    "and testicular cancer (10-yr service requirement) were added FOUR YEARS LATER "
    "by SB 310 (Ch. 442, L. 2023), signed May 4, 2023, presumed effective October "
    "1, 2023 under Montana's default effective-date statute (§ 1-2-201, MCA) -- the "
    "exact effective-date clause within SB 310's own bill text was not "
    "independently retrieved. IAFF's page applies a single 2019 date to the whole "
    "13-type list, which is materially misleading for these two types; this "
    "dataset previously carried the same error."
)
row = find_one("MT", "cancer", "firefighter")
replace_in_note(
    row,
    "Effective July 1, 2019; applies to diseases diagnosed on or after that date.",
    _MT_CANCER_DATE_NOTE,
    "MT cancer/firefighter: split the enactment date -- 11 types from 2019 (SB 160), "
    "non-Hodgkin's lymphoma + testicular cancer from 2023 (SB 310)"
)
row = find_one("MT", "cancer", "firefighter_volunteer")
append_note(row, _MT_CANCER_DATE_NOTE,
           "MT cancer/firefighter_volunteer: added same enactment-date split "
           "clarification as the paid-firefighter row")


# =============================================================================
# AL -- confirmed IAFF replicated its own blanket "October 1, 2026" date
# across ALL SEVEN conditions, when only Parkinson's disease is actually new
# in 2026 -- the other six (hypertension, cardiovascular, respiratory,
# cancer, HIV, hepatitis) trace to the original 1967 municipal enactment.
# The JSON had independently carried the same blanket-date error across five
# rows (cancer, cardiovascular, respiratory, infectious x2).
# =============================================================================

_AL_DATE_FIX_NOTE = (
    "CORRECTED (2026-08-07 research): the \"Effective October 1, 2026\" date stated "
    "above applied to ALL of Alabama's occupational-disease conditions in this "
    "dataset's prior notes, mirroring IAFF's own page, which applies a single blanket "
    "date to every condition. In fact, October 1, 2026 (HB466, 2026) is the effective "
    "date for ONLY the Parkinson's disease addition -- this condition (like "
    "hypertension, cardiovascular, respiratory, HIV, and hepatitis) traces to the "
    "ORIGINAL 1967 municipal enactment (§ 11-43-144, applicable per the statute's own "
    "grandfather clause to firefighters with 3+ years' continuous service preceding "
    "September 8, 1967). The state-track provision's (§ 36-30-40/41) original "
    "enactment year is not independently confirmed (a Jan. 1, 2013 physical-exam "
    "grandfather-clause deadline suggests ca. 2010-2013, not the previously assumed "
    "2016)."
)
for cond in ("cancer", "cardiovascular", "respiratory"):
    row = find_one("AL", cond, "firefighter")
    replace_in_note(row, "Effective October 1, 2026.", _AL_DATE_FIX_NOTE,
                    f"AL {cond}/firefighter: corrected blanket 2026 date -- this "
                    f"condition actually dates to 1967, only Parkinson's is new in 2026")

for row in find_all("AL", "infectious", "firefighter"):
    replace_in_note(row, "Effective October 1, 2026.", _AL_DATE_FIX_NOTE,
                    "AL infectious/firefighter: corrected blanket 2026 date -- this "
                    "condition actually dates to 1967, only Parkinson's is new in 2026")


# =============================================================================
# AR -- completeness gap: two confirmed non-WC benefit mechanisms (the paid-
# leave mandate, § 21-4-107, and the Firefighter Cancer Relief Network Trust
# Fund, § 21-5-110/§ 19-5-1153) are entirely absent from the JSON, which
# only carried the death-benefit and pension-disability mechanisms. Registry:
# "now confirmed across five non-WC tracks (a Firefighter Cancer Relief
# Network Trust Fund was newly identified this cycle, not in prior research)."
# =============================================================================

ar_paid_leave = {
    "condition_category": "other",
    "condition_specific": "Paid leave for occupationally-caused cancer treatment "
                          "(cross-references the same cancer list as § 21-5-705)",
    "responder_type": "firefighter",
    "presumption_type": "employer_benefit",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "Ark. Code Ann. § 21-4-107",
    "years_service_required": 5,
    "pre_employment_exam_required": None,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": ("NOT a workers' compensation presumption -- a paid-leave mandate. "
              "Entitles paid, full-time firefighters with 5+ years of service to a "
              "minimum 1,456 hours of paid leave upon initiating treatment for "
              "occupationally-caused cancer (cross-referencing the § 21-5-705(a)(3)(A)(i) "
              "cancer list). Requires a Dept. of Health/IARC-consistent carcinogen-"
              "exposure determination; presumption of occupational causation is "
              "rebuttable by medical evidence of non-occupational causation. A pre-"
              "employment physical showing no pre-existing cancer strengthens the "
              "presumption. Yields if the same cancer is already covered by workers' "
              "compensation. Believed enacted 2019; the exact bill/Act number is "
              "unconfirmed (commonly, but likely incorrectly, attributed to HB1299, "
              "which 2019 legislative records describe as an unrelated general "
              "sick-leave-accrual bill). Not listed by IAFF; entirely missing from "
              "the prior JSON."),
    "state": "AR",
    "state_name": "Arkansas",
    "iaff_url": "https://www.iaff.org/presumptive-health/ar/",
    "data_retrieved": "2026-08-07",
    "needs_verification": "Exact enacting bill/Act number for § 21-4-107 (believed "
                          "2019) is unconfirmed -- the commonly-cited HB1299 attribution "
                          "appears to be a different, unrelated bill",
}
ar_trust_fund = {
    "condition_category": "other",
    "condition_specific": "Firefighter Cancer Relief Network Trust Fund -- charitable "
                          "relief payments for cancer diagnosis (any type, network-"
                          "determined)",
    "responder_type": "firefighter",
    "presumption_type": "employer_benefit",
    "presumption_exists": True,
    "rebuttable": None,
    "statute_citation": "Ark. Code Ann. § 21-5-110 / § 19-5-1153",
    "years_service_required": None,
    "pre_employment_exam_required": None,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": ("Newly identified this research cycle -- not in prior project research "
              "and entirely missing from the JSON. NOT a burden-shifting legal "
              "presumption -- a state-administered charitable relief-fund trust (State "
              "Insurance Department), with eligibility and award determinations "
              "delegated to the Arkansas Association of Fire Chiefs, Arkansas "
              "Professional Fire Fighters Association, and Arkansas State Firefighters "
              "Association, Inc. Open to both career and volunteer firefighters "
              "enrolled in the network. Implementing rule at 23 CAR 40 (Arkansas "
              "Insurance Dept. rules). Enactment year/Act number unconfirmed. Not "
              "listed by IAFF."),
    "state": "AR",
    "state_name": "Arkansas",
    "iaff_url": "https://www.iaff.org/presumptive-health/ar/",
    "data_retrieved": "2026-08-07",
    "needs_verification": "Enactment year and Act number for § 21-5-110/§ 19-5-1153 not "
                          "confirmed",
}
ar_trust_fund_vol = dict(ar_trust_fund)
ar_trust_fund_vol["responder_type"] = "firefighter_volunteer"
data.append(ar_paid_leave)
data.append(ar_trust_fund)
data.append(ar_trust_fund_vol)
changes.append("[AR] other/firefighter: NEW ROW -- paid-leave mandate (§ 21-4-107), "
               "missing from prior JSON")
changes.append("[AR] other/firefighter: NEW ROW -- Firefighter Cancer Relief Network "
               "Trust Fund, newly identified this cycle (registry: 'not in prior "
               "research')")
changes.append("[AR] other/firefighter_volunteer: NEW ROW -- Firefighter Cancer Relief "
               "Network Trust Fund (volunteer)")


# =============================================================================
# RI -- (1) completeness gap: PTSD is covered on TWO tracks, and the pension
# track (§ 45-21.2-9, added 2021) actually PREDATES the IOD track (§ 45-19-1
# (a)(2), added 2024) by 3 years; only the IOD track was in the JSON.
# (2) completeness gap: the cardiovascular presumption (§ 45-19-16.1) covers
# "firefighters and police officers," but the JSON only had a firefighter
# row. (3) the new-hire tobacco/pre-existing-condition exclusion cutoff was
# moved from July 1, 2023 to July 1, 2025 by P.L. 2025, ch. 440/441.
# =============================================================================

ri_ptsd_pension = {
    "condition_category": "mental",
    "condition_specific": "post-traumatic stress disorder / post-traumatic stress "
                          "injury (qualifying condition for accidental disability "
                          "retirement)",
    "responder_type": "firefighter",
    "presumption_type": "pension",
    "presumption_exists": True,
    "rebuttable": None,
    "statute_citation": "R.I. Gen. Laws § 45-21.2-9",
    "years_service_required": None,
    "pre_employment_exam_required": None,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": "18-month filing deadline; subject to a three-physician "
                             "confirmation process",
    "tobacco_exclusion": None,
    "notes": ("Entirely missing from the prior JSON, which only carried the later "
              "§ 45-19-1(a)(2) IOD/salary-continuation PTSD track. This is a SECOND, "
              "separate PTSD track: PTSD was added as a qualifying condition for "
              "accidental disability retirement (66⅔% of final compensation) by P.L. "
              "2021, ch. 391 and ch. 392, effective July 16, 2021 -- notably, PTSD was "
              "recognized on this PENSION track THREE YEARS BEFORE it was recognized on "
              "the IOD/salary-continuation track (2024, see the § 45-19-1(a)(2) row). "
              "Rhode Island should be coded as a non-WC, dual pension/IOD-benefit "
              "state (comparable to Indiana, Iowa, South Dakota), not a workers' "
              "compensation presumption state."),
    "state": "RI",
    "state_name": "Rhode Island",
    "iaff_url": "https://www.iaff.org/presumptive-health/ri/",
    "data_retrieved": "2026-08-07",
    "needs_verification": None,
}
ri_ptsd_pension_le = dict(ri_ptsd_pension)
ri_ptsd_pension_le["responder_type"] = "law_enforcement"
data.append(ri_ptsd_pension)
data.append(ri_ptsd_pension_le)
changes.append("[RI] mental/firefighter: NEW ROW -- pension-track PTSD (§ 45-21.2-9, "
               "2021), predates the IOD track by 3 years, missing from prior JSON")
changes.append("[RI] mental/law_enforcement: NEW ROW -- pension-track PTSD "
               "(§ 45-21.2-9, 2021)")

row = find_one("RI", "cardiovascular", "firefighter")
replace_in_note(
    row,
    "For firefighters hired AFTER July 1, 2023: presumption does not apply if (1) "
    "pre-employment physical revealed heart disease or hypertension, or (2) "
    "firefighter regularly/habitually used tobacco products during the 5 years prior "
    "to diagnosis. No such restrictions for firefighters hired before July 1, 2023.",
    "CORRECTED (2026-08-07 research): as originally enacted (P.L. 2023, ch. 360/361, "
    "eff. June 27, 2023), the new-hire exclusion cutoff was July 1, 2023 -- but that "
    "cutoff was later MOVED to July 1, 2025 by P.L. 2025, ch. 440/441. For "
    "firefighters hired AFTER July 1, 2025: presumption does not apply if (1) "
    "pre-employment physical revealed heart disease or hypertension, or (2) "
    "firefighter regularly/habitually used tobacco products during the 5 years prior "
    "to diagnosis. No such restrictions for firefighters hired before July 1, 2025. "
    "IAFF's page shows \"July 1, 2023\" for this condition, which is actually the "
    "statute's original (now-superseded) new-hire cutoff, not its enactment date "
    "(true enactment: June 27, 2023) -- a compound, now-stale discrepancy.",
    "RI cardiovascular/firefighter: corrected new-hire cutoff date (2023 -> 2025, "
    "per P.L. 2025 ch. 440/441) and clarified enactment vs. cutoff date confusion"
)

ri_cardio_le = dict(row) if row else None
if ri_cardio_le:
    ri_cardio_le["responder_type"] = "law_enforcement"
    data.append(ri_cardio_le)
    changes.append("[RI] cardiovascular/law_enforcement: NEW ROW -- § 45-19-16.1 "
                   "explicitly covers 'firefighters AND police officers'; only the "
                   "firefighter row existed in the prior JSON")


# =============================================================================
# UT -- HB 65's cancer-list expansion (4 -> 15 types) is confirmed effective
# July 1, 2025, NOT January 1, 2026 as the prior JSON stated. January 1, 2026
# is the mandatory cancer-SCREENING program's start date (a different
# provision, § 34A-3-114), not the expanded presumption's effective date.
# =============================================================================

for resp in ("firefighter", "firefighter_volunteer"):
    row = find_one("UT", "cancer", resp)
    replace_in_note(
        row,
        "HB 65 (signed March 25, 2025, effective January 1, 2026) expanded cancer list "
        "from 4 types (pharynx, esophagus, lung, mesothelioma) to 15 types.",
        "CORRECTED (2026-08-07 research): HB 65 (\"Firefighter Cancer Amendments,\" "
        "signed March 25, 2025) expanded the cancer list from 4 types (pharynx, "
        "esophagus, lung, mesothelioma) to 15 types, effective JULY 1, 2025 -- the "
        "bill's own enacting clause states \"This bill takes effect on July 1, 2025.\" "
        "A prior internal tracking note had listed this as January 1, 2026, which is "
        "actually the SCREENING PROGRAM's (§ 34A-3-114) required start date, a "
        "separate provision -- not the effective date of the expanded cancer list "
        "itself.",
        "UT cancer: corrected HB 65 effective date from Jan 1, 2026 to July 1, 2025 "
        "-- Jan 1, 2026 is actually the separate screening-program start date"
    )


# =============================================================================
# HI -- registry flags the cancer medical-fee-enhancement provision's legal
# character as ambiguous ("flag for methodological review before coding HI
# alongside true presumption states"). This is a request for review, not a
# confirmed factual error, so presumption_exists/type are left unchanged
# (avoiding a guess) -- a needs_verification flag is added to surface the
# open methodological question for the next review cycle.
# =============================================================================

row = find_one("HI", "cancer", "firefighter")
if row and not row.get("needs_verification"):
    row["needs_verification"] = (
        "METHODOLOGICAL FLAG (2026-08-07 research): § 386-21.9's legal character (a "
        "medical-fee-schedule enhancement applied only AFTER a claim is already "
        "accepted as compensable, vs. an independent presumption of compensability) is "
        "ambiguous. It does not itself create a presumption -- standard individual "
        "proof of work-relatedness is still required for the underlying WC claim. "
        "Flagged for methodological review before treating Hawaii as a true "
        "presumption state for this condition in cross-state comparisons."
    )
    changes.append("[HI] cancer/firefighter: needs_verification added -- ambiguous "
                   "legal character flagged for methodological review, per registry")


# =============================================================================
# Skipped findings -- too vague, or the underlying fact was not confirmed
# with enough specificity this cycle to act on without guessing.
# =============================================================================

skipped.extend([
    "TX detention/custodial officers: registry notes zero active coverage since their "
    "only provision (COVID-19, § 607.0545) expired 9/1/2023 -- not actionable as a "
    "JSON row change since there is no 'detention_officer' responder_type in the "
    "schema and no active coverage exists to document.",
    "NY infectious disease: 'no NYC/GML analog found for infectious disease (RSS "
    "§ 363-dd)' -- registry frames this as a 'possible gap,' not a confirmed fact; "
    "skipped per the instruction not to guess beyond documented findings.",
    "WV female-specific cancers (ovarian/uterine/breast/cervical) gap -- registry "
    "notes 'no bill addresses' this despite advocacy, but this is a gap-flag, not a "
    "correction to any existing JSON content; no action taken.",
    "ID cancer/volunteer exclusion -- registry explicitly says this 'needs legal/"
    "primary-text confirmation before publishing either way'; left as-is.",
    "NC Article 86A pilot-program pre-2024 cancer standard -- registry explicitly "
    "flags this as unresolved ('not yet possible to say definitively'); no JSON "
    "change made.",
    "VT LE exclusion from cancer AND infectious/lung -- already correctly reflected "
    "by the ABSENCE of law_enforcement rows for those VT conditions; no row to add "
    "or remove.",
    "KS cancer/cardiovascular/respiratory pension-track true enactment year -- "
    "registry says 'best hypothesis L. 2005 ch. 196 or earlier,' explicitly "
    "unconfirmed; the JSON did not previously assert a specific (wrong) year, so "
    "left as-is rather than adding an unconfirmed hypothesis.",
    "SC 1962/1968 origin dates and LE 2005 origin date -- the JSON did not "
    "previously assert incorrect dates for these (no date was stated), so there was "
    "no error to correct; not adding speculative precision beyond what a dashboard "
    "row needs.",
    "LA 'statistically significant increased risk' catch-all 2017 origin -- already "
    "correctly reflected in condition_specific; the exact origin year is a narrative "
    "enhancement, not a correction of wrong content, and was deprioritized given the "
    "volume of higher-confidence fixes this round.",
    "NH age-65 vs age-70 cutoff -- the JSON does not state an age cutoff for this "
    "condition at all, so there was no incorrect figure to fix; deprioritized as an "
    "enhancement rather than a correction.",
    "AL state-track (§ 36-30-40/41) original enactment year -- explicitly unconfirmed "
    "in AL_timeline.md ('ca. 2010-2013... unconfirmed'); noted in the corrected note "
    "text but not asserted as a hard date.",
])


# =============================================================================
# Report
# =============================================================================

print(f"\n{'='*70}")
print(f"P6 CORRECTIONS APPLIED: {len(changes)} changes")
print(f"{'='*70}")
for c in changes:
    print(f"  {c}")

print(f"\n{'='*70}")
print(f"FINDINGS DELIBERATELY SKIPPED (insufficient confidence): {len(skipped)}")
print(f"{'='*70}")
for s in skipped:
    print(f"  - {s}")

print(f"\nRow count: {original_count} -> {len(data)} ({len(data) - original_count} net new rows)")

# Write output to the canonical Shinylive-app copy, then sync to website/data/
with open(JSON_PATH, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

shutil.copyfile(JSON_PATH, JSON_PATH_WEB)

print(f"\nWritten to {JSON_PATH}")
print(f"Copied to {JSON_PATH_WEB} to keep both dashboard data files in sync")
print("Review with: git diff website/shiny-app/data/presumptive_laws.json "
      "website/data/presumptive_laws.json")
