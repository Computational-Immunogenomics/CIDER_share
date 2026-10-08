# =============================================================================
# map.r — project-wide path constants and file utilities
# Source this at the top of every notebook before shortcuts.r.
# =============================================================================

# --- Input directories -------------------------------------------------------
I_DIR      <- "/mnt/immunocompnas1/datasets/hartwig_hg38/"
SOM_DIR    <- paste0(I_DIR, "dna-6.0/")
SOM_DIR_LQ <- "/mnt/immunocompnas1/datasets/hartwig_hg38/low_quality/"  # low-quality samples

# --- Derived biomarker directories -------------------------------------------
TMP_DIR    <- paste0(I_DIR, "biomarkers/database/")
READY_DIR  <- paste0(I_DIR, "biomarkers/ready/")

CIDER_DIR  <- paste0(TMP_DIR, "cider/")
PURPLE_DIR <- paste0(TMP_DIR, "purple/")
COBALT_DIR <- paste0(TMP_DIR, "cobalt/")
AMBER_DIR  <- paste0(TMP_DIR, "amber/")
ISO_DIR    <- paste0(TMP_DIR, "isofox/")
LILAC_DIR = paste0(TMP_DIR, "lilac/")
LINX_DIR = paste0(TMP_DIR, "linx/")

# --- Project output directory ------------------------------------------------
CIDER_PROJ_DIR <- "/mnt/immunocompnas1/datasets/cdr3_hg38/"

# Ensure output sub-directories exist at source time
dir.create(CIDER_PROJ_DIR,                              showWarnings = FALSE, recursive = TRUE)
dir.create(paste0(CIDER_PROJ_DIR, "figs/"),             showWarnings = FALSE, recursive = TRUE)
dir.create(paste0(CIDER_PROJ_DIR, "schematic_figs/"),   showWarnings = FALSE, recursive = TRUE)

# --- Shared reference files --------------------------------------------------
# DNA-RNA sample ID matching table
PAIRED_IDS <- paste0(I_DIR, "paired_ids.tsv")

# =============================================================================
# Utility: assert that all required input files exist before a notebook runs.
# Call at the top of each notebook after sourcing map.r.
#
# Usage:
#   assert_files_exist(
#     "Clinical data"  = paste0(READY_DIR, "clinical_update.txt"),
#     "Purity table"   = paste0(READY_DIR, "purple_ready.csv")
#   )
# =============================================================================
assert_files_exist <- function(...) {
  paths  <- c(...)
  labels <- names(paths)
  missing <- !file.exists(paths)
  if (any(missing)) {
    msgs <- paste0("  [", labels[missing], "] ", paths[missing])
    stop("Required input files not found:\n", paste(msgs, collapse = "\n"), call. = FALSE)
  }
  invisible(NULL)
}

# =============================================================================
# get_fp() — resolve the canonical file path for a sample / data type pair.
# Returns a plain character string; no coercion needed (paste0 already does it).
# =============================================================================
get_fp <- function(i, type = "purity") {
  switch(type,
    # PURPLE
    "purity"       = paste0(SOM_DIR, i, "/purple/", i, ".purple.purity.tsv"),
    "qc"           = paste0(SOM_DIR, i, "/purple/", i, ".purple.qc"),

    # CIDER
    "cider.vdj"    = paste0(SOM_DIR, i, "/cider/", i, ".cider.vdj.tsv.gz"),

    stop("Unknown file type: '", type, "'", call. = FALSE)
  )
}

# =============================================================================
# reader / safe_read — load a per-sample file and tag with sampleId.
# safe_read returns NULL on error rather than stopping execution.
# =============================================================================
reader <- function(i_file, sample) {
  tmp <- fread(i_file)
  if (nrow(tmp) > 0 && ncol(tmp) > 1) mutate(tmp, sampleId = sample) else NULL
}

safe_read <- function(i_file, sample) {
  tryCatch(reader(i_file, sample), error = function(e) NULL)
}
