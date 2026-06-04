#!/usr/bin/env python3
"""
P2 Corrections — June 2026
Adds missing rows identified in docs/admin/corrections-inventory.md.
Source of truth: 50-state timeline research (docs/lit/state_histories/in-progress/).

Also includes field updates for UT and VA cancer rows (inventory P2 field items).

Run from project root:
    python3 analysis/code/apply_p2_corrections.py

Appends new rows to JSON and updates specified existing rows. Review diff before committing.

SKIPPED (tentative, pending schema decision):
  - MD cardiovascular/firefighter hypertension standalone (HB 347, eff. Oct 1, 2026)
  - MD infectious/law_enforcement Lyme disease (§ 9-503(d))
"""

import json
import copy
from pathlib import Path

JSON_PATH = Path("website/shiny-app/data/presumptive_laws.json")

with open(JSON_PATH) as f:
    data = json.load(f)

original_len = len(data)
added = []
updated = []

TODAY = "2026-06-04"


def row(state, state_name, iaff_url, condition_category, condition_specific,
        responder_type, presumption_exists, presumption_type, rebuttable,
        statute_citation, years_service_required=None, pre_employment_exam_required=False,
        post_termination_months=None, post_termination_formula=None,
        discovery_during_employment_required=False, filing_deadline_notes=None,
        tobacco_exclusion=None, notes="", needs_verification=None):
    return {
        "condition_category": condition_category,
        "condition_specific": condition_specific,
        "responder_type": responder_type,
        "presumption_type": presumption_type,
        "presumption_exists": presumption_exists,
        "rebuttable": rebuttable,
        "statute_citation": statute_citation,
        "years_service_required": years_service_required,
        "pre_employment_exam_required": pre_employment_exam_required,
        "post_termination_months": post_termination_months,
        "post_termination_formula": post_termination_formula,
        "discovery_during_employment_required": discovery_during_employment_required,
        "filing_deadline_notes": filing_deadline_notes,
        "tobacco_exclusion": tobacco_exclusion,
        "notes": notes,
        "state": state,
        "state_name": state_name,
        "iaff_url": iaff_url,
        "data_retrieved": TODAY,
        "needs_verification": needs_verification,
    }


# ── ALASKA — AS 23.30.118, PTSD, eff. Jan 1, 2025 ────────────────────────────
# IAFF page omits this statute entirely. 4 rows.
AK_PTSD_NOTE = (
    "AS 23.30.118 (SB 147 / Ch. 12 SLA 2024, eff. January 1, 2025). PTSD must be "
    "diagnosed by a licensed psychologist or psychiatrist during employment or within "
    "3 years after last date of employment. Rebuttable by preponderance of evidence "
    "that PTSD resulted from non-work factors. No minimum service requirement. "
    "IAFF page does not list this statute."
)

for resp in ["firefighter", "emt_paramedic", "law_enforcement", "corrections"]:
    data.append(row(
        state="AK", state_name="Alaska",
        iaff_url="https://www.iaff.org/presumptive-health/ak/",
        condition_category="mental",
        condition_specific="Post-traumatic stress disorder (PTSD)",
        responder_type=resp,
        presumption_exists=True,
        presumption_type="statute",
        rebuttable=True,
        statute_citation="Alaska Stat. § 23.30.118",
        post_termination_months=36,
        notes=AK_PTSD_NOTE,
    ))
    added.append(f"AK mental/{resp}")

# ── TENNESSEE — § 7-51-206 (James 'Dustin' Samples Act) ──────────────────────
# Firefighters eff. Jan 1, 2024 (PC 465). LE/EMS eff. July 1, 2025 (PC 480).
# Keep existing § 8-50-119 rows (False); app will prioritize these True rows.
TN_7_51_206 = "Tenn. Code Ann. § 7-51-206 (James 'Dustin' Samples Act)"
TN_PTSD_COMMON = (
    "True WC presumption under § 7-51-206. Qualifying traumatic incidents include: "
    "witnessing death/injury of a minor who subsequently died; witnessing an individual "
    "whose death involved serious bodily injury shocking the conscience; responding to "
    "an event where a victim sustained serious bodily injury shocking the conscience; "
    "responding to an event where a co-worker/responder/family member sustained serious "
    "bodily injury or died. PTSD must be diagnosed by a mental health professional within "
    "1 year of the final date of employment. Rebuttable by preponderance of evidence that "
    "PTSD was caused by non-service-connected risk factors. Separate from and in addition "
    "to the § 8-50-119 treatment access mandate (coded as a separate row with "
    "presumption_exists=false). IAFF page does not list § 7-51-206."
)

