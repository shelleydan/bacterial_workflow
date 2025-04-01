#!/bin/bash
#SBATCH --partition=defq                       # the requested queue
#SBATCH --job-name=ANVIO                       # name of job
#SBATCH --nodes=1                              # number of nodes to use
#SBATCH --tasks-per-node=1                     #
#SBATCH --cpus-per-task=8                      #
#SBATCH --mem=8G                               # in megabytes, unless unit explicitly stated
#SBATCH --error=anvio-%J.err                   # redirect stderr to this file
#SBATCH --output=anvio-%J.out                  # redirect stdout to this file
#SBATCH --time=02:00:00                        # Assign a max time for the job to run.
##SBATCH --mail-user=<username>@cardiff.ac.uk  # email address used for event notification
##SBATCH --mail-type=all                       # email on job start, failure and end

# ~~~~~~~~~~ ACKOWLEDGMENTS ~~~~~~~~~~

# Correspondance: Dan Shelley (shelleydr@cardiff.ac.uk)

# Special thanks to Andy Ells (EllsA@cardiff.ac.uk) for support (and encouragment). 

# ~~~~~~~~~~ DEFINING VARIABLES ~~~~~~~~~~
 
WORKDIR=$(pwd)                                 # Setting Working Directory 
CONTWORKDIR="/mnt/container"                   # Generate Container Directory (ANVIO hates long container paths)

# ~~~~~~~~~ GENERATING A RANDOM PORT ~~~~~~~~~

module load python/                            # Loading Python

# Generate random port number.
PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()') # Generate the random port

echo "Your Unique Port is: ${PORT}"            # Print the random port number. 

module unload python/                          # Unload python before building the container

# ~~~~~~~~~~ IMAGE DOWNLOAD ~~~~~~~~~~

module load apptainer/1.3.4						# Loading Apptainer
                                                                        # !! Set both Singularity and Apptainer Cache (previous issues) !!
export SINGULARITY_CACHEDIR=/mnt/scratch/${USER}/singularity/cache/     # Set Singularity Cache
export APPTAINER_CACHEDIR=/mnt/scratch/${USER}/singularity/cache/       # Set Apptainer Cache
export TMPDIR=/mnt/scratch/${USER}/singularity/cache/                   # Set directory for temp. file storage 

IMAGE_NAME=meren/anvio:8                                                # Defining the image name (group/image-name)
SINGULARITY_IMAGE_NAME=anvio:8                                          # Define the cache name
SINGIMGDIR=/mnt/scratch/${USER}/singularity/cache                       # Define the singularity/apptainer directory

if [ -f /mnt/scratch/${USER}/singularity/cache/meren_anvio.sif ]; then  # Look within the singularity directory to see if the image is already downloaded
    echo "Docker image exists - skipping download."
else
    echo "Docker image does not exist - downloading ${IMAGE_NAME}"
    singularity pull /mnt/scratch/${USER}/singularity/cache/meren_anvio.sif docker://${IMAGE_NAME} # Install the image (image is docker and needs docker://)
fi

# ~~~~~~~~~~ CONTAINER AND ANVIO ~~~~~~~~~~

export BINDS="${BINDS},${WORKDIR}:${CONTWORKDIR}"                       # Binding working directory to the shorter path within the container

cat > anvio_init_${SLURM_JOB_ID}.sh << EOF                              # Generate the ANVIO initalising script to be executed

# ~~~~~ INITIATE ANVIO ENV ~~~~~

source /opt/conda/bin/activate anvioenv                                 # Activate the ANVIO environment

# ~~~~~ CONTAINER VARIABLES ~~~~~

CONTWORKDIR="/mnt/container"

# ~~~~~ FIX FASTA FILE DEFLINES ~~~~~

ANVIOGENOMES=\${CONTWORKDIR}/output/anvio/genomes                       # Identify directory where genomes are stored
ANVIODB=\${CONTWORKDIR}/output/anvio/databases                          # Define a directory to store the contig.db file. 

# Echo our variables
echo \${BINDS}
echo \${CONTWORKDIR}
echo \${ANVIOGENOMES}
echo \${ANVIODB}


