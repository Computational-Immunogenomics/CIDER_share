shh <- suppressPackageStartupMessages
shh(library(tidyverse))
shh(library(data.table))

options(repr.matrix.max.cols = 50, repr.matrix.max.rows = 100)
options(dplyr.summarise.inform = FALSE)
options(warn = -1)

# Compute rounded mean, ignoring NAs
mean_rounded <- function(x, digits = 2) round(mean(x, na.rm = TRUE), digits)

# Preview the top-left corner of a matrix
corner <- function(mat, k = 5) mat[1:k, 1:k]

# Set notebook plot dimensions
set_plot_dims <- function(w = 10, h = 6) {
  options(repr.plot.width = w, repr.plot.height = h)
}

# Count rows per group, sorted descending
top <- function(data, group_col) {
  data |>
    group_by({{ group_col }}) |>
    summarise(ct = n(), .groups = "drop") |>
    arrange(desc(ct))
}

# Reorder a factor by descending frequency (forcats::fct_infreq()), but pin
# one or more levels to the very end (in the order given) regardless of
# their count. Intended for residual catch-all categories (e.g. "Other",
# "Multiple mechanism") that shouldn't be sorted in among the named
# categories on count alone — a large "Other" just means many small groups
# were merged into it, not that it's itself a major category. `level` may
# be a single level or a character vector of several; any that aren't
# actually present in `f` are silently ignored, so it's safe to call
# without a guard at each call site (e.g. a subset where every case falls
# into a well-represented category).
#
# Usage: demo |> mutate(Treatment = fct_pin_last(Treatment, "Other"))
#        demo |> mutate(`ICI Cohort` = fct_pin_last(`ICI Cohort`, c("Non-CRC MSI", "Other MSS")))
fct_pin_last <- function(f, level) {
  f <- forcats::fct_infreq(f)
  present <- level[level %in% levels(f)]
  if (length(present) > 0) forcats::fct_relevel(f, present, after = Inf) else f
}

# Relabels a cohort/tumor-type acronym (or vector of them) as "Full name
# (ACRONYM)", using the lookup in COHORT_FULL_NAMES (helpers/config.r).
# Anything not in that lookup (e.g. "Other", or an already-suffixed label)
# is returned unchanged, so it's safe to call on a whole column without a
# guard, and safe to call before appending a suffix like " (Other)" for
# the supplemental tables' nested "Other" breakdown rows. Vectorised; NA in,
# NA out.
#
# Usage: demo |> mutate(`ICI Cohort` = full_cohort_name(cohort_broad))
#        paste0(full_cohort_name(cohort_pan), " (Other)")
full_cohort_name <- function(x) {
  x <- as.character(x)
  full <- COHORT_FULL_NAMES[x]
  ifelse(is.na(full), x, paste0(full, " (", x, ")"))
}

# Relabels cohort_broad's residual "Other" category into "Non-CRC MSI" /
# "Other MSS" (by msi_high), for any output that would otherwise show
# "Other" as one undifferentiated bucket mixing MSI-high and
# microsatellite-stable patients from many different tumor types. The
# MSI-high half is named "Non-CRC MSI" rather than "Other MSI" since
# that's exactly what it is -- CRC-MSI patients are already carved out into
# their own cohort, so every MSI-high patient left in "Other" is by
# definition non-colorectal (same name already used for this concept at
# the pan-cohort level, see PAN_LEVELS' "Non-CRC MSI" in helpers/config.r --
# kept identical, no parentheses, so the two don't read as different
# categories).
# Every other cohort_broad level (SKCM/NSCLC/BLCA/CRC-MSI/ICI-Treated) is
# returned unchanged. A patient in "Other" whose MSI status wasn't
# determined becomes "Other (Unknown MSI)" rather than silently dropping
# out. Display-only -- does not touch the canonical cohort_broad/
# cohort_broad_go columns saved in cpi_ready.rds; callers apply this to
# their own local copy and rebuild any "_go" N-suffixed factor afterwards
# (see 1_response.ipynb / 2_survival.ipynb cell 3/4 for the pattern, which
# mirrors how cohort_broad_go itself is built in 0_prepare/4_base.ipynb).
# Same split already used in Table 1 (11_demographic_table.ipynb), factored
# out here so it isn't duplicated verbatim in every notebook that wants it.
# Returns a plain character vector, not a factor -- the caller decides
# level order (e.g. "Non-CRC MSI"/"Other MSS" pinned after the real
# cohorts, not sorted in alphabetically).
#
# Usage: ready |> mutate(cohort_broad = split_other_by_msi(cohort_broad, msi_high))
split_other_by_msi <- function(cohort_broad, msi_high) {
  dplyr::case_when(
    as.character(cohort_broad) != "Other" ~ as.character(cohort_broad),
    msi_high == 1                         ~ "Non-CRC MSI",
    msi_high == 0                         ~ "Other MSS",
    TRUE                                  ~ "Other (Unknown MSI)"
  )
}

