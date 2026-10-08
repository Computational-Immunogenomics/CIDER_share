# =============================================================================
# config.r — project-wide analysis parameters
# Source this at the top of every notebook after map.r and shortcuts.r.
#
# Centralising these values means a single edit here propagates to all
# notebooks automatically, avoiding inconsistencies across the pipeline.
# =============================================================================

# ── CIDER Score formula ───────────────────────────────────────────────────────
# Two score variants are computed in 3_base.ipynb:
#
#   cider_score_adj        = cdr3_unique / (sampleMedianDepth * max(1-purity, PURITY_CAP))
#   cider_score_depth_adj  = cdr3_unique / sampleMedianDepth
#
# cider_score_adj is the primary clinical metric (purity + depth corrected).
# cider_score_depth_adj is used for RNA and ImmuneLens validation (depth only),
# putting CIDER on equal technical footing with depth-normalised RNA-seq.
#
# Both scores are right-skewed; log1p() is applied before scaling in models.
#
# PURITY_CAP: minimum value for max(1 - purity, PURITY_CAP).
# Assumes at least 10% non-tumour fraction, preventing extreme amplification
# for high-purity samples. Biologically motivated: below 10% non-tumour
# fraction the CDR3 signal becomes unreliable regardless of true infiltration.
PURITY_CAP   <- 0.10

# Scaling constant applied to both score variants before log-transformation.
# Chosen to match the cohort median sequencing depth (~100×), so the score
# approximates the percentage of genome copies carrying a detectable CDR3 signal.
# Interpretation becomes:
#   cider_score_depth_adj: % of genome equivalents with a CDR3 sequence
#   cider_score_adj:       % of non-tumour genome equivalents with a CDR3 sequence
SCORE_SCALE  <- 100


# ── TMB classification ────────────────────────────────────────────────────────
# Clinical threshold for TMB High/Low stratification (mutations per megabase).
TMB_HIGH_THRESHOLD <- 10

# ── Cohort definitions ────────────────────────────────────────────────────────
# Fixed level order for CPI broad cohorts (used in all clinical figures).
BROAD_LEVELS <- c("ICI-Treated", "SKCM", "NSCLC", "BLCA", "CRC-MSI", "Other")

# Same cohorts as BROAD_LEVELS, but with "Other" split into "Other MSS" /
# "Non-CRC MSI" (helpers/shortcuts.r::split_other_by_msi()) and reordered
# so the two MSI-related cohorts (Non-CRC MSI, CRC-MSI) sit together at
# the end, after every MSS/non-MSI-specific cohort including Other MSS --
# per direction, not just "Other" split in place. Non-CRC MSI comes
# before CRC-MSI (per direction) rather than after. Used by every figure
# that shows the Other-MSI breakdown directly: 1_response.ipynb (Figure 3),
# 2_survival.ipynb (Figure 4), 7_predicted_response_landscape.ipynb
# (Figure 7 cohort panel), 17_response_by_read_confidence.ipynb, and
# 5_models.ipynb (cohort-stratified forest plot fits -- level order doesn't
# affect that plot's visual order since 8_forest.ipynb re-sorts strata by N,
# but kept consistent with the rest for one shared source of truth).
# "Other (Unknown MSI)" (patients with unresolved MSI status) isn't listed
# here since it's a defensive residual, not an expected category -- callers
# append it at the end only if any such patients are actually present.
BROAD_LEVELS_OTHER_SPLIT <- c("ICI-Treated", "SKCM", "NSCLC", "BLCA",
                               "Other MSS", "Non-CRC MSI", "CRC-MSI")

# Fixed level order for pan-database cohorts (used in Figure 2A landscape).
# 22 named cohorts ordered approximately by N descending; "Other" always last.
# Acronyms follow TCGA conventions where applicable.
#
# CRC-MSI and Non-CRC MSI are both molecular (MSI-high) rather than
# tissue-of-origin categories, and take priority over every tissue rule in
# assign_pan_cohorts() (3_meta.ipynb) — so every other named cohort below is
# implicitly MSI-low/MSI-unknown only. Non-CRC MSI pools MSI-high patients
# from every non-colorectal tissue into one cross-cancer-type group, since
# MSI-high tumours are known to be highly immunogenic largely independent
# of tissue of origin (cf. pembrolizumab's tissue-agnostic MSI-H/dMMR
# approval) — mirrors the same design already used for the ICI-treated MSI
# response figure (MSI_GROUP_LEVELS below).
PAN_LEVELS <- c(
  "BRCA",         # Breast                          (~1,282)
  "NSCLC",        # Non-Small Cell Lung             (~985)
  "CRC-MSS",      # Colorectal MSS                  (~978)
  "CUP",          # Cancer of Unknown Primary       (~945)
  "PRAD",         # Prostate                        (~547)
  "SARC",         # Soft Tissue Sarcoma             (~580)
  "SKCM",         # Skin                            (~447)
  "OV",           # Ovarian                         (~433)
  "CNS",          # Brain / CNS                     (~333)
  "PAAD",         # Pancreas                        (~295)
  "ESOG",         # Esophagus / GEJ                 (~280)
  "KIRC",         # Kidney / Renal Cell             (~229)
  "BLCA",         # Bladder / Urothelial            (~207)
  "LNET",         # Lung NET / SCLC                 (~211)
  "CHOL",         # Biliary Tract                   (~145)
  "STAD",         # Stomach                         (~119)
  "CESC",         # Cervix                          (~115)
  "ENDO",         # Endometrium / Uterus            (~110)
  "MESO",         # Mesothelioma                    (~96)
  "LIHC",         # Liver HCC                       (~87)
  "CRC-MSI",      # Colorectal MSI-High             (~74)
  "Non-CRC MSI",  # MSI-High, any other tissue      (N unverified — new split)
  "Other"
)

