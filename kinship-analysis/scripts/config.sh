# ---- Resources
THREADS=64       # Maximum number of additional worker threads
CONDA='conda'    # Path to a conda|mamba binary

# ---- Rivollat et al's publication Input bams
RIVOLLAT_DATA_DIR="data/00-raw"
RIVOLLAT_SAMPLE_REGEX="(GRG|FLR)[0-9]+"

# ----- Reference Genome
REFGEN_DIR="data/reference-genome/"

REFGEN_URL="http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz"
REFERENCE="${REFGEN_DIR}/$(basename ${REFGEN_URL%.gz})"

GRG_REFGEN_URL="https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/phase2_reference_assembly_sequence/hs37d5.fa.gz"
GRG_REFERENCE="${REFGEN_DIR}/$(basename ${GRG_REFGEN_URL%.gz})"

# ---- AADR 1240K SNP dataset
AADR_URL="https://reichdata.hms.harvard.edu/pub/datasets/amh_repo/curated_releases/V52/V52.2/SHARE/public.dir/v52.2_1240K_public.snp"
AADR_DIR="data/targets/AADR-1240k-v52.2"

AADR_SNP="${AADR_DIR}/$(basename ${AADR_URL})"
#AADR_SNP="resources/targets/4M2-EUR-1000g-v2.20240108.snp"

# ---- Pileup parameters
EXCLUDE_FILE="resources/pileup/exclude-samples.txt"
BQ=25
MQ=25

# ---- Global directories:
RESULTS_DIR="results"

# ---- Location of our preprocessed and QC'ed bam files
CERNY_BAM_DIR="../aDNA-pipeline/results/01-preprocess/07-rescale/pmd-mask/"
CERNY_REGEX="*.pmd_masked.bam"

# ---- GRUPS-rs parameters
DO_SELF_COMPARISONS=true
DATA_DIR="/home/mlefeuvre/Desktop/new-fst"
RECOMB_DIR="/data/mlefeuvre/datasets/recombination-maps/HapMapII_GRCh37"
PEDIGREE="/data/mlefeuvre/dev/grups-rs/resources/pedigrees/extended_pedigree.txt"
MODE="fst-mmap"
REPS=500
PED_POP="EUR"
CONTAM_POP="EUR"
SEED=984621654549
AF_DOWNSAMPLING_RATE="0.0"       # Naive value
#AF_DOWNSAMPLING_RATE="2.33"      # "2.32761610026188" # CER+FLR+GRG - 1240k panel
#AF_DOWNSAMPLING_RATE="5.88"      # "5.87718790748648" # CER+FLR+GRG - 4M2 panel

# ---- READ parameters
READ_NORM_METHOD="median"
READ_NORM_VALUE="-"

# ---- Overwrite these configuration parameters to apply to Early Neolithic samples
#RESULTS_DIR="results-cerny-MN"
#CERNY_BAM_DIR="/data/mlefeuvre/projects/cerny/20230719-Cerny-neo-ancien/aDNA-pipeline/results/01-preprocess/07-rescale/pmd-mask/"
#EXCLUDE_FILE="resources/pileup/exclude-samples-neo-ancien.txt"
#AF_DOWNSAMPLING_RATE="0.0"

