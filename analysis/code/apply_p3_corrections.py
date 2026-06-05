#!/usr/bin/env python3
"""
P3 Corrections — June 2026
Applies Priority 3 corrections from docs/admin/corrections-inventory.md
plus the schema expansion adding pension / employer_benefit / lodd_only
presumption_type values for non-WC benefit states.

Run from project root:
    python3 analysis/code/apply_p3_corrections.py

Writes corrected JSON in place. Review diff before committing.
"""

import json
import copy
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
    if text in existing:
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


# ── PART 1: Schema expansion — retype non-WC benefit rows ─────────────────────

NON_WC_NOTE_AL = (
    "NOTE: Alabama's system operates separately from workers' compensation. "
    "§§ 11-43-144 and 36-30-40 create employer disability and death benefits, "
    "not a WC presumption. First responders with occupational disease must pursue "
    "these employer-benefit tracks, not a standard WC claim."
)

NON_WC_NOTE_AR = (
    "NOTE: Arkansas has no workers' compensation presumption for first responder "
    "occupational disease. § 21-5-705 is a State Claims Commission death benefit; "
    "§§ 24-4-511 and 24-10-607 are pension disability retirement benefits through "
    "APERS and LOPFI respectively. None shifts the burden of proof in WC proceedings."
)

NON_WC_NOTE_GA = (
    "NOTE: Georgia has no workers' compensation presumption for this condition. "
    "Cancer coverage (§ 25-3-23) is an employer insurance mandate; cardiovascular "
    "coverage (§ 45-9-85) is the State Indemnification Fund lump-sum disability/death "
    "benefit; PTSD coverage (§§ 45-25-1 et seq.) is a mandatory employer-funded "
    "insurance benefit. None is a WC presumption shifting the burden of proof."
)

NON_WC_NOTE_IN = (
    "NOTE: Indiana's WC system (IC 22-3-7-2) explicitly excludes municipal firefighters "
    "and police officers who are members of pension funds. These benefits are pension "
    "disability presumptions only, not workers' compensation presumptions."
)

NON_WC_NOTE_KS = (
    "NOTE: This benefit runs through the Kansas Police and Firemen's Retirement System "
    "(KP&F / KPERS pension track), not the workers' compensation system. "
    "The presumption applies to disability retirement claims, not WC claims."
)

for row in data:
    st = row["state"]
    cond = row["condition_category"]

    if st == "AL":
        patch(row, "presumption_type", "statute", "employer_benefit",
              "AL system is employer benefit, not WC")
        prepend_note(row, NON_WC_NOTE_AL, "AL non-WC clarification")

    elif st == "AR":
        patch(row, "presumption_type", "statute", "employer_benefit",
              "AR system is employer death benefit + pension, not WC")
        prepend_note(row, NON_WC_NOTE_AR, "AR non-WC clarification")

    elif st == "GA":
        patch(row, "presumption_type", "statute", "employer_benefit",
              "GA system is employer insurance mandate / State Indemnification Fund, not WC")
        prepend_note(row, NON_WC_NOTE_GA, "GA non-WC clarification")

    elif st == "IN":
        patch(row, "presumption_type", "statute", "pension",
              "IN system is pension disability presumption (IC 22-3-7-2 excludes from WC)")
        prepend_note(row, NON_WC_NOTE_IN, "IN non-WC clarification")

    elif st == "KS":
        patch(row, "presumption_type", "statute", "pension",
              "KS benefit is KP&F pension track, not WC")
        prepend_note(row, NON_WC_NOTE_KS, "KS non-WC clarification")

    elif st == "KY" and cond == "cancer":
        patch(row, "presumption_type", "statute", "lodd_only",
              "KY cancer benefit is LODD death benefit only — statute explicitly not a WC presumption")

    elif st == "NC" and cond == "cardiovascular":
        patch(row, "presumption_type", "statute", "lodd_only",
              "NC § 143-166.2(5) is LODD death benefit only, not a living-claimant WC presumption")

    elif st == "IA" and cond == "cancer" and row.get("responder_type") == "law_enforcement":
        patch(row, "presumption_type", "statute", "pension",
              "IA cancer/LE is PORS pension disability presumption, not WC")
        prepend_note(
            row,
            "NOTE: Iowa's cancer coverage for law enforcement runs through the Public Officers' "
            "Retirement System (PORS) as a pension disability presumption, not the WC system.",
            "IA LE cancer non-WC clarification"
        )


