# helpers/table_notebooks.R — single source of truth for the notebooks that
# produce this project's demographic / cohort-composition tables (Table 1
# and Tables S1-S5).
#
# Sourced by both run_figures.R (as part of the full figure pipeline) and
# run_tables.R (to regenerate just the tables on their own). Keeping this
# list in exactly one place avoids the drift problem run_all.R's own header
# comment already documents for hand-maintained notebook lists: a new table
# notebook added to one script but forgotten in the other, silently falling
# out of sync. Add a new table notebook here once and both scripts pick it
# up automatically.
TABLE_NOTEBOOKS <- c(
  "1_figures/11_demographic_table.ipynb",              # Table 1 (main text): ICI cohort demographics by response
  # Listed in ascending supplementary-table-number order (not file-name
  # order) for readability; none of these notebooks depend on each other,
  # so this order doesn't affect execution.
  "1_figures/11f_biopsy_location_breakdown.ipynb",       # Table S1 (supplementary): biopsy location breakdown
  "1_figures/11c_pretreatment_by_subcohort.ipynb",     # Table S2 (supplementary): pretreatment % by tumor type
  "1_figures/11b_demographic_table_full_cohort.ipynb", # Table S3 (supplementary): full pan-cancer cohort demographics
  "1_figures/11d_tumor_type_by_msi_status.ipynb",      # Table S4 (supplementary): primary tumor type by MSI status
  "1_figures/11e_treatment_by_mechanism_response.ipynb" # Table S5 (supplementary): ICI treatment regimens by mechanism and response
)
