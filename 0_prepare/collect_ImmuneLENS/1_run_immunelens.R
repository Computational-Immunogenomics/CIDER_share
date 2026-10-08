#!/usr/bin/env Rscript
# 1_run_immunelens.R — Run ImmuneLENS on a pre-sliced VDJ BAM file.
#
# Run AFTER 0_slice.sh has produced the sliced BAMs.
#
# Usage:
#   Rscript 1_run_immunelens.R <sampleId>
#
# Example:
#   Rscript 1_run_immunelens.R H00003905
#
# Input:  <SLICED_BAM_DIR>/<sampleId>_vdj.bam  (produced by loop_slicing.sh)
# Output: <IMMUNELENS_DIR>/<sampleId>_immunelens.csv
# Temp:   coverage files deleted after use

library(ImmuneLENS)
library(data.table)

# ── Configuration ─────────────────────────────────────────────────────────────
# Directory where 0_slice.sh wrote the pre-sliced BAMs
SLICED_BAM_DIR <- "/data/tmp/vdj_bam"

# Output directory for ImmuneLENS results
IMMUNELENS_DIR <- "/data/tmp/vdj_bam/immunelens_output"

genome_ver  <- "hg38"
target_loci <- c("TCRA", "TCRB", "TCRG", "IGH")
# ─────────────────────────────────────────────────────────────────────────────

# ── Argument ──────────────────────────────────────────────────────────────────
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: Rscript 1_run_immunelens.R <sampleId>", call. = FALSE)
sample_id <- args[1]
message("Sample: ", sample_id)

# ── Locate pre-sliced BAM ─────────────────────────────────────────────────────
bam_input <- file.path(SLICED_BAM_DIR, paste0(sample_id, "_vdj.bam"))
if (!file.exists(bam_input)) stop("Sliced BAM not found: ", bam_input, call. = FALSE)
message("BAM:    ", bam_input)

# ── Output paths ──────────────────────────────────────────────────────────────
dir.create(IMMUNELENS_DIR, showWarnings = FALSE, recursive = TRUE)
cov_dir <- paste0(file.path(IMMUNELENS_DIR, "cov_tmp", sample_id), "/")
out_csv <- file.path(IMMUNELENS_DIR, paste0(sample_id, "_immunelens.csv"))
dir.create(cov_dir, showWarnings = FALSE, recursive = TRUE)

# Skip if output already exists and is non-empty
if (file.exists(out_csv) && file.size(out_csv) > 0) {
  message("Already done, skipping: ", out_csv)
  quit(status = 0)
}

# ── Run ImmuneLENS ────────────────────────────────────────────────────────────
message("\nRunning ImmuneLENS...")
combined_results <- list()

for (locus in target_loci) {
  message("  Locus: ", locus)

  cov_path <- tryCatch(
    getCovFromBam_WGS(bamPath = bam_input, outPath = cov_dir,
                      vdj.gene = locus, hg19_or_38 = genome_ver),
    error = function(e) { message("  getCovFromBam_WGS failed: ", e$message); NULL }
  )
  if (is.null(cov_path)) next

  # loadCov() strips the chr column and returns a 2-col df: pos, reads.
  # This is exactly what runImmuneLENS expects internally.
  cov_df <- tryCatch(
    loadCov(cov_path),
    error = function(e) { message("  loadCov failed: ", e$message); NULL }
  )
  if (is.null(cov_df)) next

  # Check minimum coverage — runImmuneLENS needs sufficient positions to fit the model.
  min_rows <- 500
  if (nrow(cov_df) < min_rows) {
    message("  SKIPPED: insufficient coverage (", nrow(cov_df), " positions < ", min_rows, " required)")
    next
  }
  mean_depth <- mean(cov_df$reads, na.rm = TRUE)
  if (mean_depth < 5) {
    message("  SKIPPED: mean depth too low (", round(mean_depth, 1), "x < 5x required)")
    next
  }

  model_out <- tryCatch({
    if (locus == "IGH") {
      # IGH requires the advanced GC correction pipelines
      ImmuneLENS::runImmuneLENS(
        vdj.region.df = cov_df,
        vdj.gene      = locus,
        hg19_or_38    = genome_ver,
        GC_correct    = TRUE,
        removed_flag  = TRUE
      )
    } else {
      # TCRA, TCRB, TCRG run with standard baseline parameters
      ImmuneLENS::runImmuneLENS(
        vdj.region.df = cov_df,
        vdj.gene      = locus,
        hg19_or_38    = genome_ver
      )
    }
  }, error = function(e) {
    message("  runImmuneLENS failed: ", e$message)
    NULL
  })
  if (is.null(model_out)) next

  result          <- model_out[[1]]
  result$sample   <- NULL
  result$sampleId <- sample_id
  result$locus    <- locus
  result          <- result[, c("sampleId", "locus", setdiff(names(result), c("sampleId", "locus")))]

  # Standardise locus-specific column names so rbindlist works across loci.
  # Each locus names its fraction column differently (TCRA.tcell.fraction,
  # IGH.bcell.fraction, etc.) and its Shannon columns by gene segment name.
  names(result) <- gsub("^.*\\.tcell\\.fraction$", "fraction", names(result))
  names(result) <- gsub("^.*\\.bcell\\.fraction$", "fraction", names(result))
  names(result) <- gsub("^shannon\\.[A-Z]+V\\.div$", "shannon_V_div", names(result))
  names(result) <- gsub("^shannon\\.[A-Z]+J\\.div$", "shannon_J_div", names(result))

  combined_results[[locus]] <- result

  # Remove coverage file immediately after use
  unlink(cov_path)
  message("    Done: ", locus)
}

# ── Clean up coverage temp directory ─────────────────────────────────────────
unlink(cov_dir, recursive = TRUE)

# ── Save output ───────────────────────────────────────────────────────────────
if (length(combined_results) == 0) stop("All loci failed: ", sample_id, call. = FALSE)

final_df <- data.table::rbindlist(combined_results, fill = TRUE)
data.table::fwrite(final_df, out_csv)

message("\nSaved: ", out_csv)
message("Loci completed: ", paste(names(combined_results), collapse = ", "))