# ── PART 2: P3 field quality — citations and notes ────────────────────────────

for row in data:
    st = row["state"]
    cond = row["condition_category"]
    resp = row["responder_type"]

    # ── CA mental/firefighter: sunset date discrepancy note ───────────────────
    if st == "CA" and cond == "mental" and resp == "firefighter":
        append_note(
            row,
            "Sunset discrepancy: leginfo.legislature.ca.gov shows § 31720.91 repealing "
            "January 1, 2029; IAFF page shows 2032. Verify against AB 2770 (2024) enrolled "
            "text before citing either date.",
            "CA § 31720.91 sunset discrepancy flagged"
        )
        row["needs_verification"] = "Verify § 31720.91 sunset date: leginfo shows 2029, IAFF shows 2032"
        changes.append("[CA] mental/firefighter: needs_verification set for sunset discrepancy")

    # ── CO cardiovascular: strengthen non-WC note ─────────────────────────────
    if st == "CO" and cond == "cardiovascular":
        append_note(
            row,
            "C.R.S. §§ 29-5-301 and 29-5-302 are an employer benefit program under Title 29 "
            "(Local Government), NOT a workers' compensation presumption under Title 8. "
            "Benefits are paid directly by the employer, not through the WC system.",
            "CO cardiovascular non-WC benefit clarification"
        )

    # ── HI cancer/firefighter: mechanism clarification ────────────────────────
    if st == "HI" and cond == "cancer" and resp == "firefighter":
        append_note(
            row,
            "IMPORTANT: § 386-21.9 does not itself create a presumption of compensability. "
            "It applies only after a claim has already been accepted as compensable and enhances "
            "the medical fee schedule to 110%–150% of Medicare RBRVS. There is no independent "
            "presumption of WC compensability for firefighter cancer under Hawaii law; standard "
            "individual proof of work-relatedness is still required.",
            "HI § 386-21.9 is fee enhancement, not compensability presumption"
        )

    # ── NC cancer (§ 143-166.2 row): add oral cavity + pharynx ───────────────
    if (st == "NC" and cond == "cancer" and resp == "firefighter"
            and row.get("statute_citation", "").startswith("N.C. Gen. Stat. § 143-166.2(6)")):
        patch(
            row, "condition_specific",
            "mesothelioma, testicular cancer, intestinal cancer, esophageal cancer",
            "mesothelioma, testicular cancer, cancer of the small intestine, esophageal cancer, "
            "oral cavity cancer, pharynx cancer",
            "SL 2021-180 added oral cavity and pharynx cancers (4 → 6 types)"
        )

    # ── NV mental: reduced evidentiary gateway, not burden-shifting ───────────
    if st == "NV" and cond == "mental":
        existing = row.get("notes") or ""
        gateway_note = (
            "IMPORTANT: NRS 616C.180 is NOT a traditional burden-shifting presumption. "
            "The claimant still bears the burden of proving by clear and convincing medical "
            "and psychiatric evidence that the PTSD is work-related. This statute provides a "
            "reduced evidentiary threshold, not a shift in the burden of proof."
        )
        if "NOT a traditional" not in existing:
            row["notes"] = (gateway_note + " " + existing).strip()
            changes.append(f"[NV] mental/{resp}: gateway clarification prepended")

    # ── VT statute citations: add (11) subdivision ────────────────────────────
    if st == "VT":
        cite = row.get("statute_citation", "")
        if cite == "21 V.S.A. § 601(1)":
            patch(row, "statute_citation",
                  "21 V.S.A. § 601(1)", "21 V.S.A. § 601(11)(A)-(B)",
                  "VT cardiovascular: add (11) subdivision per timeline")
        elif cite == "21 V.S.A. § 601(3)-(6)":
            if cond in ("respiratory", "infectious"):
                patch(row, "statute_citation",
                      "21 V.S.A. § 601(3)-(6)", "21 V.S.A. § 601(11)(H)",
                      "VT respiratory/infectious: add (11) subdivision per timeline")
        elif cite == "21 V.S.A. § 601(E)":
            patch(row, "statute_citation",
                  "21 V.S.A. § 601(E)", "21 V.S.A. § 601(11)(E)-(F)",
                  "VT cancer: add (11) subdivision per timeline")
        elif cite == "21 V.S.A. § 601(I)":
            patch(row, "statute_citation",
                  "21 V.S.A. § 601(I)", "21 V.S.A. § 601(11)(I)",
                  "VT mental: add (11) subdivision per timeline")

    # ── WV mental: remove sunset, mark permanent ──────────────────────────────
    if st == "WV" and cond == "mental":
        replace_in_note(
            row,
            "July 1, 2026",
            "no expiration date (permanent)",
            "HB 2797 (eff. July 11, 2025) removed the sunset clause — coverage is now permanent"
        )
        append_note(
            row,
            "Sunset clause removed by HB 2797 (Chapter 243, Acts 2025, effective July 11, 2025). "
            "Coverage is now permanent — no legislative renewal required.",
            "WV PTSD sunset removed"
        )