for FILE in \${ANVIOGENOMES}/*.fasta                                    # Complete the following for all genomes found in ANVIOGENOMES
do
    echo \${FILE}
    NAME=\$(basename "\${FILE}" .fasta)                                 # Extract the sample ID (basename) for prefixing files
    echo \${NAME}

    # Simplify FASTA deflines
    anvi-script-reformat-fasta \${FILE} \                               # Process of simplifying FASTA deflines (definition lines)
                              -o \${ANVIOGENOMES}/\${NAME}_fixed.fa \   # Define and output directory
                              -l 0 --simplify-names                     # Define a limit to trim contrigs below a length and to simplify names. 

    # Generate contig database
    anvi-gen-contigs-database -f \${ANVIOGENOMES}/\${NAME}_fixed.fa \   # Define an input simplified FASTA file 
		              -o \${ANVIODB}/contigs_\${NAME}.db \      # Define an output for the contigs.db files
                              -n "\${NAME}"                             # Include a name for the sample (useful later)

    # Annotation of contigs.db
    anvi-run-hmms -c \${ANVIODB}/contigs_\${NAME}.db \                  # Contig.db directory
                  --num-threads \${SLURM_CPUS_PER_TASK}                 # Number of threads  (using 1 is super slow)

    anvi-run-ncbi-cogs -c \${ANVIODB}/contigs_\${NAME}.db \             # Contig.db directory
                       --num-threads \${SLURM_CPUS_PER_TASK} \          # Number of threads  (using 1 is super slow)
                       --cog-data-dir \${CONTWORKDIR}/.COG              # Point towards the .COG file
done

# ~~~~~ GENERATE EXTERNAL GENOME FILE ~~~~~

# ANVIO required a .tsv file as an input of external genomes - they define as being anything already generated in a FASTA.

DB_DIR="\${CONTWORKDIR}/output/anvio/databases/"                          # Point towards the ANVIO database file (we generated)
OUTPUT_FILE="\${CONTWORKDIR}/output/anvio/databases/external-genomes.txt" # Point to where the external-genomes.tsv should be saved. 

# Write the header
echo -e "name\tcontigs_db_path" > "\$OUTPUT_FILE"                         # Add specific headers to the external-genomes.tsv file

# Loop through all contigs_*.db files in the directory
for file in \$DB_DIR/contigs_*.db; do                                     # Find all contig.dbs in our desired path
    # Extract the filename without path
    filename=\$(basename \$file)                                          # Extract the base name

    # Extract "contigs_001" part (removes .db)
    name=\${filename%.db}                                                 # Extract the sample ID from the basename (remove .db)

    # Write to file
    echo -e "\$name\t\$file" >> "\$OUTPUT_FILE"                           # Add the file name and file path to the external-genomes.tsv file
done

cat \${OUTPUT_FILE}

# ~~~~~ PANGENOME GENERATION ~~~~~

# Generate a combined pangenome contigs database (PANGENOME.db)
anvi-gen-genomes-storage -e \${CONTWORKDIR}/output/anvio/databases/external-genomes.txt \   # Define the path to our external-genomes.tsv file 
                         -o \${CONTWORKDIR}/output/anvio/databases/PANGENOMES.db            # Define the output path and file name

# Generate the Pangenome Analysis 
anvi-pan-genome -g \${CONTWORKDIR}/output/anvio/databases/PANGENOMES.db \                   # Path to PANGENOME.db (we generated)
                -n PANGENOME_ANALYSIS \                                                     # Name out Project
                -o \${CONTWORKDIR}/output/anvio/databases/PANGENOME_ANALYSIS \              # Path to our output directory
                --num-threads \${SLURM_CPUS_PER_TASK}                                       # Number of CPUs (1 is very slow)

# Output Comments to Specify the interactive visualisation is live and steps on how to visualise. 
echo "Visualisation is live..." 

echo "Run: ssh -NL ${PORT}:gomphus1:${PORT} ${USER}@gomphus.bios.cf.ac.uk on the local terminal"

echo "Launch http://localhost:${PORT} in the browser."

echo "This interactive visualisation will remain active for ${SLURM_TIME}."

echo "REMINDER: Once finished, cancel the job (although a maximum time has been defined)."

anvi-display-pan -g \${CONTWORKDIR}/output/anvio/databases/PANGENOMES.db \                                # Input pangenome contig database
                 -p \${CONTWORKDIR}/output/anvio/databases/PANGENOME_ANALYSIS/PANGENOME_ANALYSIS-PAN.db \ # Input pangenome analysis database
                 --port-number ${PORT} --server-only                                                      # Requirements for HPC hosting

EOF

# ~~~~~~~~~ INITIATING CONTAINER ~~~~~~~~~

singularity exec --contain --bind ${BINDS} \                                  # Containerise and bind working directory. 
                 --pwd ${CONTWORKDIR} \                                       # Start the container in the working directory. 
                 /mnt/scratch/${USER}/singularity/cache/meren_anvio.sif \     # Path to ANVIO image
                 bash anvio_init_${SLURM_JOB_ID}.sh                           # Command to execute


