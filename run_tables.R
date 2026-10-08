#!/usr/bin/env Rscript
# run_tables.R — Regenerate only the demographic / cohort-composition
# tables (Table 1 and Tables S1-S5), without re-running the rest of the
# figure pipeline.
#
# Useful while iterating on table design, grouping, or formatting: the full
# figure pipeline (run_figures.R) takes much longer and clears figs/*.png
# unnecessarily when only a table notebook has changed.
#
# The notebook list itself lives in helpers/table_notebooks.R
# (TABLE_NOTEBOOKS) — the single source shared with run_figures.R — so
# adding a new table there is picked up by both scripts automatically.
#
# Usage:
#   Rscript run_tables.R
#
# Requires data preparation to have been run first (run_prepare.R): these
# notebooks read cpi_ready.rds. Table S1 (11f_biopsy_location_breakdown.ipynb)
# specifically needs a data-prep re-run if you haven't done one since
# biopsyStructureRaw was added to 0_prepare/3_meta.ipynb -- that column
# won't exist in an older cpi_ready.rds, and the notebook will error.
#
# Requirements:
#   - conda env  : conda activate clay
#   - jupyter    : included in environment.yml
#   - IRkernel   : IRkernel::installspec()  (run once per conda env)

source("helpers/table_notebooks.R")

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
    stop("Notebook failed: ", path, "\nAborting.", call. = FALSE)
  }
  invisible(NULL)
}

# ── Execute ───────────────────────────────────────────────────────────────────

message("Running table notebooks only (", length(TABLE_NOTEBOOKS), " notebooks).")
t_start <- proc.time()

for (nb in TABLE_NOTEBOOKS) {
  run_notebook(nb)
}

# ── Assemble the combined supplementary tables Excel workbook ─────────────────
# Reads the .csv + title/footnote metadata each table notebook just saved
# and formats them into one submission-ready supplementary_tables.xlsx
# (one sheet per table). Must run after the notebook loop above.
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
run_script("assemble_supplementary_tables_excel.R")

# ── Refresh figs/paper/ table files ────────────────────────────────────────────
# collect_paper_figures.R copies both figures and tables listed in its
# manifest into figs/paper/. Running it here just re-copies the freshly
# regenerated table files (and re-copies any already-present figures,
# unchanged) — it does not clear the directory first, so nothing else in
# figs/paper/ is affected. It will warn (not fail) about any figures not
# yet generated, since this script doesn't run the figure notebooks.
run_script("collect_paper_figures.R")

elapsed <- round((proc.time() - t_start)[["elapsed"]] / 60, 1)
message("\n", strrep("=", 60))
message("Table generation complete (", elapsed, " min).")
message(strrep("=", 60))
