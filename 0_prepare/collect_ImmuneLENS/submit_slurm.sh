#!/bin/bash
# submit_slurm.sh — Submit ImmuneLENS as a SLURM array job.
#
# Usage:
#   bash submit_slurm.sh
#
# Submits one SLURM job per sample in samples.txt.
# The %50 throttle limits concurrent jobs to 50 at a time — adjust as needed.
# Completed samples (non-empty CSV already exists) are skipped immediately.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLES_FILE="${SCRIPT_DIR}/samples.txt"

if [ ! -f "$SAMPLES_FILE" ]; then
    echo "Error: samples.txt not found"
    exit 1
fi

total=$(grep -c '[^[:space:]]' "$SAMPLES_FILE")
echo "Submitting array job for $total samples (max 50 concurrent)..."

sbatch <<EOF
#!/bin/bash
#SBATCH --job-name=immunelens
#SBATCH --array=1-${total}%50
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=2:00:00
#SBATCH --output=${SCRIPT_DIR}/logs/slurm_%A_%a.out
#SBATCH --error=${SCRIPT_DIR}/logs/slurm_%A_%a.err

mkdir -p "${SCRIPT_DIR}/logs"

SAMPLE_ID=\$(sed -n "\${SLURM_ARRAY_TASK_ID}p" "${SAMPLES_FILE}")

if [ -z "\$SAMPLE_ID" ]; then
    echo "No sample ID for task \$SLURM_ARRAY_TASK_ID"
    exit 1
fi

echo "Task \$SLURM_ARRAY_TASK_ID: \$SAMPLE_ID"
bash "${SCRIPT_DIR}/run_sample.sh" "\$SAMPLE_ID"
EOF
