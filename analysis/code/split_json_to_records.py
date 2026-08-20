#!/usr/bin/env python3
"""
Project: PROJ_presumptive_laws
Script:  split_json_to_records.py
Created: 2026-08-20
Purpose: One-shot bootstrap of the new pipeline's source of truth.

    Splits the QC-gated dashboard JSON (website/data/presumptive_laws.json, 479 rows,
    all 50 states verified 97-100/100 on 2026-08-07) into one committed record file
    per jurisdiction at data/raw/state_records/XX.json.

    Those record files become the pipeline's INPUT. From here on:

        data/raw/state_records/*.json  ->  4_combine_records.r  ->  v2.rds/.csv
                                       ->  5_export_json.r      ->  website JSON x2

    Why this exists: the dashboard JSON had been hand-patched by eight sequential
    one-off scripts (apply_p1_corrections.py .. apply_p8_notes_rewrite.py) applied
    directly to the JSON, bypassing the R pipeline. Nothing could regenerate it. The
    old pipeline could not simply be re-run because its source was the IAFF scrape,
    which P8 formally demoted from ground truth.

    This script is kept after running as provenance for where the record files came
    from. It is not part of the recurring pipeline and should not be re-run: doing so
    would overwrite research-maintained records with whatever is in the dashboard JSON.

Usage:  python3 analysis/code/split_json_to_records.py [--dry-run]
"""

import argparse
import json
import os
import sys
from collections import Counter, defaultdict

# ── Paths ─────────────────────────────────────────────────────────────────────

HERE      = os.path.dirname(os.path.abspath(__file__))
PROJ      = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC_JSON  = os.path.join(PROJ, "website", "data", "presumptive_laws.json")
OUT_DIR   = os.path.join(PROJ, "data", "raw", "state_records")

# ── Canonical schema ──────────────────────────────────────────────────────────
# Field order below is the documented record order (see data/codebook.md). Emitting
# keys in a fixed order keeps per-state file diffs readable when a review changes one
# field.

FIELD_ORDER = [
    # identity
    "state", "state_name",
    # classification
    "condition_category", "condition_specific", "responder_type",
    # status
    "presumption_type", "presumption_exists", "rebuttable",
    # eligibility mechanics
    "years_service_required", "pre_employment_exam_required",
    "post_termination_months", "post_termination_formula",
    "discovery_during_employment_required", "filing_deadline_notes",
    "tobacco_exclusion",
    # authority
    "statute_citation", "source_url",
    # annotation / provenance
    "notes", "needs_verification", "iaff_url", "data_retrieved",
]

# Domain orders. These match app.R (lines 29-92), which is the authoritative schema
# for what the dashboard can render. Sorting on domain order rather than
# alphabetically reproduces the arrange() in 4_combine_records.r, so a round trip
# through the pipeline is order-stable.
CONDITION_ORDER = ["cancer", "cardiovascular", "respiratory", "infectious", "mental", "other"]
RESPONDER_ORDER = ["firefighter", "firefighter_volunteer", "emt_paramedic",
                   "law_enforcement", "corrections"]
PTYPE_DOMAIN    = ["statute", "EO", "pension", "employer_benefit", "lodd_only",
                   "expired", "none"]

# ── Known data quirks resolved at bootstrap ───────────────────────────────────
# needs_verification is free text everywhere except exactly one row, which carries a
# bare boolean `true`. A column that is character-or-null in 478 rows and logical in
# one cannot survive a data-frame round trip intact. Its meaning is recorded in
# docs/lit/state_histories/registry.md (NY entry, 2026-08-07 QC): the respiratory
# revival is inferred rather than directly annotated. Normalize to that text.
#
# This is the ONE intentional content change in the pipeline rebuild. The verification
# step expects exactly this diff and nothing else.

NY_RESPIRATORY_FLAG = (
    "GML/RSS respiratory revival via § 480 is inferred rather than directly "
    "annotated in the current statutory text — lower confidence than the cancer "
    "(§ 363-d) revival, which is confirmed. Keep flagged pending an independent "
    "read of the enacted amendment."
)


def normalize_needs_verification(rec):
    """Return needs_verification as str or None, never bool."""
    v = rec.get("needs_verification")
    if v is None:
        return None
    if isinstance(v, bool):
        if not v:
            return None
        if (rec.get("state") == "NY" and rec.get("condition_category") == "respiratory"):
            return NY_RESPIRATORY_FLAG
        # Any other bare boolean is unexpected -- fail rather than invent meaning.
        raise SystemExit(
            f"ERROR: unexpected boolean needs_verification on "
            f"{rec.get('state')}/{rec.get('condition_category')}/"
            f"{rec.get('responder_type')}. Bare booleans carry no reviewable meaning; "
            f"give this row explanatory text in the source data first."
        )
    s = str(v).strip()
    return s or None


