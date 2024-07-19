# cerny-kinship-analysis

This repository contains a collection of scripts used during the kinship analysis found within [[PLACEHOLDER] (xxxxx et al. 2024)]()

> **[PLACEHOLDER]** xxxx, x., xxxx, x., xxxx, x. et al. When cultural hints of admixture do not match the genetic ancestry: the case of the Middle Neolithic Cerny Culture (2024) **https://doi.org/xxxxxxxxx** 

## Installation

### Dependencies

This pipeline requires the use of either the [conda](https://github.com/conda/conda) or [mamba](https://github.com/mamba-org/mamba) package environment manager, to ensure reproducibility. Version``>=23.1.0` is recommended for either of those.

A quick Linux installation procedure may be found below. Alternatively, detailled installation instructions for conda may be found [here](https://docs.anaconda.com/free/miniconda/#quick-command-line-install).

1. Download and install miniconda
```bash
CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
wget $CONDA_URL && bash $(basename $CONDA_URL)
~/miniconda3/bin/conda init bash
```

2. (Optional) install mamba
```bash
conda install -n base --override-channels -c conda-forge mamba
```

### Installation proper

1. Download this repository
```bash
[PLACEHOLDER] REPO_URL="https://github.com/xxxxxxx/Cerny.git"
git clone $REPO_URL
cd $(basename ${REPO_URL%.git}/kinship-analysis)
```

2. Create all the required conda environments
```bash
./scripts/00-install-conda-envs.sh install
```
Note that this will create all the environments found within the `./envs` directory. Reversing this operation may be done using the following command:

```bash
./scripts/00-install-conda-envs.sh uninstall
```

## Usage

Note that preset parameters and global variables may be reconfigured by modifying the [`scripts/config.sh`](/scripts/config.sh) configuration file. 

### Assumptions

This pipeline assumes the presence of analysis-ready bam files within a directory targeted through the `CERNY_BAM_DIR` variable. The `CERNY_BAM_DIR` variable can either be configured by modifying the value found in `scripts/config.sh`, or by exporting this value as an environment variable.

```bash
export CERNY_BAM_DIR="../aDNA-pipeline/results/01-preprocess/07-rescale/pmd-mask"
```
Note that the exported environment variable takes precedence over the one defined in `scripts/config.sh`

A set of partially pre-processed input bam files may be downloaded from the ENA's project repository [PRJEB75511](https://www.ebi.ac.uk/ena/browser/view/PRJEB75511), which were processed using an in-house workflow (see: [[PLACEHOLDER]aDNA-pipeline](https://github.com/xxxxxxx/aDNA-pipeline)). For a quick-start, See the [scripts/00-download-cerny-bams.sh](/scripts/00-download-cerny-bams.sh) utility script to automatically download all bam files from the ENA archive. Note however, that post-processing these files with [[PLACEHOLDER]`pmd-mask`](https://github.com/xxxxxxxxxx/pmd-mask) prior to running this pipeline is highly recommended, to replicate the results found in the paper.

### 1. Download and preprocess all required datasets and input files

Download the [GRCh37](http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/) and [hs37d5](https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/phase2_reference_assembly_sequence/) reference genomes.

```bash
scripts/00-download-reference-genome.sh
```

Download the [Allen Ancient DNA Resource](https://reich.hms.harvard.edu/allen-ancient-dna-resource-aadr-downloadable-genotypes-present-day-and-ancient-dna-data) dataset (v52.2)
```bash
scripts/00-download-aadr-dataset.sh
```

### 2. Download and preprocess Middle Neolithic samples from *Gurgy "Les-Noisats"* (GRG) and *Fleury-sur-Orne* (FLR)

Downloads sample alignment files from ENA projects [PRJEB36208](https://www.ebi.ac.uk/ena/browser/view/PRJEB36208), [PRJEB51061](https://www.ebi.ac.uk/ena/browser/view/PRJEB51061) and [PRJEB61818](https://www.ebi.ac.uk/ena/browser/view/PRJEB61818).

```bash
scripts/00-download-GRG-FLR-bams.sh  && scripts/00-sanitize-headers.sh && scripts/01-merge-bams.sh && scripts/02-remove-duplicates.sh && scripts/03-rescale-mapdamage.sh && scripts/04-pmd-mask.sh
```

Corresponding papers may be found here:

> Rivollat, M. et al. Ancient genome-wide DNA from France highlights the complexity of interactions between Mesolithic hunter-gatherers and Neolithic farmers. Sci. Adv. 6, (2020). https://doi.org/10.1126/sciadv.aaz5344

> Rivollat, M. et al. Ancient DNA gives new insights into a Norman Neolithic monumental cemetery dedicated to male elites. Proc. Natl. Acad. Sci. U.S.A. 119, (2022). https://doi.org/10.1073/pnas.2120786119

> Rivollat, M. et al. Extensive pedigrees reveal the social organization of a Neolithic community. Nature 620, 600–606 (2023). https://doi.org/10.1038/s41586-023-06350-8

### 3. Reorder the reference's chromosome order of our samples

**TL;DR:** This step is required because of the following htslib issue: https://github.com/samtools/htslib/issues/464

Briefly, our samples were ordered using a *lexicographically* sorted ordering of chromosomes, while most of the *Gurgy "Les-Noisats"* and *Fleury-sur-Orne* samples were processed with either hs37d5, or hg19, which are *numerically* sorted. This causes a ***silent error*** in `samtools`, which will in turn scramble the output when running `mpileup`, since the program assumes equally ordered chromosomes...

```bash
scripts/00-reorder-cerny-bams.sh
```

### 4. Gerate a joint pileup file for all samples.

This script will also exclude from the pileup file any sample defined in [resources/pileup/exclude-samples.txt](/resources/pileup/exclude-samples.txt) 

```bash
./scripts/05-generate-joint-pileup.sh
```

### 5. Apply random pseudo-haploid variant calling with pileupCaller

```bash
./scripts/06-run-pileupCaller.sh
```

### 6. Apply kinship analysis using multiple genetic relatedness estimation methods

#### using [GRUPS-rs](https://doi.org/10.47248/hpgg2404010001)

```bash
./06-multithread-grups-rs.sh || 06-rerun-failed-grups-rs.sh
./07-merge-grups-rs.sh
```

#### using [READ-v2](https://doi.org/10.1101/2024.01.23.576660)
```bash
./07-run-READv2.sh single # Analyze CER samples in isolation
./07-run-READv2.sg merged # Jointly analyze CER + GRG + FLR samples
```

#### using [READ](https://doi.org/10.1371/journal.pone.0195491):

```bash
./07-run-READ.sh
```


#### using [KIN](https://doi.org/10.1186/s13059-023-02847-7):

```bash
./05-run-KIN.sh single # Analyze CER samples in isolation
./05-run-KIN.sh merged # Jointly analyze CER + GRG + FLR samples
```

#### using [correctKin](https://doi.org/10.1186/s13059-023-02882-4)
```bash
./07-run-correctKin.sh
```

### 7. Plot the results

- Aggregate kinship estimation results as boxplots and highlight significant pairs.
    ```bash
    Rscript ./scripts/08-plot-READ-results.R \
    --results results/07-run-READv2/v52.2_1240K_public/merged/Read_Results.tsv \
    --meansP0 results/07-run-READv2/v52.2_1240K_public/merged/meansP0_AncientDNA_normalized_READv2 \
    --group-regex "GRG[0-9]+" "FLR[0-9]+" \
    --group-labels GRG FLR \
    --main-label CER \
    --notch \
    --filter-snps 1800 \
    --ci 0.95 \
    --filter-ns-pairs \
    --within-group-labels BAL VPB OLF PAS GLS \
    --within-group-regex 'BAL[0-9]+[ABC]{0,1}' 'VPB[0-9]+((-[0-9]|[ABC])){0,1}' 'OLF17' 'PAS6-1' 'GLS[0-9]+(-[0-9]){0,1}' \
    --plot-ratios 0.05 0.35 0.6
    ```

- Check and plot for sex-biased genetic distances
    ```bash
    Rscript scripts/08-kinship-analysis-Rx-ratio.R \
    --results-file results/07-run-READv2/v52.2_1240K_public/single/Read_Results.tsv \
    --rx-file resources/sex-assign/cerny-neo-moyen-Rx-ratios.tsv \
    --tool READv2 \
    --min-overlap 1800 \
    --output results/07-run-READv2/v52.2_1240K_public/single/sex-bias-boxplot-v52.2_1240K_public-READv2-single-filter1800SNPs.svg
    ```

### 8. Merging the results of all applied kinship estimation methods.

The following utility script may be executed to apply an outer join on the results of `READ`, `READ-v2`, `KIN` and `GRUPS-rs`. 

```bash
scripts/08-merge-results.sh
```
Note that the generated `.tsv` file(s) will be placed within the `./results/08-merged-kinship-results` subdirectory.
