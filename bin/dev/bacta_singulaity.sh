#!/bin/bash
#SBATCH --partition=epyc       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=8      #   
#SBATCH --mem-per-cpu=2000     # in megabytes, unless unit explicitly stated
#SBATCH --error=%J.err         # redirect stderr to this file
#SBATCH --output=%J.out        # redirect stdout to this file
##SBATCH --mail-user=[insert email address]@Cardiff.ac.uk  # email address used for event notification
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

# Write jobscript to output file (good for reproducability)
cat $0

# load singularity module
module load apptainer/1.3.4

IMAGE_NAME=oschwengers/bakta:v1.10.4
SINGULARITY_IMAGE_NAME=bakta:v1.10.4

if [ -f /mnt/scratch45/nodelete/${USER}/singularities/${SINGULARITY_IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    singularity pull /mnt/scratch45/nodelete/${USER}/singularities/${SINGULARITY_IMAGE_NAME} docker://$IMAGE_NAME
fi

# set singularity image
SINGIMAGEDIR=/mnt/scratch45/nodelete/${USER}/singularities
SINGIMAGENAME=${SINGULARITY_IMAGE_NAME}

# Set working directory
WORKINGFOLDER=$(pwd)
# Set folder which contains folders with assemblies
ASSEMBLYDIR=${WORKINGFOLDER}/genomes/
ANNOTDIR=${WORKINGFOLDER}/bakta_annot

# set folders to bind into container
export BINDS="${BINDS},${WORKINGFOLDER}:${WORKINGFOLDER}"

############# SOURCE COMMANDS ##################################
cat > bakta_source_commands_${SLURM_JOB_ID}.sh <<EOF

# bakta_db download --output ${WORKINGFOLDER}/db --type full

for f in ${ASSEMBLYDIR}/*/*.fna
do
base=\$(basename \$f | cut -f1 -d.)

bakta --db ${WORKINGFOLDER}/db/db --output ${ANNOTDIR}/\${base}/ --prefix \${base} --threads ${SLURM_CPUS_PER_TASK} ${ASSEMBLYDIR}/\${base}.1/*.fna

done


echo CPU=\${SLURM_CPUS_PER_TASK}

EOF
################ END OF SOURCE COMMANDS ######################

singularity exec --contain --bind ${BINDS} --pwd ${WORKINGFOLDER} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash bakta_source_commands_${SLURM_JOB_ID}.sh
