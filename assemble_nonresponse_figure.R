#!/usr/bin/env Rscript
# assemble_nonresponse_figure.R — Assemble Figure 7 (predicted non-response).
#
# Figure 7:
#   Panel A: Logistic regression model schematic
#   Panel B: Predicted response probability — ICI-treated cohorts (R vs NR)
#   Panel C: Predicted response probability — all untreated Hartwig patients
#
# Run after 7_predicted_response_landscape.ipynb has been executed.
#
# Usage:
#   Rscript assemble_nonresponse_figure.R

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

# ── Figure 7: Predicted response ─────────────────────────────────────────────
message("\nAssembling Figure 7 (predicted non-response)...")

panel_a <- fig("model_schematic_panel")
panel_b <- fig("predicted_response_cpi_cohorts")
panel_c <- fig("predicted_response_landscape")

# free(panel_c) exempts Panel C from patchwork's plot-area alignment so it
# can expand into the right-side space that Panel B's legend would otherwise
# reserve (requires patchwork >= 1.2.0).
figure_7 <-
  ((panel_a | panel_b) / free(panel_c)) +
  plot_layout(heights = c(0.75, 1), widths = c(1, 2)) +
  # tag_size = 12.65: 15% larger than figure_annotation()'s default of 11,
  # for this figure's A/B/C panel labels specifically (not a global change).
  figure_annotation(tag_size = 12.65)

save_fig(figure_7, "figure_7", width = 17, height = 10)

message("\nDone — figure_7.png saved to ", CIDER_PROJ_DIR, "figs/")
