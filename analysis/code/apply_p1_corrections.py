#!/usr/bin/env python3
"""
P1 Corrections — June 2026
Applies Priority 1 corrections identified in docs/admin/corrections-inventory.md.
Source of truth: 50-state timeline research (docs/lit/state_histories/in-progress/).

Run from project root:
    python3 analysis/code/apply_p1_corrections.py

Writes corrected JSON in place. Review diff before committing.
"""

import json
import copy
from pathlib import Path

JSON_PATH = Path("website/shiny-app/data/presumptive_laws.json")

with open(JSON_PATH) as f:
    data = json.load(f)

original = copy.deepcopy(data)
changes = []


def patch(row, field, old_val, new_val, note):
    if row.get(field) != old_val:
        print(f"  WARN: expected {field}={old_val!r}, got {row.get(field)!r} — skipping")
        return False
    row[field] = new_val
    changes.append(f"[{row['state']}] {row['condition_category']}/{row['responder_type']}: {field} {old_val!r} -> {new_val!r}  # {note}")
    return True


def patch_contains(row, field, old_substr, new_val, note):
    current = row.get(field, "")
    if old_substr not in str(current):
        print(f"  WARN: expected '{old_substr}' in {field}, got {current!r} — skipping")
        return False
    row[field] = new_val
    changes.append(f"[{row['state']}] {row['condition_category']}/{row['responder_type']}: {field} updated  # {note}")
    return True


