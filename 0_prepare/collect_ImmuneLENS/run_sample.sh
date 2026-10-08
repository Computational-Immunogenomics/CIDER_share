#!/bin/bash
# run_sample.sh — Slice VDJ BAM, run ImmuneLENS, clean up temp BAM.
#
# Usage:
#   bash run_sample.sh <sampleId>
#
# Example:
#   bash run_sample.sh H00003905
#
# Output: /data/tmp/vdj_bam/immunelens_output/<sampleId>_immunelens.csv
# Temp BAM deleted on exit (even if script fails).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SLICED_BAM_DIR="/data/tmp/vdj_bam"

if [ $# -lt 1 ]; then
    echo "Usage: bash run_sample.sh <sampleId>"
    exit 1
fi

SAMPLE_ID="$1"
BAM="${SLICED_BAM_DIR}/${SAMPLE_ID}_vdj.bam"

# Trap: always clean up temp BAM on exit, success or failure
trap "rm -f '${BAM}' '${BAM}.bai'; echo 'Cleaned up temp BAM'" EXIT

echo "=============================="
echo "Sample: $SAMPLE_ID"
echo "=============================="

# Step 1: Slice CRAM from GCS → local BAM
echo "[1/2] Slicing VDJ regions..."
bash "${SCRIPT_DIR}/0_slice.sh" "$SAMPLE_ID"

# Step 2: Run ImmuneLENS on the sliced BAM
echo "[2/2] Running ImmuneLENS..."
Rscript "${SCRIPT_DIR}/1_run_immunelens.R" "$SAMPLE_ID"

echo "=============================="
echo "Complete: $SAMPLE_ID"
echo "=============================="
