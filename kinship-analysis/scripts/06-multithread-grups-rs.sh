#!/usr/bin/env bash

# usage: 06-multithread-grups.sh 0 {2..4} 5 6 7 {12..14}
# each argument must correspond to a pileup sample index

# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

# ---- Prime conda
eval "$($CONDA shell.bash hook)"
$CONDA activate grups-rs-0.3.2

REFERENCE="${GRG_REFERENCE}"
PILEUP="${RESULTS_DIR}/05-pileup/cerny-reordered.merge-rivollat.pmd-masked.q${MQ}Q${BQ}.$(basename ${AADR_SNP%.snp}).$(basename ${REFERENCE%.fa.gz}).mpileup"
BAMLIST="${PILEUP%.mpileup}.bamlist"

OUTPUT_DIR="${RESULTS_DIR}/06-grups-rs/$(basename ${AADR_SNP%.snp})-${PED_POP}-$(basename ${PEDIGREE%.txt})-${REPS}-afds${AF_DOWNSAMPLING_RATE}/splitted-runs"

SAMPLE_REGEX='^[\-A-Z0-9]+(?=[.])'
parse_sample_name(){
    basename $(sed "${1}q;d" ${BAMLIST}) | grep -oP "${SAMPLE_REGEX}"
}

parse_grups_cmd(){
    [[ $# -ne 4 ]] && [[ $# -ne 2 ]] && exit 1
    read -r sample_i sample_name_i sample_j sample_name_j <<< "$1 $2 $3 $4"
    read -r -d '' GRUPS_CMD<<-EOF
	grups-rs pedigree-sims
	--pileup ${PILEUP}
	--data-dir ${DATA_DIR}
	--recomb-dir ${RECOMB_DIR}
	--pedigree ${PEDIGREE}
	--mode ${MODE}
	--reps ${REPS}
	--samples ${sample_i} ${sample_j}
	--sample-names ${sample_name_i} ${sample_name_j}
	--af-downsampling-rate ${AF_DOWNSAMPLING_RATE}
	--seed ${SEED}
	--verbose
	EOF
    if [[ $# -eq 2 ]]; then
	GRUPS_OUTPUT_DIR="${OUTPUT_DIR}/${sample_name_i}-${sample_name_i}"
        GRUPS_CMD="${GRUPS_CMD} --self-comparison"
    else
	GRUPS_OUTPUT_DIR="${OUTPUT_DIR}/${sample_name_i}-${sample_name_j}"
    fi

    GRUPS_CMD="${GRUPS_CMD} --output-dir ${GRUPS_OUTPUT_DIR}"
    mkdir -p $GRUPS_OUTPUT_DIR
    $GRUPS_CMD 2> "${GRUPS_OUTPUT_DIR}.log"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mkdir -p ${OUTPUT_DIR}

    SAMPLES_INDEX=($@)
    NSAMPLES="${#SAMPLES_INDEX[@]}"
    PROCESSED=0
    COMPARISONS=`python3 -c "print(($NSAMPLES*($NSAMPLES-1))/2)"`
    log INFO "Samples indices  : ${SAMPLES_INDEX[@]}"
    log INFO "Number of samples: ${NSAMPLES}"
    log INFO "Pileup           : ${PILEUP}"
    echo ""
    header "Running GRUPS-rs for pairwise comparisons..."
    for i in $(seq 0 $((NSAMPLES-1))); do
        sample_i="${SAMPLES_INDEX[$i]}"
        sample_name_i=`parse_sample_name $(($sample_i+1))`
        for j in $(seq $((i+1)) $((NSAMPLES-1))); do
            sample_j="${SAMPLES_INDEX[$j]}"
            sample_name_j=`parse_sample_name $(($sample_j+1))`
            ((PROCESSED+=1))
            log INFO "[$PROCESSED/$COMPARISONS]: $sample_name_i $sample_name_j"
            multithread parse_grups_cmd $sample_i $sample_name_i $sample_j $sample_name_j
        done
    done

    PROCESSED=0
    if [ "$DO_SELF_COMPARISONS" = true ]; then
        header "Running GRUPS-rs for self-comparisons..."
        for i in $(seq 0 $((NSAMPLES-1))); do
            sample_i="${SAMPLES_INDEX[$i]}"
            sample_name_i=`parse_sample_name $(($sample_i+1))`
            ((PROCESSED+=1))
            log INFO "[$PROCESSED/$NSAMPLES]: $sample_name_i $sample_name_i"
            multithread parse_grups_cmd $sample_i $sample_name_i
        done
    fi
    wait
    log INFO "Done"
fi
