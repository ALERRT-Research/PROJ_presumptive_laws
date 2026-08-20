<!-- Copied from the session plan file at implementation time. -->
**Status: COMPLETED 2026-08-20.** Implemented and verified; see
`docs/logs/2026-08-20_session9.md` for what actually happened, including three deviations
from this plan (a second legitimate duplicate, a stale shinylive export target, and the
IAFF change-detection rewrite deliberately not built).

# Rebuild the presumptive-laws data pipeline on research-derived provenance

## Context

`website/data/presumptive_laws.json` (479 rows, all 50 states QC-gated 97–100/100 on
2026-08-07) is the only authoritative copy of this project's dataset, and **nothing can
regenerate it.** It was hand-built by eight sequential one-off Python scripts
(`apply_p1_corrections.py` … `apply_p8_notes_rewrite.py`) applied directly to the JSON,
bypassing the R pipeline entirely. Every file in `data/processed/` is still dated 2026-05-27.

The R pipeline can't simply be re-run, because its source of truth is the IAFF scrape
(`2_iaff_scrape.r` → `3_iaff_extract.r` → `data/raw/iaff_extracted/` → `4_iaff_combine.r`),
and P8 formally demoted IAFF from ground truth. Re-running it would rebuild from repudiated
stale HTML and discard all eight correction passes.

**Measured, not assumed** (2026-08-20):

- Schema drift CSV → JSON is **one column**: `source_url`, added by P7.
- **Nothing was lost.** Keyed on state × condition × responder: 384 cells in the CSV, 438 in
  the JSON, CSV-only set is **empty**. The 54 new cells are the P4/P5 completeness fills
  (27 mental, 12 cardiovascular, rest scattered). Of 402 rows matched on a tighter key, 91
  have any field change, concentrated in `notes` (76, from P8) and `presumption_type` (37).
- **`4_iaff_combine.r` would actively corrupt the data if run today.** Its
  `valid_ptype <- c("statute","EO","expired","none")` (line 39) coerces anything else to
  `"none"` (lines 55–58). The live JSON contains `pension` (28 rows), `employer_benefit` (26),
  and `lodd_only` (4) — **58 rows would be silently destroyed.** `app.R`'s `type_priority` /
  `status_labels` / `status_clrs` vectors (lines 29–65) carry all seven values.
  **`app.R` is the de facto schema authority; script 4 is stale.**

So the defect is not schema drift and not the CSV. It is **provenance and reproducibility** —
a non-reproducible-output defect under `quality-gates.md`, and the same single-copy failure
mode as the (now closed) `docs/lit/state_histories/` sync gap.

**Outcome intended:** a pipeline that regenerates the current dataset from committed,
research-derived inputs, verified semantically equivalent to today's JSON, so that the
federal-coverage layer (P.L. 119-60 § 8205 — see
`docs/admin/federal-psob-cancer-presumption-2025.md`) can be built on a reproducible base
instead of a ninth one-off patch script.

## Decisions taken

| Decision | Choice |
|---|---|
| Provenance | **Hybrid** — bootstrap records from the current QC'd JSON, then extend template + agent so future reviews maintain them |
| Scope | **Pipeline only.** Federal layer is the next, separate piece of work |
| Federal data model (later) | **Separate file + separate display** (`website/data/federal_coverage.json`) |

## Target architecture

```
data/raw/state_records/{AL..WY,DC}.json      ← NEW. Committed. Source of truth.
        │   4_combine_records.r  (validate, coerce, bind)
        ▼
data/processed/presumptive_laws_v2.rds + .csv  ← regenerated output, no longer an input
        │   5_iaff_export_json.r
        ▼
website/data/presumptive_laws.json  +  website/shiny-app/data/presumptive_laws.json

Going forward, legislative-researcher writes BOTH:
   docs/lit/state_histories/XX_timeline.md   (prose narrative + sources, human-facing)
   data/raw/state_records/XX.json            (structured records, machine-facing)
```

`data/raw/state_records/` is deliberately **outside `docs/lit/`**, which is gitignored
(`.gitignore:15`). A pipeline whose input lives in an ignored directory is unreproducible on
the second machine by construction — that is the exact hole closed on 2026-08-07 and it must
not be reopened.

## Implementation

### 1. Bootstrap the record files

New script `analysis/code/split_json_to_records.py` (one-shot, kept as provenance):
read `website/data/presumptive_laws.json`, group by `state`, write
`data/raw/state_records/XX.json` — 51 files, one array of record objects each, keys in a
fixed documented order, sorted by `condition_category` then `responder_type` then
`statute_citation` for stable diffs.

Two known data quirks to resolve during the split, both verified today:

- **`needs_verification` is mixed-type.** One row — index 279, NY / respiratory /
  firefighter — holds boolean `true`; every other populated value is free text. Per
  `docs/lit/state_histories/registry.md`, NY's meaning is "§ 363-f lung revival is inferred,
  not directly annotated — lower confidence, keep flagged." Normalize to that text so the
  column is uniformly character-or-null. **This is the one intentional content change in this
  plan** and the verification step must expect it.
- **`LA / mental / law_enforcement` is a legitimate duplicate** — two distinct statutes
  (`La. R.S. 33:2581.2` and `La. R.S. 40:1374`) covering the same cell. Uniqueness must be
  asserted on **(state, condition_category, responder_type, statute_citation)**, *not* on the
  4-tuple without citation. Do not "fix" this row.

### 2. Replace the combine step

