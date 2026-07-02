#!/usr/bin/env python3
"""
P5 Corrections — July 2026
Fixes a completeness gap in Texas's law_enforcement coverage that the P4 pass
missed: the pre-pipeline TX data (retrieved 2026-05-23) never had
law_enforcement rows for cardiovascular, respiratory, or infectious/TB, or
the smallpox provision — not "presumption_exists: false", just absent rows
entirely. TX_timeline.md (2026-07-02 research) confirms peace officers ARE
covered under Gov't Code §§ 607.053, 607.054, and 607.056 via the § 607.052
applicability section ("detention officers, custodial officers, firefighters,
peace officers, and EMTs"). Only cancer (§ 607.055) excludes peace officers,
which the live data already reflected correctly by omission.

Caught by Peter reviewing the live map after the P4 patch — P4 checked for
confirmed-wrong content but didn't audit for confirmed-missing rows.

Run from project root:
    python3 analysis/code/apply_p5_corrections.py
"""

import json
from pathlib import Path

JSON_PATH = Path("website/shiny-app/data/presumptive_laws.json")

with open(JSON_PATH) as f:
    data = json.load(f)

original_count = len(data)
changes = []

GAP_NOTE = (
    " NOTE (2026-07-02 correction): this row was missing entirely from the "
    "original pre-pipeline data despite § 607.052/this section explicitly "
    "covering peace officers — added after the gap was caught on the live "
    "dashboard."
)

tx_le_respiratory = {
    "condition_category": "respiratory",
    "condition_specific": "any disease or illness of the lungs or respiratory tract with a "
                          "statistically positive correlation with peace officer service "
                          "(excluding tuberculosis, which is covered separately)",
    "responder_type": "law_enforcement",
    "presumption_type": "statute",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "Tex. Gov't Code § 607.054",
    "years_service_required": 5,
    "pre_employment_exam_required": True,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": True,
    "filing_deadline_notes": None,
    "tobacco_exclusion": True,
    "notes": ("Same terms as the firefighter/EMT respiratory row under § 607.054. Covers "
              "peace officers under Article 2.12, Code of Criminal Procedure, employed by "
              "a political subdivision (§ 607.052 applicability). Tobacco exclusion and "
              "discovery-during-employment requirement apply." + GAP_NOTE),
    "state": "TX",
    "state_name": "Texas",
    "iaff_url": "https://www.iaff.org/presumptive-health/tx/",
    "data_retrieved": "2026-07-02",
    "needs_verification": None,
}

tx_le_tb = {
    "condition_category": "infectious",
    "condition_specific": "tuberculosis",
    "responder_type": "law_enforcement",
    "presumption_type": "statute",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "Tex. Gov't Code § 607.054",
    "years_service_required": 5,
    "pre_employment_exam_required": True,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": True,
    "filing_deadline_notes": None,
    "tobacco_exclusion": True,
    "notes": ("§ 607.054 covers TB (infectious) and other lung/respiratory diseases "
              "(respiratory) in one statutory provision; split into two rows per schema "
              "rules, matching the firefighter/EMT TB row. Covers peace officers under "
              "Article 2.12, Code of Criminal Procedure (§ 607.052 applicability). Rebuttal "
              "per § 607.058 requires preponderance of evidence that a non-service cause "
              "was a substantial factor. Tobacco exclusion applies; disease must be "
              "discovered during employment." + GAP_NOTE),
    "state": "TX",
    "state_name": "Texas",
    "iaff_url": "https://www.iaff.org/presumptive-health/tx/",
    "data_retrieved": "2026-07-02",
    "needs_verification": None,
}

tx_le_cardio = {
    "condition_category": "cardiovascular",
    "condition_specific": "acute myocardial infarction, stroke",
    "responder_type": "law_enforcement",
    "presumption_type": "statute",
    "presumption_exists": True,
    "rebuttable": True,
    "statute_citation": "Tex. Gov't Code § 607.056",
    "years_service_required": 5,
    "pre_employment_exam_required": True,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": True,
    "filing_deadline_notes": None,
    "tobacco_exclusion": True,
    "notes": ("Requires that while on duty, the peace officer was engaged in nonroutine "
              "stressful or strenuous physical activity (pursuit, arrest, hazmat, emergency "
              "response, or nonroutine training exercise) AND the AMI/stroke occurred "
              "during that activity — does not include clerical, administrative, or "
              "nonmanual activities. Same terms as the firefighter/EMT row under § 607.056. "
              "Covers peace officers under Article 2.12, Code of Criminal Procedure "
              "(§ 607.052 applicability). Tobacco exclusion applies." + GAP_NOTE),
    "state": "TX",
    "state_name": "Texas",
    "iaff_url": "https://www.iaff.org/presumptive-health/tx/",
    "data_retrieved": "2026-07-02",
    "needs_verification": None,
}

tx_le_smallpox = {
    "condition_category": "other",
    "condition_specific": "smallpox; disability or death from preventative immunization "
                          "against smallpox or other disease",
    "responder_type": "law_enforcement",
    "presumption_type": "statute",
    "presumption_exists": True,
    "rebuttable": False,
    "statute_citation": "Tex. Gov't Code § 607.053",
    "years_service_required": 5,
    "pre_employment_exam_required": True,
    "post_termination_months": None,
    "post_termination_formula": None,
    "discovery_during_employment_required": True,
    "filing_deadline_notes": None,
    "tobacco_exclusion": None,
    "notes": ("Cannot be rebutted by evidence that the immunization was not required by "
              "employer, not required by law, or received voluntarily. Same terms as the "
              "firefighter/EMT row under § 607.053. Covers peace officers under Article "
              "2.12, Code of Criminal Procedure (§ 607.052 applicability). Disease must be "
              "discovered during employment per § 607.052(a)(3)." + GAP_NOTE),
    "state": "TX",
    "state_name": "Texas",
    "iaff_url": "https://www.iaff.org/presumptive-health/tx/",
    "data_retrieved": "2026-07-02",
    "needs_verification": None,
}

for row in [tx_le_respiratory, tx_le_tb, tx_le_cardio, tx_le_smallpox]:
    data.append(row)
    changes.append(f"[TX] {row['condition_category']}/law_enforcement: NEW ROW — "
                   f"{row['statute_citation']} (completeness gap fix)")

print(f"\n{'='*60}")
print(f"P5 CORRECTIONS APPLIED: {len(changes)} changes")
print(f"{'='*60}")
for c in changes:
    print(f"  {c}")

print(f"\nRow count: {original_count} -> {len(data)} ({len(data) - original_count} new rows)")

with open(JSON_PATH, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"\nWritten to {JSON_PATH}")
print("Review with: git diff website/shiny-app/data/presumptive_laws.json")
