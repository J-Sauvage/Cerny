# Imputation of ancient genomes

This is a step-by-step verbatim of the bash commands applied during the phasing and imputation of the Paris Basin Cerny samples in this publication.

## Sofware requirements

The following command-line softwares were used:

- [`bcftools`](https://samtools.github.io/bcftools/bcftools.html). Installation instructions and pre-compiled binaries may be found on the [htslib mainpage](http://www.htslib.org/)
- [`GLIMPSE-2`](https://odelaneau.github.io/GLIMPSE/). See the installation instructions [here](https://odelaneau.github.io/GLIMPSE/docs/installation)
- [`ancIBD`](https://ancibd.readthedocs.io/en/latest/Intro.html). See the installation instructions [here](https://ancibd.readthedocs.io/en/latest/Install.html)



## 1. Data preparation

### Genetic map

Here we used the genetic map b37 downloaded from the [GLIMPSE-v2 github repository](https://github.com/odelaneau/glimpse). See the permalink [here](https://github.com/odelaneau/GLIMPSE/tree/74b25176e07c9a9e58babd328d66290374ee605e/maps/genetic_maps.b37)

```bash
GENETIC_MAP="<path/to/genetic_map>"
```

### Reference Panel

Here, we used the reference panel from the 1000G phase 3 dataset (20130502 release). See the ftp website [here](http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/)

```bash
REF_PANEL_DIR="<path/to/reference_panel>"
```


### Remove multiallelic SNPs from the 1000g phase 3 dataset
```bash
for CHRO in {1..2}; do
    REF_PANEL_FILE="${REF_PANEL_DIR}/RefPanelchr${CHRO}.vcf.gz"
    bcftools norm -m -any "$REF_PANEL_FILE" -Ou --threads 4 | \
    bcftools view -m 2 -M 2 -v snps --threads 4 -Ob -o "reference_panelchr${CHRO}.bcf"
    bcftools index -f "reference_panelchr${CHRO}.bcf" --threads 4
done
```

## 2. Phasing using GLIMPSE-2


### 1. Generate Chromosomal Chunks
```bash
for CHRO in {1..22}; do 
    echo "Processing chromosome ${CHRO}"
    GLIMPSE2_chunk --input "${REF_PANEL_DIR}/reference_panel_1000GP.chr${CHRO}.bcf" \
                   --map "${GENETIC_MAP}/chr${CHRO}.b37.gmap.gz" \
                   --region "${CHRO}" \
                   --sequential \
                   --output "chunks_chr${CHRO}.txt"
done
```

### 2. Split the reference genome across chromosomes

```bash
for CHRO in {1..22}; do 
    echo "Splitting reference for chromosome ${CHRO}"
    REF="${REF_PANEL_DIR}/reference_panel_1000GP.chr${CHRO}.bcf"
    MAP="${GENETIC_MAP}/chr${CHRO}.gmap.gz"
    while IFS="" read -r LINE || [ -n "$LINE" ]; do
        ID=$(printf "%02d" $(echo $LINE | cut -d" " -f1))
        IRG=$(echo $LINE | cut -d" " -f3)
        ORG=$(echo $LINE | cut -d" " -f4)
        GLIMPSE2_split_reference --reference "${REF}" \
                                 --map "${MAP}" \
                                 --input-region "${IRG}" \
                                 --output-region "${ORG}" \
                                 --output "reference_panel_chro${CHRO}.splitreference"
    done < "chunks_chr${CHRO}.txt"
done
```

### 3. Phase

Here, a list of samples and BAM directory must be defined as two separate variables.
```bash
LIST_SAMPLE="<path/to/ListSample.txt>"
BAM_DIR="<path/to/bam_files>"
```

Note that the input samples were pre-processed using [#[PLACEHOLDER]`pmd-mask`](https://github.com/xxxxxxxx/pmd-mask).

```bash
for SAMPLE in $(cat "$LIST_SAMPLE"); do 
    echo "Phasing sample ${SAMPLE}"
    BAM="${BAM_DIR}/${SAMPLE}.bam"
    OUT="${BAM_DIR}/${SAMPLE}_imputed"
    for CHRO in {1..22}; do 
        echo "Chromosome ${CHRO}"
        SREF="reference_panel_chro${CHRO}.splitreference"
        while IFS="" read -r LINE || [ -n "$LINE" ]; do
            ID=$(printf "%02d" $(echo $LINE | cut -d" " -f1))
            IRG=$(echo $LINE | cut -d" " -f3)
            ORG=$(echo $LINE | cut -d" " -f4)
            CHR=$(echo ${LINE} | cut -d" " -f2)
            REGS=$(echo ${IRG} | cut -d":" -f 2 | cut -d"-" -f1)
            REGE=$(echo ${IRG} | cut -d":" -f 2 | cut -d"-" -f2)
            GLIMPSE2_phase --bam-file "${BAM}" \
                           --reference "${SREF}_${CHR}_${REGS}_${REGE}.bin" \
                           --output "${OUT}_${CHR}_${REGS}_${REGE}.bcf"
        done < "chunks_chr${CHRO}.txt"
    done
done
```


### 4. Ligate

```bash
for SAMPLE in $(cat "$LIST_SAMPLE"); do 
    echo "Ligating imputed files for sample ${SAMPLE}"
    for CHRO in {1..22}; do
        ls -1v "${BAM_DIR}/${SAMPLE}_imputed" > "${SAMPLE}_masked_imputed_list_imputed_files_chr${CHRO}.txt"
        GLIMPSE2_ligate --input "${SAMPLE}_masked_imputed_list_imputed_files_chr${CHRO}.txt" \
                        --output "${SAMPLE}_masked_ligated_chr${CHRO}.bcf" \
                        --threads 2
    done
done
```

## 03. Imputation using AncIBD

### 1. Merge all samples

```bash
for CHRO in {1..22}; do
    echo "Merging chromosome ${CHRO}"
    bcftools merge -O z -o "*chr${CHRO}.bcf"
done
```

### 2. ancIBD run

```bash
MARKER_PATH="<path/to/marker>"
VCF_PATH="<path/to/vcf>"
MAP_PATH="</path/to/1240k-SNP-panel-v54.1>"

for CH in {1..22}; do
    ancIBD-run --vcf "${VCF_PATH}" \
               --ch "${CH}" \
               --out "CernyFleuryGurgyAlsace" \
               --marker_path "${MARKER_PATH}" \
               --map_path "${MAP_PATH}" \
               --prefix "CernyFleuryGurgyAlsace"
done
```

### 3. Generate ancIBD summary

```bash
ancIBD-summary --tsv "CernyFleuryGurgyAlsace/CernyFleuryGurgyAlsace.ch" --out "CernyFleuryGurgyAlsace/"
```