for resp, note_suffix in [
    ("firefighter", "Full-time paid firefighters in departments recognized by TN State Fire Marshal. Eff. January 1, 2024 (PC 465)."),
    ("law_enforcement", "Law enforcement officers. Eff. July 1, 2025 (PC 480)."),
    ("emt_paramedic", "Emergency medical responders (EMTs, technician-paramedics, paramedics). Eff. July 1, 2025 (PC 480)."),
]:
    data.append(row(
        state="TN", state_name="Tennessee",
        iaff_url="https://www.iaff.org/presumptive-health/tn/",
        condition_category="mental",
        condition_specific="Post-traumatic stress disorder (PTSD); workers' compensation presumption",
        responder_type=resp,
        presumption_exists=True,
        presumption_type="statute",
        rebuttable=True,
        statute_citation=TN_7_51_206,
        post_termination_months=12,
        notes=TN_PTSD_COMMON + " " + note_suffix,
    ))
    added.append(f"TN mental/{resp} (§ 7-51-206)")

# ── WISCONSIN — § 102.17(9), PTSD ────────────────────────────────────────────
# Enacted 2021 a. 29 (eff. Apr 29, 2021). Expanded 2025 a. 145 (eff. Apr 1, 2026).
WI_PTSD_NOTE = (
    "Wis. Stat. § 102.17(9). Enacted 2021 a. 29 (eff. April 29, 2021) for law enforcement "
    "officers and full-time firefighters. Expanded by 2025 a. 145 (eff. April 1, 2026) to "
    "include all firefighters regardless of full-time/volunteer status and emergency medical "
    "responders (s. 256.01(4p)) and emergency medical services practitioners (s. 256.01(5)). "
    "Rebuttable by preponderance of evidence. Benefit cap: 32 calendar weeks per episode. "
    "Lifetime cap: no more than 3 episodes per individual. Excluded causes: disciplinary "
    "actions, work evaluations, job transfers, layoffs, demotions, terminations. "
    "IAFF page does not list this statute."
)

for resp in ["firefighter", "firefighter_volunteer", "law_enforcement", "emt_paramedic"]:
    data.append(row(
        state="WI", state_name="Wisconsin",
        iaff_url="https://www.iaff.org/presumptive-health/wi/",
        condition_category="mental",
        condition_specific="Post-traumatic stress disorder (PTSD); workers' compensation presumption",
        responder_type=resp,
        presumption_exists=True,
        presumption_type="statute",
        rebuttable=True,
        statute_citation="Wis. Stat. § 102.17(9)",
        notes=WI_PTSD_NOTE,
    ))
    added.append(f"WI mental/{resp}")

# ── OREGON — ORS 656.802(7), PTSD ────────────────────────────────────────────
# Enacted by SB 507, eff. September 29, 2019.
OR_PTSD_NOTE = (
    "ORS 656.802(7), enacted by SB 507 (eff. September 29, 2019). Covered: full-time "
    "paid firefighters, EMS providers, police officers, corrections/youth correction "
    "officers, parole/probation officers, emergency dispatchers/9-1-1 operators. "
    "Condition: PTSD or acute stress disorder (DSM-5 criteria). Eligibility: 5+ years "
    "employment OR a single traumatic event meeting DSM-5 Criterion A (waives service "
    "requirement). Rebuttal standard: clear and convincing medical evidence that duties "
    "were not of real importance in causing the condition. Claim window: employed OR "
    "separated within 7 years of claim filing. IAFF page does not list this statute."
)

for resp in ["firefighter", "emt_paramedic", "law_enforcement", "corrections"]:
    data.append(row(
        state="OR", state_name="Oregon",
        iaff_url="https://www.iaff.org/presumptive-health/or/",
        condition_category="mental",
        condition_specific="Post-traumatic stress disorder (PTSD) or acute stress disorder (DSM-5)",
        responder_type=resp,
        presumption_exists=True,
        presumption_type="statute",
        rebuttable=True,
        statute_citation="Oregon Revised Statutes § 656.802(7)",
        years_service_required=5,
        post_termination_months=84,
        notes=OR_PTSD_NOTE,
    ))
    added.append(f"OR mental/{resp}")

