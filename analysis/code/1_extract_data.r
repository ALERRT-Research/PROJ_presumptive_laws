# Project: PROJ_presumptive_laws
# Script:  1_extract_data.r
# Purpose: Hand-coded extraction of state-level presumptive WC law data from
#          two published reviews. Produces master dataset + JSON for Shinylive.
#
# Sources:
#   A) Brandt-Rauf et al. (2024), J Public Health Policy 45:562-574
#      Table 1 Part A + supplemental file (41271_2024_501_MOESM1_ESM.docx)
#      50-state x 6-condition grid; data current through December 2022
#
#   B) NCCI (2023) Research Brief, summary chart p.15
#      ~38 NCCI-jurisdiction states; responder group detail
#      Data current through November 2022
#
# Published totals (Brandt-Rauf Table 1 Part A — checksums):
#   Cancer: 44 | CV: 41 | Respiratory: 39 | Infectious: 28 | COVID: 23 | Mental: 9
#
# NOTE on scope: Brandt-Rauf includes non-WC presumptions (retirement/pension
# funds, death benefits, cancer funds) when accessible to first responders.
# Several states' presumptions operate outside the WC system (IA, KS, MA, MO
# for most conditions; AR, MS, NC for cancer; HI for CV/respiratory).
# These are coded as "statute" with a note in the citation field.
#
# Coding convention:
#   "statute"  = active statutory presumption (WC or equivalent benefit program)
#   "EO"       = presumption by Executive Order only
#   "expired"  = statute or EO existed but lapsed before/during study period
#   "none"     = no presumption found in source

source(here::here("analysis", "code", "0_setup.r"))


# =============================================================================
# BLOCK A: Condition-level presence/absence (Brandt-Rauf 2024 + supplement)
# =============================================================================

brandrauf_wide <- tribble(
  ~state, ~cancer,    ~cardiovascular, ~respiratory, ~infectious, ~covid19,    ~mental,
  "AL",   "statute",  "statute",       "statute",    "statute",   "none",      "none",
  "AK",   "statute",  "statute",       "statute",    "statute",   "none",      "none",
  "AZ",   "statute",  "statute",       "statute",    "none",      "EO",        "none",
  "AR",   "statute",  "none",          "none",       "none",      "expired",   "none",
  "CA",   "statute",  "statute",       "statute",    "statute",   "statute",   "statute",
  "CO",   "statute",  "none",          "none",       "statute",   "EO",        "none",
  "CT",   "statute",  "statute",       "none",       "none",      "none",      "statute",
  "DE",   "statute",  "none",          "none",       "none",      "none",      "none",
  "FL",   "statute",  "statute",       "statute",    "statute",   "none",      "statute",
  "GA",   "none",     "none",          "none",       "none",      "none",      "none",
  "HI",   "none",     "statute",       "statute",    "none",      "none",      "none",
  "ID",   "statute",  "none",          "none",       "none",      "none",      "none",
  "IL",   "statute",  "statute",       "statute",    "statute",   "statute",   "none",
  "IN",   "statute",  "statute",       "statute",    "statute",   "statute",   "none",
  "IA",   "statute",  "statute",       "statute",    "statute",   "none",      "none",
  "KS",   "statute",  "statute",       "statute",    "none",      "EO",        "none",
  "KY",   "statute",  "statute",       "statute",    "statute",   "EO",        "none",
  "LA",   "statute",  "statute",       "statute",    "statute",   "none",      "statute",
  "ME",   "statute",  "statute",       "statute",    "statute",   "none",      "none",
  "MD",   "statute",  "statute",       "statute",    "none",      "none",      "none",
  "MA",   "statute",  "statute",       "statute",    "none",      "EO",        "none",
  "MI",   "statute",  "statute",       "statute",    "none",      "none",      "none",
  "MN",   "statute",  "statute",       "statute",    "statute",   "statute",   "statute",
  "MS",   "none",     "none",          "none",       "none",      "none",      "none",
  "MO",   "statute",  "statute",       "statute",    "none",      "expired",   "none",
  "MT",   "statute",  "statute",       "statute",    "none",      "none",      "none",
  "NE",   "statute",  "statute",       "statute",    "statute",   "none",      "none",
  "NV",   "statute",  "statute",       "statute",    "statute",   "none",      "none",
  "NH",   "statute",  "statute",       "statute",    "none",      "EO",        "none",
  "NJ",   "statute",  "statute",       "statute",    "none",      "EO",        "none",
  "NM",   "statute",  "statute",       "statute",    "statute",   "EO",        "none",
  "NY",   "statute",  "statute",       "statute",    "statute",   "statute",   "none",
  "NC",   "none",     "none",          "none",       "none",      "none",      "none",
  "ND",   "statute",  "statute",       "statute",    "statute",   "none",      "none",
  "OH",   "statute",  "statute",       "statute",    "statute",   "none",      "none",
  "OK",   "statute",  "statute",       "statute",    "statute",   "none",      "none",
  "OR",   "statute",  "statute",       "statute",    "none",      "EO",        "statute",
  "PA",   "statute",  "statute",       "statute",    "statute",   "EO",        "none",
  "RI",   "statute",  "none",          "none",       "statute",   "none",      "none",
  "SC",   "none",     "statute",       "statute",    "none",      "none",      "none",
  "SD",   "none",     "statute",       "statute",    "none",      "none",      "none",
  "TN",   "statute",  "statute",       "statute",    "statute",   "statute",   "none",
  "TX",   "statute",  "statute",       "statute",    "statute",   "none",      "statute",
  "UT",   "statute",  "none",          "none",       "statute",   "statute",   "none",
  "VT",   "statute",  "statute",       "statute",    "statute",   "statute",   "statute",
  "VA",   "statute",  "statute",       "statute",    "statute",   "statute",   "none",
  "WA",   "statute",  "statute",       "statute",    "statute",   "EO",        "statute",
  "WV",   "statute",  "statute",       "statute",    "none",      "none",      "none",
  "WI",   "statute",  "statute",       "statute",    "statute",   "statute",   "none",
  "WY",   "statute",  "statute",       "none",       "none",      "expired",   "none"
)