for row in data:
    st = row["state"]
    cond = row["condition_category"]
    resp = row["responder_type"]

    # ── AZ PTSD: law never took effect (FDA rejected MDMA-AT, Aug 2024) ──────
    if st == "AZ" and cond == "mental":
        patch(row, "presumption_exists", True, False,
              "§ 23-972 conditioned on FDA approval of MDMA-AT; FDA rejected Aug 9, 2024 — statute never operative")
        patch(row, "presumption_type", "statute", "none",
              "statute void — conditional enactment failed")
        row["notes"] = (
            "NOTE: § 23-972 was enacted conditional on FDA approval of midomafetamine (MDMA-AT) by "
            "December 31, 2025. The FDA rejected MDMA-AT on August 9, 2024. The statute therefore "
            "never took legal effect and provides no coverage. As of June 2026, Arizona has no PTSD "
            "workers' compensation presumption for first responders. "
            + row["notes"]
        )
        changes.append(f"[AZ] mental/{resp}: notes prepended with void-statute explanation")

    # ── AZ cardiovascular: wrong statute citation ─────────────────────────────
    if st == "AZ" and cond == "cardiovascular":
        if resp == "firefighter":
            patch(row, "statute_citation",
                  "Ariz. Rev. Stat. § 23-1043.05",
                  "A.R.S. § 23-1105",
                  "IAFF had wrong citation; correct statute is § 23-1105 (HB 2410, 2017)")
        if resp == "firefighter_volunteer":
            patch(row, "statute_citation",
                  "Ariz. Rev. Stat. § 23-1043.05(D)",
                  "A.R.S. § 23-1105",
                  "IAFF had wrong citation; correct statute is § 23-1105 (HB 2410, 2017)")

    # ── IA cancer: HF 969 (June 2025) expanded from 14 types to ALL cancers ──
    if st == "IA" and cond == "cancer" and resp == "firefighter":
        patch(row, "condition_specific",
              row["condition_specific"],
              "All cancer types (any group of diseases involving abnormal cell growth with the "
              "potential to invade or spread to other parts of the body, per § 411.1(6) as amended "
              "by HF 969, eff. June 6, 2025; previously limited to 14 enumerated types)",
              "HF 969 (signed June 6, 2025) expanded from 14-type enumerated list to all cancer types")
        row["notes"] = row["notes"] + (
            " HF 969 (signed June 6, 2025, effective June 6, 2025) amended § 411.1(6) to expand "
            "the definition of 'cancer' from 14 enumerated types to all cancer types across all "
            "three Iowa retirement systems (MFPRSI, PORS, IPERS)."
        )
        changes.append(f"[IA] cancer/firefighter: notes updated for HF 969 expansion")

    # ── MS cancer: wrong statute citation (Title 45 vs Title 25) ─────────────
    if st == "MS" and cond == "cancer":
        patch_contains(row, "statute_citation",
                       "Mississippi First Responders Health and Safety Act",
                       "Miss. Code Ann. §§ 25-15-401 through 25-15-411",
                       "IAFF cited Title 45 (Death Benefits Trust Fund); correct title is 25, ch. 15, art. 11")

    # ── NH cardiovascular: age cap raised from 65 to 70 (Acts of 2021, Ch. 83:1) ──
    if st == "NH" and cond == "cardiovascular" and resp == "firefighter":
        patch_contains(row, "notes",
                       "Age 65 cutoff: benefits end one month after firefighter's 65th birthday.",
                       row["notes"].replace(
                           "Age 65 cutoff: benefits end one month after firefighter's 65th birthday.",
                           "Age 70 cutoff: benefits end one month after firefighter's 70th birthday "
                           "(raised from 65 to 70 by Acts of 2021, Ch. 83:1, eff. August 17, 2021; "
                           "IAFF page still shows outdated age 65)."
                       ),
                       "2021 amendment raised age cutoff from 65 to 70")

    # ── NM cancer: HB 128 (May 2026) expanded from 11 to 21 types, uniform 5-yr service ──
    if st == "NM" and cond == "cancer" and resp == "firefighter":
        new_condition_specific = (
            "brain cancer, bladder cancer, kidney cancer, colorectal cancer, colon cancer, "
            "non-Hodgkin's lymphoma, leukemia, ureter cancer, testicular cancer, breast cancer, "
            "esophageal cancer, multiple myeloma, cervical cancer, lung cancer, malignant melanoma, "
            "mesothelioma, ovarian cancer, prostate cancer, skin cancer, stomach cancer, thyroid cancer "
            "(21 types; expanded from 11 by Laws 2026, Ch. 36 / HB 128, eff. approx. May 20, 2026)"
        )
        patch(row, "condition_specific", row["condition_specific"], new_condition_specific,
              "HB 128 (2026) expanded from 11 to 21 cancer types")
        row["notes"] = (
            "Laws 2026, Ch. 36 (HB 128, signed March 5, 2026, effective approximately May 20, 2026) "
            "expanded the cancer list from 11 to 21 types and standardized the minimum service period "
            "to 5 years for all types (previously 5–15 years per type). Also removed age caps for "
            "testicular and breast cancer. "
            + "Applies only to full-time non-volunteer firefighters employed by state or local government "
            "who have taken the firefighter oath. Condition must not have been revealed during "
            "pre-employment or subsequent OSHA medical screening. Rebuttable by preponderance of evidence."
        )
        changes.append(f"[NM] cancer/firefighter: notes rewritten for HB 128 (2026) expansion")

    # ── OH cancer: 20-year lookback is wrong; correct is 15 years (HB 27, 2017) ──
    if st == "OH" and cond == "cancer" and resp == "firefighter":
        patch(row, "post_termination_months", 240, 180,
              "HB 27 (eff. Sep 29, 2017) sets 15-year lookback (180 mo), not 20 years (240 mo)")
        row["notes"] = row["notes"] + (
            " Lookback period: presumption does not apply if more than 15 years (180 months) have "
            "passed since last assigned to hazardous duty (per HB 27, eff. September 29, 2017; "
            "prior data incorrectly showed 20 years)."
        )
        changes.append(f"[OH] cancer/firefighter: notes updated with corrected 15-year lookback")

    # ── SC cardiovascular: stroke added by Act 132 (signed May 15, 2026) ─────
    if st == "SC" and cond == "cardiovascular" and resp == "firefighter":
        patch(row, "condition_specific",
              "heart disease",
              "heart disease, stroke",
              "Act No. 132 of 2026 (H3163, signed May 15, 2026) added stroke to § 42-11-30(A)")
        row["notes"] = row["notes"] + (
            " Stroke added by Act No. 132 of 2026 (H3163, signed and effective May 15, 2026), "
            "amending § 42-11-30(A). IAFF page has not been updated to reflect this addition."
        )
        changes.append(f"[SC] cardiovascular/firefighter: notes updated for stroke addition")

    # ── IL mental: 40 ILCS 5/4-112 is pension procedure, not WC presumption ──
    if st == "IL" and cond == "mental" and resp == "firefighter":
        patch(row, "presumption_exists", True, False,
              "40 ILCS 5/4-112 is a pension re-examination procedure rule, not a WC presumption")
        row["notes"] = (
            "Illinois has no PTSD workers' compensation presumption. HB3529 (103rd GA, 2023) "
            "proposed adding PTSD to the WC presumption list but was not enacted. "
            "40 ILCS 5/4-112 — the statute cited here — governs frequency of re-examinations and "
            "provides anti-retaliation protections for firefighters already receiving disability "
            "pension benefits; it does not create a presumption that PTSD is occupationally related "
            "and does not shift any burden of proof. Illinois first responders with PTSD must meet "
            "the general WC standard ('sudden, severe emotional shock traceable to a definite time, "
            "place and cause') — a significantly higher bar than a presumption."
        )
        changes.append(f"[IL] mental/firefighter: notes rewritten; no WC presumption exists in IL")


# ── Report ────────────────────────────────────────────────────────────────────
print(f"\n{'='*60}")
print(f"P1 CORRECTIONS APPLIED: {len(changes)} changes")
print(f"{'='*60}")
for c in changes:
    print(f"  {c}")

# Verify row count unchanged
assert len(data) == len(original), f"Row count changed: {len(original)} -> {len(data)}"
print(f"\nRow count: {len(data)} (unchanged)")

# Write output
with open(JSON_PATH, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"\nWritten to {JSON_PATH}")
print("Review with: git diff website/shiny-app/data/presumptive_laws.json")
