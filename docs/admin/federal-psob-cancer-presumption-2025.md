# Federal PSOB Cancer Presumption — Enacted 2025

**Purpose of this file.** The federal government now has a cancer presumption for public
safety officers. This note records the correct citation, the operative text, the eligibility
gates, and the ways the enacted law differs from the widely circulated bill version — so that
nothing in this project ever cites the bill when it means the statute.

Written 2026-08-20. Source documents in `docs/lit/federal/` (gitignored — see "Sync warning"
at the end).

---

## Correct citation

**Public Law 119-60, § 8205** (National Defense Authorization Act for Fiscal Year 2026),
Title LXXXII — Judiciary Matters, 139 Stat. 1846–1850. Approved **December 18, 2025**.

Codified at **34 U.S.C. § 10281(q)**, by amendment to § 1201 of Title I of the Omnibus Crime
Control and Safe Streets Act of 1968.

### Three citation traps

1. **There is no "Honoring Our Fallen Heroes Act."** S. 237 § 1 would have enacted that short
   title. It was dropped when the provision was folded into the NDAA. The words survive only
   as the section heading, "SEC. 8205. HONORING OUR FALLEN HEROES." There is no short title to
   cite, and no free-standing act. Cite P.L. 119-60 § 8205, or 34 U.S.C. § 10281(q).
2. **The subsection is (q), not (p).** S. 237 would have added subsection (p). But § 8204 of
   the same public law — immediately preceding, an unrelated PSOB expansion — took (p) first,
   so § 8205 was renumbered to (q) on enactment. Any citation to "34 U.S.C. § 10281(p)" for
   the cancer presumption is wrong and points at a different provision entirely.
3. **The signing date is December 18, 2025**, per the govinfo "approved" date for P.L. 119-60.
   Several congressional press releases and advocacy write-ups say December 19. Use the 18th.

## What it does

Creates a rebuttable presumption that a public safety officer's exposure to a carcinogen was
a line-of-duty personal injury directly and proximately resulting in death or permanent and
total disability — making the officer or survivors eligible for **PSOB** benefits.

**PSOB is not workers' compensation.** It is a federal one-time death benefit plus survivor
education benefits, administered by the Bureau of Justice Assistance. No medical treatment
coverage, no wage replacement, no ongoing indemnity, and it triggers only on death or
permanent *and total* disability. This is a materially different instrument from the state
workers'-compensation presumptions this project's dashboard tracks. See "Dashboard
implications" below.

### Covered population

The statute says **"public safety officer"** — the existing PSOB definition, which reaches law
enforcement officers, firefighters, EMS and ambulance crew members, and chaplains. It is
**not** limited to firefighters, notwithstanding that essentially all of the advocacy and press
coverage framed it as a fire-service measure.

This matters for this project: federal law now treats cancer as occupational for law
enforcement officers, while a majority of state cancer presumptions in
`website/data/presumptive_laws.json` cover firefighters only. That is a documented federal
floor sitting above a patchy state ceiling, and it is the strongest available framing for the
LEO coverage-gap argument (see the backlog idea "LEO vs. Firefighter Mortality and the
Presumptive Law Coverage Gap" in `~/.claude/bob/future-projects.md`, and
`docs/admin/vickie-speed-idea-brief-2026-08.md`).

### The standard — the most expansive in the country

Three layers, which together sit above every state standard catalogued in this project:

1. **Twenty enumerated cancers**: bladder, brain, breast, cervical, colon, colorectal,
   esophageal, kidney, leukemia, lung, malignant melanoma, mesothelioma, multiple myeloma,
   non-Hodgkin's lymphoma, ovarian, prostate, skin, stomach, testicular, thyroid.
   (Note "colon" and "colorectal" are both listed — redundant drafting, not two categories.)
2. **Plus** any form of cancer that is a WTC-related health condition under § 3312(a) of the
   Public Health Service Act (42 U.S.C. § 300mm-22(a)).
