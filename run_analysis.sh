#!/usr/bin/env bash
# run_analysis.sh — Run prepare and figures stages sequentially.
#
# Usage:
#   bash run_analysis.sh
#
# Equivalent to: Rscript run_all.R prepare figures
# Skips the collect stage (raw data collection — run once per data release).
#
# Requirements: see run_all.R

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting CIDER analysis pipeline (prepare + figures)..."
Rscript "${SCRIPT_DIR}/run_all.R" prepare figures
