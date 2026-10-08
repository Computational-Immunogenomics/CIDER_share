#!/usr/bin/env Rscript
# run_prepare.R — Execute the CIDER data preparation pipeline.
#
# Usage:
#   Rscript run_prepare.R
#
# Requires run_collect.R to have been run first (raw data files must exist).
#
# Runs notebooks in order:
#   1_cider    → cider_base.csv
#   2_rna      → isofox_genesets_ready_log2.csv
#   3_meta     → meta_base.csv
#   4_base     → ready.rds, cpi_ready.rds
#   5_models   → models_ready.rds
#
# Requirements:
#   - conda env  : conda activate clay
#   - jupyter    : included in environment.yml
#   - IRkernel   : IRkernel::installspec()  (run once per conda env)

prepare_notebooks <- c(
  "0_prepare/1_cider.ipynb",           # Parse CIDER VDJ output → cider_base.csv
  "0_prepare/1b_cider_by_confidence.ipynb", # PASS-only / low-confidence-only CIDER base variants (robustness check)
  "0_prepare/2_rna.ipynb",             # T-cell + CD8 Effector (tGE8) RNA gene sets → isofox_genesets_ready_log2.csv
  "0_prepare/3_meta.ipynb",            # Clinical + DNA + RNA → meta_base.csv
  "0_prepare/4_base.ipynb",            # Merge + CIDER Scores + cohorts → ready.rds / cpi_ready.rds
  "0_prepare/5_models.ipynb",          # Cox-PH + logistic models → models_ready.rds
  "0_prepare/6_extra_markers.ipynb"    # Somatic driver features → extra_markers.rds
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

message("Running data preparation pipeline (", length(prepare_notebooks), " notebooks).")
t_start <- proc.time()

for (nb in prepare_notebooks) {
  run_notebook(nb)
}

elapsed <- round((proc.time() - t_start)[["elapsed"]] / 60, 1)
message("\n", strrep("=", 60))
message("Data preparation complete (", elapsed, " min).")
message(strrep("=", 60))