def sort_key(rec):
    def idx(order, val):
        try:
            return order.index(val)
        except ValueError:
            return len(order)          # unknown values sort last, loudly visible
    return (
        idx(CONDITION_ORDER, rec.get("condition_category")),
        idx(RESPONDER_ORDER, rec.get("responder_type")),
        str(rec.get("statute_citation") or ""),
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true",
                    help="validate and report, write nothing")
    args = ap.parse_args()

    with open(SRC_JSON, encoding="utf-8") as f:
        rows = json.load(f)
    print(f"Loaded {len(rows)} rows from {os.path.relpath(SRC_JSON, PROJ)}")

    # ── Schema check ──────────────────────────────────────────────────────────
    seen_fields = set()
    for r in rows:
        seen_fields |= set(r.keys())
    unexpected = sorted(seen_fields - set(FIELD_ORDER))
    absent     = sorted(set(FIELD_ORDER) - seen_fields)
    if unexpected:
        sys.exit(f"ERROR: fields present in data but not in FIELD_ORDER: {unexpected}")
    if absent:
        print(f"  WARNING: fields in FIELD_ORDER absent from data: {absent}")

    # ── Domain check ──────────────────────────────────────────────────────────
    bad = []
    for i, r in enumerate(rows):
        if r.get("condition_category") not in CONDITION_ORDER:
            bad.append((i, "condition_category", r.get("condition_category")))
        if r.get("responder_type") not in RESPONDER_ORDER:
            bad.append((i, "responder_type", r.get("responder_type")))
        if r.get("presumption_type") not in PTYPE_DOMAIN:
            bad.append((i, "presumption_type", r.get("presumption_type")))
    if bad:
        for i, fld, val in bad[:20]:
            print(f"  row {i}: {fld} = {val!r}")
        sys.exit(f"ERROR: {len(bad)} out-of-domain values. Fix the data or widen the domain.")
    print("  Domains OK (condition_category, responder_type, presumption_type)")

    # ── Uniqueness ────────────────────────────────────────────────────────────
    # The natural key needs BOTH statute_citation and condition_specific. Two
    # legitimate near-duplicates exist in the data, for different reasons:
    #
    #   LA / mental / law_enforcement -- one row per statute, same covered condition
    #       (La. R.S. 33:2581.2 and La. R.S. 40:1374). Distinguished by citation.
    #   WV / cancer / firefighter     -- one statute (W. Va. Code 23-4-1(h)), two
    #       cancer groups: leukemia/lymphoma/myeloma (permanent) and bladder/
    #       mesothelioma/testicular (added 2024, sunsets July 1 2027). Distinguished
    #       by condition_specific -- splitting them is what makes the sunset
    #       representable at all.
    #
    # Neither is an error. Do not collapse them.
    KEY = ("state", "condition_category", "responder_type",
           "condition_specific", "statute_citation")
    dupes = [k for k, n in Counter(
        tuple(str(r.get(c)) for c in KEY) for r in rows).items() if n > 1]
    if dupes:
        for d in dupes:
            print(f"  DUPLICATE: {d}")
        sys.exit(f"ERROR: {len(dupes)} duplicate records on {KEY}.")
    print(f"  Unique on {KEY}")

    # ── Normalize + group ─────────────────────────────────────────────────────
    by_state = defaultdict(list)
    n_normalized = 0
    for r in rows:
        out = {}
        for fld in FIELD_ORDER:
            if fld == "needs_verification":
                before = r.get(fld)
                after  = normalize_needs_verification(r)
                if isinstance(before, bool):
                    n_normalized += 1
                    print(f"  NORMALIZED needs_verification: {r['state']}/"
                          f"{r['condition_category']}/{r['responder_type']}: "
                          f"{before!r} -> text")
                out[fld] = after
            else:
                v = r.get(fld)
                out[fld] = v if v != "" else None
        by_state[out["state"]].append(out)

    for st in by_state:
        by_state[st].sort(key=sort_key)

    print(f"\n  Jurisdictions: {len(by_state)}")
    print(f"  needs_verification values normalized: {n_normalized}")

    if args.dry_run:
        print("\n--dry-run: nothing written.")
        return

    # ── Write ─────────────────────────────────────────────────────────────────
    os.makedirs(OUT_DIR, exist_ok=True)
    total = 0
    for st in sorted(by_state):
        path = os.path.join(OUT_DIR, f"{st}.json")
        with open(path, "w", encoding="utf-8") as f:
            # ensure_ascii=False keeps section signs and dashes literal, so the files
            # are greppable and reviewable. jsonlite reads UTF-8 natively.
            json.dump(by_state[st], f, ensure_ascii=False, indent=2)
            f.write("\n")
        total += len(by_state[st])
    print(f"  Wrote {len(by_state)} files, {total} records -> "
          f"{os.path.relpath(OUT_DIR, PROJ)}/")

    if total != len(rows):
        sys.exit(f"ERROR: wrote {total} records but read {len(rows)}.")
    print("\nDone. Next: Rscript analysis/code/4_combine_records.r")


if __name__ == "__main__":
    main()
