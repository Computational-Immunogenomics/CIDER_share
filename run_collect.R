#!/usr/bin/env Rscript
# run_collect.R — Collect raw genomic data from the Hartwig WGS data request.
#
# Usage:
#   Rscript run_collect.R
#
# Collects:
#   PURPLE  — purity, qc              → PURPLE_DIR/
#   CIDER   — cider.vdj               → CIDER_DIR/
#   COBALT  — GC-corrected depths      → COBALT_DIR/depths.csv
#   AMBER   — BAF median depths        → AMBER_DIR/amber_depths.csv
#
# Run this once per data release, before run_prepare.R.
#
# Requirements:
#   - conda env : conda activate clay
#   - jupyter   : included in environment.yml
#   - IRkernel  : IRkernel::installspec()  (run once per conda env)

collect_notebooks <- c(
  "0_prepare/0_collect.ipynb"   # Collect PURPLE, CIDER, COBALT → purity.csv, cider.vdj.csv, depths.csv
)

run_notebook <- function(path) {
  message("\n", strrep("=", 60))
  message("Running: ", path)
  message(strrep("=", 60))
  flush.console()
  cmd <- paste0(
    "jupyter nbconvert --to notebook --execute --inplace ",
    "--ExecutePreprocessor.timeout=7200 ",
    "--ExecutePreprocessor.iopub_timeout=60 ",
    shQuote(path)
  )
  exit_code <- system(cmd, wait = TRUE)
  if (exit_code != 0) {
    stop("Notebook failed: ", path, "\nAborting.", call. = FALSE)
  }
  invisible(NULL)
}

message("Running data collection (", length(collect_notebooks), " notebook).")
t_start <- proc.time()

for (nb in collect_notebooks) {
  run_notebook(nb)
}

elapsed <- round((proc.time() - t_start)[["elapsed"]] / 60, 1)
message("\n", strrep("=", 60))
message("Data collection complete (", elapsed, " min).")
message(strrep("=", 60))
