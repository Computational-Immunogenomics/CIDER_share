#!/bin/bash
# run_all_samples.sh — Run ImmuneLENS for all sample IDs in samples.txt.
#
# Usage:
#   bash run_all_samples.sh
#
# Runs run_sample.sh sequentially for each sample ID in samples.txt.
# Skips samples whose output CSV already exists and is non-empty.
# Logs progress to run_all_samples.log.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLES_FILE="${SCRIPT_DIR}/samples.txt"
LOG_FILE="${SCRIPT_DIR}/run_all_samples.log"
IMMUNELENS_DIR="/data/tmp/vdj_bam/immunelens_output"

if [ ! -f "$SAMPLES_FILE" ]; then
    echo "Error: samples.txt not found at $SAMPLES_FILE"
    exit 1
fi

total=$(grep -c '[^[:space:]]' "$SAMPLES_FILE")
echo "Starting ImmuneLENS run for $total samples. Logging to $LOG_FILE"
echo "==============================" | tee -a "$LOG_FILE"
echo "Run started: $(date)" | tee -a "$LOG_FILE"
echo "==============================" | tee -a "$LOG_FILE"

n=0
n_skip=0
n_fail=0

while IFS= read -r sample_id || [ -n "$sample_id" ]; do
    # Skip blank lines and comments
    [[ -z "$sample_id" || "$sample_id" == \#* ]] && continue

    n=$((n + 1))
    out_csv="${IMMUNELENS_DIR}/${sample_id}_immunelens.csv"

    # Skip if already completed
    if [ -f "$out_csv" ] && [ -s "$out_csv" ]; then
        echo "[$n/$total] SKIP $sample_id (already done)" | tee -a "$LOG_FILE"
        n_skip=$((n_skip + 1))
        continue
    fi

    echo "[$n/$total] Running $sample_id..." | tee -a "$LOG_FILE"

    if bash "${SCRIPT_DIR}/run_sample.sh" "$sample_id" >> "$LOG_FILE" 2>&1; then
        echo "[$n/$total] OK   $sample_id" | tee -a "$LOG_FILE"
    else
        echo "[$n/$total] FAIL $sample_id" | tee -a "$LOG_FILE"
        n_fail=$((n_fail + 1))
    fi

done < "$SAMPLES_FILE"

echo "==============================" | tee -a "$LOG_FILE"
echo "Run complete: $(date)" | tee -a "$LOG_FILE"
echo "Processed: $total | Skipped: $n_skip | Failed: $n_fail" | tee -a "$LOG_FILE"
echo "==============================" | tee -a "$LOG_FILE"
