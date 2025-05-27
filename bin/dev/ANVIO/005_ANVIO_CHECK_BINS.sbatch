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

module load apptainer/1.3.4                                             # Loading Apptainer
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

mkdir ${ANVIODIR}/sequence_extracted
ANVIOSEQEXT=${ANVIODIR}/sequence_extracted


anvi-show-collections-and-bins -p \${ANVIODB}/${DBNAME}/${DBNAME}-PAN.db

#anvi-get-sequences-for-gene-clusters -g \${ANVIODB}/${DBNAME}.db \
 #                                    -p \${ANVIODB}/${DBNAME}/${DBNAME}-PAN.db \
  #                                   --list-bins



EOF

# ~~~~~~~~~ INITIATING CONTAINER ~~~~~~~~~

singularity exec --contain --bind ${BINDS} --pwd ${CONTAINERDIR} ${SINGULARITY_IMG} bash anvio_init_${SLURM_JOB_ID}.sh
# --contain --bind =  Containerise and bind working directory.
# --pwd = Start the container in the working directory.

