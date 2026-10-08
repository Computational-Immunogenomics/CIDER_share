#!/usr/bin/env Rscript
# collect_paper_figures.R — Copy key paper figures and tables to figs/paper/.
#
# Assembles a clean subdirectory containing only the figures and tables
# intended for submission: main figures 2–7, the named supplementals,
# Table 1's .docx, and the combined supplementary_tables.xlsx.
#
# Run after all assembler scripts and the table notebooks
# (helpers/table_notebooks.R's TABLE_NOTEBOOKS) have completed.
#
# Usage:
#   Rscript collect_paper_figures.R

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
SCRIPT_DIR <- if (length(script_path) > 0) {
  normalizePath(dirname(script_path), mustWork = FALSE)
} else {
  getwd()
}

source(file.path(SCRIPT_DIR, "helpers/map.r"))

figs_dir  <- paste0(CIDER_PROJ_DIR, "figs/")
paper_dir <- paste0(CIDER_PROJ_DIR, "figs/paper/")
dir.create(paper_dir, showWarnings = FALSE, recursive = TRUE)

# ── Figure manifest ───────────────────────────────────────────────────────────
paper_figures <- c(
  # Main figures
  "figure_2.png",
  "figure_3.png",
  "figure_4.png",
  "figure_5.png",
  "figure_6.png",
  "figure_7.png",
  # Supplementals
  "supplement_purity.png",
  "supplement_forest.png",
  "supplement_unique_vs_total.png",
  "supplement_xgboost_combined.png",
  "supplement_depth_stability.png",
  "supplement_ici_specificity.png",
  "supplement_survival_specificity.png",
  "supplement_driver_tcell_fdr.png",
  "supplement_diversity_metrics.png",
  "supplement_response_by_read_confidence.png",
  "supplement_tcell_geneset_panel.png"
)

# ── Table manifest ────────────────────────────────────────────────────────────
# Table 1 is the only main-text table (11_demographic_table.ipynb) and now
# outputs only a .docx (no .csv/.html -- nothing downstream needs them).
#
# Tables S1-S5 (11b_demographic_table_full_cohort.ipynb /
# 11c_pretreatment_by_subcohort.ipynb / 11d_tumor_type_by_msi_status.ipynb /
# 11e_treatment_by_mechanism_response.ipynb /
# 11f_biopsy_location_breakdown.ipynb) each still write a .csv to figs/, but
# that's purely a build intermediate for assemble_supplementary_tables_excel.R
# -- supplementary_tables.xlsx (one workbook, one sheet per table) is the
# only supplementary-table deliverable, so it's the only one collected here.
paper_tables <- c(
  "table_1_demographics.docx",
  "supplementary_tables.xlsx"
)

# ── Copy ──────────────────────────────────────────────────────────────────────
copy_all <- function(files, label) {
  message("\nCollecting paper ", label, " → ", paper_dir)
  missing <- character(0)
  for (f in files) {
    src  <- paste0(figs_dir, f)
    dest <- paste0(paper_dir, f)
    if (file.exists(src)) {
      file.copy(src, dest, overwrite = TRUE)
      message("  ✓  ", f)
    } else {
      missing <- c(missing, f)
      message("  ✗  ", f, "  [NOT FOUND]")
    }
  }
  missing
}

missing_figures <- copy_all(paper_figures, "figures")
missing_tables  <- copy_all(paper_tables,  "tables")
missing <- c(missing_figures, missing_tables)

if (length(missing) > 0) {
  warning(
    length(missing), " file(s) not found — run the relevant assembler script(s) or ",
    "demographic-table notebook(s) first:\n",
    paste0("  ", missing, collapse = "\n"),
    call. = FALSE
  )
} else {
  message(
    "\nDone — ", length(paper_figures), " figures and ", length(paper_tables),
    " table file(s) copied to figs/paper/"
  )
}
