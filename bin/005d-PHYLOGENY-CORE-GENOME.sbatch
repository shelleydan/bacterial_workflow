#!/bin/bash
#SBATCH --partition=defq       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=16     #
#SBATCH --mem-per-cpu=1000     # in megabytes, unless unit explicitly stated
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

# Write jobscript to output file (good for reproducibility)
cat $0

module load py-panaroo/

workdir=$(pwd)
annodir=${workdir}/output/annotation

mkdir ${workdir}/output/core_genome
coredir=${workdir}/output/core_genome
mkdir ${coredir}/trees


# Pangenome Creation

panaroo -i ${annodir}/*/*gff -o ${coredir} -t ${SLURM_CPUS_PER_TASK} --clean-mode sensitive -a core --aligner mafft --remove-invalid-genes

module load raxml-ng/

raxml-ng-mpi \
        --all --msa ${coredir}/core_gene_alignment.aln \
        --model GTR \
        --bs-tree 1000 \
        --prefix ${coredir}/trees/pangenome_trees \
        --threads 8

module purge


