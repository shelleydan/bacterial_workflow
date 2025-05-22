#!/bin/bash
#SBATCH --partition=defq                       # the requested queue
#SBATCH --job-name=MLST                        # name of job
#SBATCH --nodes=1                              # number of nodes to use
#SBATCH --tasks-per-node=1                     #
#SBATCH --cpus-per-task=8                      #
#SBATCH --mem=8G                               # in megabytes, unless unit explicitly stated
#SBATCH --error=mlst-%J.err                   # redirect stderr to this file
#SBATCH --output=mlst-%J.out                  # redirect stdout to this file
#SBATCH --time=05:00:00                        # Assign a max time for the job to run.
##SBATCH --mail-user=<username>@cardiff.ac.uk  # email address used for event notification
##SBATCH --mail-type=all                       # email on job start, failure and end

# ~~~~~~~~~~ DEFINING VARIABLES ~~~~~~~~~~

WORKDIR=$(pwd)
CONTWORKDIR="/mnt/container"

# ~~~~~~~~~~ NEW DIRECTORY ~~~~~~~~~~

mkdir ${WORKDIR}/output/mlst

# ~~~~~~~~~~ IMAGE DOWNLOAD ~~~~~~~~~~

module load apptainer/1.3.4

export SINGULARITY_CACHEDIR=/mnt/scratch/${USER}/singularity/cache/
export APPTAINER_CACHEDIR=/mnt/scratch/${USER}/singularity/cache/
export TMPDIR=/mnt/scratch/${USER}/singularity/cache/

IMAGE_NAME=staphb/mlst
SINGULARITY_IMAGE_NAME=mlst
SINGIMGDIR=/mnt/scratch/${USER}/singularity/cache

if [ -f /mnt/scratch/${USER}/singularity/cache/staphb_mlst.sif ]; then
    echo "Docker image exists - skipping download."
else
    echo "Docker image does not exist - downloading ${IMAGE_NAME}"
    singularity pull /mnt/scratch/${USER}/singularity/cache/staphb_mlst.sif docker://${IMAGE_NAME}
fi

# ~~~~~~~~~~ CONTAINER AND LAUNCH ~~~~~~~~~~

export BINDS="${BINDS},${WORKDIR}:${CONTWORKDIR}"

cat > mlst_init_${SLURM_JOB_ID}.sh << EOF

# ~~~~~ VARIABLES ~~~~~

CONTWORKDIR="/mnt/container"
GENOMES=\${CONTWORKDIR}/output/genomes/compiled-genomes

# Running MLST twice, with and without a legacy option:

mlst \${GENOMES}/*.fasta > \${CONTWORKDIR}/output/mlst/mlst_${SLURM_JOB_ID}.tsv

mlst --legacy --scheme pacnes_3 \${GENOMES}/*.fasta > \${CONTWORKDIR}/output/mlst/mlst_legacy_${SLURM_JOB_ID}.tsv

EOF

# ~~~~~~~~~~ CONTAINER EXECUTE ~~~~~~~~~~

singularity exec --contain --bind ${BINDS} --pwd ${CONTWORKDIR} /mnt/scratch/${USER}/singularity/cache/staphb_mlst.sif bash mlst_init_${SLURM_JOB_ID}.sh
