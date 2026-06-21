# Hi-C Data Analysis Pipeline

This repository contains a comprehensive, highly dynamic, and reproducible bash-based pipeline for processing **High-throughput Chromosome Conformation Capture (Hi-C)** sequencing data. The pipeline handles everything from raw fastq downloads to advanced 3D feature detection (TADs, Compartments, and Chromatin Loops) using the industry-standard Juicer toolset.

---

## What is Hi-C and Why is it Important?

The genome isn’t just a linear string of DNA—it exists as a highly folded, complex three-dimensional structure within the cell nucleus. 

**Hi-C** is a powerful molecular technique that captures and sequences DNA fragments that are physically close to each other in 3D space, even if they are millions of base pairs apart on the linear genome. 

Understanding this 3D architecture is absolutely critical because it dictates genome function:
* **Gene Regulation:** It reveals how distant regulatory elements like enhancers physically contact promoters to turn genes on or off (Chromatin Loops).
* **Structural Organization:** It maps the boundaries of Topologically Associating Domains (TADs)—insulated neighborhoods where genes share regulatory patterns.
* **Disease & Cancer:** Disruptions in the 3D genome (such as structural variations that merge TADs) can cause enhancers to activate the wrong genes, leading to oncogenesis and other genetic diseases.
* **Compartmentalization:** It identifies active (A) and inactive (B) compartments, showing large-scale epigenetic states.

## Why Use This Pipeline?

This pipeline bridges the gap between complex bioinformatics tools and reproducibility. It is designed to be:
1. **Fully Dynamic:** Just provide a list of SRA IDs or local sample names in the `config.sh`, and the pipeline handles the rest.
2. **Reproducible:** A unified `environment.yml` guarantees that you and your collaborators are using the exact same software versions.
3. **Automated Structure:** It autonomously enforces a clean, logical project directory structure, keeping raw data, QC reports, and aligned matrices perfectly organized.
4. **Resilient:** Built-in checks ensure that if a step fails or is interrupted, you can restart the script and it will intelligently resume from where it left off, rather than repeating hours of alignment.

---

## Repository Structure

```text
hic_pipeline/
├── environment.yml                # Conda environment definition
├── config.sh                      # Central configuration file (paths, threads, samples)
├── generate_restriction_sites.py  # Python script to generate enzyme cut sites
├── 00_setup_env_and_tools.sh      # Script to build Juicer and install jar files
├── 01_prepare_reference.sh        # Script to download/index the reference genome
└── 02_hic_pipeline.sh             # Main execution script to process all samples
```

---

## Step-by-Step Usage Guide

Follow these steps to deploy and run the pipeline on your own machine or cluster.

### Step 1: Clone the Repository
If you haven't already, clone this repository to your local machine and navigate into the folder:
```bash
git clone <https://github.com/Waqaskhan600/Hi-C_Data_Analysis_Pipeline.git>
cd hic_pipeline
```

### Step 2: Setup the Conda Environment
We use Conda to manage all dependencies (Python, bwa, samtools, fastqc, java, etc.). Create and activate the environment:
```bash
conda env create -f environment.yml
conda activate hic_analysis
```

### Step 3: Install the Tools (Juicer)
Run the initial setup script. This will clone the Juicer repository, compile the necessary scripts, and download the `juicer_tools.jar` required for feature extraction.
```bash
./00_setup_env_and_tools.sh
```

### Step 4: Configure Your Run
Open `config.sh` in your favorite text editor. This is your command center.
* **Genomes:** Set the `GENOME` variable (default is `hg38`). 
* **Enzymes:** Define the `RESTRICTION_SITE` used during your Hi-C library prep (e.g., `MboI` or `HindIII`).
* **Samples:** Add your target sample names or SRA accessions to the `SAMPLES` array at the bottom of the file.
* **Resources:** Adjust the `THREADS` and `MEMORY` variables to match your machine's capabilities.

### Step 5: Prepare the Reference Genome
Run the reference preparation script. If the reference fasta isn't found locally, this script will download it from UCSC, index it using BWA, calculate chromosome sizes, and map out the restriction enzyme cut sites.
```bash
./01_prepare_reference.sh
```

### Step 6: Execute the Main Pipeline
With the environment activated and references ready, start the main pipeline. 
```bash
./02_hic_pipeline.sh
```

#### What `02_hic_pipeline.sh` actually does per sample:
1. **Data Retrieval:** Downloads fastq files via `fasterq-dump` (if SRA IDs are provided and data isn't local).
2. **Quality Control:** Generates `FastQC` reports.
3. **Trimming:** Trims adapters and low-quality bases via `Trim Galore`.
4. **Alignment & Matrix Generation:** Executes the `juicer.sh` pipeline to generate the core `.hic` contact matrix.
5. **Feature Extraction:**
   - Detects **TADs** (Arrowhead algorithm)
   - Detects **A/B Compartments** (Eigenvector analysis)
   - Detects **Chromatin Loops** (HiCCUPS algorithm)

### Step 7: Visualizing the Results
Once the pipeline finishes, navigate to `project/<sample_name>/aligned/`. You will find the `inter_30.hic` matrix file. You can load this file into the desktop or web version of **Juicebox** (https://aidenlab.org/juicebox/) to interactively explore your 3D genome maps, alongside the generated TAD and Loop `.bedpe` annotation files!
