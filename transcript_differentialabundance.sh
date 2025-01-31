#!/bin/bash
conda init bash
conda activate pipelines

usage() {
    echo "Usage: $0 <CASE> <CONTROL> <MATRIX> <GENE_LENGTH> -o <output_dir> -n <project_name> -f <fastq_dir> -g <gtf_file> -w <work_dir>"
    echo "Required Arguments (Positional):"
    echo "  1. CASE          - File containig case ids"
    echo "  2. CONTROL       - File containig control ids"
    echo "  3. MATRIX        - Transcript count file from rnaseq"
    echo "  4. GENE_LENGTH   - Transcript length file from rnaseq"
    echo ""
    echo "Optional Flags:"
    echo "  -o    Specify output directory"
    echo "  -n    Specify project name"
    echo "  -f    Specify the fastq directory"
    echo "  -g    Specify the gtf file"
    echo "  -w    Specify work directory"
    echo "  -h    Display this help message"
    exit 1
}

if [[ "$#" -lt 4 ]]; then
    echo "Error: Missing arguments."
    usage
fi

# Needed input files
CASE=$1
CONTROL=$2
MATRIX=$3
GENE_LENGTH=$4

if [[ ! -f $CASE || ! -f $CONTROL || ! -f $MATRIX || ! -f $GENE_LENGTH ]]; then
    echo "Error: One of the file does not exist. Please provide a valid files."
    exit 1
   fi


# Defauklt options
OUTDIR=./
NAME="differentialabundundance_transcript"
GTF_FOLDER=/work/datasets/rnaseq/Ensemble/GRCh38.111/annotations
GTF_FILE=$GTF_FOLDER/Homo_sapiens.GRCh38.111.chr.gtf.gz
#ENS2GENE=$GTF_FOLDER/gene_ens2name.tsv
FASTQ_DIR=/work/biofold/biofold/pnrr-mr/rnaseq/raw/
PROFILE=rnaseq,singularity
FEATURE_ID_COL="transcript_id"
DIFFERENTIAL_FEATURE_ID_COLUMN="transcript_id"
FEATURES_METADATA_COLS="transcript_id,gene_id,gene_name,gene_biotype"


# Start reading options after the 4 required inputs
shift 4

while getopts "o:n:f:g:w:l:h" opt; do
  case $opt in
    o) OUTDIR="$OPTARG" ;;     # output directory
    n) NAME="$OPTARG" ;;       # name on the project
    f) FASTQ_DIR="$OPTARG" ;;  # fastq files directory
    g) GTF_FILE="$OPTARG" ;;   # gtf file
    w) WORK_DIR="$OPTARG" ;;   # provide work directory
    h) usage ;;  # Display the help message
    *) echo "Invalid option"; exit 1 ;;
  esac
done


if [[ -n "$WORK_DIR" ]]; then
    WORK_DIR=$OUTDIR/work   # store work files under $OUTDIR/work
fi

if [[ -n "$LOG_FILE" ]]; then
   LOG_FILE=$OUTDIR/nextflow.log     # store log file under $OUTDIR/work
fi

CONTRAST="contrast_$NAME.csv"
SAMPLE_SHEET=$NAME"_sample_sheet.csv"


# Generate modified MATRIX file replacing tx with transcript_id
sed '1 s/tx/transcript_id/' $MATRIX > "${MATRIX%.*}.mod.tsv"
MATRIX="${MATRIX%.*}.mod.tsv"

# Generate modified GENE_LENGTH file replacing tx with transcript_id
sed '1 s/tx/transcript_id/' $GENE_LENGTH > "${GENE_LENGTH%.*}.mod.tsv"
GENE_LENGTH="${GENE_LENGTH%.*}.mod.tsv"

#sed command used to replace NG- with NG. in the sample name
echo "sample,fastq_1,fastq_2,condition,replicate,batch" >$SAMPLE_SHEET 
awk -v fdir=$FASTQ_DIR '{print $1","fdir$1"_1.fastq.gz,"fdir$1"_2.fastq.gz,case,1,F"}' $CASE |sed 's/^NG-/NG\./' >> $SAMPLE_SHEET
awk -v fdir=$FASTQ_DIR '{print $1","fdir$1"_1.fastq.gz,"fdir$1"_2.fastq.gz,control,1,F"}' $CONTROL |sed 's/^NG-/NG\./'  >> $SAMPLE_SHEET

echo "id,variable,reference,target,blocking" > $CONTRAST
echo $NAME"_case_control,condition,control,case," >> $CONTRAST

nextflow run nf-core/differentialabundance \
         --input $SAMPLE_SHEET  \
         --contrasts $CONTRAST  \
         --matrix $MATRIX       \
         --transcript_length_matrix $GENE_LENGTH \
         --features_id_col $FEATURE_ID_COL \
         --differential_feature_id_column $DIFFERENTIAL_FEATURE_ID_COLUMN \
         --features_metadata_cols $FEATURES_METADATA_COLS \
         --gtf $GTF_FILE        \
         -work-dir $WORK_DIR    \
         --outdir $OUTDIR/$NAME \
         -profile $PROFILE

