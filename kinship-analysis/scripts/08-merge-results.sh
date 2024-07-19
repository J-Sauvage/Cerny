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

SAMPLE_REGEX='[A-Z]{3}[0-9]+[ABC]{0,1}(-[0-9]){0,1}'


OUTPUT_DIR="${RESULTS_DIR}/08-merged-kinship-results/$(basename ${AADR_SNP%.snp})"

GRUPS_RESULTS_DIR="${RESULTS_DIR}/06-grups-rs/$(basename ${AADR_SNP%.snp})-${PED_POP}-$(basename ${PEDIGREE%.txt})-${REPS}-afds${AF_DOWNSAMPLING_RATE}/merged-run"
READ_RESULTS_DIR="${RESULTS_DIR}/07-run-READ/$(basename ${AADR_SNP%.snp})"
READV2_RESULTS_DIR="${RESULTS_DIR}/07-run-READv2/$(basename ${AADR_SNP%.snp})"
KIN_RESULTS_DIR="${RESULTS_DIR}/05-KIN/$(basename ${AADR_SNP%.snp})"


# ---- merge and clean GRUPS-rs results
header "Merging GRUPS-rs results"

GRUPS_OUTPUT_DIR="${OUTPUT_DIR}/GRUPS-rs/$(basename ${GRUPS_RESULTS_DIR%"merged-run"})"
GRUPS_CLEAN="${GRUPS_OUTPUT_DIR}/$(find ${GRUPS_RESULTS_DIR} -name *.result | xargs basename | sed 's/.result$/.merged/')"

log INFO "Input dir: ${GRUPS_RESULTS_DIR}"
log INFO "Output file: ${GRUPS_CLEAN}"

mkdir -p ${GRUPS_OUTPUT_DIR}
join -t$'\t' $(find ${GRUPS_RESULTS_DIR} -type f -name *.result -o -name *.probs) \
> ${GRUPS_CLEAN}

# ---- merge and clean READ results
header "Merging READ-v1 results"
READ_CLEAN="${OUTPUT_DIR}/READ-v1/READ_results-clean"
log INFO "Input dir: ${READ_RESULTS_DIR}"
log INFO "Output file: ${READ_CLEAN}"

mkdir -p $(dirname ${READ_CLEAN})
join -t $'\t' ${READ_RESULTS_DIR}/READ_results <(cat ${READ_RESULTS_DIR}/meansP0_AncientDNA_normalized |tr " " "\t") \
| sed -E "s/^($SAMPLE_REGEX)($SAMPLE_REGEX)/\1-\3/" \
> ${READ_CLEAN} 

# ---- merge and clean READv2 results
header "Merging READ-v2 results"
for runtype in "single" "merged"; do
    subdir="${READV2_RESULTS_DIR}/${runtype}"
    if [ -f "${subdir}/Read_Results.tsv" ]; then
        READV2_CLEAN="${OUTPUT_DIR}/READ-v2/${runtype}/READv2_results-clean.tsv"
        drawline
        log INFO "Found subruntype ${runtype}"
        log INFO "Input dir: ${subdir}"
        log INFO "Output file: ${READV2_CLEAN}"

        mkdir -p $(dirname ${READV2_CLEAN})
        results="${subdir}/Read_Results.tsv"
        means="${subdir}/meansP0_AncientDNA_normalized_READv2"
        join -t $'\t' ${results} <(cat ${means} | tr " " "\t") \
        | sed -E "s/^($SAMPLE_REGEX)($SAMPLE_REGEX)/\1-\3/" \
        > ${READV2_CLEAN} 
    fi
done

# ---- merge and clean KIN results
header "Merging KIN results"
for runtype in "single" "merged"; do
    subdir="${KIN_RESULTS_DIR}/${runtype}" 
    if [ -f "${subdir}/KIN-results/KIN_results.csv" ]; then
        KIN_CLEAN="${OUTPUT_DIR}/KIN/${runtype}/KIN_results-clean.csv"
        drawline
        log INFO "Found subruntype ${runtype}"
        log INFO "Input dir: ${subdir}"
        log INFO "Output file: ${KIN_CLEAN}"

        results="${subdir}/KIN-results/KIN_results.csv"
        overlap="${subdir}/kingaroo/overlap.csv"
        mkdir -p $(dirname ${KIN_CLEAN})
        join --header -t $'\t' ${results} <(cat ${overlap} | tr "," "\t") \
        | cut -f2- \
        | rev \
        | cut -f1,3- \
        | rev \
        | sed 's/.pmd_masked.reordered//g' \
        | sed 's/.merged.rmdup.pmd-mask//g' \
        | sed 's/_._/-/' \
        > ${KIN_CLEAN}
    fi
