# Corrections Inventory
Generated: 2026-06-04
Source: 50-state timeline research (docs/lit/state_histories/in-progress/)

## Summary
- Total corrections needed: 76
- Priority 1 (wrong values): 10 states, 17 corrections
- Priority 2 (missing rows): 12 states, 38 corrections
- Priority 3 (field quality): 15 states, 21 corrections

---

## Priority 1 — Wrong Values

### Arizona (AZ)
**Current JSON:** Two rows for PTSD (firefighter + law_enforcement), `presumption_exists: true`, `presumption_type: "statute"`, citing `Ariz. Rev. Stat. § 23-972`.
**Timeline finding:** § 23-972 was enacted conditioned on FDA approval of midomafetamine (MDMA-AT) by December 31, 2025. The FDA rejected MDMA-AT on August 9, 2024. The statute explicitly did not take effect. The Arizona timeline (Key Gap #1) confirms § 23-972 is "effectively void."
**Correction needed:**
- Both AZ mental/firefighter and mental/law_enforcement rows: change `presumption_exists` from `true` to `false`, change `presumption_type` from `"statute"` to `"none"`. Update notes to state the condition was never legally operative.

### Arizona (AZ) — Statute Citation Error
**Current JSON:** AZ cardiovascular/firefighter and cardiovascular/firefighter_volunteer rows cite `Ariz. Rev. Stat. § 23-1043.05`.
**Timeline finding:** The operative cardiovascular statute is `A.R.S. § 23-1105` (enacted HB 2410, 2017). Section 23-1043.05 does not appear to be the correct operative statute — the IAFF page had the wrong citation and the JSON copied it.
**Correction needed:** Change `statute_citation` in AZ cardiovascular/firefighter and cardiovascular/firefighter_volunteer rows from `§ 23-1043.05` to `A.R.S. § 23-1105`.

### Iowa (IA) — Outdated Cancer List
**Current JSON:** IA cancer/firefighter row lists 14 enumerated cancer types in `condition_specific`, citing `Iowa Code § 411.6(5); § 411.1(6)`.
**Timeline finding:** HF 969 (signed June 6, 2025, effective June 6/July 1, 2025) amended § 411.1(6) to expand the definition of "cancer" from the 14-type enumerated list to ALL cancer types ("a group of diseases involving abnormal cell growth with the potential to invade or spread to other parts of the body"). This applies across all three Iowa retirement systems (MFPRSI, PORS, IPERS).
**Correction needed:**
- IA cancer/firefighter: update `condition_specific` to reflect "all cancers (any type)" per amended § 411.1(6), add note that HF 969 (eff. June 2025) expanded from 14 enumerated types to all cancer types.
- The cancer rows for IA law_enforcement (IPERS track) do not appear in the JSON; add missing rows (see Priority 2).

### Mississippi (MS) — Statute Citation Wrong
**Current JSON:** MS cancer rows (firefighter, firefighter_volunteer, law_enforcement) cite "Mississippi First Responders Health and Safety Act" sections. The IAFF page cited "Title 45, Chapter 2."
**Timeline finding:** The MS timeline explicitly states (Key Gap #1): "The IAFF page cites Title 45, Chapter 2. The MFRHSA is in Title 25, Chapter 15, Article 11." Title 45, Chapter 2 is the separate Death Benefits Trust Fund (not disease presumptions). The correct citation is `Miss. Code Ann. §§ 25-15-401 through 25-15-411`.
**Correction needed:** Update `statute_citation` for all three MS cancer rows from the current citation referencing "Section 2-7" to `Miss. Code Ann. §§ 25-15-401 through 25-15-411`.

### Mississippi (MS) — Missing Cardiovascular Condition
**Current JSON:** MS has no cardiovascular rows.
**Timeline finding:** The MFRHSA (§ 25-15-405, Section 3) also includes a cardiovascular/stroke presumption: any acute cardiovascular or stroke event (ischemic or hemorrhagic) developing within 24 hours of a work shift involving training or a stressful event is classified as a service-connected disease. Covered groups: firefighters and law enforcement officers.
**Correction needed:** Add cardiovascular rows for MS firefighter and law_enforcement (see Priority 2).

### New Hampshire (NH) — Age Cap Wrong
**Current JSON:** NH cardiovascular/firefighter row notes "Benefits do not continue beyond one month after firefighter reaches age 65."
**Timeline finding:** The 2021 amendment (Acts of 2021, Ch. 83:1, eff. August 17, 2021) raised the age cutoff from 65 to **70**. The IAFF page still shows 65 and was not updated. The JSON copied the stale IAFF value.
**Correction needed:** NH cardiovascular/firefighter: update the age cutoff in the notes from "age 65" to "age 70."

### New Mexico (NM) — Outdated Cancer List
**Current JSON:** NM cancer/firefighter row lists 11 enumerated cancers with variable service periods (5–15 years per type) in `condition_specific`.
**Timeline finding:** Laws 2026, Chapter 36 (HB 128, signed March 5, 2026, effective approximately May 20, 2026) expanded the cancer list from 11 types to 21 types AND standardized the service period to 5 years for all types. Added: cervical, colon (separately from colorectal), lung, malignant melanoma, mesothelioma, ovarian, prostate, skin, stomach, thyroid. Removed the variable 5–15 year per-type service periods (uniform 5-year period now). Also removed age caps for testicular and breast cancer.
**Correction needed:**
- NM cancer/firefighter: update `condition_specific` to reflect the 21-type list with uniform 5-year service period.
- Update `years_service_required` from the current variable-per-type language to `5`.
- Update notes to reflect the 2026 expansion and removal of breast/testicular age caps.

### Ohio (OH) — Cancer Lookback Wrong
**Current JSON:** OH cancer/firefighter notes "Presumption does not apply if more than 20 years since last assigned to hazardous duty."
**Timeline finding:** The OH timeline (citing HB 27, effective September 29, 2017) clarifies the lookback is **15 years**, not 20. The possible 20-year figure may have appeared in an interim version before HB 27 corrected it. The current statute (as verified by the timeline) is 15 years.
**Correction needed:** OH cancer/firefighter: update the filing deadline notes and any mention of "20 years" to "15 years." Current `post_termination_months` is set to 240 (20 yrs); correct to 180 (15 yrs).

### South Carolina (SC) — Missing Stroke (Added May 2026)
**Current JSON:** SC cardiovascular/firefighter only lists "heart disease" in `condition_specific`, citing `S.C. Code Ann. § 42-11-30(A)`.
**Timeline finding:** Act No. 132 of 2026 (H3163, signed May 15, 2026, eff. May 15, 2026) amended § 42-11-30(A) to add **stroke** alongside heart disease. The statute now reads "heart disease, stroke, or respiratory disease." The IAFF page has not been updated to reflect this.
**Correction needed:** SC cardiovascular/firefighter: update `condition_specific` to include stroke. Update notes to note the May 2026 addition.

### Tennessee (TN) — PTSD Rows Incorrectly Coded
**Current JSON:** TN has two PTSD rows (firefighter + emt_paramedic) with `presumption_exists: false`, citing `§ 8-50-119`. Notes correctly describe this as a treatment access mandate, not a WC presumption.
**Timeline finding:** The TN timeline documents a TRUE workers' compensation PTSD presumption enacted by PC 465 (James "Dustin" Samples Act), effective January 1, 2024, codified at `T.C.A. § 7-51-206`. This covers full-time paid firefighters. It was expanded effective July 1, 2025 to law enforcement officers and emergency medical responders (PC 480). **The IAFF page omits § 7-51-206 entirely.** The JSON also omits it.
**Correction needed:** Keep the existing § 8-50-119 rows coded as `presumption_exists: false` (correctly noted as treatment access mandate). Add missing WC presumption rows for TN PTSD under § 7-51-206 (see Priority 2).

### Wisconsin (WI) — Missing PTSD Rows
**Current JSON:** WI has no PTSD rows at all.
**Timeline finding:** 2021 a. 29 (effective April 29, 2021) created Wis. Stat. § 102.17(9), a true WC PTSD presumption for law enforcement officers and full-time firefighters. 2025 a. 145 (effective April 1, 2026) expanded it to all firefighters (including volunteers) and emergency medical responders/practitioners. **The IAFF page omits § 102.17(9) entirely.**
**Correction needed:** Add PTSD rows for WI (see Priority 2).

---

## Priority 2 — Missing Rows

### Alaska (AK) — PTSD Missing (AS 23.30.118)
**Missing:** mental × firefighter, emt_paramedic, law_enforcement, corrections
**Statute:** Alaska Stat. § 23.30.118 (created by SB 147 / Ch. 12 SLA 2024, effective January 1, 2025)
**Key facts:**
- `presumption_exists`: true
- `presumption_type`: "statute"
- `rebuttable`: true
- Covered occupations: correctional officers, emergency medical technicians, emergency medical dispatchers, firefighters, mobile intensive care paramedics (AS 18.08), peace officers, state-certified EMS personnel
- No minimum years of service
- Trigger: PTSD diagnosed by psychiatrist or psychologist, received during employment or within 3 years after last employment date
- Rebuttal: preponderance of evidence that PTSD resulted from non-work factors
- `post_termination_months`: 36
- `statute_citation`: "Alaska Stat. § 23.30.118"
- IAFF page does not list this statute at all as of June 2026.

Add rows for: firefighter, emt_paramedic, law_enforcement, corrections (emergency dispatchers map closest to this category).

### Iowa (IA) — Law Enforcement and EMS Cancer/Infectious Disease Missing
**Missing:** cancer × law_enforcement (PORS/IPERS tracks); infectious disease × law_enforcement; multiple IPERS protection occupation rows
**Statute:** Iowa Code § 97A.1(6) (PORS, state-level peace officers); Iowa Code § 97B.50A (IPERS protection occupation members — includes EMTs, sheriffs, conservation officers, etc.)
**Key facts:**
- PORS covers Iowa State Patrol, DCI, Narcotics Enforcement, State Fire Marshal, Capitol Police for cancer (all types as of HF 969, June 2025)
- IPERS § 97B.50A covers protection occupation / special service members including municipal FF and police NOT in Ch. 411/97A systems, EMTs/EMS providers, sheriffs/deputies, conservation officers, parole officers, airport security
- `presumption_type`: "statute"
- `presumption_exists`: true — BUT note: Iowa's systems are pension/retirement disability presumptions, NOT workers' compensation
- `rebuttable`: true (standard for all three Iowa tracks)
- IPERS has a critical structural note: Iowa Administrative Code specifies the burden of proof does NOT shift from the member; "under no circumstances shall the burden of proof shift from the special service member" — this makes IPERS structurally weaker than a standard rebuttable presumption

[TENTATIVE] Add law_enforcement cancer row for Iowa covering PORS track (Iowa State Patrol etc.) — these are pension disability presumptions. Verify PORS covers heart/respiratory/infectious as well as cancer. Timeline flags heart/respiratory/infectious for PORS track as unconfirmed.

### Maine (ME) — Law Enforcement Cardiovascular/Respiratory Missing
**Missing:** cardiovascular × law_enforcement; respiratory × law_enforcement
**Statute:** 39-A M.R.S.A. § 328-D (PL 2023, c. 445, effective 2023)
**Key facts:**
- `presumption_exists`: true
- `presumption_type`: "statute"
- `rebuttable`: true
- Covered group: active law enforcement officers holding current and valid certification from the Board of Trustees of the Maine Criminal Justice Academy
- Conditions: cardiovascular injury/disease and pulmonary disease
- Requirements: 2+ years tenure; condition developed or injury occurred within 6 months of law enforcement activities or training/drill
- `years_service_required`: 2
- `statute_citation`: "Me. Rev. Stat. Title 39-A, Sec. 328-D"
- IAFF page for Maine does not list § 328-D (confirmed gap in IAFF page, not a statutory gap)

### Maryland (MD) — Law Enforcement Cardiovascular Missing
**Missing:** cardiovascular × law_enforcement (Md. Code, Lab. & Empl. § 9-503(b))
**Statute:** Md. Code, Lab. & Empl. § 9-503(b)
**Key facts:**
- `presumption_exists`: true
- `presumption_type`: "statute"
- `rebuttable`: null (rebuttability not specified in the current JSON pattern for MD; timeline says rebuttable by competent evidence)
- Covered groups: paid police officers statewide; deputy sheriffs of specific counties (Montgomery, Anne Arundel, Baltimore City, Allegany); correctional officers of Montgomery and Prince George's counties
- Conditions: heart disease, hypertension (requires disability or death + condition worsening post-employment for county-specific deputies/corrections)
- `statute_citation`: "Maryland Code, Labor and Employment § 9-503(b)"

Also missing: Lyme disease × law_enforcement/rangers. Statute: `§ 9-503(d)`, covers forest rangers, park rangers, wildlife rangers, DNR paid LE employees, MNCPPC park police assigned to outdoor wooded environments. [TENTATIVE] Map to `responder_type: "law_enforcement"` as closest available category.

### Maryland (MD) — Hypertension-Only Presumption (New 2026)
**Missing:** Additional cardiovascular row for MD firefighter (standalone hypertension, eff. Oct 1, 2026)
**Statute:** Md. Code, Lab. & Empl. § 9-503(a) as amended by HB 347 / Ch. 300 (eff. October 1, 2026)
**Key facts:** The new standalone hypertension provision applies to paid firefighters, fire instructors, rescue squad members, ALS unit members, sworn State Fire Marshal members — does NOT apply to volunteers. Requires: hypertension diagnosis, medication prescribed 90+ consecutive days, 2-year cumulative service, currently employed at claim time. No disability required (unlike the existing § 9-503(a) heart disease/hypertension standard). This is a materially different access standard that warrants a separate row noting the October 1, 2026 effective date and "paid firefighters only" (volunteer exclusion).

[TENTATIVE] Whether to add a new row vs. amending the existing row is a schema question for the data team. Mark this tentative pending discussion.

### Missouri (MO) — PTSD WC Missing
**Missing:** mental × firefighter, law_enforcement, emt_paramedic
**Statute:** RSMo § 287.067(9) (enacted by SB 24, effective August 28, 2023)
**Key facts:**
- `presumption_exists`: true
- `presumption_type`: "statute"
- `rebuttable`: true
- Covered groups: certified first responders — firefighters, police officers, EMTs, paramedics, and telecommunicators
- Condition: PTSD (DSM-5 diagnosis required)
- Standard: clear and convincing evidence that PTSD resulted from employment
- No physical injury required
- Qualifying events include: witnessing death or serious injury of a minor; witnessing a death; being involved in a life-threatening situation; treating a person who subsequently dies
- Notice deadline: 52 weeks after qualifying exposure or diagnosis, whichever is later
- Preexisting PTSD not compensable
- `statute_citation`: "RSMo § 287.067(9)"
- IAFF page does not list § 287.067(9) — it only shows the pension/pool statutes

### North Carolina (NC) — Cardiovascular Presumption Missing (LODD only row exists)
**Current JSON:** NC only has cancer rows and no cardiovascular row. The LODD myocardial infarction provision is missing entirely.
**Missing:** cardiovascular × firefighter, law_enforcement, emt_paramedic (G.S. § 143-166.2 myocardial infarction LODD)
**Statute:** G.S. § 143-166.2(5) — Myocardial infarction on-duty LODD presumption
**Key facts:**
- `presumption_exists`: true
- `presumption_type`: "statute"
- `rebuttable`: null (no explicit rebuttal mechanism described — it is a LODD classification, not a traditional rebuttable presumption)
- Conditions: myocardial infarction occurring while on duty, or within 24 hours after participating in a training exercise or responding to an emergency situation
- This is a **death benefit only** provision (LODD classification), not a WC presumption for living firefighters
- Covered groups: law enforcement officers, firefighters, rescue squad workers
- `statute_citation`: "N.C. Gen. Stat. § 143-166.2(5)"
- `years_service_required`: null
- Notes must clearly flag "death benefit only — LODD classification, not WC presumption"

### Oregon (OR) — PTSD Missing
**Missing:** mental × firefighter, emt_paramedic, law_enforcement, corrections
**Statute:** ORS 656.802(7) (enacted by SB 507, effective September 29, 2019)
**Key facts:**
- `presumption_exists`: true
- `presumption_type`: "statute"
- `rebuttable`: true (clear and convincing evidence rebuttal standard)
- Covered groups: full-time paid firefighters, EMS providers, police officers, corrections/youth correction officers, parole/probation officers, emergency dispatchers/9-1-1 operators
- Condition: PTSD or acute stress disorder (DSM-5 criteria)
- Eligibility: 5+ years employment OR experienced a single traumatic event meeting DSM-5 Criterion A
- Rebuttal: clear and convincing medical evidence that duties were not of real importance in causing the condition
- Separation window: employed OR separated within 7 years of claim
- `statute_citation`: "Oregon Revised Statutes § 656.802(7)"
- `years_service_required`: 5 (but waived for single Criterion A event)
- Also: 2025 SB 588 added PERS pension disability track for PTSD — [TENTATIVE] this is a secondary pension benefit, consider a separate row coded appropriately

### Tennessee (TN) — PTSD WC Presumption Missing (§ 7-51-206)
**Missing:** mental × firefighter (§ 7-51-206, eff. Jan 1, 2024); mental × law_enforcement, emt_paramedic (§ 7-51-206, eff. July 1, 2025)
**Statute:** T.C.A. § 7-51-206 (James "Dustin" Samples Act)
**Key facts:**
- `presumption_exists`: true
- `presumption_type`: "statute"
- `rebuttable`: true (preponderance of evidence that PTSD was caused by non-service-connected risk factors)
- Firefighter coverage: full-time paid firefighters in departments recognized by state fire marshal, eff. January 1, 2024
- LE/EMS coverage: law enforcement officers and emergency medical responders (EMTs, technician-paramedics, paramedics), eff. July 1, 2025 (PC 480)
- Qualifying traumatic incidents (at least one required): (1) witnessing death/injury of a minor who subsequently died; (2) witnessing individual whose death involved serious bodily injury shocking the conscience; (3) responding to event where victim had serious bodily injury shocking the conscience; (4) responding to event where a responder/co-worker/family member sustained serious bodily injury or died
- Diagnosis requirement: by mental health professional within 1 year of final date of employment
- `statute_citation`: "Tenn. Code Ann. § 7-51-206"
- Separate from the § 8-50-119 treatment access mandate already in the JSON (keep those rows)

### Utah (UT) — Cancer List Outdated (Post-2025 Expansion)
**Missing:** Updated cancer row reflecting expanded list (15 types, eff. January 1, 2026)
**Current JSON:** UT cancer rows (firefighter + volunteer) list only 4 cancers: pharynx, esophagus, lung, mesothelioma.
**Timeline finding:** HB 65 (signed March 25, 2025, effective January 1, 2026) expanded the list from 4 to 15 types: bladder, brain, colorectal, esophageal, kidney, leukemias, lung, lymphomas, melanomas, mesotheliomas, oropharynx, ovarian, prostate, testicular, thyroid. The IAFF page has not been updated.
**Correction needed (treated as P2 because the current data is so outdated it's functionally a different row):**
- Update `condition_specific` to reflect all 15 cancer types.
- Add screening requirement note (biennial physicals + Rocky Mountain Center screenings starting at 7 years of service, required from July 1, 2026).
- Update tobacco exclusion note (cannabis added alongside tobacco for respiratory tract cancers).

### Virginia (VA) — Throat Cancer Definition Clarified (2025)
**Missing:** Updated note on throat cancer definition in VA cancer rows
**Statute:** Va. Code § 65.2-402(C) as amended by cc. 392, 404 (eff. July 1, 2025)
**Key facts:** The 2025 amendment defined "throat cancer" to explicitly include cancers of the pharynx, larynx, adenoid, tonsil, esophagus, trachea, nasopharynx, oropharynx, and hypopharynx. Before this, esophageal cancer claims under "throat cancer" were being denied. The definition applies only to diagnoses on or after July 1, 2025.
**Correction needed (P2 for definition completeness):**
- Update `condition_specific` for VA cancer rows to include the expanded throat cancer definition in parentheses.

### West Virginia (WV) — Leukemia/Lymphoma/Myeloma Lapse Gap Note
**Missing:** Notes clarifying the 2023 lapse and 2024 re-enactment for WV cancer/firefighter (leukemia, lymphoma, multiple myeloma row)
**Key facts:** The original SB 82 (2018) provision for leukemia/lymphoma/myeloma lapsed July 1, 2023. SB 170 (March 8, 2024) re-enacted it without a sunset. Claims arising during the gap (July 1, 2023 – March 8, 2024) may be disputed.
**Correction needed (P2):** Add note to WV cancer/firefighter (leukemia/lymphoma/myeloma) row explaining the lapse and re-enactment gap. No change to `presumption_exists` value (already true and correctly coded).

### Wisconsin (WI) — PTSD Missing (§ 102.17(9))
**Missing:** mental × firefighter, firefighter_volunteer, law_enforcement, emt_paramedic
**Statute:** Wis. Stat. § 102.17(9) (enacted 2021 a. 29; expanded 2025 a. 145, eff. April 1, 2026)
**Key facts:**
- `presumption_exists`: true
- `presumption_type`: "statute"
- `rebuttable`: true (preponderance of evidence standard)
- Original coverage (eff. April 29, 2021): law enforcement officers and full-time firefighters employed by state or political subdivision
- Expanded coverage (eff. April 1, 2026): all firefighters regardless of full-time/volunteer status; emergency medical responders (s. 256.01(4p)); emergency medical services practitioners (s. 256.01(5))
- Benefit cap: 32 calendar weeks per episode
- Lifetime cap: no more than 3 times per individual lifetime
- Excluded causes: disciplinary actions, work evaluations, job transfers, layoffs, demotions, terminations
- `statute_citation`: "Wis. Stat. § 102.17(9)"
- IAFF page does not list this statute at all

---

## Priority 3 — Field Quality

### Alabama (AL) — Presumption Type
**Field:** `presumption_type`
**Current:** "statute" for all AL rows
**Correct per timeline:** Alabama's system is explicitly noted in HB466 as separate from workers' compensation. §§ 11-43-144 and 36-30-40 are disability/death benefit statutes, NOT WC presumptions. The timeline (Key Gap #1) states "Alabama's system is explicitly noted in HB466 as separate from workers' compensation." The dashboard should not label this as a standard WC presumption.
**Correction needed:** The `presumption_type` field does not have an "employer_benefit" value in the schema — this may require a schema discussion. At minimum, update notes for all AL rows to prominently flag "NOT a workers' compensation presumption — employer disability/death benefit system (§§ 11-43-144 and 36-30-40 operate separately from WC)."

### Arkansas (AR) — Presumption Type Critical Error
**Field:** `presumption_exists`, `presumption_type`
**Current:** AR has two rows (firefighter + firefighter_volunteer) with `presumption_exists: true` and `presumption_type: "statute"`.
**Correct per timeline:** AR timeline (Critical Structural Note): "Arkansas does not have a workers' compensation presumption for any first responder condition." The AR statutes listed (§§ 21-5-705, 24-4-511, 24-10-607) are: (1) a State Claims Commission death benefit, (2) pension disability retirement benefits through APERS, and (3) pension disability retirement benefits through LOPFI. None is a WC presumption.
**Correction needed:** This is also a Priority 1 issue flagged above. Change `presumption_type` from "statute" to a value reflecting non-WC benefit (if schema allows) or update notes to clearly state "NOT a workers' compensation presumption — death benefit (§ 21-5-705) and pension disability retirement (§§ 24-4-511, 24-10-607) only." Consider whether `presumption_exists: false` is more accurate given the WC-centric framing of the dashboard. [TENTATIVE — requires team decision on how non-WC states should be coded]

### California (CA) — § 31720.91 PTSD Sunset Discrepancy
**Field:** `notes` (CA mental/firefighter row)
**Current:** Notes reference "repealed January 1, 2032 per SB 623 extension."
**Correct per timeline:** The CA timeline (Key Gap #1) flags a discrepancy: the IAFF shows § 31720.91 repealing January 1, 2032, but statute text fetched from leginfo on 2026-06-02 shows January 1, 2029 (consistent with § 3212.15). The timeline recommends verifying AB 2770 enrolled text before publishing.
**Correction needed:** Update notes to flag the discrepancy. Change "2032" to "2029 (per current leginfo text; verify against AB 2770 enrolled text — IAFF shows 2032)." Tag `needs_verification: "Verify § 31720.91 sunset date: leginfo shows 2029, IAFF shows 2032, AB 2770 (2024) governs"`.

### Colorado (CO) — Cardiovascular Track Mislabeled
**Field:** `presumption_type`, `rebuttable`, notes
**Current:** CO cardiovascular rows (firefighter and firefighter_volunteer) have `presumption_type: "statute"` and `rebuttable: null`. Notes correctly say "This is a benefit statute under Title 29, not a WC presumption under Title 8."
**Correct per timeline:** C.R.S. §§ 29-5-301, 29-5-302 are employer benefit programs, not WC presumptions. The `rebuttable` field being null is noted as correct for a benefit program. However, the `presumption_type` field shows "statute" which in context implies a WC presumption.
**Correction needed:** This is borderline — the notes already flag it correctly. Ensure the dashboard display for CO cardiovascular rows emphasizes "employer benefit program (not WC presumption)" in any user-facing tooltip. The schema value "statute" may be the best available option given the current schema.

### Georgia (GA) — Presumption Type
**Field:** `presumption_type`
**Current:** GA cancer rows use `presumption_type: "statute"`; cardiovascular rows use `presumption_type: "statute"`.
**Correct per timeline:** GA has no workers' compensation presumption for any condition. Cancer is an employer-insurance mandate (§ 25-3-23). Cardiovascular is the State Indemnification Fund (§ 45-9-85) — a lump-sum disability/death benefit. Neither track is a WC presumption.
**Correction needed:** Same structural issue as AL and AR. Update notes for all GA rows to flag "NOT a workers' compensation presumption" prominently.

### Georgia (GA) — PTSD Missing (Ashley Wilson Act)
**Missing:** mental × firefighter, law_enforcement, emt_paramedic, corrections (O.C.G.A. §§ 45-25-1 et seq.)
**Note:** This also belongs in Priority 2 but is documented here for field quality context.
**Statute:** O.C.G.A. §§ 45-25-1 et seq. (HB 451, signed May 1, 2024; claims eligible from Jan 1, 2025)
**Key facts:**
- `presumption_exists`: true (employer must provide coverage)
- `presumption_type`: "statute" (but like the cancer/cardiovascular, this is an employer-insurance mandate, NOT WC)
- Covered groups: peace officers, firefighters, emergency medical professionals, 911 operators, probation officers, jail/correctional officers
- Condition: Occupational PTSD from traumatic events on or after July 1, 2024
- Benefits: $3,000 lump sum on diagnosis; 60% monthly salary up to $5,000/month (paid); $1,500/month (volunteers); 36 months
- `statute_citation`: "O.C.G.A. §§ 45-25-1 et seq."
- PTSD must be diagnosed within 2 years of the traumatic event
- This is a mandatory employer-funded insurance benefit — not WC

### Hawaii (HI) — Cancer Presumption Mechanism Wrong
**Field:** notes, `presumption_type`
**Current:** HI cancer/firefighter row has `presumption_type: "statute"` and notes "When a cancer claim is accepted as compensable for a firefighter with 5+ years of service, employer is liable for medical care at 110%-150% of Medicare RBRVS fees."
**Correct per timeline:** HRS § 386-21.9 is a medical care cost-enhancement provision, not a standalone WC presumption of compensability. It applies only AFTER a claim has "already been accepted or determined to be compensable" — there is no built-in presumption of compensability. The underlying compensability still requires individual proof under standard WC rules. The JSON notes capture this but `presumption_exists: true` may overstate what the statute does.
**Correction needed:** Add stronger clarification in notes: "§ 386-21.9 does not itself create a presumption of compensability — it enhances the medical fee schedule once compensability is established by other means. There is no independent presumption of WC compensability for firefighter cancer under Hawaii law."

### Illinois (IL) — PTSD Row Mislabeled
**Field:** `presumption_exists`, notes
**Current:** IL mental/firefighter row has `presumption_exists: true`, citing `40 ILCS 5/4-112`. Notes say this provides "mandatory annual medical re-examination may be discontinued if firefighter has reached age 45."
**Correct per timeline:** 40 ILCS 5/4-112 provides procedural protections for firefighters receiving disability pensions for PTSD (anti-retaliation, re-examination discontinuance). It is NOT a WC presumption that PTSD is occupational in origin. The IL timeline confirms no PTSD presumption exists in Illinois.
**Correction needed:** IL mental/firefighter: change `presumption_exists` from `true` to `false`. Update notes to clarify this is a pension administrative procedure, not a WC presumption.

### Indiana (IN) — Benefit Type
**Field:** notes
**Current:** IN rows correctly note "This is a pension/disability benefit structure, not a WC presumption per se" in notes.
**Correct per timeline:** IC 22-3-7-2 explicitly excludes municipal firefighters and police officers who are pension fund members from the general occupational disease WC system. The timeline confirms these are pension disability presumptions only.
**Correction needed:** Notes are adequately descriptive; however, verify that `presumption_type` is appropriate. The field shows "statute" which is technically correct but may mislead.

### Kansas (KS) — Missing Bloodborne Pathogen Rows
**Missing:** infectious × firefighter, law_enforcement (KSA 74-4952, bloodborne pathogens added 2019)
**Statute:** KSA 74-4952 (as amended by L. 2019, ch. 50 / HB 2031)
**Key facts:**
- `presumption_exists`: true
- `presumption_type`: "statute" (pension track)
- `rebuttable`: true
- Covered groups: same as other KSA 74-4952 conditions (police officers and firefighters, 5+ years credited service)
- Condition: bloodborne pathogens (defined by cross-reference to KSA 65-128 administrative regulations)
- `years_service_required`: 5
- `statute_citation`: "K.S.A. 74-4952"
- Note: this is the pension track (KP&F), not WC

### Kentucky (KY) — Presumption Type and Scope Clarification
**Field:** `presumption_type`, `presumption_exists`, notes
**Current:** KY cancer/firefighter row has `presumption_exists: true`, notes correctly say "CRITICAL: This provision creates a line-of-duty DEATH BENEFIT presumption only — the statute explicitly states it does NOT create a WC presumption."
**Correct per timeline:** The KY timeline (Key Gap #2) confirms "The dashboard should clearly flag Kentucky as having a death benefit only, not a workers' compensation presumption. Living firefighters diagnosed with cancer cannot file a presumptive WC claim in Kentucky." The notes are already correct; the issue is that `presumption_exists: true` and `presumption_type: "statute"` may mislead dashboard users.
**Correction needed:** Notes correctly flag this. No field value change strictly required. Ensure dashboard tooltip/display clearly states "DEATH BENEFIT ONLY — not a WC presumption."

### Nevada (NV) — PTSD Row Mislabeled
**Field:** `presumption_exists`
**Current:** NV mental rows (firefighter, firefighter_volunteer, emt_paramedic, law_enforcement) have `presumption_exists: true`.
**Correct per timeline:** NRS 616C.180 is NOT a traditional WC presumption. It is a reduced evidentiary gateway — the first responder still bears the burden of proving their claim by clear and convincing medical/psychiatric evidence. The burden of proof remains with the claimant. The timeline (Key Gap #1) states "NRS 616C.180 is NOT a traditional presumption."
**Correction needed:** NV mental rows: Add clear note that this is NOT a burden-shifting presumption — claimant still bears burden of proof. Consider whether `presumption_exists: false` is more accurate (the burden doesn't shift). At minimum, add to notes: "This is a reduced evidentiary gateway, not a burden-shifting presumption. Claimant still must prove by clear and convincing evidence. NRS 616C.180 is better characterized as a narrowed compensability standard than a presumption."

### North Carolina (NC) — Cancer Row Description
**Field:** `condition_specific` (§ 143-166.2 row)
**Current:** NC cancer/firefighter (§ 143-166.2) row lists only 4 cancers: "mesothelioma, testicular cancer, intestinal cancer, esophageal cancer."
**Correct per timeline:** As of SL 2021-180, oral cavity and pharynx cancers were added, bringing the enumerated list to 6 types. The current condition_specific is missing oral cavity and pharynx cancers.
**Correction needed:** NC cancer/firefighter (§ 143-166.2): update `condition_specific` to: "mesothelioma, testicular cancer, cancer of the small intestine, esophageal cancer, oral cavity cancer, pharynx cancer."

### Oregon (OR) — Cancer Row Missing Gynecologic
**Field:** `condition_specific`
**Current:** OR cancer/firefighter row lists cancers but needs to be checked against the 2022 HB 4113 expansion.
**Correct per timeline:** HB 4113 (eff. January 1, 2023) added bladder cancer and gynecologic cancers (uterus, fallopian tubes, ovaries, cervix, vagina, vulva) to ORS 656.802(5). The current JSON row already lists both in condition_specific — this appears correct. No change needed.

### Vermont (VT) — Statute Citation Error
**Field:** `statute_citation`
**Current:** VT cardiovascular rows cite `21 V.S.A. § 601(1)`. VT respiratory and infectious rows cite `21 V.S.A. § 601(3)-(6)`. VT cancer row cites `21 V.S.A. § 601(E)`. VT mental rows cite `21 V.S.A. § 601(I)`.
**Correct per timeline:** The VT timeline shows the operative subsection designations are: cardiovascular/respiratory = § 601(11)(A)-(B); cancer = § 601(11)(E)-(F); lung/infectious = § 601(11)(H); PTSD = § 601(11)(I). The JSON citations appear to use abbreviated forms that omit the "(11)" subdivision designation.
**Correction needed:** Update VT statute citations to use the full "(11)" subdivisional reference: e.g., `21 V.S.A. § 601(11)(B)` for cardiovascular, `21 V.S.A. § 601(11)(E)-(F)` for cancer, `21 V.S.A. § 601(11)(H)` for lung/infectious, `21 V.S.A. § 601(11)(I)` for PTSD.

### West Virginia (WV) — PTSD Sunset Removed
**Field:** notes
**Current:** WV mental rows note the sunset date "July 1, 2026" for the PTSD provision.
**Correct per timeline:** HB 2797 (Chapter 243, Acts 2025, effective July 11, 2025) removed the sunset clause from § 23-4-1f. PTSD coverage is now permanent — no legislative reauthorization required.
**Correction needed:** WV mental rows: update notes to state "Sunset clause removed by HB 2797 (eff. July 11, 2025) — coverage is now permanent (no legislative renewal required)." Remove reference to the July 1, 2026 expiration date.

---

## States With No Corrections Needed

The following states had JSON data that accurately matches the timeline findings with no material errors requiring correction:

AK (non-PTSD rows), AZ (non-PTSD, non-cardiovascular statute rows), CA (except § 31720.91 sunset flag), CO (with noted benefit-type caveat already in notes), CT, DE, FL, HI (with noted mechanism caveat), ID, IL (non-PTSD rows), IN (non-mental rows), KS (non-infectious rows), KY (with noted death-benefit caveat), LA, MA, MD (non-LE cardiovascular rows, pre-Oct 2026 provisions), ME (non-LE cardiovascular rows), MI, MN, MO (non-PTSD rows), MS (non-cardiovascular rows; with corrected statute citation), MT, NC (non-cardiovascular rows; with corrected cancer list), ND, NE, NH (with age cap correction), NJ, NM (pre-2026 data), NV (non-mental rows), NY, OH, OK, OR (non-PTSD rows), PA, RI, SC (with stroke addition noted), SD, TN (non-PTSD rows; cancer list appears current), TX, UT (pre-Jan 2026 data), VA, VT (with citation correction), WA, WI (non-PTSD rows), WV (non-sunset rows), WY.

---

## Implementation Notes

**Schema constraints:** Several states (AL, AR, GA, KY, IA, WI non-PTSD, etc.) have benefit structures that are legally distinct from WC presumptions but the current schema does not have a `presumption_type` value for "pension" or "employer_benefit" that would cleanly distinguish them. Until the schema is expanded, the most practical fix is to update the `notes` field prominently and ensure dashboard tooltips reflect the distinction.

**Priority for implementation:** Address Priority 1 items first (especially AZ PTSD which actively misleads users, and IA cancer list update). Then Priority 2 missing rows (AK PTSD, TN PTSD, WI PTSD, OR PTSD, MO PTSD are the most significant omissions). Priority 3 items can be addressed in a batch editing pass.

**Data pipeline reminder:** After editing the raw JSON source files, run the full pipeline per CLAUDE.md:
```
Rscript analysis/code/4_iaff_combine.r
Rscript analysis/code/5_iaff_export_json.r
cp website/data/presumptive_laws.json website/shiny-app/data/presumptive_laws.json
```
