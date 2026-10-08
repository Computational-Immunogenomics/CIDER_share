#!/usr/bin/env Rscript
# assemble_main_figures.R — Assemble Figures 2–6 from saved .rds panels.
#
# Figure 2: CIDER Score Landscape + RNA/ImmuneLENS validation + locus correlation heatmap
# Figure 3: CIDER Score vs ICI Response
# Figure 4: CIDER Score vs Overall Survival
# Figure 5: TMB Orthogonality | ROC | CIDER×TMB Survival
# Figure 6: Predictive specificity for ICI therapy vs. general prognostic effects
#
# Note: Figure 7 (predicted non-response: model schematic | CPI cohorts |
# landscape) is assembled separately by assemble_nonresponse_figure.R, not
# here -- it depends on 7_predicted_response_landscape.ipynb's panels, which
# this script doesn't otherwise need.
#
# Run after the relevant figure notebooks have been executed:
#   0_landscape.ipynb, 1_response.ipynb, 2_survival.ipynb,
#   4_cider_validation.ipynb, 5_cider_vs_tmb.ipynb, 9_roc.ipynb,
#   3_survival_with_tmb.ipynb, 20_ici_specificity_main.ipynb
#
# Usage:
#   Rscript assemble_main_figures.R

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
# ggtext must be loaded (not just installed) for element_grob() to dispatch
# on the element_markdown() strip text used by Figure 6's saved plot object
# (20_ici_specificity_main.ipynb) -- that S3 method is only registered once
# this library() call runs, since this script is a separate R process from
# the notebook that built and saved the .rds.
library(ggtext)

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

# ── Figure 2 — CIDER Score Landscape + RNA/ImmuneLENS/Correlation (4 panels) ──
# Standardized on the former "Figure 2b" layout (adds the pairwise TCR-locus
# correlation heatmap as Panel D) per direction to focus on this version.
message("\nAssembling Figure 2...")

figure_2 <-
  fig("landscape") /
  wrap_plots(fig("tcell_validation_rna"), fig("tcell_validation_il"),
             fig("cider_corr_heatmap"),
             nrow = 1, widths = c(1.0, 2.2, 1.0)) +
  plot_layout(heights = c(1.1, 1.0)) +
  plot_annotation(
    tag_levels = "A",
    theme = go_theme + theme(plot.tag = element_text(size = 14, face = "bold"))
  )

save_fig(figure_2, "figure_2", width = 14, height = 8.1)

# Note: Figure 3b (overall + per-locus loci breakdown) and Figure 3c
# (overall + combined alpha-beta loci + TRG) were previously also assembled
# here, from the response_loci_*/response_loci_3c_bottom panels saved by
# 1_response.ipynb. Skipped per direction to only output Figure 3 below;
# those panel .rds files are still produced by 1_response.ipynb if needed
# again.

# ── Figure 3 — CIDER Score Predicts ICI Response ─────────────────────────────
message("\nAssembling Figure 3...")

figure_3 <-
  fig("main_response_figure") +
  plot_annotation(
    theme = go_theme
  )

save_fig(figure_3, "figure_3", width = 11, height = 5)

# ── Figure 4 — CIDER Score Predicts Overall Survival ─────────────────────────
message("\nAssembling Figure 4...")

figure_4 <-
  wrap_elements(full = fig("main_survival_figure")) +
  plot_annotation(
    theme = go_theme
  )

save_fig(figure_4, "figure_4", width = 11, height = 7.2)  # 10% shorter (was height = 8)

# ── Figure 5 — TMB Independence and Additive Value ───────────────────────────
message("\nAssembling Figure 5...")

figure_5 <-
  (fig("tmb_vs_tcell") | fig("overall_roc") | fig("pan_cancer_survival_tmb")) +
  plot_layout(widths = c(1, 1, 1)) +
  plot_annotation(
    tag_levels = "A",
    theme = go_theme + theme(plot.tag = element_text(size = 14, face = "bold"))
  )

save_fig(figure_5, "figure_5", width = 13, height = 5)

# ── Figure 6 — Predictive Specificity for ICI Therapy vs. General Prognostic Effects ──
# Single-panel figure, already fully titled/captioned by
# 20_ici_specificity_main.ipynb -- no additional tag/title needed, same
# pattern as Figure 3/4 above. Replaces the former Figure 7
# (main_ici_specificity_figure, retired from the main figure sequence --
# superseded by this figure, which is this analysis's updated version).
#
# ici_specificity_predictive_vs_prognostic.rds is a gtable/grob (it has a
# text label manually inserted into its facet spacing), not a plain ggplot
# object -- wrap_elements() accepts that without issue, same as any other
# grob.
message("\nAssembling Figure 6...")

figure_6 <-
  wrap_elements(full = fig("ici_specificity_predictive_vs_prognostic")) +
  plot_annotation(
    theme = go_theme
  )

save_fig(figure_6, "figure_6", width = 7.7, height = 4.9)

# Note: Figure 7 (predicted non-response: model schematic | CPI cohorts |
# landscape) is assembled by assemble_nonresponse_figure.R, not here -- see
# that script for the figure_7.png build.

message("\nDone — Figures 2–6 saved to ", CIDER_PROJ_DIR, "figs/")
