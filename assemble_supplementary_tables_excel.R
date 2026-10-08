#!/usr/bin/env Rscript
# assemble_supplementary_tables_excel.R — Combine all supplementary tables
# (S1-S5) into one submission-ready Excel workbook.
#
# Journals typically want supplementary tables as a single .xlsx (one sheet
# per table, self-contained with its own title and footnote). Each table
# notebook writes only a .csv to figs/ -- a build intermediate, not a
# deliverable in its own right -- plus a small title/footnote metadata
# sidecar (a .json file with the same base name + "_meta") saved alongside
# it; this script reads both and writes them into one workbook, which is
# the only supplementary-table output that actually gets collected into
# figs/paper/ (see collect_paper_figures.R).
#
# The metadata sidecar means this script never re-derives a table's title
# or footnote text (e.g. exclusion counts) itself — that logic stays in
# exactly one place, the table's own notebook — so the two can't drift out
# of sync.
#
# Run after the table notebooks (11b/11c/11d/11e/11f; see
# helpers/table_notebooks.R) have produced their .csv/_meta.json outputs.
# Table 1 (main text, not supplementary) is intentionally excluded.
#
# Usage:
#   Rscript assemble_supplementary_tables_excel.R
#
# Requirements:
#   - r-openxlsx, r-jsonlite, r-readr (see environment.yml)

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
SCRIPT_DIR <- if (length(script_path) > 0) {
  normalizePath(dirname(script_path), mustWork = FALSE)
} else {
  getwd()
}

source(file.path(SCRIPT_DIR, "helpers/map.r"))

figs_dir <- paste0(CIDER_PROJ_DIR, "figs/")

# ── Table manifest ────────────────────────────────────────────────────────────
# One entry per workbook sheet. csv/meta are read relative to figs_dir.
# Order here is the order sheets appear in the workbook.
supplementary_tables <- list(
  list(
    sheet = "Table S1",
    csv   = "table_s1_biopsy_location_breakdown.csv",
    meta  = "table_s1_biopsy_location_breakdown_meta.json"
  ),
  list(
    sheet = "Table S2",
    csv   = "table_s2_pretreatment_by_subcohort.csv",
    meta  = "table_s2_pretreatment_by_subcohort_meta.json"
  ),
  list(
    sheet = "Table S3",
    csv   = "table_s3_demographics_full_cohort.csv",
    meta  = "table_s3_demographics_full_cohort_meta.json"
  ),
  list(
    sheet = "Table S4",
    csv   = "table_s4_tumor_type_by_msi_status.csv",
    meta  = "table_s4_tumor_type_by_msi_status_meta.json"
  ),
  list(
    sheet = "Table S5",
    csv   = "table_s5_treatment_by_mechanism_response.csv",
    meta  = "table_s5_treatment_by_mechanism_response_meta.json"
  )
)

# ── Styles ────────────────────────────────────────────────────────────────────
# Times New Roman throughout, matching fig_references/supplementary_methods_ml_roc.docx.
title_style <- openxlsx::createStyle(
  fontName = "Times New Roman", fontSize = 12, textDecoration = "bold",
  wrapText = TRUE, valign = "center"
)
header_style <- openxlsx::createStyle(
  fontName = "Times New Roman", fontSize = 10, textDecoration = "bold",
  wrapText = TRUE, halign = "center", valign = "center",
  border = "bottom", borderStyle = "medium"
)
body_style <- openxlsx::createStyle(
  fontName = "Times New Roman", fontSize = 10, valign = "center"
)
footnote_style <- openxlsx::createStyle(
  fontName = "Times New Roman", fontSize = 9, textDecoration = "italic",
  wrapText = TRUE, valign = "top"
)

