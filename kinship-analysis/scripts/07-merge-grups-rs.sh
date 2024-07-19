#!/usr/bin/env bash

# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

# ---- Prime conda
eval "$($CONDA shell.bash hook)"
$CONDA activate grups-rs-0.3.2

BASE_DIR="${RESULTS_DIR}/06-grups-rs/$(basename ${AADR_SNP%.snp})-${PED_POP}-$(basename ${PEDIGREE%.txt})-${REPS}-afds${AF_DOWNSAMPLING_RATE}"
INPUT_DIR="${BASE_DIR}/splitted-runs"
OUTPUT_DIR="${BASE_DIR}/merged-run"

_merge_file(){
    awk '(NR==1||FNR>1){print}' ${INPUT_DIR}/*/${1}
}

_fetch_filename(){
    echo $(find ${INPUT_DIR} -name $1 -type f | sort -u) >2
    find ${INPUT_DIR} -name $1 -type f | xargs basename -a | uniq 
}

merge_and_rewrite(){
    local pattern="$1"
    local output_dir="$2"
    _merge_file $pattern > "${output_dir}/$(_fetch_filename $pattern)"
}

copy_all(){
    log INFO "Copying all files matching pattern '$1' in $2"
    find ${INPUT_DIR} -type f -name $1 -exec cp {} $2 \;
}

reorder_samples() {
    local file="${1}/$(_fetch_filename $2)"
    local bamlist="$3"
    local FILE_CONTENTS=$(cat $file);
    echo "${FILE_CONTENTS}" | head -n1 > ${file}
    for sample in $(cat $bamlist | cut -f3 -d'/' | cut -d'.' -f1); do
        grep "^${sample}-" <(echo "${FILE_CONTENTS}")
    done >> "${file}"
}

REFERENCE="${GRG_REFERENCE}"
PILEUP="${RESULTS_DIR}/05-pileup/cerny-reordered.merge-rivollat.pmd-masked.q${MQ}Q${BQ}.$(basename ${AADR_SNP%.snp}).$(basename ${REFERENCE%.fa.gz}).mpileup"
BAMLIST="${PILEUP%.mpileup}.bamlist"

mkdir -p ${OUTPUT_DIR}
declare -a PATTERNS=("*.result" "*.pwd" "*.probs")
for pattern in "${PATTERNS[@]}"; do
    header "Merging files matching pattern '$pattern'"
    merge_and_rewrite ${pattern} ${OUTPUT_DIR}
    reorder_samples ${OUTPUT_DIR} ${pattern} ${BAMLIST}
done

SIMDIR="${OUTPUT_DIR}/simulations"
BLKDIR="${OUTPUT_DIR}/blocks"
mkdir -p ${SIMDIR} && copy_all "*.sims" ${SIMDIR}
mkdir -p ${BLKDIR} && copy_all "*.blk" ${BLKDIR}

touch "${OUTPUT_DIR}/dummy-yaml.yaml"
