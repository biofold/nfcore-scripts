# nfcore-scripts

rnaseq.sh: Run nf-core rnaseq pipeline

    Usage: ./rnaseq.sh [options]

    Options:
      -o <output_dir>      Set output directory (default: './results')
      -r <raw_data_dir>    Set raw FastQ file directory (default: './fastq_files')
      -s <samplesheet>     Provide an existing samplesheet CSV file
      -i <sample_id_file>  Provide a file containing sample IDs to generate the samplesheet
      -v variant=true      Execute variant calling with gatk
      -h                   Display this help message

    Either the -s (samplesheet) or -i (sample_id_file) option must be provided, but not both.
    For -i, the sample_id_file should contain one sample identifier per line.
    The samplesheet will include columns: 'sample', 'fastq_1', 'fastq_2', 'strand' (auto by default).

    Example:
      ./run_rnaseq.sh -i /path/to/sample_ids.txt
      ./run_rnaseq.sh -s /path/to/existing_samplesheet.csv
      ./run_rnaseq.sh -i /path/to/sample_ids.txt -o /path/to/output_directory


differentialabundance.sh: Differential expression of genes starting from salmon counts analysis

    Usage: ./gene_differentialabundance.sh <CASE> <CONTROL> <MATRIX> <GENE_LENGTH> 
    -o <output_dir> -n <project_name> -f <fastq_dir> -g <gtf_file> -w <work_dir>
    -t <transcript_true>

    Required Arguments (Positional):
      1. CASE          - File containig case ids
      2. CONTROL       - File containig control ids
      3. MATRIX        - Gene/Transcript count file from rnaseq
      4. GENE_LENGTH   - Gene/Transcript length file from rnaseq

    Optional Flags:
      -o OUTDIR          Output directory
      -n NAME            Project name
      -f FASTQ_DIR       Fastq directory
      -g GTF_FILE        GTF file
      -w WORK_DIR        Work directory
      -t TRANSCRIPT=true Transcript Differential Abundance
      -h                 Display this help message

