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
$CONDA activate sequencetools-1.5.2


SAMPLE_POP_NAME="Cerny"

INPUT_DIR="${RESULTS_DIR}/05-pileup"
OUTPUT_DIR="${RESULTS_DIR}/06-pileupCaller"

REFERENCE="${GRG_REFERENCE}"

run_pileupcaller(){
    read -r pileup bamlist targets reference output_dir popname  <<<$(echo $1 $2 $3 $4 $5 $6)
    output_basename="${output_dir}/$(basename ${pileup%.mpileup})"

    header "Running pileupCaller"
    log INFO "Pileup          : ${pileup}"
    log INFO "Samples bamlist : ${bamlist}"
    log INFO "Reference       : ${reference}"
    log INFO "Output directory: ${output_dir}"
    log INFO "Sample pop name : ${popname}"
    drawline

    cat ${pileup} | pileupCaller \
    --randomHaploid \
    --snpFile ${targets} \
    --plinkOut ${output_basename} \
    --samplePopName ${popname} \
    --sampleNameFile <(cat ${bamlist} | xargs basename -a | cut -f1 -d.) \
    > "${output_basename}.log" 2>&1
}


mkdir -p ${OUTPUT_DIR}

header "Running pseudo-haploidisation using PileupCaller (CER only pileup)"
PILEUP="${INPUT_DIR}/cerny-reordered.pmd-masked.q${MQ}Q${BQ}.$(basename ${AADR_SNP%.snp}).$(basename ${REFERENCE%.fa.gz}).mpileup"
BAMLIST="${PILEUP%.mpileup}.bamlist"
run_pileupcaller $PILEUP $BAMLIST $AADR_SNP $REFERENCE $OUTPUT_DIR "Cerny"


header "Running pseudo-haploidisation using PileupCaller (CER+GRG+FLR pileup)"
PILEUP="${INPUT_DIR}/cerny-reordered.merge-rivollat.pmd-masked.q${MQ}Q${BQ}.$(basename ${AADR_SNP%.snp}).$(basename ${REFERENCE%.fa.gz}).mpileup"
BAMLIST="${PILEUP%.mpileup}.bamlist"
run_pileupcaller $PILEUP $BAMLIST $AADR_SNP $REFERENCE $OUTPUT_DIR "Cerny"

log INFO "Done."
