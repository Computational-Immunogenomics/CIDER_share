#!/usr/bin/env Rscript
# assemble_nonresponse_figure_pretreat.R — Assemble the 3-predictor
# (CIDER + TMB + Pretreatment) alternative to Figure 7.
#
# Alternative Figure 7 (3-predictor model):
#   Panel A': Logistic regression model schematic, 3 inputs
#             (CIDER, TMB, Pretreatment status)
#   Panel B': Predicted response probability, ICI-treated cohorts,
#             split 4 ways per cohort (Responder/Non-Responder x
#             Pretreated/Not Pretreated)
#   Panel C': Predicted response probability, untreated Hartwig patients,
#             using the 3-predictor model (no external-study overlay)
#
# Independent of assemble_nonresponse_figure.R (main) -- this swaps the
# underlying MODEL, not just how a panel is drawn, so all three panels come
# from new objects specific to this alternative. Panels B' and C' are
# faceted by pretreatment status (Pretreated / Not Pretreated).
#
# Run after 1_figures/7b_predicted_response_pretreat.ipynb has been executed
# (fits the 3-predictor model and saves all three panels; fully independent
# of 7_predicted_response_landscape.ipynb and 9_roc.ipynb).
#
# Usage:
#   Rscript assemble_nonresponse_figure_pretreat.R

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

# ── Alternative Figure 7: 3-predictor model ──────────────────────────────────
message("\nAssembling alternative Figure 7 (CIDER + TMB + Pretreatment model)...")

panel_a3 <- fig("model_schematic_3factor_panel")
panel_b3 <- fig("predicted_response_cpi_cohorts_pretreat")
panel_c3 <- fig("predicted_response_landscape_pretreat")

# free(panel_c3) exempts Panel C' from patchwork's plot-area alignment, same
# as the main assembly, so its layout matches figure_7.png's structure.
figure_7_pretreat <-
  ((panel_a3 | panel_b3) / free(panel_c3)) +
  plot_layout(heights = c(0.75, 1), widths = c(1, 2)) +
  # tag_size = 12.65: matches the main Figure 7's A/B/C panel label size.
  figure_annotation(tag_size = 12.65)

save_fig(figure_7_pretreat, "figure_7_pretreat", width = 18, height = 10.5)

message("\nDone — figure_7_pretreat.png saved to ", CIDER_PROJ_DIR, "figs/")
