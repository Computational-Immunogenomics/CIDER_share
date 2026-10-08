#!/usr/bin/env Rscript
# collect_results.R — Collect all per-sample ImmuneLENS CSVs into one file.
#
# Usage:
#   Rscript collect_results.R
#
# Input:  /data/tmp/vdj_bam/immunelens_output/<sampleId>_immunelens.csv
# Output: /data/tmp/vdj_bam/immunelens_output/immunelens_combined.csv

library(data.table)

IMMUNELENS_DIR <- "/data/tmp/vdj_bam/immunelens_output"
OUT_FILE       <- file.path(IMMUNELENS_DIR, "immunelens_combined.csv")

csv_files <- list.files(IMMUNELENS_DIR, pattern = "_immunelens\\.csv$", full.names = TRUE)

# Exclude the combined output itself if it exists
csv_files <- csv_files[basename(csv_files) != "immunelens_combined.csv"]

if (length(csv_files) == 0) stop("No ImmuneLENS CSVs found in: ", IMMUNELENS_DIR, call. = FALSE)

message("Found ", length(csv_files), " sample file(s). Combining...")

combined <- rbindlist(lapply(csv_files, fread), fill = TRUE)

fwrite(combined, OUT_FILE)

message("Samples:  ", uniqueN(combined$sampleId))
message("Rows:     ", nrow(combined))
message("Saved:    ", OUT_FILE)
