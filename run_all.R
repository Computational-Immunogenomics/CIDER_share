#!/usr/bin/env Rscript
# run_all.R — Execute the full CIDER immune infiltration analysis pipeline.
#
# Thin orchestrator: delegates each stage to run_collect.R, run_prepare.R,
# and run_figures.R rather than keeping its own copy of their notebook
# lists. This is the single fix for the recurring problem where run_all.R's
# inlined lists drifted out of sync with the dedicated per-stage scripts
# (missing notebooks, stale references to superseded ones) — now there is
# exactly one place that defines what each stage runs.
#
# Usage:
#   Rscript run_all.R                  # run collect + prepare + figures
#   Rscript run_all.R prepare          # run only run_prepare.R
#   Rscript run_all.R figures          # run only run_figures.R
#   Rscript run_all.R tables           # run only run_tables.R (Table 1 + S1-S5)
#   Rscript run_all.R prepare figures  # run multiple stages
#
# Requirements: see run_collect.R, run_prepare.R, and run_figures.R for the
# notebooks/scripts each stage runs and their individual requirements.
#   - conda env  : conda activate clay
#   - jupyter    : included in environment.yml
#   - IRkernel   : IRkernel::installspec()  (run once per conda env)
#   - renv       : renv::restore()  (see README.md)
#   - nbstripout : nbstripout --install  (run once per clone)

args   <- commandArgs(trailingOnly = TRUE)
stages <- if (length(args) == 0) c("collect", "prepare", "figures") else args

# ── Stage dispatch ────────────────────────────────────────────────────────────

valid_stages <- c("collect", "prepare", "figures", "tables", "all")
unknown <- setdiff(stages, valid_stages)
if (length(unknown) > 0) {
  stop(
    "Unknown stage(s): ", paste(unknown, collapse = ", "),
    "\nValid options: ", paste(valid_stages, collapse = " | "),
    call. = FALSE
  )
}

# "all" expands to collect + prepare + figures
if ("all" %in% stages) stages <- union(stages, c("collect", "prepare", "figures"))

# Each stage's script owns its own notebook/assembler list, its own
# figs/-clearing logic (figures stage), and its own timing message — this
# script just runs them in order and stops on the first failure.
#
# "tables" is a convenience subset of "figures" (both run the same
# TABLE_NOTEBOOKS, see helpers/table_notebooks.R) for regenerating just
# Table 1 / S1-S5 without the rest of the figure pipeline — it is
# deliberately NOT included in "all"'s expansion below, since "figures"
# already runs those same notebooks.
stage_scripts <- c(
  collect = "run_collect.R",
  prepare = "run_prepare.R",
  figures = "run_figures.R",
  tables  = "run_tables.R"
)

run_stage <- function(script) {
  message("\n", strrep("=", 60))
  message("Running: ", script)
  message(strrep("=", 60))
  flush.console()
  exit_code <- system(paste("Rscript", shQuote(script)), wait = TRUE)
  if (exit_code != 0) {
    stop("Stage failed: ", script, "\nAborting pipeline.", call. = FALSE)
  }
  invisible(NULL)
}

# ── Execute ───────────────────────────────────────────────────────────────────

active_stages <- names(stage_scripts)[names(stage_scripts) %in% stages]
message("Stages: ", paste(active_stages, collapse = ", "))

t_start <- proc.time()

for (stage in active_stages) {
  run_stage(stage_scripts[[stage]])
}

elapsed <- round((proc.time() - t_start)[["elapsed"]] / 60, 1)
message("\n", strrep("=", 60))
message("Pipeline complete (", elapsed, " min).")
message(strrep("=", 60))
