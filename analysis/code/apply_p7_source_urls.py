#!/usr/bin/env python3
"""
P7 Source URLs -- August 2026
Adds a `source_url` field to every row in the presumptive-laws dataset by
exact-matching each row's (state, statute_citation) pair against a mapping
of citation strings to source URLs extracted from each state's
docs/lit/state_histories/[XX]_timeline.md "Sources" section (extracted by
five parallel batch agents covering all 50 states).

This pass ONLY adds the `source_url` field -- no other field on any row is
touched, and no rows are added or removed. Matching is exact-string only on
`statute_citation`; rows whose citation is not present in the merged mapping
(either because the state had no mapping for that exact citation, or the
citation was one of the handful explicitly skipped by the extraction
agents) get `source_url: null`. No guessing, no fuzzy matching.

Run from project root:
    python3 analysis/code/apply_p7_source_urls.py

Inputs:
    analysis/code/tmp_source_urls_batch1.json .. tmp_source_urls_batch5.json
        Each shaped {"STATE_ABBREV": {"exact statute_citation string": "url", ...}, ...}
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
    Path(f"analysis/code/tmp_source_urls_batch{i}.json") for i in range(1, 6)
]

# =============================================================================
# Merge the five batch files (disjoint state sets -- straightforward merge)
# =============================================================================

merged_mapping = {}
for batch_file in BATCH_FILES:
    with open(batch_file) as f:
        batch = json.load(f)
    for state, citation_map in batch.items():
        if state in merged_mapping:
            raise ValueError(f"Duplicate state {state!r} found across batch files "
                              f"-- batches were expected to cover disjoint state sets")
        merged_mapping[state] = citation_map

print(f"Merged {len(merged_mapping)} states from {len(BATCH_FILES)} batch files "
      f"({sum(len(v) for v in merged_mapping.values())} total citation->url entries)")

# =============================================================================
# Load canonical data and apply source_url
# =============================================================================

with open(JSON_PATH_WEB) as f:
    data = json.load(f)

original_count = len(data)

state_totals = {}
state_matched = {}

for row in data:
    state = row["state"]
    citation = row.get("statute_citation")
    state_totals[state] = state_totals.get(state, 0) + 1

    url = merged_mapping.get(state, {}).get(citation)
    row["source_url"] = url if url else None
    if url:
        state_matched[state] = state_matched.get(state, 0) + 1

assert len(data) == original_count, "Row count changed -- this script must only add a field"

# =============================================================================
# Report
# =============================================================================

total_matched = sum(state_matched.values())
total_null = original_count - total_matched

print(f"\n{'='*70}")
print(f"P7 SOURCE URLS APPLIED")
print(f"{'='*70}")
print(f"Total rows: {original_count}")
print(f"  source_url populated: {total_matched}")
print(f"  source_url null:      {total_null}")

print(f"\n{'State':<6}{'Matched':>10}{'Total':>10}")
for state in sorted(state_totals.keys()):
    matched = state_matched.get(state, 0)
    total = state_totals[state]
    print(f"{state:<6}{matched:>10}{total:>10}")

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
