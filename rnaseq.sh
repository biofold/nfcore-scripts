#!/bin/bash

# Default values
OUTPUT_DIR="./results"  # Default output directory
RAW_DATA_DIR="./fastq_files"  # Default raw FastQ file directory
PROFILE=singularity
ENSEMBLE=/work/datasets/rnaseq/Ensemble
REFERENCE=GRCh38.111
GTF=$ENSEMBLE/$REFERENCE/annotations/Homo_sapiens.GRCh38.111.chr.gtf.gz
GENOME=$ENSEMBLE/$REFERENCE/genomes/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz
ALIGNER=star_salmon
VAR_CALLER=gatk
STAR_INDEX=$ENSEMBLE/$REFERENCE/indexes
SALMON_INDEX=$ENSEMBLE/$REFERENCE/indexes/salmon

# Function to display usage
usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -o <output_dir>      Set output directory (default: './results')"
  echo "  -r <raw_data_dir>    Set raw FastQ file directory (default: './fastq_files')"
  echo "  -s <samplesheet>     Provide an existing samplesheet CSV file"
  echo "  -i <sample_id_file>  Provide a file containing sample IDs to generate the samplesheet"
  echo "  -v variant=true      Boolean flag for variant calling"
  echo "  -h                   Display this help message"
  echo ""
  echo "Either the -s (samplesheet) or -i (sample_id_file) option must be provided, but not both."
  echo "For -i, the sample_id_file should contain one sample identifier per line."
  echo "The samplesheet will include columns: 'sample', 'fastq_1', 'fastq_2', 'strand' (auto by default)."
  echo ""
  echo "Example:"
  echo "  ./run_rnaseq.sh -i /path/to/sample_ids.txt"
  echo "  ./run_rnaseq.sh -s /path/to/existing_samplesheet.csv"
  echo "  ./run_rnaseq.sh -i /path/to/sample_ids.txt -o /path/to/output_directory"
  exit 0
}



# Check if arguments are provided
while getopts "o:r:s:i:vh" opt; do
  case $opt in
    o) OUTPUT_DIR="$OPTARG" ;;
    r) RAW_DATA_DIR="$OPTARG" ;;
    s) SAMPLESHEET="$OPTARG" ;;  # Provided samplesheet file
    i) SAMPLE_ID_FILE="$OPTARG" ;;  # Provided sample_id_file
    v) VARIANT=true ;;           # Add variant calling
    h) usage ;;  # Display the help message
    *) echo "Invalid option"; exit 1 ;;
  esac
done


# Ensure only one of -s or -i is provided
if [[ -n "$SAMPLE_ID_FILE" && -n "$SAMPLESHEET" ]]; then
  echo "Error: You cannot provide both the sample_id_file (-i) and the samplesheet (-s). Please choose one."
  exit 1
fi

# Ensure output directory exists
mkdir -p $OUTPUT_DIR

# If sample_id_file (-i) is provided, generate the samplesheet
if [[ -n "$SAMPLE_ID_FILE" ]]; then
  if [[ ! -f "$SAMPLE_ID_FILE" ]]; then
    echo "Error: The file '$SAMPLE_ID_FILE' does not exist. Please provide a valid file."
    exit 1
  fi
  
  if [[ -n "$SAMPLE_ID_FILE" ]]; then
    SAMPLESHEET="samplesheet.csv"  # Default samplesheet file    
  fi
  
  echo "Reading sample identifiers from $SAMPLE_ID_FILE..."
  mapfile -t SAMPLES < "$SAMPLE_ID_FILE"

  # Create the samplesheet for nf-core/rnaseq
  echo "Creating samplesheet for nf-core/rnaseq..."

  # Initialize the samplesheet with column headers including strand column (auto by default)
  echo "sample,fastq_1,fastq_2,strandedness" > $SAMPLESHEET

  # Loop through each sample and add its FastQ file paths and strandness to the samplesheet
  for SAMPLE in "${SAMPLES[@]}"; do
    FASTQ_1="$RAW_DATA_DIR/${SAMPLE}"_1.fastq.gz
    FASTQ_2="$RAW_DATA_DIR/${SAMPLE}"_2.fastq.gz
    if [[ -f "$FASTQ_1"  &&  -f "$FASTQ_2" ]]; then
      # By default, the strandness is set to "auto"
      echo "$SAMPLE,$FASTQ_1,$FASTQ_2,auto" >> $SAMPLESHEET
    else
      echo "Warning: FastQ files for $SAMPLE not found in $RAW_DATA_DIR"
    fi
  done
  echo "Samplesheet '$SAMPLESHEET' created from sample IDs with strandness 'auto'."

# If samplesheet (-s) is provided, use the given file
elif [[ -n "$SAMPLESHEET" ]]; then
  if [[ ! -f "$SAMPLESHEET" ]]; then
    echo "Error: The provided samplesheet '$SAMPLESHEET' does not exist. Please provide a valid file."
    exit 1
  fi
  echo "Using provided samplesheet '$SAMPLESHEET'."
fi

# Run nf-core/rnaseq pipeline
echo "Starting nf-core/rnaseq pipeline..."

CMD="nextflow run nf-core/rnaseq \
  -profile $PROFILE \
  --input $SAMPLESHEET \
  --outdir $OUTPUT_DIR/rnaseq \
  --gtf $GTF \
  --fasta $GENOME \
  --aligner $ALIGNER \
  --save_mapped_reads \
  --skip_markduplicates false \
  --star_index $STAR_INDEX \
  --salmon_index $SALMON_INDEX"

if [ "$VARIANT" = true ]; then
    CMD+=" --variant_caller $VAR_CALLER "  # Add flag if -v is passed
fi

$CMD

echo "nf-core/rnaseq pipeline completed."

