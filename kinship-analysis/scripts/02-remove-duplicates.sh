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
conda activate picard-2.27.4

INPUT_DIR="${RESULTS_DIR}/01-merge"
OUTPUT_DIR="${RESULTS_DIR}/02-dedup"

mkdir -p ${OUTPUT_DIR}

NSAMPLES="$(ls -1 ${INPUT_DIR}/*.bam | wc -l)"
PROCESSED=0
for bam in ${INPUT_DIR}/*.bam; do
    filestem="${OUTPUT_DIR}/$(basename ${bam%.bam}).rmdup"
    ((PROCESSED+=1))
    log INFO "[$PROCESSED/$NSAMPLES]: ${bam}"
    multithread picard MarkDuplicates -I ${bam} -O "${filestem}.bam" -M "${filestem}.metrics" --REMOVE_DUPLICATES true --VALIDATION_STRINGENCY LENIENT > ${filestem}.log 2>&1
done
wait
log INFO "Done"
