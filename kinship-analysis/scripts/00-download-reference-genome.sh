#!/usr/bin/env bash

download_reference(){
    local target_dir="$1"
    local url="$2"
    header "Downloading $(basename ${url}) reference genome"
    mkdir -p ${target_dir}
    wget -O- ${url} | gzip -dc > "${target_dir}/$(basename "${url%.gz}")"
    wget -P ${target_dir} "${url%.gz}.fai"
}

# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

# ---- Prime conda
eval "$($CONDA shell.bash hook)"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    if [ ! -f ${REFERENCE} ]; then 
        download_reference "${REFGEN_DIR}" "${REFGEN_URL}"	
    fi

    if [ ! -f ${GRG_REFERENCE} ]; then
        download_reference "${REFGEN_DIR}" "${GRG_REFGEN_URL}"
    fi

    header "Creating Sequence Dictionary"
    $CONDA activate picard-2.27.4
    picard CreateSequenceDictionary -R ${REFERENCE}
    echo "Done"
fi