# ── Full cohort names (supplemental tables) ───────────────────────────────────
# Maps each BROAD_LEVELS/PAN_LEVELS tumor-type acronym above to its full
# name, for use in the supplemental tables (S2-S4), where "Full name
# (ACRONYM)" is shown instead of a bare acronym so the table is readable
# without a separate abbreviations key. Main-figure axis labels keep the
# bare acronym instead (space is tight there, and TCGA-style acronyms are
# standard shorthand in that context) — see full_cohort_name() in
# helpers/shortcuts.r, which applies this mapping.
#
# Deliberately not exhaustive: "Other", "ICI-Treated", and "Pan-Cancer"
# aren't acronyms and are left out on purpose, so full_cohort_name() falls
# back to returning them unchanged.
COHORT_FULL_NAMES <- c(
  BRCA          = "Breast cancer",
  NSCLC         = "Non-small cell lung cancer",
  LNET          = "Lung neuroendocrine tumor",
  "CRC-MSI"     = "Colorectal cancer, MSI-High",
  "Non-CRC MSI" = "MSI-High cancer, non-colorectal",
  "CRC-MSS"     = "Colorectal cancer, MSS",
  PRAD          = "Prostate cancer",
  SARC          = "Soft tissue sarcoma",
  SKCM          = "Skin cutaneous melanoma",
  OV            = "Ovarian cancer",
  CNS           = "Brain/central nervous system cancer",
  PAAD          = "Pancreatic cancer",
  KIRC          = "Kidney renal cell carcinoma",
  ESOG          = "Esophageal/gastroesophageal junction cancer",
  BLCA          = "Bladder urothelial carcinoma",
  CHOL          = "Biliary tract cancer",
  STAD          = "Stomach adenocarcinoma",
  CESC          = "Cervical cancer",
  ENDO          = "Endometrial/uterine cancer",
  MESO          = "Mesothelioma",
  LIHC          = "Liver hepatocellular carcinoma",
  CUP           = "Cancer of unknown primary"
)

# ── ICI treatment normalisation + mechanism lookup ────────────────────────────
# Two-step reference map for ICI treatment strings from clinical_update.txt.
#
# Step 1 — ICI_TREATMENT_NORM
#   Collapses raw strings (duplicated drug names, reversed order) to a single
#   canonical name per unique regimen. Use "+" to denote combinations.
#
# Step 2 — ICI_MECHANISM_MAP
#   Maps each canonical name to a mechanism category.
#   Categories: Anti-PD1 | Anti-PDL1 | Anti-CTLA4 | Combo
#
# Usage:
#   df <- df |>
#     mutate(
#       treatment_clean = ICI_TREATMENT_NORM[treatment],
#       mechanism_clean = ICI_MECHANISM_MAP[treatment_clean]
#     )

ICI_TREATMENT_NORM <- c(
  # Anti-PD1
  "Nivolumab"                              = "Nivolumab",
  "Pembrolizumab"                          = "Pembrolizumab",
  "Pembrolizumab/Pembrolizumab"            = "Pembrolizumab",
  # Anti-PDL1
  "Durvalumab"                             = "Durvalumab",
  "Atezolizumab"                           = "Atezolizumab",
  "Atezolizumab/Atezolizumab/Atezolizumab" = "Atezolizumab",
  "Avelumab"                               = "Avelumab",
  "PD-L1 antibody"                         = "PD-L1 antibody",
  # Anti-CTLA4
  "Ipilimumab"                             = "Ipilimumab",
  "Tremelimumab"                           = "Tremelimumab",
  "Medi0562/Tremelimumab"                  = "Medi0562 + Tremelimumab",
  # Combo
  "Ipilimumab/Nivolumab"                   = "Ipilimumab + Nivolumab",
  "Nivolumab/Ipilimumab"                   = "Ipilimumab + Nivolumab",
  "Ipilimumab/Nivolumab/Nivolumab"         = "Ipilimumab + Nivolumab",
  "Ipilimumab/Pembrolizumab"               = "Ipilimumab + Pembrolizumab"
)

