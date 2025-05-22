#!/bin/bash

#SBATCH --partition=defq       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=16      #
#SBATCH --mem-per-cpu=20000     # in megabytes, unless unit explicitly stated
#SBATCH --error=ASS-%J.err         # redirect stderr to this file
#SBATCH --output=ASS-%J.out        # redirect stdout to this file
##SBATCH --mail-user= shelleydr@Cardiff.ac.uk  # email address used for event notification
##SBATCH --mail-type=end                                   # email on job end
##SBATCH --mail-type=fail                                  # email on job failure

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo `date "+%d_%m_%Y"`
echo \$SLURM_JOB_ID=${SLURM_JOB_ID}
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}

#Variables - end data to be used is in trimqc
#Defining variables
workdir=$(pwd) #Script can be run from any file as this always updates
rawdir=${workdir}/input/rawdata
trimdir=${workdir}/output/trimdata

# New Output Directory
mkdir ${workdir}/output/genomes
assdir=${workdir}/output/genomes
mkdir ${assdir}/compiled-genomes
compiledir=${assdir}/compiled-genomes

#Running Unicyler with the loop for basename.

module load py-unicycler/
module load py-quast/

for f in ${rawdir}/*_R1.fastq* #Listing all files in the ra$
do
R1=$(basename $f | cut -f1 -d.) #divide by the '.' and take t$
base=$(echo $R1 | sed 's/_R1//') #Removes the '_R1_ e..g viru$

unicycler -1 ${trimdir}/${base}*_R1.fastq.gz \
	  -2 ${trimdir}/${base}*_R2.fastq.gz \
	  -t 8 \
	  -o ${assdir}/${base}

mv ${assdir}/${base}/assembly.fasta ${compiledir}/${base}-assembly.fasta

done

quast.py \
        -t 4 \
        -o ${assdir} \
        ${assdir}/*/*fasta

module purge




