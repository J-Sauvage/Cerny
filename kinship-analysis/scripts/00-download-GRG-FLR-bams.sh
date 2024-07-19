#!/usr/bin/env bash

set -euo pipefail

WORKERS=0;                # (don't edit) Number of currently running worker threads


# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

mkdir -p ${RIVOLLAT_DATA_DIR}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # ---- Download Rivollat 2020 + 2022 FLR individuals
    REGEX="ftp.sra.ebi.ac.uk/[.a-zA-Z0-9/]+/FLR[0-9]+([.]TF){0,1}.bam"
    FILEREPORT="resources/ftp-filereports/filereport-rivollat-fleury.tsv"
    download_filereport $REGEX $FILEREPORT ${RIVOLLAT_DATA_DIR} 

    # ---- Download rivollat 2023 GRG individuals
    REGEX='ftp.sra.ebi.ac.uk(/[a-zA-Z0-9/_]+)+.bam(?!.bai)'
    FILEREPORT="resources/ftp-filereports/filereport_read_run_PRJEB61818_tsv.txt"
    download_filereport $REGEX $FILEREPORT ${RIVOLLAT_DATA_DIR} 

    # ---- Download rivollat 2020 GRG individuals
    REGEX='ftp.sra.ebi.ac.uk(/[a-zA-Z0-9/.]+)+.bam(?!.bai)'
    FILEREPORT="resources/ftp-filereports/filereport_read_run_PRJEB36208_tsv.txt"
    download_filereport $REGEX $FILEREPORT ${RIVOLLAT_DATA_DIR} 

    echo "Done."
fi

