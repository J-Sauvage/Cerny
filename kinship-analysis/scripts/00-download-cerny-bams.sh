#!/usr/bin/env bash
set -euo pipefail

PRJEB="PRJEB75511"

usage() {
    echo "Usage:   $0 <output-dir>"
    echo ""
    echo "Example: Running '$0 ./bam-output' will:"
    echo "1. Create a ./bam-output directory (if non-existent)"
    echo "2. Download all bam files from ENA's ${PRJEB} project directory within the specified directory"
    echo ""
    exit 1
}

download_ena(){
    local ACCESSION="$1"
    local ENA_URL="https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${ACCESSION}&result=read_run&fields=submitted_ftp"

    for sample_urls in $(wget -qO- $ENA_URL | tail | cut -f1); do 
        for url in "${sample_urls//;/ }"; do
	    echo $url
	    wget $url
        done
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    [[ $# -eq 0 ]] && usage

    OUTPUT_DIR="$1"
    mkdir -p $OUTPUT_DIR && cd $OUTPUT_DIR
    download_ena $PRJEB 
fi 