3. **Plus** a live expansion mechanism: the Director must review the definition at least once
   every 3 years and may update it by rule *or* by publication in the Federal Register or on
   the Bureau's website. Any person may petition to add a cancer; the Director must refer a
   qualifying petition to medical experts within 180 days, act on the recommendation, and
   notify both Judiciary Committees within 30 days of substantive action. Supporting evidence
   may come from NIOSH, the National Toxicology Program, the National Academies, or IARC.

In the taxonomy used in `vickie-speed-idea-brief-2026-08.md`, this is not "enumerated list"
and not plain "IARC/dynamic" — it is enumerated **plus** dynamic **plus** an enforceable
citizen-petition right. It is a tier above New Hampshire's post-SB71/2023 unrestricted
standard in mechanism, if not in nominal breadth, and it is the natural benchmark against
which to score state standards.

**Drafting subtlety worth getting right:** the IARC Group 1 / Group 2A classification attaches
to the **carcinogen** — the exposure agent — not to the cancer type. `"Carcinogen"` means an
agent classified by IARC under Group 1 or 2A *and* reasonably linked to an exposure-related
cancer. The cancer list itself is closed-but-expandable. Do not describe this as an
"IARC cancer list."

### Eligibility gates (34 U.S.C. § 10281(q)(2)(A))

All four must be satisfied:

- exposure occurred while the officer was engaged in line-of-duty action or activity;
- the officer began serving **not fewer than 5 years** before the date of diagnosis;
- diagnosis occurred **not more than 15 years** after the officer's last date of active
  service; and
- the cancer directly and proximately results in death or permanent and total disability.

**Rebuttal (q)(2)(B):** the presumption does not apply if competent medical evidence
establishes that the exposure was **not a substantial contributing factor** in the death or
disability. That is a comparatively claimant-friendly rebuttal bar — the government must
affirmatively disprove substantial contribution, not merely offer an alternative explanation.

### Retroactivity and the filing deadline

- Applies to death claims predicated on deaths **on or after January 1, 2020**, and to
  disability claims **filed on or after January 1, 2020**.
- Claimants have **3 years from the date of enactment** to file — so the window closes on or
  about **December 18, 2028**.

The retroactive window plus the hard filing deadline is a concrete, dated, public-facing fact
that affected families are unlikely to know about. It is a strong candidate for a callout on
the redesigned public site and for advocacy partners.

### Other operative pieces of § 8205

- **(b) Confidentiality.** Amends § 812(a) of the 1968 Act (34 U.S.C. § 10231(a)) to broaden
  confidentiality protection to information furnished under *any* law to *any* component of
  the Office of Justice Programs, by any entity or person. Effective **as if enacted
  December 27, 1979** — 46 years of retroactivity, which reads as a litigation fix riding
  along rather than a technical cleanup. Tangential to this project.
- **(d) "Line of duty action" defined for the COVID presumption.** Amends § 3 of the
  Safeguarding America's First Responders Act of 2020 (34 U.S.C. § 10281 note) to define
  "line of duty action" as any action a public safety officer engaged in at the agency's
  direction, or that the officer is authorized or obligated to perform. Same Jan 1, 2020
  retroactivity and same 3-year filing window. This meaningfully broadens the SAFR COVID
  presumption, not just the cancer one.
- **(e) Rescission.** $255,000,000 permanently rescinded from the DOJ Assets Forfeiture Fund.
  **This was not in S. 237** — it is a pay-for added in the NDAA. Relevant only as evidence
  that the enacted text is not a clean copy of the bill.

## Enacted text vs. S. 237 RS — what actually changed

The operative language of the presumption, the cancer list, the gates, the rebuttal standard,
the update mechanism, and the retroactivity provisions are **verbatim identical** between
S. 237 RS (reported May 20, 2025) and P.L. 119-60 § 8205. Verified by direct comparison.

Structural and additive changes on enactment:

| S. 237 RS | P.L. 119-60 § 8205 |
|---|---|
| § 1 enacts short title "Honoring Our Fallen Heroes Act of 2025" | No short title; heading only |
| Adds 34 U.S.C. § 10281**(p)** | Adds § 10281**(q)** (§ 8204 took (p)) |
| SAFR "line of duty action" definition in free-standing § 3 | Folded in as § 8205**(d)** |
| — | § 8205**(e)**: $255M Assets Forfeiture Fund rescission |

