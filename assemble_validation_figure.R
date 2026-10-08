#!/usr/bin/env Rscript
# assemble_validation_figure.R — Assemble supplemental correlation figure.
#
# supplement_correlation:
#   Pairwise CIDER Score correlation heatmap across T-cell loci
#
# Run after 4_cider_validation.ipynb has been executed.
#
# Usage:
#   Rscript assemble_validation_figure.R

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
SCRIPT_DIR <- if (length(script_path) > 0) {
  normalizePath(dirname(script_path), mustWork = FALSE)
} else {
  getwd()
}

source(file.path(SCRIPT_DIR, "helpers/map.r"))
source(file.path(SCRIPT_DIR, "helpers/shortcuts.r"))
source(file.path(SCRIPT_DIR, "helpers/config.r"))
source(file.path(SCRIPT_DIR, "helpers/themes.r"))

library(patchwork)

fig <- function(name, notebook = "4_cider_validation.ipynb") {
  path <- paste0(CIDER_PROJ_DIR, "figs/", name, ".rds")
  if (!file.exists(path))
    stop("Missing panel: ", name, ".rds — run ", notebook, " first.")
  readRDS(path)
}

save_fig <- function(plot, fig_name, width, height) {
  saveRDS(plot, paste0(CIDER_PROJ_DIR, "figs/", fig_name, ".rds"))
  ggsave(paste0(CIDER_PROJ_DIR, "figs/", fig_name, ".png"),
         plot, width = width, height = height, dpi = 300)
  message("Saved: ", fig_name, ".png")
}

# ── supplement_correlation: T-cell loci correlation heatmap ──────────────────
message("\nAssembling supplement_correlation (T-cell loci heatmap)...")

figure_s5 <-
  fig("cider_corr_heatmap") +
  figure_annotation()

save_fig(figure_s5, "supplement_correlation", width = 7.09, height = 6)

message("\nDone — supplement_correlation.png saved to ", CIDER_PROJ_DIR, "figs/")
