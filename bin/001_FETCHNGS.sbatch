#!/bin/bash

#SBATCH --partition=defq       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=8     #
#SBATCH --mem-per-cpu=16000     # in megabytes, unless unit explicitly stated
#SBATCH --error=%J.err         # redirect stderr to this file
#SBATCH --output=%J.out        # redirect stdout to this file
##SBATCH --mail-user= shelleydr@Cardiff.ac.uk  # email address used for event notification
##SBATCH --mail-type=end                                   # email on job end
##SBATCH --mail-type=fail                                  # email on job failure

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID}
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}

## Directories
workdir=$(pwd) #Script can be run from any file as this always updates
rawdir=${workdir}/input/rawdata


module load nextflow/
module load apptainer/

#NXF_APPTAINER_CACHEDIR=/mnt/scratch/c2006576/singularity/cache \
#NXF_SINGULARITY_CACHEDIR=/mnt/scratch/c2006576/singularity/cache \
#NXF_TEMP=/mnt/scratch/c2006576/singularity/temp \

nextflow run nf-core/fetchngs \ 
	-profile apptainer \
	--input SraAccList.csv \
	--outdir input/rawdata \
	--max_cpus 8 \
     	--max_memory 16GB \
	-c configFile \


module purge