# ── MISSOURI — RSMo § 287.067(9), PTSD ───────────────────────────────────────
# Enacted by SB 24, eff. August 28, 2023.
MO_PTSD_NOTE = (
    "RSMo § 287.067(9), enacted by SB 24 (eff. August 28, 2023). Covered: certified "
    "first responders — firefighters, police officers, EMTs, paramedics, and "
    "telecommunicators. PTSD must be diagnosed per DSM-5 criteria. Standard: clear "
    "and convincing evidence that PTSD resulted from employment. No physical injury "
    "required. Qualifying events include: witnessing death or serious injury of a "
    "minor; witnessing a death; being involved in a life-threatening situation; "
    "treating a person who subsequently dies. Preexisting PTSD not compensable. "
    "IAFF page does not list § 287.067(9) — it only shows pension/pool statutes."
)

for resp in ["firefighter", "law_enforcement", "emt_paramedic"]:
    data.append(row(
        state="MO", state_name="Missouri",
        iaff_url="https://www.iaff.org/presumptive-health/mo/",
        condition_category="mental",
        condition_specific="Post-traumatic stress disorder (PTSD; DSM-5 diagnosis required)",
        responder_type=resp,
        presumption_exists=True,
        presumption_type="statute",
        rebuttable=True,
        statute_citation="RSMo § 287.067(9)",
        filing_deadline_notes="52 weeks after qualifying exposure or diagnosis, whichever is later",
        notes=MO_PTSD_NOTE,
    ))
    added.append(f"MO mental/{resp}")

# ── GEORGIA — Ashley Wilson Act (§§ 45-25-1 et seq.), PTSD ───────────────────
# HB 451, signed May 1, 2024; claims eligible from Jan 1, 2025.
GA_PTSD_NOTE = (
    "O.C.G.A. §§ 45-25-1 et seq. (Ashley Wilson Act; HB 451, signed May 1, 2024; "
    "claims eligible January 1, 2025). IMPORTANT: This is a mandatory employer-funded "
    "insurance benefit, NOT a workers' compensation presumption. Benefits: $3,000 lump "
    "sum on diagnosis; 60% of monthly salary up to $5,000/month (paid); $1,500/month "
    "(volunteers); up to 36 months. PTSD must be diagnosed by a licensed mental health "
    "professional within 2 years of the traumatic event occurring on or after July 1, "
    "2024. Covered groups: peace officers, firefighters, emergency medical professionals, "
    "911 operators, probation officers, jail and correctional officers. Employer must "
    "provide insurance coverage. IAFF page does not list this statute."
)

for resp in ["firefighter", "law_enforcement", "emt_paramedic", "corrections"]:
    data.append(row(
        state="GA", state_name="Georgia",
        iaff_url="https://www.iaff.org/presumptive-health/ga/",
        condition_category="mental",
        condition_specific="Post-traumatic stress disorder (PTSD); employer-funded insurance benefit",
        responder_type=resp,
        presumption_exists=True,
        presumption_type="statute",
        rebuttable=None,
        statute_citation="O.C.G.A. §§ 45-25-1 et seq.",
        notes=GA_PTSD_NOTE,
    ))
    added.append(f"GA mental/{resp}")

# ── MAINE — § 328-D, LE cardiovascular and respiratory ───────────────────────
# PL 2023, c. 445. IAFF page does not list § 328-D.
ME_328D_NOTE = (
    "39-A M.R.S.A. § 328-D (PL 2023, c. 445). Active law enforcement officers holding "
    "current and valid certification from the Board of Trustees of the Maine Criminal "
    "Justice Academy. Minimum 2 years tenure required. Condition must have developed "
    "or injury occurred within 6 months of law enforcement activities or training/drill. "
    "Rebuttable by a preponderance of evidence. IAFF page does not list § 328-D."
)