# Pivot to long format
brandrauf_long <- brandrauf_wide |>
  pivot_longer(
    cols      = cancer:mental,
    names_to  = "condition",
    values_to = "presumption_type"
  ) |>
  mutate(
    presumption_exists   = presumption_type %in% c("statute", "EO"),
    source               = "BrandtRauf_2024",
    data_current_through = "2022-12"
  )


# =============================================================================
# VERIFICATION CHECKSUMS
# =============================================================================

published_totals <- c(
  cancer = 44, cardiovascular = 41, respiratory = 39,
  infectious = 28, covid19 = 23, mental = 9
)

coded_totals <- brandrauf_wide |>
  summarise(across(cancer:mental, ~ sum(. %in% c("statute", "EO"), na.rm = TRUE)))

cat("\n=== VERIFICATION: Coded vs Published Totals ===\n")
comparison <- bind_rows(
  coded     = coded_totals,
  published = as_tibble(t(published_totals))
) |>
  mutate(source = c("coded", "published")) |>
  relocate(source)
print(comparison)

discrepancies <- names(published_totals)[as.integer(coded_totals) != published_totals]
if (length(discrepancies) == 0) {
  cat("\nAll column totals match published figures.\n")
} else {
  cat("\nRemaining discrepancies:", paste(discrepancies, collapse = ", "), "\n")
}


# =============================================================================
# BLOCK B: Statute citations (from supplement + NCCI)
# =============================================================================

