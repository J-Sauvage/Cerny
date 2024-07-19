#!/usr/bin/env bash
set -eo pipefail

# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

# ---- Prime conda
eval "$($CONDA shell.bash hook)"
conda activate pmd-mask-0.3.2

REFERENCE="${GRG_REFERENCE}"
RESCALE_REGEX=".rescaled"


INPUT_DIR="${RESULTS_DIR}/02-dedup"
RESCALE_DIR="${RESULTS_DIR}/03-mapdamage"
OUTPUT_DIR="${RESULTS_DIR}/04-pmd-mask"

mkdir -p ${OUTPUT_DIR}

NSAMPLES="$(ls -1 ${INPUT_DIR}/*.bam | wc -l)"
PROCESSED=0

header "Processing ${NSAMPLES} samples with pmd-mask"

for bam in ${INPUT_DIR}/*.bam; do
    ((PROCESSED+=1))
    misincorporation=$(find ${RESCALE_DIR} -type f -name misincorporation.txt | grep "$(basename ${bam%.bam})")
    stem="${OUTPUT_DIR}/$(basename ${bam%.bam}).pmd-mask"
    output_bam="${stem}.bam"
    metrics="${stem}.metrics"
    log INFO "[$PROCESSED/$NSAMPLES]: ${bam}"
    echo "  - misincorporation: $misincorporation"
    echo "  - output bam      : $output_bam"
    echo "  - metrics file    : $metrics"

    pmd-mask -@ ${THREADS} --bam ${bam} -o ${output_bam} -m ${misincorporation} -M ${metrics} -f ${REFERENCE} -OBAM --verbose >  >(tee ${stem}.log) 2>&1
done

log INFO "Done"