for cond, cond_specific in [
    ("cardiovascular", "Cardiovascular injury or disease"),
    ("respiratory", "Pulmonary disease"),
]:
    data.append(row(
        state="ME", state_name="Maine",
        iaff_url="https://www.iaff.org/presumptive-health/me/",
        condition_category=cond,
        condition_specific=cond_specific,
        responder_type="law_enforcement",
        presumption_exists=True,
        presumption_type="statute",
        rebuttable=True,
        statute_citation="Me. Rev. Stat. Title 39-A, § 328-D",
        years_service_required=2,
        notes=ME_328D_NOTE,
    ))
    added.append(f"ME {cond}/law_enforcement (§ 328-D)")

# ── MARYLAND — § 9-503(b), LE cardiovascular ─────────────────────────────────
data.append(row(
    state="MD", state_name="Maryland",
    iaff_url="https://www.iaff.org/presumptive-health/md/",
    condition_category="cardiovascular",
    condition_specific="Heart disease, hypertension",
    responder_type="law_enforcement",
    presumption_exists=True,
    presumption_type="statute",
    rebuttable=True,
    statute_citation="Maryland Code, Labor and Employment § 9-503(b)",
    notes=(
        "Covers paid police officers statewide and deputy sheriffs of specific counties "
        "(Montgomery, Anne Arundel, Baltimore City, Allegany) and correctional officers "
        "of Montgomery and Prince George's counties. Heart disease and hypertension "
        "presumed occupationally related; rebuttable by competent evidence. County-specific "
        "deputies and corrections: also requires disability or death and condition worsening "
        "post-employment. IAFF page does not separately list § 9-503(b)."
    ),
))
added.append("MD cardiovascular/law_enforcement (§ 9-503(b))")

# ── NORTH CAROLINA — § 143-166.2(5), cardiovascular LODD ────────────────────
# Death benefit only — not a WC presumption for living first responders.
NC_LODD_NOTE = (
    "G.S. § 143-166.2(5). DEATH BENEFIT ONLY — myocardial infarction occurring while "
    "on duty or within 24 hours after participating in a training exercise or responding "
    "to an emergency situation is classified as a line-of-duty death for purposes of "
    "the State's death benefit program. This is NOT a workers' compensation presumption "
    "for living first responders — it provides no WC disability or medical benefits "
    "for a firefighter/officer who survives. No minimum service requirement. "
    "No rebuttal mechanism specified."
)

for resp in ["firefighter", "law_enforcement", "emt_paramedic"]:
    data.append(row(
        state="NC", state_name="North Carolina",
        iaff_url="https://www.iaff.org/presumptive-health/nc/",
        condition_category="cardiovascular",
        condition_specific="Myocardial infarction (on duty or within 24 hours of emergency response/training)",
        responder_type=resp,
        presumption_exists=True,
        presumption_type="statute",
        rebuttable=False,
        statute_citation="N.C. Gen. Stat. § 143-166.2(5)",
        notes=NC_LODD_NOTE,
    ))
    added.append(f"NC cardiovascular/{resp} (LODD only)")

# ── MISSISSIPPI — § 25-15-405, cardiovascular ────────────────────────────────
MS_CV_NOTE = (
    "Miss. Code Ann. § 25-15-405 (Mississippi First Responders Health and Safety Act, "
    "Section 3). Acute cardiovascular or stroke event (ischemic or hemorrhagic) "
    "developing within 24 hours of a work shift involving training or a stressful event "
    "is classified as a service-connected disease. 10-year minimum service requirement. "
    "Effective July 1, 2021. IAFF page does not list the cardiovascular provision."
)

for resp in ["firefighter", "law_enforcement"]:
    data.append(row(
        state="MS", state_name="Mississippi",
        iaff_url="https://www.iaff.org/presumptive-health/ms/",
        condition_category="cardiovascular",
        condition_specific="Acute cardiovascular event or stroke (ischemic or hemorrhagic) within 24 hours of training or stressful work event",
        responder_type=resp,
        presumption_exists=True,
        presumption_type="statute",
        rebuttable=True,
        statute_citation="Miss. Code Ann. § 25-15-405",
        years_service_required=10,
        notes=MS_CV_NOTE,
    ))
    added.append(f"MS cardiovascular/{resp}")

