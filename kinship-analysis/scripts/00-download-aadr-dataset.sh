#!/usr/bin/env bash

# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

header "Downloading AADR Database SNP callset"
log INFO "URL             : ${AADR_URL}"
log INFO "Output directory: ${AADR_DIR}"

mkdir -p ${AADR_DIR}
wget -P ${AADR_DIR} ${AADR_URL}