# ── PART 3: New rows — KS bloodborne pathogen (infectious disease) ─────────────

ks_infectious_ff = {
    "condition_category": "infectious",
    "condition_specific": "bloodborne pathogens (as defined by K.A.R. 28-71 regulations "
                          "cross-referenced in KSA 65-128, including HIV, hepatitis B, hepatitis C, "
                          "and other pathogens transmitted through blood or body fluids)",
    "responder_type": "firefighter",
    "presumption_type": "pension",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "K.S.A. 74-4952 (as amended by L. 2019, ch. 50 / HB 2031)",
    "years_service_required": 5,
    "pre_employment_exam_required": None,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": None,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": (
        "NOTE: This benefit runs through the Kansas Police and Firemen's Retirement System "
        "(KP&F / KPERS pension track), not the workers' compensation system. "
        "HB 2031 (L. 2019, ch. 50) added bloodborne pathogens to K.S.A. 74-4952 effective "
        "July 1, 2019. Pathogen definition references K.A.R. 28-71 bloodborne pathogen "
        "regulations. Requires 5+ years of credited KPERS service. Rebuttable by "
        "preponderance of evidence."
    ),
    "state": "KS",
    "state_name": "Kansas",
    "iaff_url": "https://www.iaff.org/presumptive-health/ks/",
    "data_retrieved": "2026-06-04",
    "needs_verification": None,
}

ks_infectious_le = dict(ks_infectious_ff)
ks_infectious_le["responder_type"] = "law_enforcement"
ks_infectious_le["notes"] = (
    "NOTE: This benefit runs through the Kansas Police and Firemen's Retirement System "
    "(KP&F / KPERS pension track), not the workers' compensation system. "
    "Same statute covers 'policeman or fire fighter' (K.S.A. 74-4952). "
    "HB 2031 (L. 2019, ch. 50) added bloodborne pathogens effective July 1, 2019. "
    "Requires 5+ years of credited KPERS service."
)

data.append(ks_infectious_ff)
data.append(ks_infectious_le)
changes.append("[KS] infectious/firefighter: NEW ROW — bloodborne pathogen (HB 2031, pension track)")
changes.append("[KS] infectious/law_enforcement: NEW ROW — bloodborne pathogen (HB 2031, pension track)")


# ── Report ─────────────────────────────────────────────────────────────────────

print(f"\n{'='*60}")
print(f"P3 CORRECTIONS APPLIED: {len(changes)} changes")
print(f"{'='*60}")
for c in changes:
    print(f"  {c}")

print(f"\nRow count: {original_count} → {len(data)} ({len(data) - original_count} new rows)")

# Write output
with open(JSON_PATH, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"\nWritten to {JSON_PATH}")
print("Review with: git diff website/shiny-app/data/presumptive_laws.json")
