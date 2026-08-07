#!/usr/bin/env python3
"""
P8 Notes Rewrite -- August 2026
Replaces the `notes` field for every row whose original notes mentioned
"IAFF" in a research-audit-log voice (e.g. "CORRECTED (2026-08-07
research): ... mirroring IAFF's own page...") with plain-language,
user-facing text that keeps the same substantive legal facts but drops the
IAFF-comparison/research-meta-commentary. Rewrites were produced by three
parallel batch agents covering all 50 states.

This pass ONLY replaces the `notes` field on matched rows -- no other field
on any row is touched, and no rows are added or removed. Matching is exact
string match only, on (state, notes); rows whose notes text is not an exact
match to one of the mapped original strings for that state are left
completely untouched (including rows that never mentioned IAFF at all). No
guessing, no fuzzy matching.

Run from project root:
    python3 analysis/code/apply_p8_notes_rewrite.py

Inputs:
    analysis/code/tmp_notes_rewrite_batchA.json .. tmp_notes_rewrite_batchC.json
        Each shaped {"STATE_ABBREV": {"exact original note text": "rewritten note text", ...}, ...}
    website/data/presumptive_laws.json (canonical copy, read)

Writes updated JSON to website/data/presumptive_laws.json, then copies it to
website/shiny-app/data/presumptive_laws.json to keep both dashboard data
files in sync (matching the CLAUDE.md-documented sync step).
"""

import json
import shutil
from pathlib import Path

JSON_PATH_WEB = Path("website/data/presumptive_laws.json")
JSON_PATH_SHINY = Path("website/shiny-app/data/presumptive_laws.json")

BATCH_FILES = [
    Path("analysis/code/tmp_notes_rewrite_batchA.json"),
    Path("analysis/code/tmp_notes_rewrite_batchB.json"),
    Path("analysis/code/tmp_notes_rewrite_batchC.json"),
]

# =============================================================================
# Merge the three batch files (disjoint state sets -- straightforward merge)
# =============================================================================

merged_mapping = {}
for batch_file in BATCH_FILES:
    with open(batch_file) as f:
        batch = json.load(f)
    for state, notes_map in batch.items():
        if state in merged_mapping:
            raise ValueError(f"Duplicate state {state!r} found across batch files "
                              f"-- batches were expected to cover disjoint state sets")
        merged_mapping[state] = notes_map

total_distinct_notes = sum(len(v) for v in merged_mapping.values())
print(f"Merged {len(merged_mapping)} states from {len(BATCH_FILES)} batch files "
      f"({total_distinct_notes} distinct original->rewritten note entries)")

# =============================================================================
# Load canonical data and apply notes rewrites
# =============================================================================

with open(JSON_PATH_WEB) as f:
    data = json.load(f)

original_count = len(data)

state_changed = {}
matched_originals_by_state = {state: set() for state in merged_mapping}

for row in data:
    state = row.get("state")
    if state not in merged_mapping:
        continue
    notes = row.get("notes")
    notes_map = merged_mapping[state]
    if notes in notes_map:
        row["notes"] = notes_map[notes]
        state_changed[state] = state_changed.get(state, 0) + 1
        matched_originals_by_state[state].add(notes)

assert len(data) == original_count, "Row count changed -- this script must only rewrite a field"

# =============================================================================
# Report
# =============================================================================

total_changed = sum(state_changed.values())

print(f"\n{'='*70}")
print(f"P8 NOTES REWRITE APPLIED")
print(f"{'='*70}")
print(f"Total rows: {original_count}")
print(f"  rows changed: {total_changed}")

print(f"\n{'State':<6}{'Rows changed':>14}")
for state in sorted(merged_mapping.keys()):
    print(f"{state:<6}{state_changed.get(state, 0):>14}")

# Verify every mapped original note text found at least one exact match
print(f"\n{'-'*70}")
print("Unmatched original note-text entries (expected: none)")
print(f"{'-'*70}")
unmatched_count = 0
for state, notes_map in merged_mapping.items():
    for original_text in notes_map:
        if original_text not in matched_originals_by_state[state]:
            unmatched_count += 1
            print(f"  [{state}] NO MATCH FOUND for original text starting: "
                  f"{original_text[:80]!r}...")
if unmatched_count == 0:
    print("  (none -- every original note text matched at least one row)")
else:
    print(f"\n  WARNING: {unmatched_count} original note text(s) had no matching row.")

# =============================================================================
# Write output to the canonical website/data/ copy, then sync to shiny-app/
# =============================================================================

with open(JSON_PATH_WEB, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

shutil.copyfile(JSON_PATH_WEB, JSON_PATH_SHINY)

print(f"\nWritten to {JSON_PATH_WEB}")
print(f"Copied to {JSON_PATH_SHINY} to keep both dashboard data files in sync")
print("Review with: git diff website/data/presumptive_laws.json "
      "website/shiny-app/data/presumptive_laws.json")