citations <- tribble(
  ~state, ~condition,      ~citation,                                                           ~notes,
  "AL",   "cancer",        "AL ST § 11-43-144 (2023)",                                          NA,
  "AL",   "cardiovascular","AL ST § 11-43-144 (2023)",                                          "Includes hypertension, heart disease",
  "AL",   "respiratory",   "AL ST § 11-43-144 (2023)",                                          NA,
  "AL",   "infectious",    "AL ST § 11-43-144 (2023)",                                          "Covers AIDS, hepatitis",
  "AK",   "cancer",        "AK ST § 23-30-121 (2023)",                                          "Certain cancers",
  "AK",   "cardiovascular","AK ST § 23-30-121 (2023)",                                          "Cardiovascular events",
  "AK",   "respiratory",   "AK ST § 23-30-121 (2023)",                                          "Respiratory disease",
  "AZ",   "cancer",        "AZ ST § 23-901.09 & 23-1105 (2023)",                               "Certain cancers",
  "AZ",   "cardiovascular","AZ ST § 23-901.09 & 23-1105 (2023)",                               "Cardiac",
  "AZ",   "respiratory",   "AZ ST § 23-901.09 & 23-1105 (2023)",                               "Pulmonary",
  "AZ",   "covid19",       "Governor Executive Order",                                           "EO only",
  "AR",   "covid19",       "Act 353 (H.B. 1488, 93rd Gen. Assembly) 2021",                     "Expired 5/1/2023",
  "CA",   "cancer",        "CA LABOR § 3212.1 (2023)",                                          NA,
  "CA",   "cardiovascular","CA LABOR § 3212 (2023)",                                            "Heart trouble presumption for peace officers and firefighters",
  "CA",   "respiratory",   "CA LABOR § 3212.8, 3212.9 (2023)",                                 "Pneumonia, tuberculosis",
  "CA",   "infectious",    "CA LABOR § 3212.5 (2023)",                                          "Blood-borne infectious disease",
  "CA",   "covid19",       "CA LAB § 3212.87 (2023)",                                           "Expired 1/1/2024; active as of Dec 2022",
  "CA",   "mental",        "CA LABOR § 3212.15 (2023)",                                         "PTSD",
  "CO",   "cancer",        "CO ST § 8-41-209 (2023)",                                           NA,
  "CO",   "infectious",    "CO ST § 8-41-208 (2023)",                                           "Hepatitis C",
  "CO",   "covid19",       "Governor Executive Order",                                           "EO only",
  "CT",   "cancer",        "CT ST §§ 31-294i–31-294j (2023)",                                   "Scope contested; includes lymphoma and certain cancers",
  "CT",   "cardiovascular","CT ST §§ 31-294i–31-294j (2023)",                                   "Cardiac",
  "CT",   "mental",        "CT ST Sec. 31-294k(a)(2) (2023)",                                   "Qualifying events required; lists 6 specific traumatic events",
  "DE",   "cancer",        "DE ST Title 18 §§ 6701 & 6701B (2023)",                            "No proof of causation required; line of duty disability fund",
  "FL",   "cancer",        "FL ST § 112.1816 (2023)",                                           "Alternative to WC for certain cancers",
  "FL",   "cardiovascular","FL ST § 112.18 (2023)",                                             "Heart disease, hypertension, tuberculosis",
  "FL",   "respiratory",   "FL ST § 112.18 (2023)",                                             "Tuberculosis",
  "FL",   "infectious",    "FL ST § 112.181 (2023)",                                            "Hepatitis, meningococcal meningitis, TB",
  "FL",   "mental",        "FL ST § 112.1815 (2023)",                                           "PTSD; qualifying events specified",
  "HI",   "cardiovascular","HI ST § 88-79 (2023)",                                              "Service-connected disability retirement (not WC)",
  "HI",   "respiratory",   "HI ST § 88-79 (2023)",                                              "Service-connected disability retirement (not WC)",
  "ID",   "cancer",        "ID ST § 72-438 (2023)",                                             "Certain listed cancers",
  "IL",   "cancer",        "IL ST CH 820 § 310/1 (2023)",                                       NA,
  "IL",   "cardiovascular","IL ST CH 820 § 310/1 (2023)",                                       "Heart or vascular disease, hypertension",
  "IL",   "respiratory",   "IL ST CH 820 § 310/1 (2023)",                                       "Lung or respiratory disease, TB",
  "IL",   "infectious",    "IL ST CH 820 § 310/1 (2023)",                                       "Blood-borne pathogen",
  "IL",   "covid19",       "IL ST CH 820 § 310/1(g) (2023)",                                    "Statutory; active as of Dec 2022",
  "IN",   "cancer",        "IN ST § 5-10-15-9 (2023)",                                          "Certain cancers",
  "IN",   "cardiovascular","IN ST § 5-10-15-9 (2023)",                                          "Heart disease",
  "IN",   "respiratory",   "IN ST § 5-10-15-9 (2023)",                                          "Lung disease",
  "IN",   "infectious",    "IN ST § 5-10-13-5 (2023)",                                          "Infectious diseases including COVID",
  "IN",   "covid19",       "IN ST § 5-10-13-5 (2023)",                                          "Covered under infectious disease statute",
  "IA",   "cancer",        "IA ST § 411.6 (2023)",                                              "Retirement benefits system (not WC)",
  "IA",   "cardiovascular","IA ST § 411.6 (2023)",                                              "Retirement benefits system (not WC); heart disease",
  "IA",   "respiratory",   "IA ST § 411.6 (2023)",                                              "Retirement benefits system (not WC); lung, respiratory",
  "KS",   "cancer",        "KS ST § 74-4952 (2023)",                                            "Retirement system (not WC)",
  "KS",   "cardiovascular","KS ST § 74-4952 (2023)",                                            "Retirement system (not WC); heart",
  "KS",   "respiratory",   "KS ST § 74-4952 (2023)",                                            "Retirement system (not WC); lung",
  "KS",   "covid19",       "Governor Executive Order",                                           "EO only",
  "KY",   "cancer",        "KY ST § 61.315 (2023)",                                             "Death benefits for cancer",
  "KY",   "cardiovascular","KY ST § 61.315 (2023)",                                             NA,
  "KY",   "respiratory",   "KY ST § 61.315 (2023)",                                             NA,
  "KY",   "infectious",    "KY ST § 61.315 (2023)",                                             NA,
  "KY",   "covid19",       "Executive Order 2020-277 (2020)",                                   "EO only",
  "LA",   "cancer",        "LA RS 33:2011 (2023)",                                              NA,
  "LA",   "cardiovascular","LA RS 33:2011 (2023)",                                              NA,
  "LA",   "respiratory",   "LA RS 33:2581 (2023)",                                              "Lung disease, hearing loss",
  "LA",   "infectious",    "LA RS 33:1948 (2023)",                                              "Hepatitis B and C",
  "LA",   "mental",        "LA RS 33:2581.2 (2023)",                                            "PTSD",
  "ME",   "cancer",        "ME ST T. 39A § 328B (2023)",                                        "Certain cancers",
  "ME",   "cardiovascular","ME ST T. 39A § 328 (2023)",                                         "Heart",
  "ME",   "respiratory",   "ME ST T. 39A § 328 (2023)",                                         "Lung",
  "ME",   "infectious",    "ME ST T. 39A § 328A (2023)",                                        "Hepatitis, meningococcal meningitis, TB",
  "ME",   "mental",        "ME ST T. 39A § 201(3-A) (2023)",                                    "PTSD",
  "MD",   "cancer",        "MD Labor and Employment Code Ann. § 9-503 (2023)",                  "Some cancers",
  "MD",   "cardiovascular","MD Labor and Employment Code Ann. § 9-503 (2023)",                  "Heart, hypertension",
  "MD",   "respiratory",   "MD Labor and Employment Code Ann. § 9-503 (2023)",                  "Lung disease",
  "MA",   "cancer",        "MA ST § 94B (2023)",                                                "Retirement/pension system (not WC)",
  "MA",   "cardiovascular","MA ST § 94 (2023)",                                                 "Retirement/pension; hypertension, heart disease",
  "MA",   "respiratory",   "MA ST § 94A (2023)",                                                "Retirement/pension; respiratory disease",
  "MA",   "covid19",       "Governor Executive Order",                                           "EO only",
  "MI",   "cancer",        "MI ST 418.405 (2023)",                                              "Presumed coverage fund",
  "MI",   "cardiovascular","MI ST 418.405 (2023)",                                              "Heart disease; presumed coverage fund",
  "MI",   "respiratory",   "MI ST 418.405 (2023)",                                              "Respiratory disease; presumed coverage fund",
  "MN",   "cancer",        "MN ST § 176.011 (2023)",                                            NA,
  "MN",   "cardiovascular","MN ST § 176.011 (2023)",                                            "Myocarditis, coronary sclerosis",
  "MN",   "respiratory",   "MN ST § 176.011 (2023)",                                            "Pneumonia",
  "MN",   "infectious",    "MN ST § 176.011 (2023)",                                            "Infectious disease",
  "MN",   "covid19",       "MN ST § 176.011 (2023)",                                            "Statutory",
  "MN",   "mental",        "MN ST § 176.011 (2023)",                                            "Mental impairment",
  "MO",   "cancer",        "MO ST § 87.006 (2023)",                                             "Retirement benefits only (not WC)",
  "MO",   "cardiovascular","MO ST § 87.006 (2023)",                                             "Retirement benefits; cardiac, hypertension",
  "MO",   "respiratory",   "MO ST § 87.006 (2023)",                                             "Retirement benefits; lung disease",
  "MO",   "covid19",       "MO ST § 87.006 (2023)",                                             "Covered under retirement statute; expired",
  "MT",   "cancer",        "MT ST § 39-71-1401 (2023)",                                         "Certain cancers",
  "MT",   "cardiovascular","MT ST § 39-71-1401 (2023)",                                         "Myocardial infarction",
  "MT",   "respiratory",   "MT ST § 39-71-1401 (2023)",                                         NA,
  "NE",   "cancer",        "NE ST § 35-1001 (2023)",                                            NA,
  "NE",   "cardiovascular","NE ST § 35-1001 (2023)",                                            NA,
  "NE",   "respiratory",   "NE ST § 35-1001 (2023)",                                            NA,
  "NE",   "infectious",    "NE ST § 35-1001 (2023)",                                            "Blood-borne diseases, TB, meningococcal meningitis, MRSA",
  "NV",   "cancer",        "NV ST § 617.453 (2023)",                                            NA,
  "NV",   "cardiovascular","NV ST § 617.457 (2023)",                                            "Heart disease",
  "NV",   "respiratory",   "NV ST § 617.455 (2023)",                                            "Lung disease",
  "NV",   "infectious",    "NV ST §§ 617.481, 617.485 (2023)",                                 "Infectious disease, hepatitis",
  "NH",   "cancer",        "NH ST § 281A-17 (2023)",                                            NA,
  "NH",   "cardiovascular","NH ST § 281A-17 (2023)",                                            "Heart disease",
  "NH",   "respiratory",   "NH ST § 281A-17 (2023)",                                            "Lung disease",
  "NJ",   "cancer",        "NJ ST § 34:15-7.3 (2023)",                                          NA,
  "NJ",   "cardiovascular","NJ ST § 34:15-7.3 (2023)",                                          "Cardiovascular, cerebrovascular",
  "NJ",   "respiratory",   "NJ ST § 34:15-43.2 (2023)",                                         "Respiratory disease; volunteers covered",
  "NJ",   "covid19",       "NJ ST § 34:15-31.12 (2023)",                                        "EO basis",
  "NM",   "cancer",        "NM ST § 52-3-32.1 (2023)",                                          "Cancer, hepatitis, TB, diphtheria, meningococcal, MRSA",
  "NM",   "cardiovascular","NM ST § 52-3-32.1 (2023)",                                          NA,
  "NM",   "respiratory",   "NM ST § 52-3-32.1 (2023)",                                          "TB",
  "NM",   "infectious",    "NM ST § 52-3-32.1 (2023)",                                          "Hepatitis, TB, diphtheria, meningococcal, MRSA; EO basis",
  "NM",   "covid19",       "2020 NM Executive Order 20-025",                                     "EO; active through March 2023",
  "NM",   "mental",        "NMSA § 52-3-32.1(B)(13) (2023)",                                    "PTSD",
  "NY",   "cancer",        "NY Gen Mun Laws § 207-k, kk, kkk (2023)",                          NA,
  "NY",   "cardiovascular","NY Gen Mun Laws § 207-k, q (2023)",                                 "Heart disease, stroke",
  "NY",   "respiratory",   "NY Gen Mun Laws § 207-k; RET & SS § 363-F (2023)",                 "Lung disease, Parkinson's",
  "NY",   "infectious",    "NY Gen Mun Laws § 207-p (2023)",                                    "HIV, TB, hepatitis",
  "NY",   "covid19",       "NY RET & SS § 361(b) (2023)",                                       "Death benefit only",
  "ND",   "cancer",        "ND ST § 65-01-15.1, 15.2 (2023)",                                   NA,
  "ND",   "cardiovascular","ND ST § 65-01-15.1, 15.2 (2023)",                                   "Heart disease, hypertension",
  "ND",   "respiratory",   "ND ST § 65-01-15.1, 15.2 (2023)",                                   "Respiratory disease",
  "ND",   "infectious",    "ND ST § 65-01-15.1, 15.2 (2023)",                                   "Blood-borne pathogens",
  "OH",   "cancer",        "OH ST § 4123.68(w) & (x) (2023)",                                   NA,
  "OH",   "cardiovascular","OH ST § 4123.68(w) & (x) (2023)",                                   "Cardiovascular, heart",
  "OH",   "respiratory",   "OH ST § 4123.68(w) & (x) (2023)",                                   "Pulmonary, respiratory",
  "OH",   "infectious",    "OH ST § 4123.68(w) & (x) (2023)",                                   "Blood-borne disease",
  "OK",   "cancer",        "OK ST T. 11 § 49-110 (2023)",                                       NA,
  "OK",   "cardiovascular","OK ST T. 11 § 49-110 (2023)",                                       "Heart disease",
  "OK",   "respiratory",   "OK ST T. 11 § 49-110 (2023)",                                       "Respiratory disease",
  "OK",   "infectious",    "OK ST T. 11 § 49-110 (2023)",                                       "Infectious disease",
  "OR",   "cancer",        "OR ST § 656.802(4) & (5) (2023)",                                   "14 listed cancer types; 5+ years employment required",
  "OR",   "cardiovascular","OR ST § 656.802(4) & (5) (2023)",                                   "Cardiovascular-renal disease, hypertension",
  "OR",   "respiratory",   "OR ST § 656.802(4) & (5) (2023)",                                   "Lung disease",
  "OR",   "mental",        "OR ST § 656.802(b) (2023)",                                         "PTSD as occupational disease",
  "PA",   "cancer",        "PA ST 77 P.S. § 1208 (2023)",                                       "Cancer, occupational disease",
  "PA",   "cardiovascular","PA ST 77 P.S. § 1208 (2023)",                                       NA,
  "PA",   "respiratory",   "PA ST 77 P.S. § 1208 (2023)",                                       NA,
  "PA",   "infectious",    "PA ST 77 P.S. § 1208 (2023)",                                       NA,
  "RI",   "cancer",        "RI ST § 45-19-1-2, 45-19.1-3, 45-19.1-4 (2023)",                  "Conclusive (irrebuttable) presumption",
  "RI",   "infectious",    "RI Gen. Laws §§ 23-28.36-4, 28.37-1 (2023)",                       "Infectious disease",
  "SC",   "cardiovascular","SC Code § 42-11-30 (2023)",                                         "Heart or respiratory disease proximate to fighting a fire",
  "SC",   "respiratory",   "SC Code § 42-11-30 (2023)",                                         "Respiratory disease proximate to fighting a fire",
  "SD",   "cardiovascular","SD LR § 9-16-45 (2023)",                                            "Heart disease, hypertension; possibly pension-based",
  "SD",   "respiratory",   "SD LR § 9-16-45 (2023)",                                            "Respiratory disease; possibly pension-based",
  "TN",   "cancer",        "Tenn. Code Ann. § 7-51-201 (2023)",                                 NA,
  "TN",   "cardiovascular","Tenn. Code Ann. § 7-51-201 (2023)",                                 "Lung or heart disease (non-WC compensation)",
  "TN",   "respiratory",   "Tenn. Code Ann. § 7-51-201 (2023)",                                 "Lung or heart disease (non-WC compensation)",
  "TN",   "infectious",    "Tenn. Code Ann. § 7-51-209 (2023)",                                 "Infectious disease",
  "TN",   "covid19",       "Tenn. Code Ann. § 7-51-209 (2023)",                                 "Covered under infectious disease statute",
  "TX",   "cancer",        "TX GOVT § 607.055 (2023)",                                          NA,
  "TX",   "cardiovascular","TX GOVT § 607.056 (2023)",                                          "Myocardial infarction, stroke",
  "TX",   "respiratory",   "TX GOVT § 607.054 (2023)",                                          "TB or other lung disease",
  "TX",   "infectious",    "TX GOVT §§ 607.057, 607.058 (2023)",                               "Infectious disease",
  "TX",   "mental",        "TX Labor § 504.019 (2023)",                                         "PTSD for first responders",
  "UT",   "cancer",        "UT ST § 34A-3-113 (2023)",                                          NA,
  "UT",   "cardiovascular","UT ST § 34A-2-901 (2023)",                                          NA,
  "UT",   "infectious",    "UT ST § 34A-2-901 (2023) & § 78B-8-401 (2023)",                   "Infectious diseases including COVID",
  "UT",   "covid19",       "UT ST § 34A-3-202 (2023) & § 78B-8-401 (2023)",                   "Statutory",
  "VT",   "cancer",        "VT ST T.21 § 601 (2023)",                                           NA,
  "VT",   "cardiovascular","VT ST T.21 § 601 (2023)",                                           "Heart injury or disease within 72 hours of service",
  "VT",   "respiratory",   "VT ST T.21 § 601 (2023)",                                           "Lung disease",
  "VT",   "infectious",    "VT ST T.21 § 601 (2023)",                                           "Infectious disease",
  "VT",   "covid19",       "VT ST T.21 § 601 (2023)",                                           "Statutory",
  "VT",   "mental",        "VT ST T.21 § 601 (2023)",                                           "PTSD",
  "VA",   "cancer",        "VA ST § 65.2-402 (2023)",                                           NA,
  "VA",   "cardiovascular","VA ST § 65.2-402 (2023)",                                           "Heart disease, hypertension",
  "VA",   "respiratory",   "VA ST § 65.2-402 (2023)",                                           "Respiratory disease",
  "VA",   "infectious",    "VA ST § 65.2-402.1 (2023)",                                         "Hepatitis, meningococcal meningitis, TB, HIV",
  "VA",   "covid19",       "VA ST § 65.2-402.1 (2023)",                                         "Statutory",
  "WA",   "cancer",        "WA ST § 51.32.185 (2023)",                                          NA,
  "WA",   "cardiovascular","WA ST § 51.32.185 (2023)",                                          "Heart problems within 72 hours of firefighting",
  "WA",   "respiratory",   "WA ST § 51.32.185 (2023)",                                          "Respiratory diseases",
  "WA",   "infectious",    "WA ST § 51.32.185 (2023)",                                          "Infectious disease",
  "WA",   "covid19",       "Governor Inslee Executive Order (2020)",                             "EO; quarantined first responders",
  "WA",   "mental",        "WA ST § 51.32.185 (2023)",                                          "PTSD",
  "WV",   "cancer",        "WV ST § 23-4-1 (2023)",                                             NA,
  "WV",   "cardiovascular","WV ST § 23-4-1 (2023)",                                             "Cardiovascular or pulmonary disease",
  "WV",   "respiratory",   "WV ST § 23-4-1 (2023)",                                             "Pulmonary disease",
  "WI",   "cancer",        "WI ST § 891.455 (2023)",                                            "Death or disability benefits, pension",
  "WI",   "cardiovascular","WI ST § 891.45 (2023)",                                             "Heart or respiratory impairment",
  "WI",   "respiratory",   "WI ST § 891.45 (2023)",                                             "Respiratory impairment",
  "WI",   "infectious",    "WI ST § 891.453 (2023)",                                            "Infectious disease",
  "WI",   "covid19",       "WI ST §§ 891.453, 102.03(6)(b) (2023)",                            "Statutory",
  "WY",   "cancer",        "WY ST §§ 27-15-101 & 102 (2023)",                                  NA,
  "WY",   "cardiovascular","WY ST §§ 27-15-101 & 102 (2023)",                                  "Cardiovascular disease, myocardial infarction, stroke",
  "WY",   "covid19",       "WY ST § 27-14-102 (2023)",                                          "Expired 3/31/2022",
  # IAFF 2024 supplementary entries (citation TBD)
  "ID",   "cardiovascular", NA,                                                                   "IAFF 2024: statute (citation TBD)",
  "ID",   "respiratory",    NA,                                                                   "IAFF 2024: statute (citation TBD)",
  "ID",   "infectious",     NA,                                                                   "AIDS, ARC, HIV, hepatitis, TB; IAFF 2024 (citation TBD)",
  "MO",   "infectious",     NA,                                                                   "HIV/AIDS, TB, Hepatitis A-D; retirement system; IAFF 2024",
  "CO",   "cardiovascular", NA,                                                                   "IAFF 2024: statute (citation TBD)",
  "CO",   "respiratory",    NA,                                                                   "IAFF 2024: statute (citation TBD)",
  "WY",   "respiratory",    NA,                                                                   "IAFF 2024: statute (citation TBD)"
)


