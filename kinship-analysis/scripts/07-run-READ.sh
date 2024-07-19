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
PLINK_BASENAME="${RESULTS_DIR}/06-pileupCaller/cerny-reordered.merge-rivollat.pmd-masked.q${MQ}Q${BQ}.$(basename ${AADR_SNP%.snp}).$(basename ${REFERENCE%.fa.gz})"
OUTPUT_DIR="${RESULTS_DIR}/07-run-READ/$(basename ${AADR_SNP%.snp})"

mkdir -p ${OUTPUT_DIR}

$CONDA activate plink-1.9

header "Transpose to [.tped|.tfam] format"
log INFO "Input Basename: ${PLINK_BASENAME}"

plink \
--threads ${THREADS} \
--bfile ${PLINK_BASENAME} \
--chr 1-22 \
--allow-no-sex \
--keep-allele-order \
--recode transpose tab \
--out "${OUTPUT_DIR}/$(basename ${PLINK_BASENAME})"

header "run READ"
log INFO "Normalization method: ${READ_NORM_METHOD}"
log INFO "Normalization value : ${READ_NORM_VALUE}"

$CONDA activate READ
cd ${OUTPUT_DIR}
ln -srf $(which READscript.R) READscript.R
touch meansP0_AncientDNA_normalized
python2 $(which READ.py) $(basename ${PLINK_BASENAME}) ${READ_NORM_METHOD} ${READ_NORM_VALUE}
