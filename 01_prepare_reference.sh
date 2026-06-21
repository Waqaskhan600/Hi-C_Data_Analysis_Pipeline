#!/bin/bash
# 01_prepare_reference.sh - Download and prepare reference genome

source config.sh

echo "=========================================="
echo " Preparing Reference Genome and Sites"
echo "=========================================="

# Ensure environment is active
if [[ "$CONDA_DEFAULT_ENV" != "hic_analysis" ]]; then
    echo "Warning: Conda environment 'hic_analysis' is not active."
    echo "Please run: conda activate hic_analysis before executing this script."
    # We won't exit, but we warn the user
fi

mkdir -p "${REF_DIR}/${GENOME}"
cd "${REF_DIR}/${GENOME}" || exit 1

# 1. Download Reference Genome
echo "[1/3] Checking reference genome ${GENOME}..."
if [ ! -f "${GENOME}.fa" ]; then
    echo "Downloading ${GENOME}.fa.gz..."
    wget -q "${FASTA_URL}" -O "${GENOME}.fa.gz"
    echo "Unzipping genome..."
    gunzip "${GENOME}.fa.gz"
else
    echo "Reference genome ${GENOME}.fa already exists."
fi

# 2. BWA Index
echo "[2/3] Checking BWA index..."
if [ ! -f "${GENOME}.fa.bwt" ]; then
    echo "Indexing genome with BWA (this may take a while)..."
    bwa index "${GENOME}.fa"
else
    echo "BWA index already exists."
fi

# 3. Generate restriction sites
echo "[3/3] Generating restriction sites and chrom sizes..."
if [ ! -f "${GENOME}.chrom.sizes" ]; then
    echo "Generating chromosome sizes..."
    samtools faidx "${GENOME}.fa"
    cut -f1,2 "${GENOME}.fa.fai" > "${GENOME}.chrom.sizes"
fi

if [ ! -f "${RESTRICTION_FILE}" ]; then
    echo "Generating restriction sites..."
    # Call the python script we created earlier
    python3 "${PROJECT_DIR}/../generate_restriction_sites.py" "${GENOME}.fa" "${GENOME}"
else
    echo "Restriction site file ${RESTRICTION_FILE} already exists."
fi

echo "Reference preparation complete!"
