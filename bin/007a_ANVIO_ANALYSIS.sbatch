#!/bin/bash
#SBATCH --partition=defq                       # the requested queue
#SBATCH --job-name=ANVIO                       # name of job
#SBATCH --nodes=1                              # number of nodes to use
#SBATCH --tasks-per-node=1                     #
#SBATCH --cpus-per-task=16                      #
#SBATCH --mem=8G                               # in megabytes, unless unit explicitly stated
#SBATCH --error=anvio-%J.err                   # redirect stderr to this file
#SBATCH --output=anvio-%J.out                  # redirect stdout to this file
#SBATCH --time=05:00:00                        # Assign a max time for the job to run.
##SBATCH --mail-user=<username>@cardiff.ac.uk  # email address used for event notification
##SBATCH --mail-type=all                       # email on job start, failure and end

# ~~~~~~~~~~ ACKOWLEDGMENTS ~~~~~~~~~~

# Correspondance: Dan Shelley (shelleydr@cardiff.ac.uk)

# Special thanks to Andy Ells (EllsA@cardiff.ac.uk) for support (and encouragment).

# ~~~~~~~~~~ NOTES ~~~~~~~~~~

# ANVIO does not like commands spread over multiple lines (seperated by \), therefore they're written on single 
# lines with comments noted below. Sorry! 

# ~~~~~~~~~~ CONFIG ~~~~~~~~~~
 
source ANVIO.config

# CONFIG VARIABLES......................................................#

echo "==================================================="
echo "Config Called Variables............................"
echo "==================================================="
echo "Cache Directory:.......... ${CACHEDIR}"
echo "Image Directory:.......... ${IMAGEDIR}"
echo "Tmp Directory:............ ${TMPDIR}"
echo "==================================================="
echo "Container Directory:...... ${CONTAINERDIR}"
echo "Container Tmp Directory:.. ${CONTAINERTMP}"
echo "==================================================="
echo "ANVIO Genomes Directory:.. ${ANVIOGENOMES}"
echo "ANVIO Database Directory:. ${ANVIODB}"
echo "ANVIO Metadata Directory:. ${METADATA}"
echo "==================================================="

# ~~~~~~~~~~ IMAGE DOWNLOAD ~~~~~~~~~~

module load apptainer/1.3.4						# Loading Apptainer
                                                                        # !! Set both Singularity and Apptainer Cache (previous issues) !!
export SINGULARITY_CACHEDIR=${CACHEDIR}   # Singularity Cache
export APPTAINER_CACHEDIR=${CACHEDIR}     # Apptainer Cache
export TMPDIR=${TMPDIR}                   # Temp storage directory 

if [ -f ${SINGULARITY_IMG} ]; then                             # See if the Image is already downloaded
    echo "Docker image exists - skipping download."
else
    echo "Docker image does not exist - downloading ${IMAGENAME}"
    singularity pull ${SINGULARITY_IMG} docker://${IMAGENAME} # Install the image (image is docker and needs do$
fi

# ~~~~~~~~~~ CONTAINER AND ANVIO ~~~~~~~~~~

export BINDS="${WORKDIR}:${CONTAINERDIR},${TMPDIR}:${CONTAINERTMP}" # Binding Work and Tmp directories

cat > anvio_init_${SLURM_JOB_ID}.sh << EOF                              # Generate the ANVIO initalising script to be executed

# ~~~~~ INITIATE ANVIO ENV ~~~~~

source /opt/conda/bin/activate anvioenv                                 # Activate the ANVIO environment

# Calling the Config in the Container ................................#

source ANVIO.config

# Container Variables ................................................#

echo \${BINDS}
echo \${CONTAINERDIR}
echo \${ANVIOGENOMES}
echo \${ANVIODB}

# Fix FASTA Deflines .................................................#

