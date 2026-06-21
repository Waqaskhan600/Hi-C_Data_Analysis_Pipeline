#!/bin/bash
# config.sh - Central configuration file for Hi-C Pipeline

# ==========================================
# 1. Project Directories
# ==========================================
export PROJECT_DIR="/media/user/New_Volume/Epigen/hic_pipeline/project"
export TOOLS_DIR="/media/user/New_Volume/Epigen/hic_pipeline/tools"
export REF_DIR="/media/user/New_Volume/Epigen/hic_pipeline/references"

# ==========================================
# 2. Reference Genome Information
# ==========================================
export GENOME="hg38"
export FASTA_URL="https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz"
export FASTA_FILE="${REF_DIR}/${GENOME}/${GENOME}.fa"
export CHROM_SIZES="${REF_DIR}/${GENOME}/${GENOME}.chrom.sizes"

# Restriction enzyme info
export RESTRICTION_SITE="MboI"
export RESTRICTION_FILE="${REF_DIR}/${GENOME}/${GENOME}_${RESTRICTION_SITE}.txt"

# ==========================================
# 3. Global Pipeline Parameters
# ==========================================
export THREADS=16
export MEMORY="32g"

# Juicer settings
export JUICER_DIR="${TOOLS_DIR}/juicer"
export JUICER_TOOLS="${JUICER_DIR}/scripts/common/juicer_tools.jar"
export NORMALIZATION="KR"

# ==========================================
# 4. Samples to Process
# ==========================================
# Add your SRA accession IDs or sample names here
export SAMPLES=(
    "SRR1658570"
    # "SRR1658571"
)
