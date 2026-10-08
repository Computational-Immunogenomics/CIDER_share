#!/bin/bash
# 0_slice.sh — Slice VDJ regions from GCS CRAM for one sample.
#
# Usage:
#   bash 0_slice.sh <sampleId>
#
# Example:
#   bash 0_slice.sh H00003905

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Configuration ─────────────────────────────────────────────────────────────
BED_FILE="${SCRIPT_DIR}/../../immunelens_ready.bed"   # repo-bundled VDJ loci BED
REF_GENOME="/home/rhassaine/ref_genome/38/GRCh38_masked_exclusions_alts_hlas.fasta"  # cluster-specific; update for your site
OUTPUT_DIR="/data/tmp/vdj_bam"
# ─────────────────────────────────────────────────────────────────────────────

if [ $# -lt 1 ]; then
    echo "Usage: bash 0_slice.sh <sampleId>"
    exit 1
fi

SAMPLE_ID="$1"
OUTPUT_BAM="${OUTPUT_DIR}/${SAMPLE_ID}_vdj.bam"

# Skip if already done
if [ -f "$OUTPUT_BAM" ] && [ -f "${OUTPUT_BAM}.bai" ]; then
    echo "Already done, skipping: $OUTPUT_BAM"
    exit 0
fi

mkdir -p "$OUTPUT_DIR"

CRAM_GS_URL="gs://hartwig-reads/dna/${SAMPLE_ID}/tumor/alignments/${SAMPLE_ID}.cram"

echo "Sample:  $SAMPLE_ID"
echo "Input:   $CRAM_GS_URL"
echo "Output:  $OUTPUT_BAM"

# Refresh GCS token
export GCS_OAUTH_TOKEN=$(gcloud auth print-access-token 2>/dev/null)
if [ -z "$GCS_OAUTH_TOKEN" ]; then
    echo "Error: Failed to fetch GCS token. Run: gcloud auth login"
    exit 1
fi

# cd to output dir so samtools writes the remote CRAM index cache there
cd "$OUTPUT_DIR"

# Slice VDJ regions
echo "Slicing..."
samtools view -h -b -T "$REF_GENOME" -M -L "$BED_FILE" "$CRAM_GS_URL" -o "$OUTPUT_BAM"

# Index
echo "Indexing..."
samtools index "$OUTPUT_BAM"

# Remove remote CRAM index cache downloaded by samtools
rm -f "${SAMPLE_ID}.cram.crai"

echo "Done: $OUTPUT_BAM"
