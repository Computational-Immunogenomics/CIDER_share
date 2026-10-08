library(ggpubr)

# =============================================================================
# PROJECT COLOUR PALETTE — single source of truth for every colour used in
# any figure under 1_figures/. Exactly six hex values, no exceptions: every
# scale_fill_manual()/scale_colour_manual() value, every geom_*(colour = ...)
# override, every annotate()/element_text() colour, anywhere in the paper,
# is one of the six COL_* constants below (or a named palette built from
# them, e.g. responder_colors). Never hardcode a literal hex string, a
# ggplot "greyNN" shade, or "black" in a notebook -- reuse the constant so
# the whole paper's colour scheme stays changeable from this one file.
#
# Semantic roles (apply the SAME role to the SAME kind of concept in every
# figure, so a colour always means the same thing across the whole paper):
#   COL_POSITIVE -- orange.      The headline "CIDER + TMB" combined model in
#                   the ROC/AUC model-comparison panels (9_roc.ipynb Figure
#                   5B and 12_xgboost_model.ipynb's supplement) -- the one
#                   model these panels want to draw the eye to. Not used for
#                   Responder/High (see COL_ACCENT below) -- keep this
#                   confined to the model-comparison context so it still
#                   reads as one consistent "headline" meaning everywhere it
#                   appears.
#   COL_NEGATIVE -- medium grey. "Negative"/baseline value: Non-Responder,
#                   CIDER T-cell Low, the bottom end of any 3-level ordered
#                   scale. Doubles as the project's one general-purpose
#                   "muted/reference/structural" ink -- dashed guide lines,
#                   de-emphasised points, box/violin outlines, anywhere a
#                   notebook previously reached for an ad hoc "grey40",
#                   "grey50", "grey60", "grey70", "grey80", or "grey90".
#   COL_MID      -- sage green.  The middle tier of any 3-level ordered
#                   scale (tertile_color's "Medium"), or a second
#                   categorical value when a figure needs exactly 3
#                   same-family groups.
#   COL_ACCENT   -- blue.        "Positive"/exceptional value: Responder,
#                   CIDER T-cell High, and the top end of any 3-level
#                   ordered scale (tertile_color's "High"). Also the general
#                   second accent for any two-category comparison that is
#                   NOT a Responder/High-Low-style positive/negative
#                   contrast (e.g. a read-type, a covariate-adjustment
#                   spec, or "CIDER Score" alone in a model-comparison
#                   panel where COL_POSITIVE is reserved for the combined
#                   "CIDER + TMB" model -- see COL_POSITIVE above).
#   COL_OVERLAY  -- coral-red.   RESERVED. Used in exactly one place in the
#                   whole paper: the published-literature ORR reference
#                   overlay on Figure 7's predicted-response-landscape panel
#                   (1_figures/7_predicted_response_landscape.ipynb). Never
#                   used as a general categorical colour anywhere else.
#   COL_INK      -- charcoal.    All label/annotation text and strong
#                   structural lines: plot titles, axis text, legend text,
#                   geom_text() annotations (medians, counts, p-values,
#                   significance stars), axis lines/ticks. Replaces every
#                   ad hoc "black", "grey10", "grey20", "grey30" used for
#                   text or strong lines. Set as go_theme's default text
#                   colour below, so most text needs no per-call override.
# =============================================================================
COL_POSITIVE <- "#d08934"   # orange      — headline "CIDER + TMB" model (ROC/AUC model-comparison panels only)
COL_NEGATIVE <- "#828282"   # medium grey — negative / Low / Non-Responder; also general muted/reference ink
COL_MID      <- "#7e9d7d"   # sage green  — Medium / third category in a 3-level family
COL_ACCENT   <- "#5a8fb4"   # blue        — positive / High / Responder; general second accent elsewhere
COL_OVERLAY  <- "#d2544e"   # coral-red   — RESERVED for the Figure 7 literature-ORR overlay only
COL_INK      <- "#2a2a2a"   # charcoal    — all text/annotation and strong structural lines

# responder_colors <- c("Responder"     = "#D55E00",   # vermillion — positive outcome
#                       "Non-Responder" = "#0072B2")   # blue       — negative outcome
responder_colors <- c("Responder"     = COL_ACCENT,
                      "Non-Responder" = COL_NEGATIVE)

# high_low_color   <- c("Low"  = "#56B4E9",            # sky blue     — low infiltration
#                       "High" = "#009E73")             # bluish green — high infiltration
high_low_color   <- c("Low"  = COL_NEGATIVE,
                      "High" = COL_ACCENT)