# =============================================================================
# BLOCK C: NCCI responder group detail (~38 NCCI-jurisdiction states, p.15)
# =============================================================================

ncci_raw <- tribble(
  ~state, ~condition,      ~groups,
  "AK",   "cancer",        "fire",
  "AK",   "respiratory",   "fire",
  "AK",   "cardiovascular","fire",
  "AZ",   "cancer",        "fire;police",
  "AZ",   "respiratory",   "fire;police",
  "AZ",   "cardiovascular","fire",
  "CO",   "cancer",        "fire",
  "CO",   "infectious",    "fire;police;ems",
  "CT",   "cardiovascular","fire;police",
  "FL",   "cancer",        "fire;police;ems;corr",
  "FL",   "respiratory",   "fire;police;ems;corr",
  "FL",   "infectious",    "fire;police;ems",
  "FL",   "cardiovascular","fire;police;ems",
  "ID",   "cancer",        "fire",
  "IL",   "cancer",        "fire;ems",
  "IL",   "respiratory",   "fire;ems",
  "IL",   "infectious",    "fire;ems",
  "IL",   "cardiovascular","fire;ems",
  "LA",   "cancer",        "fire",
  "LA",   "respiratory",   "fire",
  "LA",   "infectious",    "fire;police",
  "LA",   "cardiovascular","fire",
  "LA",   "mental",        "fire;police;ems",
  "ME",   "cancer",        "fire",
  "ME",   "respiratory",   "fire;police;ems;corr",
  "ME",   "infectious",    "fire;police;ems;corr",
  "ME",   "cardiovascular","fire",
  "ME",   "mental",        "fire;police;ems;corr",
  "MD",   "cancer",        "fire;ems",
  "MD",   "respiratory",   "fire;ems",
  "MD",   "cardiovascular","fire;police;ems",
  "MT",   "cancer",        "fire",
  "MT",   "respiratory",   "fire",
  "MT",   "cardiovascular","fire",
  "NV",   "cancer",        "fire;police",
  "NV",   "respiratory",   "fire;police",
  "NV",   "infectious",    "fire;police;ems",
  "NV",   "cardiovascular","fire;police",
  "NH",   "cancer",        "fire",
  "NH",   "respiratory",   "fire",
  "NH",   "cardiovascular","fire",
  "NM",   "cancer",        "fire",
  "NM",   "respiratory",   "fire",
  "NM",   "infectious",    "fire",
  "NM",   "cardiovascular","fire",
  "OK",   "cancer",        "fire",
  "OK",   "respiratory",   "fire",
  "OK",   "infectious",    "fire",
  "OK",   "cardiovascular","fire",
  "OR",   "cancer",        "fire",
  "OR",   "respiratory",   "fire",
  "OR",   "cardiovascular","fire",
  "OR",   "mental",        "fire;police;ems;corr",
  "SC",   "cardiovascular","fire;police",
  "TN",   "cancer",        "fire",
  "TX",   "cancer",        "fire;ems",
  "TX",   "respiratory",   "fire;police;ems",
  "TX",   "infectious",    "fire;police;ems",
  "TX",   "cardiovascular","fire;police;ems",
  "UT",   "cancer",        "fire",
  "UT",   "infectious",    "fire",
  "VT",   "cancer",        "fire;ems",
  "VT",   "respiratory",   "fire;police;ems",
  "VT",   "infectious",    "fire;police;ems",
  "VT",   "cardiovascular","fire;police;ems",
  "VT",   "mental",        "fire;police;ems",
  "VA",   "cancer",        "fire",
  "VA",   "respiratory",   "fire",
  "VA",   "infectious",    "fire;police;corr",
  "VA",   "cardiovascular","fire",
  "WV",   "cancer",        "fire",
  "WV",   "respiratory",   "fire"
)


