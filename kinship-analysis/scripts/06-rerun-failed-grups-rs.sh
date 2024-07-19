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
$CONDA activate grups-rs-0.3.2

INPUT_DIR="${RESULTS_DIR}/06-grups-rs/$(basename ${AADR_SNP%.snp})-${PED_POP}-$(basename ${PEDIGREE%.txt})-${REPS}-afds${AF_DOWNSAMPLING_RATE}/splitted-runs"


fetch_failed_runs(){
    find $INPUT_DIR -name *.result -exec wc -l {} \; | grep "^0" | awk '{print $2}' | xargs dirname
}

fetch_last_yaml(){
    find $1 -name *.yaml | sort | tail -n-1
}

header "Searching for potentially failed GRUPS-rs runs..."
for run_directory in $(fetch_failed_runs); do
    log WARN "Found failed run at $run_directory"
    yaml=$(fetch_last_yaml $run_directory)
    log INFO  " - Found $yaml"
    log INFO "  - running grups-rs from-yaml $yaml with overwrite: true"
    grups-rs from-yaml <(sed 's/overwrite: false/overwrite: true/' $yaml) --verbose
done