ICI_MECHANISM_MAP <- c(
  "Nivolumab"                  = "Anti-PD1",
  "Pembrolizumab"              = "Anti-PD1",
  "Durvalumab"                 = "Anti-PDL1",
  "Atezolizumab"               = "Anti-PDL1",
  "Avelumab"                   = "Anti-PDL1",
  "PD-L1 antibody"             = "Anti-PDL1",
  "Ipilimumab"                 = "Anti-CTLA4",
  "Tremelimumab"               = "Anti-CTLA4",
  "Medi0562 + Tremelimumab"    = "Anti-CTLA4",
  "Ipilimumab + Nivolumab"     = "Combo",
  "Ipilimumab + Pembrolizumab" = "Combo"
)

# ── MSI-status cohort grouping (supplementary MSI response figure) ───────────
# Fixed level order for the MSI-status boxplot grouping used in
# 1_figures/18_msi_response.ipynb: an all-ICI-treated MSS/MSI split, plus a
# breakdown of the MSI-high patients into CRC-MSI (already its own
# cohort_broad category) and "Non-CRC MSI" — MSI-high patients from every
# other broad cohort (SKCM, NSCLC, BLCA, Other) pooled together, since none
# of those individually has enough MSI-high ICI-treated patients to stand
# alone. Same name/concept as the "Non-CRC MSI" PAN_LEVELS category above,
# just computed from the 5-way cohort_broad scheme instead of cohort_pan.
# Labelled "ICI-Treated (...)" rather than "Pan-Cancer (...)" since every
# patient in this figure is ICI-treated — "Pan-Cancer" is reserved elsewhere
# in the repo for the full 22-cohort database scheme (PAN_LEVELS), a much
# broader (mostly untreated) population.
MSI_GROUP_LEVELS <- c("ICI-Treated (MSS)", "ICI-Treated (MSI)", "CRC-MSI", "Non-CRC MSI")

# ── Biopsy structure covariate ────────────────────────────────────────────────
# Biopsy site, collapsed to the most common structures plus a residual
# "Other" for everything else, so it can be used as a low-cardinality
# covariate in the adjusted regression models (5_models.ipynb). Defined
# once here (rather than per-notebook) since — unlike the Table
# 1/S2-specific collapsing thresholds above — this grouping has a single
# purpose (a regression covariate) and needs to be identical everywhere
# it's used. Assigned in 3_meta.ipynb from the raw `biopsyStructure` field
# in clinical_go.txt. "Skin (subcutaneous)" and "Skin (cutaneous)" are
# pooled into one "Skin (subcutaneous/cutaneous)" level (see 3_meta.ipynb's
# case_when), matching the same pooling Table S1
# (1_figures/11f_biopsy_location_breakdown.ipynb) uses for its own display.
BIOPSY_STRUCTURE_LEVELS <- c("Lymph node", "Liver", "Lung", "Skin (subcutaneous/cutaneous)", "Other")

# Raw biopsyStructure string(s) (clinical_go.txt, preserved unmodified in
# `biopsyStructureRaw` by 3_meta.ipynb -- see that notebook and
# BIOPSY_STRUCTURE_LEVELS above) that indicate the WGS biopsy was taken
# from the primary tumor itself rather than a metastasis. Used only by
# 1_figures/11f_biopsy_location_breakdown.ipynb (Table S1), which needs
# this distinction and so works from the raw value rather than the
# collapsed BIOPSY_STRUCTURE_LEVELS scheme above (which has no "primary
# tumor" category of its own -- it currently folds these into "Other").
# Extend this list if clinical_go.txt uses another spelling.
BIOPSY_PRIMARY_TUMOR_RAW_VALUES <- c("Primary tumor", "Primary tumour", "Primary tumor location")

# ── Sub-cohort breakdown threshold ────────────────────────────────────────────
# Minimum number of ICI-treated patients a granular category (a cohort_pan
# tumour type, or -- in Table S1 -- a raw biopsy site) must have to be
# broken out as its own row nested under an "Other" subtotal. Categories
# below this threshold are pooled into a residual "Other (Other)" row
# instead of being named individually — see
# 1_figures/11c_pretreatment_by_subcohort.ipynb and every other
# supplementary table that nests an "Other" breakdown (S1, S2, S4).
SUBCOHORT_MIN_OTHER_TYPE_N <- 3

# ── T-cell group levels ────────────────────────────────────────────────────────
# This project is T-cell-focused: the CDR3 pipeline (helpers/shortcuts.r's
# create_groups()) only emits T-cell overall + its three loci. B-cell and
# the combined "Lymphocytes" (T-cell + B-cell) categories were removed from
# scope; if BCR-based analyses are ever revisited, reintroduce both the
# levels here and the corresponding bind_rows() branches in create_groups()
# together (a mismatch between the two silently coerces stray gp values to
# NA wherever factor(gp, levels = GP_LEVELS) is applied).
GP_LEVELS <- c("T-cell", "T-cell (TRA/TRD)", "T-cell (TRB)", "T-cell (TRG)")