So: nobody's substantive reading of the bill was wrong, but every *citation* drawn from the
bill is wrong.

## Related: § 8204, retired officers and targeted attacks

Immediately preceding, and easy to miss: **P.L. 119-60 § 8204** adds 34 U.S.C. § 10281(p),
making a **retired law enforcement officer** eligible for PSOB benefits if the officer died or
became permanently and totally disabled as the direct and proximate result of a personal
injury from a **targeted attack because of the officer's service** as a law enforcement
officer. Retroactive to actions taken **on or after January 1, 2012**.

Not a cancer or presumptive-law provision, so out of scope for the dashboard's data model.
Recorded here because it is (a) the reason the cancer presumption is subsection (q), and
(b) a second 2025 federal recognition that occupational risk to law enforcement persists past
separation from service — thematically adjacent to the LEO coverage-gap argument.

## Dashboard implications (not yet designed — planning deferred)

Flagged 2026-08-20, no implementation and no schema decision made.

- **A federal layer cannot be a 51st row in `presumptive_laws.json`.** Different benefit type
  (lump-sum death/disability benefit vs. workers' compensation), different administering body
  (BJA vs. state WC boards), different trigger (death or permanent total disability only, vs.
  treatment and wage replacement). Presenting it as one more jurisdiction alongside the states
  would imply federal coverage substitutes for state coverage, which is false and is precisely
  the inference advocacy partners would least want a policymaker to draw.
- Candidate treatments: a separate benefit-type axis; or a persistent "federal floor" band
  displayed above the state map; or a distinct federal page outside the state template.
- **This forces the deferred CSV-pipeline decision** (open since 2026-07-02, see `bob.md`).
  Adding a federal layer is a schema change. Hand-patching a schema change into the JSON with
  another one-off Python script, on top of `apply_p1` through `apply_p6`, produces a data model
  nobody can reason about. Decide whether to retire or restore
  `data/processed/presumptive_laws_v2.csv` as source of truth **before** building this.
- Benchmark opportunity: the federal 20-cancer list plus dynamic-update mechanism gives every
  state a natural comparison column ("does this state match the federal standard?").
- Contrast worth noting: the federal list includes breast, cervical, and ovarian cancer. West
  Virginia has no bill addressing female-specific cancers despite advocacy raised Feb 2026
  (see `bob.md` Pending Notes).

## Source documents

In `docs/lit/federal/`:

- `klobuchar_2025_s237_psob_exposure_cancers.pdf` — S. 237 RS, the reported committee version,
  May 20, 2025. **Superseded. Do not cite.** Retained because it is the version in general
  circulation and the one advocacy partners are likely to hand over.
- `.lit/klobuchar_2025_s237_psob_exposure_cancers.md` — extracted text of the above.
- `pl119-60_sec8204-8205_enacted.txt` — **the operative text.** §§ 8204–8205 as enacted,
  extracted from the govinfo P.L. 119-60 HTML, page markers and marginal NOTE tags stripped.

Online:

- Enacted law: https://www.govinfo.gov/app/details/PLAW-119publ60
- Full text HTML: https://www.govinfo.gov/content/pkg/PLAW-119publ60/html/PLAW-119publ60.htm
- Bill history: https://www.congress.gov/bill/119th-congress/senate-bill/237
- CBO cost estimate for S. 237: https://www.cbo.gov/publication/61589

### Sync warning

`docs/lit/` is gitignored project-wide (`.gitignore:15`, "Copyrighted PDFs — not for public
distribution"). The three source files above therefore exist **only on the machine that
downloaded them** and will not follow to another machine — the same failure mode that left
`docs/lit/state_histories/` desynced from 2026-06-02 to 2026-08-07. This note is in
`docs/admin/` specifically so that the citation and the operative details survive in the repo
even when the source files do not. The enacted text is a U.S. Government work and not
copyrighted; if it becomes inconvenient to re-fetch, consider a narrow `.gitignore` exception
for `docs/lit/federal/*.txt` rather than committing the whole directory.
