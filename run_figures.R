#!/usr/bin/env Rscript
# run_figures.R — Execute the CIDER figure generation pipeline only.
#
# Usage:
#   Rscript run_figures.R
#
# Requires data preparation to have been run first (run_prepare.R).
# Clears all existing .png and .rds files from the figs/ directory, and all
# files in figs/paper/, before running.
#
# Requirements:
#   - conda env  : conda activate clay
#   - jupyter    : included in environment.yml
#   - IRkernel   : IRkernel::installspec()  (run once per conda env)

source("helpers/table_notebooks.R")  # TABLE_NOTEBOOKS: Table 1 / S1-S5 notebooks, shared with run_tables.R

figure_notebooks <- c(
  "1_figures/0_landscape.ipynb",          # CIDER Score landscape (full Hartwig cohort)
  "1_figures/1_response.ipynb",           # CIDER Score vs ICI response
  "1_figures/2_survival.ipynb",           # OS and PFS by CIDER High/Low
  "1_figures/2b_survival_specificity.ipynb", # Panel A of supplement_survival_specificity.png: OS by CIDER High/Low, ICI specificity (treatment class)
  "1_figures/3_survival_with_tmb.ipynb",  # Survival by CIDER × TMB groups
  "1_figures/3b_survival_tmb_specificity.ipynb", # Panel B of supplement_survival_specificity.png: OS by CIDER x TMB, ICI specificity (treatment class)
  "1_figures/4_cider_validation.ipynb",       # CIDER Score validation: RNA and ImmuneLENS
  "1_figures/5_cider_vs_tmb.ipynb",       # CIDER Score vs TMB
  "1_figures/6_cider_vs_purity.ipynb",    # Purity/depth adjustment diagnostics
  # 9_roc.ipynb runs before 7_predicted_response_landscape.ipynb (out of
  # numeric order) because 7 now loads the combined TMB + CIDER Score model
  # fit in 9 (figs/tmb_cider_combined_model.rds) instead of refitting its
  # own -- this is what keeps the "TMB + CIDER Score" AUC reported in
  # Figure 5B and Figure 7 Panel C identical. Don't reorder these two.
  "1_figures/9_roc.ipynb",                # ROC/AUC: CIDER vs TMB vs combined (also fits + saves the shared combined model for Figure 7)
  "1_figures/7_predicted_response_landscape.ipynb", # Predicted response landscape (Figure 7) -- loads 9_roc.ipynb's combined model
  # 7b_predicted_response_pretreat.ipynb (alternative 3-predictor Figure 7
  # with CIDER + TMB + Pretreatment) is disabled for now -- its paired
  # assembler script below is disabled too. Re-enable both together.
  "1_figures/8_forest.ipynb",             # Cox-PH and logistic forest plots (tumour type + mechanism)
  "1_figures/10_unique_vs_total.ipynb",      # Unique vs total CDR3 read comparison
  TABLE_NOTEBOOKS,                           # Table 1 (main text) + Tables S1-S5 (supplementary)
  "1_figures/12_xgboost_model.ipynb",         # XGBoost vs logistic regression (CIDER + TMB)
  "1_figures/13_driver_tcell.ipynb",          # Driver gene × T-cell: systematic regression analysis
  "1_figures/14_depth_stability.ipynb",       # CIDER score stability across sequencing depth (pan-cancer)
  "1_figures/15_ici_specificity.ipynb",       # ICI specificity of CIDER T-cell score (full supplement: every row fit under both None and TMB/Clinical/Purity covariate specs)
  "1_figures/16_diversity_metrics.ipynb",     # Supplementary: TCR diversity metrics vs ICI response
  "1_figures/17_response_by_read_confidence.ipynb", # Supplementary: CIDER T-cell Score vs response, by CDR3 read-confidence filter
  # 18_msi_response.ipynb (supplement_msi_response.png: CIDER T-cell Score
  # vs response, by MSI status) is disabled -- removed from the paper figure
  # set. The notebook itself is left in 1_figures/ untouched.
  "1_figures/19_dna_vs_rna_response.ipynb",         # Supplementary: DNA-based CIDER T-cell Score vs RNA (T-cell signature + CD8 Effector + PDL1), by-cohort responder-discrimination check
  "1_figures/20_ici_specificity_main.ipynb",        # Figure 6: predictive specificity of CIDER T-cell score for ICI therapy vs. general prognostic effects (BOR/OS, TMB-adjusted) -- simplified main-figure companion to 15_ici_specificity.ipynb
  "1_figures/21_tcell_geneset_panel.ipynb"          # Supplementary: CIDER T-cell Score vs 5 independent RNA gene-set signatures (Infiltration/Effector/PDL1) -- (A) bar plot of Pearson r, (B) ICI responder-discrimination boxplot
)

