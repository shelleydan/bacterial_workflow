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

# ~~~~~~~~~~ DEFINING VARIABLES ~~~~~~~~~~
 
WORKDIR=$(pwd)                                 # Setting Working Directory 
CONTWORKDIR="/mnt/container"                   # Generate Container Directory (ANVIO hates long container paths)

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

export BINDS="${BINDS},${WORKDIR}:${CONTWORKDIR},/mnt/scratch/$USER/anvio8/tmp:/tmp"                       # Binding working directory to the shorter path within the container

cat > anvio_init_${SLURM_JOB_ID}.sh << EOF                              # Generate the ANVIO initalising script to be executed

# ~~~~~ INITIATE ANVIO ENV ~~~~~

source /opt/conda/bin/activate anvioenv                                 # Activate the ANVIO environment

# ~~~~~ CONTAINER VARIABLES ~~~~~

CONTWORKDIR="/mnt/container"

# ~~~~~ FIX FASTA FILE DEFLINES ~~~~~

export TMPDIR=/tmp

ANVIOGENOMES=\${CONTWORKDIR}/output/genomes/FinalGenomes                       # Identify directory where genomes are stored
ANVIODB=\${CONTWORKDIR}/output/anvio/databases                          # Define a directory to store the contig.db file. 

# PyANI for Pangenomes
anvi-compute-genome-similarity --external-genomes \${CONTWORKDIR}/output/anvio/databases/external-genomes.txt \
                               --program fastANI \
                               --output-dir \${CONTWORKDIR}/output/anvio/ANI \
                               --num-threads \${SLURM_CPUS_PER_TASK} \
                               --pan-db \${CONTWORKDIR}/output/anvio/databases/PANGENOME_ANALYSIS/PANGENOME_ANALYSIS-PAN.db 

echo "Analysis and environment preperation complete. Run 007b_ANVIO_VISUALISATION.sbatch to view your genomes."

EOF

# ~~~~~~~~~ INITIATING CONTAINER ~~~~~~~~~

singularity exec --contain --bind ${BINDS} --pwd ${CONTWORKDIR} /mnt/scratch/${USER}/singularity/cache/meren_anvio.sif bash anvio_init_${SLURM_JOB_ID}.sh 

# --contain --bind =  Containerise and bind working directory.
# --pwd = Start the container in the working directory.


