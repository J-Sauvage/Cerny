#!/usr/bin/env bash
set -eo pipefail

REQUESTED_DIR="${CERNY_BAM_DIR}"

# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

REQUESTED_DIR="${REQUESTED_DIR:-$CERNY_BAM_DIR}"

fetch_bams() {
    find ${REQUESTED_DIR} -type f -name ${CERNY_REGEX}
}


echo $REQUESTED_DIR

fetch_bams