# ── IOWA — LE cancer, PORS track (TENTATIVE) ─────────────────────────────────
data.append(row(
    state="IA", state_name="Iowa",
    iaff_url="https://www.iaff.org/presumptive-health/ia/",
    condition_category="cancer",
    condition_specific="All cancer types (per § 97A.1(6) as amended by HF 969, eff. June 2025)",
    responder_type="law_enforcement",
    presumption_exists=True,
    presumption_type="statute",
    rebuttable=True,
    statute_citation="Iowa Code § 97A.1(6) (PORS — state peace officers)",
    notes=(
        "Iowa Public Officers' Retirement System (PORS) pension disability presumption "
        "for Iowa State Patrol, DCI, Narcotics Enforcement, State Fire Marshal, and "
        "Capitol Police officers. Pension-track disability presumption — NOT a workers' "
        "compensation presumption. HF 969 (eff. June 2025) expanded cancer definition "
        "from enumerated list to all cancer types. Coverage of heart/respiratory/infectious "
        "under PORS is unconfirmed — flagged for verification."
    ),
    needs_verification="Confirm PORS tracks for heart/respiratory/infectious disease under § 97A; "
                       "confirm HF 969 applies to PORS track same as MFPRSI track",
))
added.append("IA cancer/law_enforcement (PORS — TENTATIVE)")


# ── FIELD UPDATES (P2 items coded as row updates) ────────────────────────────

UT_15_CANCERS = (
    "bladder cancer, brain cancer, colorectal cancer, esophageal cancer, kidney cancer, "
    "leukemia, lung cancer, lymphoma, malignant melanoma, mesothelioma, oropharynx cancer, "
    "ovarian cancer, prostate cancer, testicular cancer, thyroid cancer "
    "(15 types; expanded from 4 by HB 65, signed March 25, 2025, eff. January 1, 2026)"
)

UT_NEW_NOTES = (
    "HB 65 (signed March 25, 2025, effective January 1, 2026) expanded cancer list from "
    "4 types (pharynx, esophagus, lung, mesothelioma) to 15 types. 8-year minimum service "
    "required. Annual physical examinations required during employment. Biennial physicals "
    "and Rocky Mountain Center screenings required starting at 7 years of service (effective "
    "July 1, 2026). Tobacco exclusion: no tobacco or cannabis use for 8 years preceding "
    "report of condition (cannabis added alongside tobacco for respiratory tract cancers by "
    "HB 65). Covers paid and volunteer firefighters per 67-20-2(5)(b)(ii). "
    "IAFF page has not been updated to reflect the 2026 expansion."
)

VA_THROAT_FULL = (
    "throat cancer (pharynx, larynx, adenoid, tonsil, esophagus, trachea, nasopharynx, "
    "oropharynx, hypopharynx — definition clarified by cc. 392, 404, eff. July 1, 2025)"
)

for r in data:
    # UT cancer: update both firefighter and firefighter_volunteer to 15-type list
    if r["state"] == "UT" and r["condition_category"] == "cancer":
        r["condition_specific"] = UT_15_CANCERS
        r["notes"] = UT_NEW_NOTES
        updated.append(f"UT cancer/{r['responder_type']}: expanded to 15-type list")

    # VA cancer: update volunteer and LE rows to include full throat cancer definition
    if r["state"] == "VA" and r["condition_category"] == "cancer" and r["responder_type"] in ["firefighter_volunteer", "law_enforcement"]:
        if "throat" in r.get("condition_specific", "") and "pharynx, larynx" not in r.get("condition_specific", ""):
            old_specific = r["condition_specific"]
            r["condition_specific"] = old_specific.replace("throat", VA_THROAT_FULL)
            updated.append(f"VA cancer/{r['responder_type']}: throat cancer definition expanded")


# ── Report ────────────────────────────────────────────────────────────────────
print(f"\n{'='*60}")
print(f"P2 CORRECTIONS: {len(added)} rows added, {len(updated)} rows updated")
print(f"{'='*60}")
print(f"\nNew rows ({len(added)}):")
for a in added:
    print(f"  + {a}")
print(f"\nField updates ({len(updated)}):")
for u in updated:
    print(f"  ~ {u}")

print(f"\nRow count: {original_len} -> {len(data)} (+{len(data) - original_len})")

with open(JSON_PATH, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"Written to {JSON_PATH}")