for FILE in ${ANVIOGENOMES}/*.fasta                                    # Complete the following for all genomes found in ANVIOGENOMES
do
    echo \${FILE}
    NAME=\$(basename "\${FILE}" .fasta)                                 # Extract the sample ID (basename) for prefixing files
    echo \${NAME}

    ## Simplify FASTA deflines
    anvi-script-reformat-fasta \${FILE} -o ${ANVIOGENOMES}/\${NAME}_fixed.fa -l 0 --simplify-names
    # -o =  Define an output directory
    # -l =  Define a limit to trim contrigs below a length and to simplify names 

    ## Generate contig database
    anvi-gen-contigs-database -f ${ANVIOGENOMES}/\${NAME}_fixed.fa -o ${ANVIODB}/\${NAME}.db -n "\${NAME}"
    # -f = Define an input simplified FASTA file
    # -o = Define an output for the contigs.db files
    # -n = Include a name for the sample (useful later)

    ## Annotation of contigs.db
    anvi-run-hmms -c ${ANVIODB}/\${NAME}.db --num-threads ${SLURM_CPUS_PER_TASK} 
    # -c = Contig.db directory
    # --num-threads = Number of threads  (using 1 is super slow)

    anvi-run-ncbi-cogs -c ${ANVIODB}/\${NAME}.db --num-threads ${SLURM_CPUS_PER_TASK} --cog-data-dir ${COGDB}
    # -c = Contig.db directory
    # --num-threads = Number of threads  (using 1 is super slow)
    # --cog-data-dir = The NCBI COG data base (see README.md on how to install ---- when I make it...)
done

wait
# ~~~~~ GENERATE EXTERNAL GENOME FILE ~~~~~

# ANVIO required a .tsv file as an input of external genomes - they define as being anything already generated in a FASTA.

OUTPUT_FILE="${ANVIODB}/external-genomes.txt"

# Write the header
echo -e "name\tcontigs_db_path" > "$OUTPUT_FILE"

# Loop through all .db files
for file in \${ANVIODB}/*.db; do
    echo \${file}

    filename=\$(basename "\${file}")
    echo "Raw filename: \$filename"

    name=\${filename%.db}
    echo "Extracted name: \$name"

    echo -e "\${name}\t\${file}" >> "\$OUTPUT_FILE"
done

cat "$OUTPUT_FILE"

wait
# ~~~~~ PANGENOME GENERATION ~~~~~

# Generate a combined pangenome contigs database (PANGENOME.db)
anvi-gen-genomes-storage -e ${ANVIODB}/external-genomes.txt -o ${ANVIODB}/${DBNAME}.db
# -e = Define the path to our external-genomes.tsv file
# -o = Define the output path and file name

wait

# Generate the Pangenome Analysis 
anvi-pan-genome -g ${ANVIODB}/${DBNAME}.db -n "${DBNAME}" -o \${ANVIODB}/${DBNAME} --num-threads ${SLURM_CPUS_PER_TASK} 
# -g = Path to PANGENOME.db (we generated)
# -n = Name out Project
# -o = Path to our output directory
# --num-threads = Number of CPUs (1 is very slow)

wait

# PyANI for Pangenomes
anvi-compute-genome-similarity --external-genomes ${ANVIODB}/external-genomes.txt \
                               --program fastANI \
                               --output-dir ${ANVIODIR}/ANI \
                               --num-threads ${SLURM_CPUS_PER_TASK} \
                               --pan-db ${ANVIODB}/${DBNAME}/${DBNAME}-PAN.db

wait

# Import Metadata
anvi-import-misc-data ${METADATA} \
                      -p \${ANVIODB}/${DBNAME}/${DBNAME}-PAN.db \
                      --target-data-table layers

echo "Analysis and environment preperation complete. Run 007b_ANVIO_VISUALISATION.sbatch to view your genomes."

EOF

# ~~~~~~~~~ INITIATING CONTAINER ~~~~~~~~~

singularity exec --contain --bind ${BINDS} --pwd ${CONTAINERDIR} ${SINGULARITY_IMG} bash anvio_init_${SLURM_JOB_ID}.sh
# --contain --bind =  Containerise and bind working directory.
# --pwd = Start the container in the working directory.


