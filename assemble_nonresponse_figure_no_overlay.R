#!/usr/bin/env Rscript
# assemble_nonresponse_figure_no_overlay.R — Assemble Figure 7 without the
# external-study ORR overlay.
#
# Identical to assemble_nonresponse_figure.R (Figure 7: model schematic,
# CPI-cohort response, predicted response landscape) except Panel C omits
# the published-literature ORR reference overlay (red tick marks/labels).
#
# Panel A: Logistic regression model schematic                 (unchanged)
# Panel B: Predicted response probability — ICI-treated cohorts (unchanged)
# Panel C: Predicted response probability — untreated Hartwig patients,
#          WITHOUT the external-study ORR overlay (uses
#          predicted_response_landscape_no_overlay.rds, saved by
#          7_predicted_response_landscape.ipynb just before the overlay is
#          added).
#
# Run after 7_predicted_response_landscape.ipynb has been executed.
#
# Usage:
#   Rscript assemble_nonresponse_figure_no_overlay.R

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
    stop("Missing panel: ", name, ".rds — run 7_predicted_response_landscape.ipynb first.")
  readRDS(path)
}

save_fig <- function(plot, fig_name, width, height) {
  saveRDS(plot, paste0(CIDER_PROJ_DIR, "figs/", fig_name, ".rds"))
  ggsave(paste0(CIDER_PROJ_DIR, "figs/", fig_name, ".png"),
         plot, width = width, height = height, dpi = 300)
  message("Saved: ", fig_name, ".png")
}

# ── Figure 7 (no external-study overlay) ─────────────────────────────────────
message("\nAssembling Figure 7 (no external-study overlay)...")

panel_a <- fig("model_schematic_panel")
panel_b <- fig("predicted_response_cpi_cohorts")
panel_c <- fig("predicted_response_landscape_no_overlay")

# free(panel_c) exempts Panel C from patchwork's plot-area alignment, same as
# the main assembly, so its layout matches figure_7.png exactly apart from
# the missing overlay.
figure_7_no_overlay <-
  ((panel_a | panel_b) / free(panel_c)) +
  plot_layout(heights = c(0.75, 1), widths = c(1, 2)) +
  # tag_size = 12.65: matches the main Figure 7's A/B/C panel label size.
  figure_annotation(tag_size = 12.65)

save_fig(figure_7_no_overlay, "figure_7_no_overlay", width = 17, height = 10)

message("\nDone — figure_7_no_overlay.png saved to ", CIDER_PROJ_DIR, "figs/")