# Tertile palette for three-group KM plots (Low / Medium / High)
# tertile_color <- c(
#   "Low"    = "#56B4E9",   # sky blue     — low infiltration
#   "Medium" = "#E69F00",   # orange       — medium infiltration
#   "High"   = "#009E73"    # bluish green — high infiltration
# )
tertile_color <- c(
  "Low"    = COL_NEGATIVE,
  "Medium" = COL_MID,
  "High"   = COL_ACCENT
)

# Shared 4-endpoint palette (OS / PFS / BOR / DCB) -- used by every forest
# plot and endpoint-coloured panel in the paper (8_forest.ipynb,
# 10_unique_vs_total.ipynb, 19_dna_vs_rna_response.ipynb,
# 20_ici_specificity_main.ipynb), defined once here instead of re-declared
# ad hoc per notebook, so OS/PFS/BOR/DCB are always the same colour
# wherever they appear. Survival endpoints (OS, PFS) get the two "cool"
# project colours; response endpoints (BOR, DCB) get the
# orange/grey pair -- an arbitrary but fixed and documented split, not a
# positive/negative judgement about any one endpoint (note: this orange/grey
# pair is no longer the same pairing responder_colors uses for
# Responder/Non-Responder -- see COL_POSITIVE/COL_ACCENT above).
endpoint_colors <- c(
  "OS"  = COL_ACCENT,
  "PFS" = COL_MID,
  "BOR" = COL_POSITIVE,
  "DCB" = COL_NEGATIVE
)

# Generic CIDER × TMB groups — gp prefix is stripped in survival_tmb_plot
# before these are applied, so keys are always "Low/High / TMB Low/High".
# Currently unused anywhere in the pipeline (kept for any notebook that
# revives the 4-group CIDER x TMB survival panel). Low/Low and High/High
# reuse the project's negative/positive pair; the two "mixed" groups use
# the sage/blue pair rather than a 7th colour.
multi_cols <- c(
  "Low / TMB Low"   = COL_NEGATIVE,
  "Low / TMB High"  = COL_ACCENT,
  "High / TMB Low"  = COL_MID,
  "High / TMB High" = COL_POSITIVE
)

# =============================================================================
# Base theme — journal-ready sizing (reproduces cleanly at 85–170 mm width)
# =============================================================================
go_theme <-
  theme_classic() +
  theme(
    text              = element_text(colour = COL_INK),
    panel.grid.major  = element_blank(),
    panel.grid.minor  = element_blank(),
    plot.title        = element_text(hjust = 0.5, size = 11, face = "bold", colour = COL_INK),
    axis.text.x       = element_text(size = 9, colour = COL_INK),
    axis.text.y       = element_text(size = 9, colour = COL_INK),
    axis.title.x      = element_text(size = 11, colour = COL_INK),
    axis.title.y      = element_text(size = 11, colour = COL_INK),
    axis.line         = element_line(colour = COL_INK),
    axis.ticks        = element_line(colour = COL_INK),
    legend.text       = element_text(size = 9, colour = COL_INK),
    legend.title      = element_text(size = 10, face = "bold", colour = COL_INK),
    strip.text        = element_text(size = 9, colour = COL_INK),
    strip.background  = element_blank(),
    plot.tag          = element_text(size = 11, face = "bold", hjust = 0, colour = COL_INK)
  )

# =============================================================================
# figure_annotation() — consistent patchwork plot_annotation wrapper.
#
# Adds bold A/B/C panel tags and a centred, bold figure title.
# Use in place of inline plot_annotation() in every multi-panel figure.
#
# Usage:
#   (p1 | p2) + figure_annotation("My Figure Title")
#   (p1 | p2) + figure_annotation()           # no title
#   wrap_plots(...) + figure_annotation(tag = FALSE)  # title only
# =============================================================================
figure_annotation <- function(title = NULL, tag = TRUE, legend_pos = NULL, tag_size = 11) {
  # legend_pos: pass "bottom", "right", etc. to control collected-legend placement.
  # tag_size: override default panel label size (default 11).
  # Avoids the patchwork `&` operator, which conflicts with R's S7 dispatch
  # in some package versions.
  leg <- if (!is.null(legend_pos)) theme(legend.position = legend_pos) else theme()
  plot_annotation(
    title      = title,
    tag_levels = if (tag) "A" else NULL,
    theme      = go_theme + theme(
      plot.title = element_text(hjust = 0.5, size = 13, face = "bold", colour = COL_INK),
      plot.tag   = element_text(size = tag_size, face = "bold", hjust = 0, colour = COL_INK)
    ) + leg
  )
}

