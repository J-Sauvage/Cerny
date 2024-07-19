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
$CONDA activate samtools-1.15

REFERENCE="${GRG_REFERENCE}"

CERNY_INPUT_DIR="${RESULTS_DIR}/00-cerny-reordered"
GURGY_INPUT_DIR="${RESULTS_DIR}/04-pmd-mask"
OUTPUT_DIR="${RESULTS_DIR}/05-pileup"

run_samtools() {
    read -r bq mq bamlist targets reference output  <<<$(echo $1 $2 $3 $4 $5 $6)
    header "Running samtools mpileup"
    log INFO "Targets             : ${targets}"
    log INFO "Reference           : ${reference}"
    log INFO "Min. Base Quality   : ${bq}"
    log INFO "Min. Mapping Quality: ${mq}"
    log INFO "Input bam list      : ${bamlist}"
    log INFO "Output pileup       : ${output}"

    samtools mpileup -RB -q ${mq} -Q ${bq} -l <(awk 'BEGIN{OFS="\t"}$2<=22{print $2, $4}' ${targets}) -f ${reference} -b ${bamlist} > ${output}
}


mkdir -p ${OUTPUT_DIR}

header "Generating pileup file (CER only) using samtools mpileup "
OUTPUT_PILEUP="${OUTPUT_DIR}/cerny-reordered.pmd-masked.q${MQ}Q${BQ}.$(basename ${AADR_SNP%.snp}).$(basename ${REFERENCE%.fa.gz}).mpileup"
BAMLIST="${OUTPUT_PILEUP%.mpileup}.bamlist"

# ---- Create bamlist
ls -1 ${CERNY_INPUT_DIR}/*.bam | exclude_samples >  ${BAMLIST}

run_samtools ${BQ} ${MQ} ${BAMLIST} ${AADR_SNP} ${REFERENCE} ${OUTPUT_PILEUP}

header "Generating joint pileup file (CER+GRG+FLR) using samtools mpileup "
OUTPUT_PILEUP="${OUTPUT_DIR}/cerny-reordered.merge-rivollat.pmd-masked.q${MQ}Q${BQ}.$(basename ${AADR_SNP%.snp}).$(basename ${REFERENCE%.fa.gz}).mpileup"
BAMLIST="${OUTPUT_PILEUP%.mpileup}.bamlist"

# ---- Create bamlist
ls -1 ${CERNY_INPUT_DIR}/*.bam | exclude_samples >  ${BAMLIST}
ls -1 ${GURGY_INPUT_DIR}/*.bam | exclude_samples >> ${BAMLIST} 

run_samtools ${BQ} ${MQ} ${BAMLIST} ${AADR_SNP} ${REFERENCE} ${OUTPUT_PILEUP}