# =============================================================================
# BLOCK D: IAFF (2024) supplementary entries — conditions not in Brandt-Rauf
# =============================================================================
# Source: IAFF Presumptive Disability Chart (January 2024)
# These are ADDITIONS for state × condition cells missing from Brandt-Rauf.
# They do NOT override values already coded above.

iaff_additions <- tribble(
  ~state, ~condition,
  "ID",   "cardiovascular",
  "ID",   "respiratory",
  "ID",   "infectious",
  "MO",   "infectious",
  "CO",   "cardiovascular",
  "CO",   "respiratory",
  "WY",   "respiratory"
) |> mutate(
  presumption_type     = "statute",
  presumption_exists   = TRUE,
  source               = "IAFF_2024",
  data_current_through = "2024-01"
)


# =============================================================================
# BLOCK E: Known enactment years (panel variable for causal designs)
# =============================================================================
# Intended use: staggered DiD / event-study designs on first-responder mortality.
# Populated from NCCI text, legislative records, and secondary sources.
# NA = law predates comprehensive tracking or year not yet confirmed.

enactment_year_known <- tribble(
  ~state, ~condition,      ~enactment_year, ~enactment_notes,
  "CO",   "cancer",        2007L,           "C.R.S. § 8-41-209 enacted 2007 (NCCI text)",
  "AR",   "covid19",       2021L,           "H.B. 1488, 93rd Gen. Assembly; expired 5/1/2023",
  "MN",   "covid19",       2020L,           "Added to MN ST § 176.011 in 2020",
  "LA",   "cancer",        NA_integer_,     "Predates 2017; significantly expanded 2017 (Act No. 287)",
  "MD",   "cancer",        NA_integer_,     "Expanded to 9 cancers ~2012; to 11 cancers 2019 (NCCI text)",
  "AK",   "cancer",        NA_integer_,     "Predates 2018 NCCI brief; breast cancer added 2022"
)