done

# ---- merge all results
# Note: READscript.R forces a lexicographical sort on the PairIndividuals column
#       (since it uses the aggregate() function). We use awk, and the order of the KIN-results.csv
#       file to reorder these files.
#MERGED="${OUTPUT_DIR}/merged-kinship-results.tsv"
#join -t$'\t' --header ${READ_CLEAN}  <(head -n 2 ${KIN_CLEAN} && tail -n +3 ${KIN_CLEAN} | sort ) \
#| join -t $'\t' --header ${GRUPS_CLEAN} - -a1 \
#> ${MERGED}
MERGED_OUTPUT="${OUTPUT_DIR}/merged-kinship-results.tsv"
header "Merging results"
log INFO "Output file: ${MERGED_OUTPUT}"

R_CMD=$(cat << END

    # ---- Import GRUPS and READv1
    grups <- read.table("${GRUPS_CLEAN}", header = T, sep = "\t")
    read  <- read.table("${READ_CLEAN}", header = T, sep = "\t")
    colnames(grups) <- c(colnames(grups)[1], paste0("GRUPS-rs.", colnames(grups)[-1]))
    colnames(read) <- c(colnames(read)[1], paste0("READ.", colnames(read)[-1]))
    
    # ---- Merge GRUPS-rs and READv1
    merged <- merge(grups, read, by.x="Pair_name", by.y="PairIndividuals", all=T)

    # ---- Merge READv2
    for (subtype in c("single", "merged")) {
      readv2_file <- paste("${OUTPUT_DIR}", "READ-v2", subtype, "READv2_results-clean.tsv", sep="/")
      if(file.exists(readv2_file)) {
        readv2<- read.table(readv2_file, header = TRUE, sep ="\t")
        colnames(readv2) <- c(colnames(readv2)[1], paste0(paste0("READv2.",subtype,"."), colnames(readv2)[-1]))
        merged <- merge(merged, readv2, by.x="Pair_name", by.y="PairIndividuals", all=T)
      }
    }

    for (subtype in c("single", "merged")) {
      kin_file <- paste("${OUTPUT_DIR}", "KIN", subtype, "KIN_results-clean.csv", sep="/")
      if (file.exists(kin_file)) {
        kin <- read.table(kin_file, header = TRUE, sep = "\t")
        colnames(kin) <- c(colnames(kin)[1], paste0(paste0("KIN.",subtype,"."), colnames(kin)[-1]))
        merged <- merge(merged, kin, by.x = "Pair_name", by.y="Pair", all=T)
      }  
    }
    
    write.table(merged, file="${MERGED_OUTPUT}", row.names = F, sep="\t", quote=F)
    
END
)

[[ -f ${MERGED_OUTPUT} ]] && rm ${MERGED_OUTPUT}
Rscript <(echo "${R_CMD}")

if [[ ! -f ${MERGED_OUTPUT} ]]; then
    echo "Error. Failed R command..."
    exit 1 
fi

# ---- Paste sample aliases
SAMPLE_ALIAS_TABLE="resources/sample-alias-table.txt"
TMP_OUTPUT="$(paste <( \
  awk -F'[^A-Z0-9_]+' 'FNR==NR{a[$1]=$2;next}{for(n=1;n<=NF;n++)if($n in a)gsub($n,a[$n])}1' "${SAMPLE_ALIAS_TABLE}" "${MERGED_OUTPUT}" \
  | cut -f1 \
  | sed  's/^Pair_name/Pair_alias/' \
  ) ${MERGED_OUTPUT})"

echo "${TMP_OUTPUT}" > ${MERGED_OUTPUT}