# =============================================================================
# fmt_pval() — format p-values for figure annotations.
# Shows exact values for p >= 0.001; scientific notation for smaller values.
# Examples: 0.023 → "p = 0.023", 7.4e-11 → "p = 7.4e-11"
# =============================================================================
fmt_pval <- function(p) {
  if (is.na(p)) return("p = NA")
  if (p >= 0.001) return(paste0("p = ", round(p, 3)))
  paste0("p = ", formatC(p, format = "e", digits = 1))
}

# =============================================================================
# log10p1_trans — log10(x + 1) axis transformation for CIDER Score axes.
#
# Maps zero-infiltration samples to 0 (log10(0+1) = 0), avoiding -Inf.
# Use with scale_x_continuous(trans = log10p1_trans) or scale_y_continuous().
# Equivalent to log1p but in base 10 for readable axis labels.
# =============================================================================
log10p1_trans <- scales::trans_new(
  name      = "log10p1",
  transform = function(x) log10(x + 1),
  inverse   = function(x) 10^x - 1,
  breaks    = function(x) c(0, 1, 10, 100),
  format    = function(x) scales::number(x, accuracy = 1)
)

# =============================================================================
# stat_cor tag layers — use tags_main for primary panels, tags_supp for
# supplementary panels with more facets and less space.
# =============================================================================
tags_main <- list(
  theme(plot.tag = element_text(size = 11, face = "bold",
                                margin = margin(b = 8, r = 8))),
  # label.y = Inf places the annotation at the top of the panel frame,
  # above the data range, so scatter points can never obscure it.
  # vjust = 1.3 drops it just below the top edge.
  stat_cor(method = "pearson", aes(label = after_stat(r.label)),
           label.x.npc = "left", label.y = Inf, vjust = 1.3,
           fontface = "bold", size = 3.5, colour = COL_INK)
)

tags_supp <- list(
  theme(plot.tag = element_text(size = 10, face = "bold",
                                margin = margin(b = 6, r = 6))),
  stat_cor(method = "pearson", aes(label = after_stat(r.label)),
           label.x.npc = "left", label.y = Inf, vjust = 1.3,
           fontface = "bold", size = 3.0, colour = COL_INK)
)

# =============================================================================
# density_alpha() — map local 2D point density to alpha for scatter plots.
#
# Computes a 2D kernel density estimate (MASS::kde2d) in the *visual* space
# (after axis transformation) so that alpha contours match what the viewer
# sees. Dense regions become more opaque; sparse outliers more transparent.
#
# Arguments:
#   x, y        : raw data vectors (before any axis transformation)
#   tx, ty      : transformations matching the plot axis scales.
#                 Default: identity (linear axes).
#                 For log10p1_trans axes use: function(v) log10(v + 1)
#   n           : KDE grid resolution (default 100)
#   alpha_range : c(min_alpha, max_alpha) for lowest/highest density points
#
# Usage — single panel:
#   df |> mutate(pt_alpha = density_alpha(x, y,
#                  tx = function(v) log10(v + 1), ty = function(v) log10(v + 1)))
#
# Usage — faceted plot (per-group density):
#   df |>
#     group_by(facet_var) |>
#     mutate(pt_alpha = density_alpha(x, y, tx = function(v) log10(v + 1))) |>
#     ungroup()
#
# In ggplot:
#   geom_point(aes(alpha = pt_alpha), colour = COL_NEGATIVE, size = 0.7) +
#   scale_alpha_identity(guide = "none")
# =============================================================================
density_alpha <- function(x, y,
                           tx = identity, ty = identity,
                           n = 100, alpha_range = c(0.08, 0.85)) {
  xt  <- tx(x)
  yt  <- ty(y)
  ok  <- is.finite(xt) & is.finite(yt)
  out <- rep(NA_real_, length(x))
  # kde2d calls bw.nrd0 internally, which returns 0 when IQR is 0 (e.g. many
  # tied zeros). Use tryCatch to fall back to uniform mid-alpha in that case.
  d <- tryCatch(
    MASS::kde2d(xt[ok], yt[ok], n = n),
    error = function(e) NULL
  )
  if (is.null(d)) {
    out[ok] <- mean(alpha_range)
    return(out)
  }
  ix  <- pmax(1L, pmin(findInterval(xt, d$x), n))
  iy  <- pmax(1L, pmin(findInterval(yt, d$y), n))
  out[ok] <- scales::rescale(d$z[cbind(ix[ok], iy[ok])], to = alpha_range)
  out
}