# =============================================================================
# ASSEMBLE MASTER DATASET
# =============================================================================

state_names <- tibble(
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
            "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
            "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
            "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
            "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California",
                 "Colorado","Connecticut","Delaware","Florida","Georgia",
                 "Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas",
                 "Kentucky","Louisiana","Maine","Maryland","Massachusetts",
                 "Michigan","Minnesota","Mississippi","Missouri","Montana",
                 "Nebraska","Nevada","New Hampshire","New Jersey","New Mexico",
                 "New York","North Carolina","North Dakota","Ohio","Oklahoma",
                 "Oregon","Pennsylvania","Rhode Island","South Carolina",
                 "South Dakota","Tennessee","Texas","Utah","Vermont",
                 "Virginia","Washington","West Virginia","Wisconsin","Wyoming")
)

master <- bind_rows(brandrauf_long, iaff_additions) |>
  left_join(state_names, by = "state") |>
  left_join(ncci_raw |> rename(ncci_groups = groups), by = c("state", "condition")) |>
  left_join(citations |> rename(statute_citation = citation), by = c("state", "condition")) |>
  left_join(enactment_year_known, by = c("state", "condition")) |>
  mutate(
    condition_label = recode(condition,
      cancer         = "Cancer",
      cardiovascular = "Cardiovascular Disease",
      respiratory    = "Respiratory Disease",
      infectious     = "Infectious Disease",
      covid19        = "COVID-19",
      mental         = "Mental Health / PTSD"
    )
  ) |>
  relocate(state, state_name, condition, condition_label,
           presumption_type, presumption_exists,
           ncci_groups, statute_citation, notes,
           source, data_current_through,
           enactment_year, enactment_notes)

cat("\n=== MASTER DATASET ===\n")
cat("Rows:", nrow(master), "\n")
cat("\nPresumptions by condition:\n")
master |>
  group_by(condition_label) |>
  summarise(n_presumption = sum(presumption_exists, na.rm = TRUE)) |>
  print()


# =============================================================================
# SAVE OUTPUTS
# =============================================================================

saveRDS(master, file = here(data_proc_dir, "presumptive_laws.rds"))
cat("\nSaved: data/processed/presumptive_laws.rds\n")

master |>
  select(state, state_name, condition, condition_label,
         presumption_type, presumption_exists,
         ncci_groups, statute_citation, notes,
         source, data_current_through,
         enactment_year, enactment_notes) |>
  write_json(
    path       = here(web_data_dir, "presumptive_laws.json"),
    pretty     = TRUE,
    auto_unbox = TRUE,
    na         = "null"
  )
cat("Saved: website/data/presumptive_laws.json\n")
