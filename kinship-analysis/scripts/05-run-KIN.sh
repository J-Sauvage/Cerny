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
$CONDA activate kin-3.1.3


CERNY_DIR="${RESULTS_DIR}/00-cerny-reordered"
GURGY_DIR="${RESULTS_DIR}/04-pmd-mask"

OUTPUT_DIR="${RESULTS_DIR}/05-KIN/$(basename ${AADR_SNP%.snp})"

# Canonicalize AADR_SNP path is it is not absolute.
[[ "$AADR_SNP" =~ ^"/" ]] || AADR_SNP="$(pwd)/${AADR_SNP}"

filestem_bam() {
    xargs basename -a | sed 's/.bam$//'
}

# ---- Check whether or not to run KIN only on the CER samples, or the joint CER+GRG+FLR samples
case $RUNTYPE in
    "single")
        OUTPUT_DIR="${OUTPUT_DIR}/single"
        ;;
    "merged")
        OUTPUT_DIR="${OUTPUT_DIR}/merged"
        ;;
    *)
        usage
        echo "Missing positional argument. PLease specify whether or not KIN should be applied only on the target CER samples ('single') or with the joint Rivollat samples ('merged')"
	exit 1
        ;;
esac

# ---- symlink bam files
SYMDIR="${OUTPUT_DIR}/symbams"
header "Symblink bam files..."
log INFO "Symlink dir: ${SYMDIR}"

log INFO "Symlinked files location: ${CERNY_DIR} $([[ $RUNTYPE == "merged" ]] && echo "| ${GURGY_DIR}" || echo '')"

mkdir -p "${SYMDIR}"
ln -srft "${SYMDIR}" $(ls -1 ${CERNY_DIR}/*.bam | exclude_samples | xargs)
[[ $RUNTYPE == "merged" ]] && ln -srft "${SYMDIR}" $(ls -1 ${GURGY_DIR}/*.bam | exclude_samples | xargs)

# ---- create bam file list
log INFO "Create bam file list..."
BAMLIST="${OUTPUT_DIR}/cerny.pmd-mask-bams.list"
ls -1 ${CERNY_DIR}/*.bam | exclude_samples | filestem_bam  > ${BAMLIST}
[[ $RUNTYPE == "merged" ]] && ls -1 ${GURGY_DIR}/*.bam | exclude_samples | filestem_bam >> ${BAMLIST}


# ---- run KINgaroo
KINGAROO_DIR="${OUTPUT_DIR}/kingaroo"
header "run KINgaroo..."
log INFO "KINgaroo output directory: ${KINGAROO_DIR}"
log INFO "Input bam list:            ${BAMLIST}"

mkdir -p ${KINGAROO_DIR}
cd ${KINGAROO_DIR}

KINgaroo \
--cores ${THREADS} \
--contam_parameter 0 \
--bamfiles_location "../$(basename $SYMDIR)" \
--target_location "../$(basename $BAMLIST)" \
--bedfile <(awk 'BEGIN{OFS="\t"}($2<=22){print $2,$4-1,$4, $5,$6}' ${AADR_SNP})


# ---- run KIN
header "run KIN..."

cd ../

KIN \
--cores ${THREADS} \
--input_location "./kingaroo/" \
--output_location "./KIN-results/" \
--target_location $(basename $BAMLIST)

