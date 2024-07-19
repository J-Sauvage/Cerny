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
conda activate mapdamage-2.2.1

INPUT_DIR="${RESULTS_DIR}/02-dedup"
OUTPUT_DIR="${RESULTS_DIR}/03-mapdamage"
REFERENCE="${GRG_REFERENCE}"

mkdir -p ${OUTPUT_DIR}

NSAMPLES="$(ls -1 ${INPUT_DIR}/*.bam | wc -l)"
PROCESSED=0
WORKERS=0

for bam in ${INPUT_DIR}/*.bam; do
    if [[ ! -f ${bam}.bai ]]; then
        log INFO "Index ${bam}"
        samtools index -@ ${THREADS} ${bam}
    fi
done


for bam in ${INPUT_DIR}/*.bam; do
    filestem="${OUTPUT_DIR}/$(basename ${bam%.bam}).rescaled"
    ((PROCESSED+=1))
    log INFO "[$PROCESSED/$NSAMPLES]: ${bam}"
    multithread mapDamage  -i "${bam}" -r "${REFERENCE}" --rescale --verbose --folder "${filestem}" > ${filestem}.log 2>&1
done
wait

log INFO "Done"
