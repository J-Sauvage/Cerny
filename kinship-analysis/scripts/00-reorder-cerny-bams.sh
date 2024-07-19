#!/usr/bin/env bash
set -eo pipefail

# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

MAX_THREADS=32
[[ $THREADS -gt $MAX_THREADS ]] && THREADS=$MAX_THREADS

# ---- Prime conda
eval "$($CONDA shell.bash hook)"


fetch_bams() {
    find ${CERNY_BAM_DIR} -type f -name ${CERNY_REGEX}
}

conda activate picard-2.27.4

OUTPUT_DIR="${RESULTS_DIR}/00-cerny-reordered"
mkdir -p ${OUTPUT_DIR}
mkdir -p ${OUTPUT_DIR}/tmp 

NSAMPLES=$(fetch_bams | wc -l)
PROCESSED=0

header "Setup"
log INFO "Reference Genome: $REFERENCE"
log INFO "Output Directory: ${OUTPUT_DIR}"
log INFO "Number of samples to process: ${NSAMPLES}"

header "Main loop: Reorder samples"
for bam in $(fetch_bams); do
    ((PROCESSED+=1))
    filestem="${OUTPUT_DIR}/$(basename ${bam%.bam}.reordered)"
    multithread picard ReorderSam -I ${bam} -O ${filestem}.bam --SEQUENCE_DICTIONARY $REFERENCE > ${filestem}.log 2>&1 
    log INFO "[$PROCESSED/$NSAMPLES]: $bam"
done

wait

rm -r "${OUTPUT_DIR}/tmp"