# Canonicalizes a raw ICI treatment string via the hand-curated
# ICI_TREATMENT_NORM lookup (helpers/config.r) -- e.g. both
# "Nivolumab/Ipilimumab" and "Ipilimumab/Nivolumab" become "Ipilimumab +
# Nivolumab". Falls back to the input unchanged for any raw string not in
# the lookup (rather than silently dropping/NA-ing regimens the
# hand-curated list doesn't yet cover), so it's safe to call on a whole
# column without a guard. Vectorised; NA in, NA out.
#
# Usage: demo |> mutate(Treatment = normalize_ici_treatment(treatment))
normalize_ici_treatment <- function(x) {
  x <- as.character(x)
  canon <- ICI_TREATMENT_NORM[x]
  ifelse(is.na(canon), x, unname(canon))
}

# Strips gtsummary/gt markdown bold syntax (**text** or __text__) from a
# gtsummary table's plain-text export. gtsummary tables (Table 1, Table S3)
# store header/label bold formatting as markdown -- modify_header()'s
# literal "**{level}**" template strings, and bold_labels()'s internal
# styling, which happens to serialize as "__text__" -- and gt::md() /
# as_gt() / as_flex_table() correctly render that markdown as real bold
# text in the .html/.docx outputs. as_tibble() has no notion of rich text,
# though, so it leaves the raw markdown characters sitting in the string;
# left alone, a CSV opened in Excel shows literal "**Age**" / "__Sex__"
# instead of clean column/row names. Only the CSV export needs this call
# (HTML/.docx already render correctly) -- see 11_demographic_table.ipynb
# and 11b_demographic_table_full_cohort.ipynb's "Save outputs" cells.
# Non-greedy regex so "**A**, N = 1 (**B**)"-style strings with more than
# one bold span still strip correctly. Vectorised.
#
# Usage: tbl |> as_tibble() |> dplyr::rename_with(strip_gt_markdown) |>
#          dplyr::mutate(dplyr::across(dplyr::where(is.character), strip_gt_markdown))
strip_gt_markdown <- function(x) {
  x <- gsub("\\*\\*(.*?)\\*\\*", "\\1", x)
  x <- gsub("__(.*?)__", "\\1", x)
  x
}

# =============================================================================
# build_cider_base() — summarise raw CIDER VDJ calls into per-sample,
# per-lymphocyte-group CDR3 metrics (unique count, total reads, Shannon
# entropy, clonality), for a chosen set of CIDER `filter` QC categories.
#
# Centralises the logic shared by 1_cider.ipynb (the primary pipeline, which
# keeps both "PASS" and "NO_HIGH_QUAL_SUPPORT" calls) and any sensitivity
# analysis that wants a stricter or looser confidence cutoff — e.g.
# 1b_cider_by_confidence.ipynb, which builds PASS-only and
# low-confidence-only variants for a response-comparison robustness check
# (1_figures/17_response_by_read_confidence.ipynb).
#
# Arguments:
#   cider_vdj_raw : the *unfiltered* CIDER VDJ table (one row per clonotype
#                   call), as read directly from cider.vdj.csv. Must contain
#                   sampleId, cdr3AA, locus, assignedReads, filter.
#   filter_values : character vector of `filter` values to keep, e.g.
#                   c("PASS", "NO_HIGH_QUAL_SUPPORT") for the primary
#                   pipeline, c("PASS") for a PASS-only variant, or
#                   c("NO_HIGH_QUAL_SUPPORT") for a low-confidence-only
#                   variant.
#   all_samples   : data.frame of sampleId for every sample where CIDER was
#                   run (regardless of whether any calls passed `filter`),
#                   used to zero-fill true zero-infiltration samples rather
#                   than silently dropping them. See 1_cider.ipynb for how
#                   this is derived (clinical ∩ WGS ∩ raw CIDER output).
#
# Returns: a tibble with one row per (sampleId, gp), gp being "T-cell" or a
#   per-locus group like "T-cell (TRA/TRD)". T-cell loci are identified by
#   a "T"-prefixed locus code (TRA/TRD/TRB/TRG); BCR loci are not retained
#   here — this project is T-cell-focused (see helpers/config.r's GP_LEVELS).
# =============================================================================
build_cider_base <- function(cider_vdj_raw, filter_values, all_samples) {
  tmp <- cider_vdj_raw |>
    dplyr::filter(filter %in% filter_values) |>
    dplyr::transmute(sampleId, cdr3AA, locus, assignedReads)

  create_groups <- function(df) {
    df <- df |> dplyr::filter(grepl("^T", locus))
    dplyr::bind_rows(
      df |> dplyr::mutate(gp = "T-cell"),
      df |> dplyr::mutate(gp = paste0("T-cell (", locus, ")"))
    )
  }

  base <- create_groups(tmp) |>
    dplyr::group_by(sampleId, gp) |>
    dplyr::mutate(freq = assignedReads / sum(assignedReads)) |>
    dplyr::summarise(
      cdr3_unique     = dplyr::n(),
      cdr3_total      = sum(assignedReads),
      shannon         = -sum(freq * log(freq)),
      evenness        = ifelse(dplyr::n() > 1, shannon / log(dplyr::n()), 0),
      clonality       = 1 - evenness,
      max_clone_reads = max(assignedReads),
      max_clone_pct   = max(freq) * 100,
      .groups         = "drop"
    )

  add_zeros <- all_samples |>
    dplyr::cross_join(base |> dplyr::select(gp) |> dplyr::distinct())

  base |>
    dplyr::right_join(add_zeros, by = c("sampleId", "gp")) |>
    dplyr::mutate(dplyr::across(where(is.numeric), ~ tidyr::replace_na(.x, 0)))
}
