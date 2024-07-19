#!/usr/bin/env bash
set -euo pipefail

# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

# ---- Prime conda
eval "$($CONDA shell.bash hook)"
conda activate samtools-1.15

# ---- Create output directory
OUTPUT_DIR="${RESULTS_DIR}/01-merge"
mkdir -p ${OUTPUT_DIR}

NSAMPLES="$(ls -1 ${RIVOLLAT_DATA_DIR}/*.bam | wc -l)"
PROCESSED=0
for sample in $(get_matching_file_pattern $RIVOLLAT_SAMPLE_REGEX $RIVOLLAT_DATA_DIR/*.bam); do
    ((PROCESSED+=1))
    log INFO "[$PROCESSED/$NSAMPLES]: Merging ${sample}..."
    samtools merge -@ $THREADS -OBAM -o ${OUTPUT_DIR}/${sample}.merged.bam ${RIVOLLAT_DATA_DIR}/*${sample}*.bam
done

echo Done