run_notebook <- function(path) {
  message("\n", strrep("=", 60))
  message("Running: ", path)
  message(strrep("=", 60))
  cmd <- paste0(
    "jupyter nbconvert --to notebook --execute --inplace ",
    "--ExecutePreprocessor.timeout=3600 ",
    "--ExecutePreprocessor.iopub_timeout=60 ",
    shQuote(path)
  )
  flush.console()
  exit_code <- system(cmd, wait = TRUE)
  if (exit_code != 0) {
    stop("Notebook failed: ", path, "\nAborting pipeline.", call. = FALSE)
  }
  invisible(NULL)
}

# ── Clear figures directory ───────────────────────────────────────────────────

figs_dir <- file.path(
  Sys.getenv("CIDER_PROJ_DIR", unset = "/mnt/immunocompnas1/datasets/cdr3_hg38/"),
  "figs"
)
if (dir.exists(figs_dir)) {
  old_files <- list.files(figs_dir, pattern = "\\.(png|rds)$", full.names = TRUE)
  if (length(old_files) > 0) {
    message("\nClearing ", length(old_files), " existing figure(s) from: ", figs_dir)
    file.remove(old_files)
  }
}

# figs/paper/ is collect_paper_figures.R's output — the final, submission-ready
# subset of figures and tables. Cleared here (every run, not just when a file
# is overwritten) so a figure or table removed from collect_paper_figures.R's
# manifest (e.g. a renamed or retired figure) doesn't linger indefinitely;
# collect_paper_figures.R repopulates it at the end of this script from
# whatever the manifest currently lists.
paper_dir <- file.path(figs_dir, "paper")
if (dir.exists(paper_dir)) {
  old_paper_files <- list.files(paper_dir, full.names = TRUE)
  if (length(old_paper_files) > 0) {
    message("Clearing ", length(old_paper_files), " existing file(s) from: ", paper_dir)
    file.remove(old_paper_files)
  }
}

# ── Execute ───────────────────────────────────────────────────────────────────

message("Running figure generation pipeline (", length(figure_notebooks), " notebooks).")
t_start <- proc.time()

for (nb in figure_notebooks) {
  run_notebook(nb)
}


# ── Assemble supplemental figures ────────────────────────────────────────────
# These scripts combine panels from the notebooks above into the final
# supplemental PNGs. Run after all figure notebooks have completed.

assembler_scripts <- c(
  "assemble_main_figures.R",                   # Figures 2–6 (assembled from panels)
  "assemble_purity_figure.R",                  # supplement_purity.png
  "assemble_survival_specificity_figure.R",    # supplement_survival_specificity.png (Panel A: CIDER-only, Panel B: CIDER x TMB)
  "assemble_nonresponse_figure.R",             # figure_7.png
  "assemble_nonresponse_figure_no_overlay.R",  # figure_7_no_overlay.png (no external-study ORR overlay)
  # "assemble_nonresponse_figure_pretreat.R",  # figure_7_pretreat.png -- disabled for now (depends on 1_figures/7b_predicted_response_pretreat.ipynb, also disabled above)
  "assemble_unique_vs_total_figure.R",         # supplement_unique_vs_total.png
  "assemble_supplementary_tables_excel.R",     # supplementary_tables.xlsx (Tables S1-S5, one workbook)
  "collect_paper_figures.R"                    # copy key figures/tables → figs/paper/
)

run_script <- function(path) {
  message("\n", strrep("=", 60))
  message("Running: ", path)
  message(strrep("=", 60))
  exit_code <- system(paste("Rscript", shQuote(path)), wait = TRUE)
  if (exit_code != 0) {
    stop("Script failed: ", path, "\nAborting.", call. = FALSE)
  }
  invisible(NULL)
}

for (script in assembler_scripts) {
  run_script(script)
}

elapsed <- round((proc.time() - t_start)[["elapsed"]] / 60, 1)
message("\n", strrep("=", 60))
message("Figure generation complete (", elapsed, " min).")
message(strrep("=", 60))