# =============================================================================
# response_plot() — boxplot of CIDER CDR3 richness by ICI response, faceted
# by an arbitrary grouping column on the x-axis (cohort, read-confidence
# filter, etc.).
#
# Originally defined inline in 1_figures/1_response.ipynb; moved here so it
# can be reused without duplication by any notebook that needs the same
# "responder vs non-responder" boxplot style — e.g.
# 1_figures/17_response_by_read_confidence.ipynb, which reuses it unmodified
# by passing a "read confidence filter" column in place of a cohort column.
#
# Arguments:
#   data       — a data frame with columns: gp, responder, and whatever
#                x_col/y_col name.
#   cdr3_gp    — value to filter `gp` to: "T-cell" or a per-locus group
#                (e.g. "T-cell (TRA/TRD)"). Set every row's gp to this same value
#                beforehand if the caller has already restricted the data
#                (the filter becomes a no-op in that case).
#   x_col      — column for the x-axis (e.g. "cohort_broad_go", or any other
#                grouping factor such as a read-confidence filter label).
#   title      — plot title.
#   y_col      — which CIDER score to plot: "cider_score" (unadjusted),
#                "cider_score_adj" (purity + depth adjusted), or
#                "cider_score_depth_adj" (depth adjusted only).
#   x_dodge    — number of rows to stagger x-axis labels across
#                (ggplot2::guide_axis(n.dodge = ...)), to avoid overlapping
#                labels when x_col has long text (e.g. MSI-status group
#                names). Default 1 (single row, unchanged behaviour for all
#                existing callers).
# =============================================================================
response_plot <- function(data, cdr3_gp, x_col, title, y_col = "cider_score", x_dodge = 1) {
  y_lab <- switch(y_col,
    cider_score           = paste0("CIDER Raw ",      cdr3_gp, " Score"),
    cider_score_adj       = paste0("CIDER ", cdr3_gp, " Score (Purity Adjusted)"),
    cider_score_depth_adj = paste0("CIDER ", cdr3_gp, " Score"),
    y_col
  )

  df <- data |> dplyr::filter(gp == cdr3_gp)

  # Per-group medians (shown inside/above boxes)
  med_labels <- df |>
    dplyr::group_by(.data[[x_col]], responder) |>
    dplyr::summarise(med = median(.data[[y_col]], na.rm = TRUE), .groups = "drop") |>
    dplyr::mutate(med_label = as.character(round(med)))

  # Per-group counts (shown at bottom of plot)
  count_labels <- df |>
    dplyr::group_by(.data[[x_col]], responder) |>
    dplyr::summarise(n = dplyr::n(), .groups = "drop") |>
    dplyr::mutate(n_label = paste0("n = ", n))

  # Jitter data: cap at 150 points per x-group × response group to avoid overplotting
  jitter_data <- df |>
    dplyr::group_by(.data[[x_col]], responder) |>
    dplyr::slice_sample(n = 150) |>
    dplyr::ungroup()

  df |>
    ggplot2::ggplot(ggplot2::aes(x = .data[[x_col]], y = .data[[y_col]], fill = responder)) +
    ggplot2::geom_jitter(
      data     = jitter_data,
      ggplot2::aes(colour = responder),
      position = ggplot2::position_jitterdodge(jitter.width = 0.15, dodge.width = 0.75),
      alpha = 0.2, size = 0.5, show.legend = FALSE
    ) +
    ggplot2::scale_colour_manual(values = responder_colors, guide = "none") +
    ggplot2::geom_boxplot(alpha = 0.7, outlier.shape = NA) +
    ggplot2::geom_text(
      data        = med_labels,
      ggplot2::aes(x = .data[[x_col]], y = med, label = med_label, group = responder),
      inherit.aes = FALSE,
      position    = ggplot2::position_dodge(width = 0.75),
      vjust = -0.4, size = 2.2, fontface = "bold", colour = COL_INK
    ) +
    ggplot2::geom_text(
      data        = count_labels,
      ggplot2::aes(x = .data[[x_col]], y = 0, label = n_label, group = responder),
      inherit.aes = FALSE,
      position    = ggplot2::position_dodge(width = 0.75),
      vjust = 1.5, size = 2.4, colour = COL_NEGATIVE
    ) +
    go_theme +
    ggplot2::scale_fill_manual(values = responder_colors) +
    ggpubr::stat_compare_means(
      ggplot2::aes(group = responder), method = "wilcox.test",
      label = "p.format", digits = 2, vjust = -1, colour = COL_INK
    ) +
    ggplot2::scale_x_discrete(guide = ggplot2::guide_axis(n.dodge = x_dodge)) +
    ggplot2::scale_y_continuous(
      trans  = log10p1_trans,
      expand = ggplot2::expansion(mult = c(0.06, 0.10))
    ) +
    ggplot2::labs(y = y_lab, x = "Cohort", fill = "Response", title = title) +
    ggplot2::theme(plot.title = ggplot2::element_text(size = 13, face = "bold", hjust = 0.5, colour = COL_INK))
}
