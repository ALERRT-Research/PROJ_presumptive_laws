# Scoping Note: 50-State Public Pages Redesign

**Prepared for:** meeting with Vickie Speed (CEO, Blue Cancer Connect), week of 2026-08-11
**Prepared:** 2026-08-07 | **Status:** planning document only — no build work has started
**Companion to:** `vickie-speed-idea-brief-2026-08.md` (cancer-standard research angle, same meeting)

---

## Why this document exists

This is a plan, not a preview. It lays out what a public-facing, 50-state version of the
presumptive laws dashboard would contain, how it would be built without adding any new
infrastructure cost, and how it would stay current after launch. The goal for this meeting is
to show Vickie Speed a credible, concrete build plan — not a finished product — as evidence of
what ALERRT's research infrastructure can turn into with modest support.

**What makes this feasible now, and not six months ago:** the underlying legal research is
done. As of 2026-08-07, all 50 states have a fully researched, source-cited legislative history
file, independently quality-reviewed (scores 97–100/100). That data is what would populate the
pages described below — this proposal adds a public-facing layer on top of research that
already exists, not a new research effort.

---

## 1. What each state page would contain

Every state gets one page, all built from the same template. Four sections, each populated
directly from material already sitting in `docs/lit/state_histories/[XX]_timeline.md` — nothing
below requires new data collection:

1. **Plain-language summary** — a few paragraphs describing which conditions (cancer,
   cardiovascular, respiratory, infectious disease, PTSD/mental health) are covered, for which
   responder groups (firefighters, police, EMS, volunteers), and any major gaps or restrictions
   worth flagging in plain terms. Drawn from each file's existing narrative sections
   ("IAFF-Listed Conditions," "Key Gaps and Open Questions").

2. **Source links** — direct links to the actual statute text and bill history, not just a
   citation. Every timeline file already ends with a "Sources" section listing these; the page
   just surfaces them for a general reader.

3. **Coverage infographic** — a compact visual answering "who's covered, for what" (a small
   grid of responder group × condition) plus a timeline strip of when each presumption was
   enacted, amended, or is set to expire/sunset. This is a visualization layer on top of data
   that already exists in the files' "Primary Statutes," "Summary Timeline Table," and
   "Expirations and Sunsets" tables — no new data, just a rendering of the tables already
   present.

4. **Pending/upcoming legislation flag** — a short callout box for bills still moving through
   that state's legislature (e.g., Kentucky's HB 34, Nebraska's LB400/LB501). Every timeline
   file already tracks this in its legislative history and gaps sections.

Anything a timeline file flags as unconfirmed or low-confidence (several states have these)
would carry a visible "unverified" note on the page rather than being presented as settled fact
— the pages inherit the same confidence-labeling discipline the underlying research already
uses.

---

## 2. How this fits the existing site — no new infrastructure

The project already runs on Quarto with an embedded Shinylive app: a fully static site, no
server, no database, hosted on GitHub Pages. This redesign does not change that model. It adds
50 static pages beside the existing interactive map, generated the same way the rest of the
site is generated.

**The approach: one template, one generation script, not 50 hand-written files.**

- A single Quarto template (`.qmd`) defines the four-section layout described above, with
  placeholders for state name, summary text, source links, and chart data.
- A generation script (R, consistent with the project's existing R pipeline in
  `analysis/code/`) reads each `docs/lit/state_histories/[XX]_timeline.md` file, extracts the
  relevant tables and sections, and renders one populated `.qmd`/`.html` page per state from
  the template.
- The coverage infographic and timeline strip are generated programmatically from each state's
  "Primary Statutes" and "Summary Timeline Table," the same way the existing dashboard's charts
  are generated from `presumptive_laws.json` — this reuses the project's existing
  R-to-static-HTML habits rather than introducing a new toolchain.
- Output is 50 static HTML files added to the Quarto site's build, deployed via the existing
  `quarto render` + `deploy.sh` steps already in the project's workflow.

