#!/usr/bin/env Rscript
# assemble_unique_vs_total_figure.R — Assemble supplemental unique vs total figure.
#
# supplement_unique_vs_total.png:
#   Row 1 — A: Unique vs total score scatter   B: Combined validation summary (RNA + ImmuneLENS)
#   Row 2 — C/D: Slope charts — response (BOR/DCB) and survival (OS/PFS)
#
# Run after 10_unique_vs_total.ipynb has been executed.
#
# Usage:
#   Rscript assemble_unique_vs_total_figure.R

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

fig <- function(name) {
  path <- paste0(CIDER_PROJ_DIR, "figs/", name, ".rds")
  if (!file.exists(path))
    stop("Missing panel: ", name, ".rds — run 10_unique_vs_total.ipynb first.")
  readRDS(path)
}

save_fig <- function(plot, fig_name, width, height) {
  saveRDS(plot, paste0(CIDER_PROJ_DIR, "figs/", fig_name, ".rds"))
  ggsave(paste0(CIDER_PROJ_DIR, "figs/", fig_name, ".png"),
         plot, width = width, height = height, dpi = 300)
  message("Saved: ", fig_name, ".png")
}

message("\nAssembling supplement_unique_vs_total...")

row1 <- wrap_plots(fig("unique_vs_total_scatter"), fig("unique_vs_total_val_summary"),
                   nrow = 1, widths = c(0.89, 1.11))
row2 <- (fig("unique_vs_total_forest_response") / fig("unique_vs_total_forest_survival")) +
  plot_layout(guides = "collect") +
  figure_annotation(tag = FALSE, legend_pos = "right")

figure_uv <-
  (row1 / row2) +
  plot_layout(heights = c(0.552, 1.08)) +
  figure_annotation()

save_fig(figure_uv, "supplement_unique_vs_total", width = 9, height = 7.7)

message("\nDone — supplement_unique_vs_total.png saved to ", CIDER_PROJ_DIR, "figs/")
