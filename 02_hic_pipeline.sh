#!/bin/bash
# 02_hic_pipeline.sh - Main Hi-C analysis pipeline loop

source config.sh

echo "=========================================="
echo " Starting Hi-C Analysis Pipeline"
echo "=========================================="

if [[ "$CONDA_DEFAULT_ENV" != "hic_analysis" ]]; then
    echo "Warning: Conda environment 'hic_analysis' is not active."
fi

for SAMPLE in "${SAMPLES[@]}"; do
    echo "------------------------------------------"
    echo "Processing Sample: ${SAMPLE}"
    echo "------------------------------------------"

    # Define sample directories
    SAMPLE_DIR="${PROJECT_DIR}/${SAMPLE}"
    RAW_DIR="${SAMPLE_DIR}/raw_data"
    QC_DIR="${SAMPLE_DIR}/qc_reports"
    TRIM_DIR="${SAMPLE_DIR}/trimmed_data"
    FASTQ_DIR="${SAMPLE_DIR}/fastq"
    ALIGNED_DIR="${SAMPLE_DIR}/aligned"
    TADS_DIR="${ALIGNED_DIR}/tads"
    COMPARTMENTS_DIR="${ALIGNED_DIR}/compartments"
    LOOPS_DIR="${ALIGNED_DIR}/loops"

    mkdir -p "${RAW_DIR}" "${QC_DIR}/raw" "${QC_DIR}/trimmed" "${TRIM_DIR}" "${FASTQ_DIR}"
    mkdir -p "${ALIGNED_DIR}" "${TADS_DIR}" "${COMPARTMENTS_DIR}" "${LOOPS_DIR}"

    # ==========================================
    # Step 1: Download Data (Optional)
    # ==========================================
    # If using local data, place the fastq files in RAW_DIR
    if [ ! -f "${RAW_DIR}/${SAMPLE}_1.fastq.gz" ] && [ ! -f "${RAW_DIR}/${SAMPLE}_1.fastq" ]; then
        echo "[1/6] Downloading ${SAMPLE} from SRA..."
        cd "${RAW_DIR}"
        fasterq-dump "${SAMPLE}"
        gzip *.fastq
    else
        echo "[1/6] Raw data for ${SAMPLE} found. Skipping download."
    fi

    # ==========================================
    # Step 2: Quality Control
    # ==========================================
    echo "[2/6] Running FastQC on raw data..."
    fastqc "${RAW_DIR}"/*.fastq.gz -o "${QC_DIR}/raw" -t "${THREADS}"

    # ==========================================
    # Step 3: Adapter Trimming
    # ==========================================
    echo "[3/6] Running Trim Galore..."
    if [ ! -f "${TRIM_DIR}/${SAMPLE}_1_val_1.fq.gz" ]; then
        trim_galore \
            --paired \
            --quality 20 \
            --stringency 3 \
            --length 20 \
            --fastqc \
            --cores 8 \
            --output_dir "${TRIM_DIR}" \
            "${RAW_DIR}/${SAMPLE}_1.fastq.gz" \
            "${RAW_DIR}/${SAMPLE}_2.fastq.gz"
    else
        echo "Trimmed files found. Skipping trimming."
    fi

    # ==========================================
    # Step 4: Prepare input for Juicer
    # ==========================================
    echo "[4/6] Preparing input for Juicer..."
    if [ ! -f "${FASTQ_DIR}/${SAMPLE}_R1.fastq" ]; then
        gunzip -c "${TRIM_DIR}/${SAMPLE}_1_val_1.fq.gz" > "${FASTQ_DIR}/${SAMPLE}_R1.fastq"
        gunzip -c "${TRIM_DIR}/${SAMPLE}_2_val_2.fq.gz" > "${FASTQ_DIR}/${SAMPLE}_R2.fastq"
    else
        echo "Juicer input files ready."
    fi

    # ==========================================
    # Step 5: Run Juicer Pipeline
    # ==========================================
    echo "[5/6] Running Juicer Pipeline..."
    if [ ! -f "${ALIGNED_DIR}/inter_30.hic" ]; then
        bash "${JUICER_DIR}/scripts/common/juicer.sh" \
            -D "${JUICER_DIR}" \
            -d "${SAMPLE_DIR}" \
            -g "${GENOME}" \
            -s "${RESTRICTION_SITE}" \
            -p "${CHROM_SIZES}" \
            -y "${RESTRICTION_FILE}" \
            -z "${FASTA_FILE}" \
            -t "${THREADS}"
            
        # Validate output
        java -Xmx${MEMORY} -jar "${JUICER_TOOLS}" validate "${ALIGNED_DIR}/inter_30.hic"
    else
        echo "Juicer output (inter_30.hic) found. Skipping alignment."
    fi

    # ==========================================
    # Step 6: Advanced Analysis (TADs, Compartments, Loops)
    # ==========================================
    echo "[6/6] Running Advanced Feature Detection..."
    HIC_FILE="${ALIGNED_DIR}/inter_30.hic"

    # TADs (Arrowhead)
    if [ ! -f "${TADS_DIR}/25000_blocks.bedpe" ]; then
        echo "Detecting TADs..."
        java -Xmx${MEMORY} -jar "${JUICER_TOOLS}" arrowhead \
            -m 5000 -r 25000 -k "${NORMALIZATION}" \
            "${HIC_FILE}" "${TADS_DIR}"
            
        awk 'NR>1 {print $1"\t"$2"\t"$6"\tTAD_"NR-1"\t1000\t."}' \
            "${TADS_DIR}/25000_blocks.bedpe" | tail -n +2 > \
            "${TADS_DIR}/tad_domains_25kb.bed"
    fi

    # Compartments (Eigenvector)
    # Note: Running for chr1 as example from markdown. You can loop over chromosomes.
    if [ ! -f "${COMPARTMENTS_DIR}/chr1_eigenvector_100kb.txt" ]; then
        echo "Detecting Compartments for chr1..."
        java -Xmx${MEMORY} -jar "${JUICER_TOOLS}" eigenvector \
            "${NORMALIZATION}" \
            "${HIC_FILE}" \
            chr1 \
            BP 100000 \
            "${COMPARTMENTS_DIR}/chr1_eigenvector_100kb.txt"
    fi

    # Loops (HiCCUPS)
    if [ ! -d "${LOOPS_DIR}/postprocessed_pixels_5000.bedpe" ]; then
        echo "Detecting Loops..."
        # HiCCUPS requires a GPU usually, but can run on CPU with limits
        java -Xmx${MEMORY} -jar "${JUICER_TOOLS}" hiccups \
            -m 512 \
            -r 5000,10000 \
            -f 0.1,0.1 \
            -p 4,2 \
            -i 7,5 \
            -d 20000,20000 \
            "${HIC_FILE}" \
            "${LOOPS_DIR}"
    fi

    echo "Finished processing ${SAMPLE}."
done

echo "=========================================="
echo " Pipeline Complete!"
echo "=========================================="
