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

REFERENCE="${GRG_REFERENCE}"
PLINK_BASENAME="cerny-reordered.merge-rivollat.pmd-masked.q${MQ}Q${BQ}.$(basename ${AADR_SNP%.snp}).$(basename ${REFERENCE%.fa.gz})"

INPUT_DIR="${RESULTS_DIR}/06-pileupCaller"
OUTPUT_DIR="${RESULTS_DIR}/07-correctKin/$(basename ${AADR_SNP%.snp})"

mkdir -p ${OUTPUT_DIR}

header "Symlink input files"
log INFO "Input basename  : ${INPUT_DIR}/${PLINK_BASENAME}"
log INFO "Target directory: ${OUTPUT_DIR}" 
for ext in bed bim; do
    ln -srft "${OUTPUT_DIR}" "${INPUT_DIR}/${PLINK_BASENAME}.${ext}"
done

sed 's/\t/ /g' "${INPUT_DIR}/${PLINK_BASENAME}.fam" > "${OUTPUT_DIR}/${PLINK_BASENAME}.fam"

header "Running PCangsd-v0.99"

$CONDA activate pcangsd-0.99
pcangsd -plink "${OUTPUT_DIR}/${PLINK_BASENAME}" -o "${OUTPUT_DIR}/${PLINK_BASENAME}" -inbreed 1 -kinship -threads ${THREADS}
$CONDA deactivate

header "Running correctKin MarkerOverlap"
$CONDA activate correctKIN
markerOverlap "${OUTPUT_DIR}/${PLINK_BASENAME}.bed"

header "Running correctKin filterRelates"
filterRelates "${OUTPUT_DIR}/${PLINK_BASENAME}.overlap" "${OUTPUT_DIR}/${PLINK_BASENAME}.kinship.npy" > "${OUTPUT_DIR}/${PLINK_BASENAME}.rels.tsv"
