#!/usr/bin/env bash

# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

# ---- Prime conda
eval "$($CONDA shell.bash hook)"

install_env(){
    mamba env create -f "${1}"
}

uninstall_env(){
    mamba env remove -y -n $(grep 'name:' ${1} | sed -E 's/^name:[ ]*//')
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case $1 in
        install)
	    CONDA_CMD=install_env
        ;;
        uninstall)
            CONDA_CMD=uninstall_env
        ;;
        *)
            echo -e "[ERROR] Unknown command.\nUSAGE: $0 [install|uninstall]"
	    exit 1
        ;;
    esac

    for yaml in ./envs/*.yml; do
        $CONDA_CMD "${yaml}"
    done
fi