Net effect: no new hosting, no new database, no server-side code, and no departure from tools
Peter already uses daily. The only new pieces are the template and the generation script — both
one-time builds that get reused every update cycle.

---

## 3. Keeping it current: an update cadence, not a one-time build

Peter's own research registry (`docs/lit/state_histories/registry.md`) already assigns each
state a review cadence based on when its legislature meets:

- **5 states on a biennial cycle** (TX, NV, MT, ND, OR — odd-year sessions): re-check by
  September of the session year.
- **45 states on an annual cycle**: re-check each January after that year's session closes.

The public pages would ride on top of this same schedule rather than inventing a new one:

1. When a state's scheduled review happens (per the registry's "Next Review" date) and its
   timeline file is updated, re-run the generation script for that state only — it regenerates
   one page from the updated source file, not the full site.
2. A lightweight batch pass (re-run the generator for every state whose "Next Review" date has
   passed) happens each January, since that's when the large majority of states' sessions have
   just closed.
3. Each page carries a visible "last verified" date pulled directly from the timeline file's
   own header field, so visitors — and Vickie Speed — can see the update discipline, not just
   take it on faith.

This makes the maintenance burden proportional to actual legislative activity: most states
need one check a year, five need one every two years, and no state page ever needs a rebuild
from scratch.

---

## 4. Effort estimate and phasing

This is scoping only — no template exists yet and no generation code has been written. Treating
it as a single undifferentiated task would be a planning mistake; it breaks into phases that can
be checkpointed and shown to Vickie Speed incrementally rather than delivered as one large
reveal:

| Phase | What happens | Rough scope |
|---|---|---|
| 1. Template design | Design the one-page layout (summary, links, infographic, timeline) and get it right on 1 state, by hand, before automating anything | Small — a few focused sessions |
| 2. Generation pipeline | Write the R script that parses timeline files into the template's data structure; build the infographic/timeline chart generator | Medium — the main engineering lift |
| 3. Pilot (5–10 states) | Run the pipeline on a small, deliberately varied set of states (e.g., a mix of simple single-track states and complex multi-track states like NY or TN) to stress-test the template against real data messiness | Small–medium, mostly debugging edge cases the pilot surfaces |
| 4. Full rollout (all 50) | Run the validated pipeline against all 50 timeline files, spot-check output, wire into the Quarto build and deploy step | Small once Phase 2–3 are solid — this is where "one script vs. 50 hand files" pays off |
| 5. Cadence handoff | Document the update workflow (tie generation re-runs to the registry's review dates) so this becomes routine maintenance, not a recurring special project | Small, one-time documentation task |

No phase has a committed timeline yet. The honest framing for Vickie Speed: the research
foundation (Phase 0, effectively) is done and QC-verified; everything above is designed but
unbuilt, and Phase 3's pilot is the natural first checkpoint to show tangible progress.

---

## 5. Connection to the LEO-vs-firefighter coverage-gap idea

This redesign and the backlogged project "LEO vs. Firefighter Mortality and the Presumptive Law
Coverage Gap" (`future-projects.md`, added 2026-07-03) reinforce each other rather than
competing for attention:

- The backlog project uses NOMS mortality data to argue that law enforcement officers face
  occupational death patterns comparable to firefighters, yet have far thinner presumptive-law
  coverage — a gap attributable to organizing history, not risk.
- The state pages give that argument a visible, state-by-state receipt: each page's coverage
  infographic will, in most states, show firefighters covered across several conditions and law
  enforcement covered across few or none for the same conditions (the Texas and New Mexico
  timeline files are clean examples of this pattern already).
- Practically, if the mortality project moves forward, its findings could be layered onto the
  same per-state infographic as an additional data point — no new page architecture required,
  since the template already has a coverage-grid slot built for exactly this kind of
  group-by-condition comparison.

Neither project depends on the other to proceed, but building the state pages first gives the
mortality project a ready-made publication venue instead of a from-scratch one.