New `analysis/code/4_combine_records.r`, adapted from `4_iaff_combine.r` — keep its structure,
its validation block (lines 93–130) and its summary reporting (lines 132–167), which are
genuinely worth preserving. Changes:

- Input `data/raw/state_records/*.json` instead of `data/raw/iaff_extracted/*.json`.
- **Correct the stale domains** to match `app.R` (lines 29–92), which is authoritative:
  - `valid_ptype <- c("statute","EO","pension","employer_benefit","lodd_only","expired","none")`
  - `valid_conditions` and `valid_responders` already match `app.R`; verify and leave.
- Fail loudly instead of silently coercing: an out-of-domain `presumption_type` should abort
  with the offending rows printed, not become `"none"`. Silent coercion is what made the old
  script dangerous.
- Handle `needs_verification` and `source_url` explicitly in the character-coercion block
  (lines 84–88) — neither is currently handled at all.
- Add the uniqueness assertion from step 1, and assert 51 jurisdictions and a 479-row count.

Retire `4_iaff_combine.r` (leave on disk, add a header comment pointing at the replacement and
warning that its `valid_ptype` is destructive). Demote `2_iaff_scrape.r` / `3_iaff_extract.r`
to IAFF change-detection — scrape, diff against the previous scrape, report which state pages
moved — feeding the per-state review cadence in `docs/lit/state_histories/registry.md`. No
data path runs through them any more.

### 3. Fix the export step

`analysis/code/5_iaff_export_json.r` currently writes only `website/data/presumptive_laws.json`
(line 12). The `website/shiny-app/data/` copy is byte-identical right now, which means someone
copied it by hand — a live footgun. Write both paths from the one data frame and hash-verify
they match. Confirm `source_url` survives serialization (455 of 479 rows populated, 24
deliberately null).

### 4. Rewrite the codebook

`data/codebook.md` documents the **v1** schema — `condition`, `responder_groups`, `source`,
`data_current_through`, and a `covid19` category that exists in no current file. Only 6 of its
documented columns exist in the live data. Rewrite for the actual 21-field v2 schema, including
the seven-value `presumption_type` domain, `source_url`, the mixed-type resolution for
`needs_verification`, and the legitimate-duplicate rule. This is documentation *of the thing
being built*, so it belongs in this change rather than deferred.

### 5. Wire the agent for future reviews

- `docs/lit/state_histories/templates/state_template.md` — add a fenced JSON block section
  ("Structured Records") carrying the full 21-field record set for that state, alongside the
  existing prose. The template already mandates a source URL per statute row, which is where
  `source_url` comes from; this formalizes what P7 extracted by hand.
- `~/.claude/agents/legislative-researcher.md` — instruct the agent to write
  `data/raw/state_records/XX.json` as a required output alongside `XX_timeline.md`, using the
  documented domains, and to treat the record file as the machine-readable twin of the prose.
- `~/.claude/agents/legislative-reviewer.md` — add a rubric item scoring record/prose agreement
  (every statute in the prose appears in the records with a matching citation, and vice versa).

## Verification

**Byte-identical output is not the test and will fail** — the current JSON was last written by
Python with `ensure_ascii=True` (e.g. `"Alaska Stat. § 23.30.121…"`), while `jsonlite`
emits the literal `§`, and key order differs. The correct test is semantic equivalence.

1. Snapshot the current JSON to a scratch path before touching anything.
2. Run the pipeline end to end: `split_json_to_records.py` → `4_combine_records.r` →
   `5_iaff_export_json.r`.
3. Compare regenerated vs. snapshot with a throwaway Python check: parse both, normalize types
   (`"TRUE"`/`true`, `""`/`null`), compare as multisets of records keyed on
   (state, condition_category, responder_type, statute_citation). **Expect exactly one
   difference: the NY `needs_verification` normalization from step 1.** Any other diff is a
   regression — stop and fix rather than accepting.
4. Assert 479 rows, 51 jurisdictions, and that `presumption_type` still has 417 `statute` /
   28 `pension` / 26 `employer_benefit` / 4 `lodd_only` / 2 `none` / 2 `expired`. If any of the
   58 non-WC rows became `none`, the domain fix in step 2 didn't take.
5. Hash-check the two JSON copies match.
6. Re-render the Shinylive app (`cd website && shinylive export shiny-app dashboard`) and load
   it. Confirm the map, the UpSet panel, the state drill-down table, and the per-row statute
   hyperlinks all still work — `app.R` reads the JSON directly at line 13 and keys the map on
   `state`, so a schema slip shows up visually.
7. Save the session log and a copy of this plan to `docs/logs/` and
   `docs/logs/plans/2026-08-20_pipeline-rebuild.md` per `plan-first-workflow.md`.

Nothing gets committed without your approval.

## Explicitly out of scope

- **The federal layer.** Next piece of work. Keeping it out is what makes step 3's regression
  test meaningful.
- **`data_retrieved` is stale** — 411 of 479 rows still say `2026-05-23` despite the
  2026-08-07 re-research. Fixing it is a content change that would contaminate the equivalence
  check. Do it as a follow-up, deliberately, from `registry.md`'s per-state verified dates.
- **`app.R` line 1326 still renders a state-level "IAFF source ↗" link**, inconsistent with
  P8's demotion of IAFF and more wrong once federal coverage exists. App-level copy, not
  pipeline. Follow-up.
- **Re-verifying that the 479 rows are correct.** This plan preserves the dataset; it does not
  re-audit it. Correctness rests on the 2026-08-07 QC pass.
