#!/bin/bash
# 00_setup_env_and_tools.sh - Setup Conda environment and install Juicer

source config.sh

echo "=========================================="
echo " Setting up Hi-C Pipeline Environment"
echo "=========================================="

# Create directories
mkdir -p "${PROJECT_DIR}"
mkdir -p "${TOOLS_DIR}"
mkdir -p "${REF_DIR}"

# 1. Conda Environment
echo "[1/3] Creating Conda Environment..."
# Check if conda is installed
if ! command -v conda &> /dev/null; then
    echo "Error: Conda is not installed or not in PATH."
    exit 1
fi

# Create environment if it doesn't exist
if ! conda env list | grep -q "hic_analysis"; then
    conda env create -f environment.yml
else
    echo "Environment 'hic_analysis' already exists. Skipping creation."
fi

# 2. Install Juicer
echo "[2/3] Installing Juicer..."
cd "${TOOLS_DIR}" || exit 1

if [ ! -d "juicer" ]; then
    git clone https://github.com/aidenlab/juicer.git
    cd juicer
    mkdir -p scripts/common
    cp CPU/*.* scripts/common/
    cp CPU/common/* scripts/common/
    
    # Download Juicer Tools
    echo "Downloading Juicer Tools..."
    wget -q https://github.com/aidenlab/Juicebox/releases/download/v2.17.00/juicer_tools_2.17.00.jar
    mv juicer_tools_2.17.00.jar scripts/common/juicer_tools.jar
else
    echo "Juicer is already installed in ${TOOLS_DIR}/juicer."
fi

echo "[3/3] Setup complete!"
echo "To activate the environment, run: conda activate hic_analysis"