# Adds one table as a self-contained, formatted sheet: a bold title row,
# a blank spacer, the table itself (bold header row, frozen so it stays
# visible on scroll), and — if the table has one — an italic footnote row
# below a second spacer. Column widths are sized to each column's longest
# value (header included), clamped to a sane range so a handful of long
# free-text cells don't blow out the whole sheet.
add_table_sheet <- function(wb, sheet_name, csv_path, meta_path) {
  if (!file.exists(csv_path) || !file.exists(meta_path)) {
    warning(sprintf(
      "Skipping \"%s\": missing %s -- run the notebook that produces it first.",
      sheet_name, if (!file.exists(csv_path)) csv_path else meta_path
    ), call. = FALSE)
    return(invisible(FALSE))
  }

  # Every column read as character: these CSVs already hold display-ready
  # strings (e.g. "12 (34%)", "—"), and forcing character avoids readr
  # silently reformatting anything that happens to look numeric.
  df   <- readr::read_csv(csv_path, col_types = readr::cols(.default = "c"), na = "")
  meta <- jsonlite::fromJSON(meta_path)

  n_col <- ncol(df)
  n_row <- nrow(df)

  openxlsx::addWorksheet(wb, sheet_name)

  # Row 1: title, merged across every data column.
  openxlsx::writeData(wb, sheet_name, meta$title, startRow = 1, startCol = 1, colNames = FALSE)
  openxlsx::mergeCells(wb, sheet_name, cols = seq_len(n_col), rows = 1)
  openxlsx::addStyle(wb, sheet_name, title_style, rows = 1, cols = seq_len(n_col), gridExpand = TRUE)
  openxlsx::setRowHeights(wb, sheet_name, rows = 1, heights = 30)

  # Row 2 is left blank as a spacer; the table starts at row 3.
  header_row     <- 3
  data_start_row <- header_row + 1
  data_end_row   <- data_start_row + n_row - 1

  openxlsx::writeData(
    wb, sheet_name, df, startRow = header_row, startCol = 1,
    colNames = TRUE, borders = "surrounding"
  )
  openxlsx::addStyle(wb, sheet_name, header_style, rows = header_row, cols = seq_len(n_col), gridExpand = TRUE)
  if (n_row > 0) {
    openxlsx::addStyle(
      wb, sheet_name, body_style,
      rows = data_start_row:data_end_row, cols = seq_len(n_col), gridExpand = TRUE
    )
  }
  openxlsx::freezePane(wb, sheet_name, firstActiveRow = data_start_row, firstActiveCol = 2)

  # Footnote (if any): one blank spacer row below the table, then the
  # footnote text merged across every data column.
  footnote <- meta$footnote
  if (!is.null(footnote) && nzchar(footnote)) {
    footnote_row <- data_end_row + 2
    openxlsx::writeData(wb, sheet_name, footnote, startRow = footnote_row, startCol = 1, colNames = FALSE)
    openxlsx::mergeCells(wb, sheet_name, cols = seq_len(n_col), rows = footnote_row)
    openxlsx::addStyle(wb, sheet_name, footnote_style, rows = footnote_row, cols = seq_len(n_col), gridExpand = TRUE)
    openxlsx::setRowHeights(wb, sheet_name, rows = footnote_row, heights = 30)
  }

  col_widths <- vapply(seq_len(n_col), function(i) {
    values <- c(names(df)[i], df[[i]])
    max(nchar(values), na.rm = TRUE)
  }, numeric(1))
  openxlsx::setColWidths(
    wb, sheet_name, cols = seq_len(n_col),
    widths = pmin(pmax(col_widths + 2, 10), 45)
  )

  invisible(TRUE)
}

# ── Build workbook ────────────────────────────────────────────────────────────
wb <- openxlsx::createWorkbook()

n_added <- 0
for (t in supplementary_tables) {
  added <- add_table_sheet(
    wb, t$sheet,
    csv_path  = paste0(figs_dir, t$csv),
    meta_path = paste0(figs_dir, t$meta)
  )
  if (isTRUE(added)) n_added <- n_added + 1
}

if (n_added == 0) {
  stop("No supplementary tables were available to assemble -- run the table notebooks first.", call. = FALSE)
}

out_path <- paste0(figs_dir, "supplementary_tables.xlsx")
openxlsx::saveWorkbook(wb, out_path, overwrite = TRUE)
message(sprintf("Saved: %s (%d of %d sheets)", out_path, n_added, length(supplementary_tables)))
