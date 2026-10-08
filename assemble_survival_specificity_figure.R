#!/usr/bin/env Rscript
# assemble_survival_specificity_figure.R — Assemble the combined ICI
# specificity survival supplement.
#
# supplement_survival_specificity.png:
#   Panel A — CIDER T-cell High/Low overall-survival KM curves, by
#             treatment class (ICI Therapy, Non-ICI Therapy, Chemotherapy,
#             Targeted therapy, Hormonal therapy, Multiple therapy), 3x2
#   Panel B — Same six treatment-class cohorts, CIDER High/Low (colour) x
#             TMB High/Low (linetype) overall-survival curves, 3x2
#
# Each panel is already a fully-assembled 3x2 grid (with its own collected
# legend and per-cohort titles) produced by its own notebook -- this script
# only stacks the two grids and adds the outer A/B tags; it doesn't rebuild
# any of the underlying survival curves itself.
#
# Run after:
#   2b_survival_specificity.ipynb      (survival_specificity_cider_panel)
#   3b_survival_tmb_specificity.ipynb  (survival_specificity_tmb_panel)
#
# Usage:
#   Rscript assemble_survival_specificity_figure.R

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
    stop("Missing panel: ", name, ".rds — check the relevant notebook has been run.")
  readRDS(path)
}

save_fig <- function(plot, fig_name, width, height) {
  saveRDS(plot, paste0(CIDER_PROJ_DIR, "figs/", fig_name, ".rds"))
  ggsave(paste0(CIDER_PROJ_DIR, "figs/", fig_name, ".png"),
         plot, width = width, height = height, dpi = 300)
  message("Saved: ", fig_name, ".png")
}

# ── Assemble combined survival specificity supplement ───────────────────────
message("\nAssembling supplement_survival_specificity.png...")

# wrap_elements(full = ...) treats each already-composed 3x2 grid (with its
# own internal plot_annotation()/collected legend) as a single opaque block,
# same pattern used for Figure 4/6 in assemble_main_figures.R -- the outer
# tag_levels = "A" below only labels these two blocks, not the six
# treatment-class sub-panels inside each (which keep their own descriptive
# titles; both source notebooks already set tag = FALSE for that reason).
panel_a <- fig("survival_specificity_cider_panel")
panel_b <- fig("survival_specificity_tmb_panel")

supplement_survival_specificity <-
  (wrap_elements(full = panel_a) / wrap_elements(full = panel_b)) +
  plot_layout(heights = c(1, 1.1)) +  # Panel B is slightly taller (needs room for its own bottom legend; Panel A has no legend)
  plot_annotation(
    tag_levels = "A",
    theme = go_theme + theme(plot.tag = element_text(size = 14, face = "bold"))
  )

save_fig(supplement_survival_specificity, "supplement_survival_specificity", width = 12, height = 15)

message("\nDone — supplement_survival_specificity.png saved to ", CIDER_PROJ_DIR, "figs/")
