#!/bin/bash
#SBATCH --partition=defq       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=16     #
#SBATCH --mem-per-cpu=1000     # in megabytes, unless unit explicitly stated
#SBATCH --error=%J-ABRICATE-MEGARES.err         # redirect stderr to this file
#SBATCH --output=%J-ABRICATE-MEGARES.out        # redirect stdout to this file
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
date=`date "+%d_%m_%Y"`

module load abricate/

WORKDIR=$(pwd)
GENOMES=${WORKDIR}/output/genomes/FinalGenomes

mkdir ${WORKDIR}/output/amr_megares
amrdir=${WORKDIR}/output/amr_megares


for f in ${GENOMES}/*.fasta #Listing all files in the ra$
do
#R1=$(basename $f | cut -f1 -d.) #divide by the '.' and take t$

base=$(basename "${f}" .fasta)

#base=$(echo $R1 | sed 's/_R1//') #Removes the '_R1_ e..g viru$
echo ${base}

abricate --db cardiffamr --datadir /mnt/scratch/c2006576/bacterial_workflow/DB --threads ${SLURM_CPUS_PER_TASK} ${GENOMES}/${base}.fasta > ${amrdir}/${base}_megares.tab

done

abricate --summary ${amrdir}/*_megares.tab > ${amrdir}/megares_summary_${date}.tab

sed -E 's#.*/(.*)_megares\.tab#\1#' ${amrdir}/megares_summary_${date}.tab > ${amrdir}/AMR_modified_file_${date}.tab

#rm -- ${amrdir}/'*-megares.tab'
module purge
