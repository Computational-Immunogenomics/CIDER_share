#!/usr/bin/env Rscript
# assemble_purity_figure.R — Assemble supplemental purity figure (S1).
#
# Figure S1:
#   Row 1 — A: Before/after scatter coloured by purity, 1/3 width
#              (adjustment formula in subtitle)
#            B: Tumour purity by cohort and response, 2/3 width
#   Row 2 — C: CIDER T-cell Score (purity adjusted) vs ICI response (full width)
#
# Run after:
#   1_response.ipynb          (purity_dist, main_response_figure_depth)
#   6_cider_vs_purity.ipynb   (purity_scatter)
#
# Usage:
#   Rscript assemble_purity_figure.R

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
    stop("Missing panel: ", name, ".rds — check notebook has been run.")
  readRDS(path)
}

save_fig <- function(plot, fig_name, width, height) {
  saveRDS(plot, paste0(CIDER_PROJ_DIR, "figs/", fig_name, ".rds"))
  ggsave(paste0(CIDER_PROJ_DIR, "figs/", fig_name, ".png"),
         plot, width = width, height = height, dpi = 300)
  message("Saved: ", fig_name, ".png")
}

# ── Assemble Figure S1 ────────────────────────────────────────────────────────
message("\nAssembling Figure S1 (purity supplement)...")

# Panel A: before/after scatter — formula embedded in subtitle
# Panel B: Tumour purity by cohort and response
# Panel C: CIDER T-cell Score (purity adjusted) vs ICI response
p_scatter <- fig("purity_scatter") +
  ggplot2::labs(subtitle = "Adjusted = CIDER T-cell Score / max(1 − purity, 0.1)") +
  ggplot2::theme(
    plot.subtitle    = ggplot2::element_text(hjust = 0.5, size = 9, face = "italic", colour = "grey30"),
    legend.position  = "bottom",
    legend.direction = "horizontal",
    legend.margin    = ggplot2::margin(t = 2, b = 0)
  ) +
  ggplot2::guides(colour = ggplot2::guide_colourbar(title.position = "left", barwidth = 7, barheight = 0.5))

p_purity_dist <- fig("purity_dist") +
  ggplot2::scale_x_discrete(guide = ggplot2::guide_axis(n.dodge = 2)) +
  ggplot2::theme(
    legend.position  = "bottom",
    legend.direction = "horizontal",
    legend.margin    = ggplot2::margin(t = 2, b = 0)
  )

p_response <- fig("main_response_figure_depth") +
  ggplot2::theme(legend.position = "none")

row1 <- (wrap_elements(full = p_scatter) | wrap_elements(full = p_purity_dist)) +
  plot_layout(widths = c(1, 2))

figure_s1 <-
  (row1 / wrap_elements(full = p_response)) +
  plot_layout(heights = c(1, 1)) +
  figure_annotation("Tumour Purity and CIDER Score Adjustment")

save_fig(figure_s1, "supplement_purity", width = 9.9, height = 8.0)

message("\nDone — supplement_purity.png saved to ", CIDER_PROJ_DIR, "figs/")
