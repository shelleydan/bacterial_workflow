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

#Making Directories and Definin Variable
workdir=$(pwd)
mkdir ${workdir}/output/phylogeny
spike=${workdir}/output/extracted_gene

#catonanate all fasta files into one file. 
cat ${spike}/*.fasta > ${spike}/combined_16S.fasta

wait
#Loading MAFFT for sequence Alignment
module load mafft/

mafft ${spike}/combined_16S.fasta > ${spike}/align_16S.fasta

module unload mafft/
wait 
#Loading RAXML for tree generation
module load raxml-ng/

raxml-ng-mpi --all \
	--msa ${spike}/align_16S.fasta \
	--model GTR \
	--bs-tree 100 \
	--prefix ${spike}_bacterial_16S_tree \
	--threads 8

module unload raxml-ng/

mv ${workdir}/output/*_bacterial_16S* ${workdir}/output/phylogeny

#Next: Load figtree in the terminal followed by $figtree, and open the support files
