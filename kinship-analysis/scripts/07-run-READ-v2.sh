#!/usr/bin/env bash
set -eo pipefail

RUNTYPE="${1}"

usage() {
    echo "$(basename $(readlink -f "${BASH_SOURCE[0]}")) [single|merged]"
}

# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

# ---- Prime conda
eval "$($CONDA shell.bash hook)"

REFERENCE="${GRG_REFERENCE}"
OUTPUT_DIR="${RESULTS_DIR}/07-run-READv2/$(basename ${AADR_SNP%.snp})"

# ---- Check whether or not to run READ on the CER-only pileup file, or the joint CER+GRG+FLR pileup file
case $RUNTYPE in
    "single")
        PLINK_BASENAME="${RESULTS_DIR}/06-pileupCaller/cerny-reordered.pmd-masked.q${MQ}Q${BQ}.$(basename ${AADR_SNP%.snp}).$(basename ${REFERENCE%.fa.gz})"
	OUTPUT_DIR="${OUTPUT_DIR}/single"
        ;;
    "merged")
        PLINK_BASENAME="${RESULTS_DIR}/06-pileupCaller/cerny-reordered.merge-rivollat.pmd-masked.q${MQ}Q${BQ}.$(basename ${AADR_SNP%.snp}).$(basename ${REFERENCE%.fa.gz})"
        OUTPUT_DIR="${OUTPUT_DIR}/merged"
        ;;
    *)
	usage
	echo "Missing positional argument. Please specify on which pileup file should READ be applied (single | merged)"
        exit 1
        ;;
esac

mkdir -p ${OUTPUT_DIR}

# ---- prepare optargs if norm_method == "value"
[[ $READ_NORM_METHOD =~ "value" ]] && NORM_VALUE_OPTARG="--norm_value ${READ_NORM_VALUE}" || NORM_VALUE_OPTARG=""

# ---- canonicalize input basename if needed
[[ $PLINK_BASENAME =~ ^"/" ]] || PLINK_BASENAME="$(pwd)/${PLINK_BASENAME}"

header "run READ-v2"
log INFO "Input Plink basename: ${PLINK_BASENAME}"
log INFO "Normalization method: ${READ_NORM_METHOD}"
log INFO "Normalization value : ${READ_NORM_VALUE}"

cd ${OUTPUT_DIR}
$CONDA activate READv2
READ2 --input "${PLINK_BASENAME}" --norm_method ${READ_NORM_METHOD} ${NORM_VALUE_OPTARG}
