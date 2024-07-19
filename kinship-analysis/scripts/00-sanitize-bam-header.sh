#!/usr/bin/env bash

# ------------------------------------------------------------------------------------------------ #
# Description: Removes 'chr' prefix in bam headers from Rivollat et al's paper if any are found.
#              When found, the program create several copies and symbolic link within the input
#              directory of the file:
#              1. Backup the raw <prefix>.bam as  <prefix>.unsanitized.bam.bak
#              2. Create a <sample>.sanitized.bam copy, with 'chr' prefixes removed from the bam
#              3. Create a symlink from <prefix>.bam to <sample>.sanitized.bam
#              


# ---- Import config and common utility functions
THIS_SCRIPT_DIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
IMPORTS=("config.sh" "utilities.sh")
for script in "${IMPORTS[@]}"; do
    source ${THIS_SCRIPT_DIR}/$script
done

# ---- Prime $CONDA
eval "$($CONDA shell.bash hook)"
$CONDA activate samtools-1.15

PROCESSED=0
NSAMPLES="$(ls -1 ${RIVOLLAT_DATA_DIR}/*.bam | wc -l)"
for bam in ${RIVOLLAT_DATA_DIR}/*.bam; do
    ((PROCESSED+=1))
    log INFO "[$PROCESSED/$NSAMPLES]: ${bam} "

    if $(samtools view -H ${bam} | grep "^@SQ" | grep -q "SN:chr"); then
        log WARN "Found 'chr' in headers. sanitizing..."
        samtools view -@ ${THREADS} -h ${bam} | \
          sed -e '/^@SQ/s/SN\:chr/SN\:/' -e '/^[^@]/s/\tchr/\t/2' | \
          awk -F"\t" 'BEGIN{OFS="\t"}{gsub("chr", "", $3); print}' | \
          samtools view -@ ${THREADS} -OBAM -o ${bam%.bam}.sanitized.bam
    fi
done

cd ${RIVOLLAT_DATA_DIR}
for sanitized in *.sanitized.bam; do 
    raw="${sanitized%.sanitized.bam}.bam";
    mv ${raw} ${raw%.bam}.unsanitized.bam.bak && ln -s $sanitized $raw
done

