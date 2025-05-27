#!/bin/bash

#SBATCH --partition=defq       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=8      #
#SBATCH --mem-per-cpu=16000     # in megabytes, unless unit explicitly stated
#SBATCH --error=%J-PROKKA.err         # redirect stderr to this file
#SBATCH --output=%J-PROKKA.out        # redirect stdout to this file
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
trimdir=${workdir}/output/trimdata
assdir=${workdir}/output/genomes
rawdir=${workdir}/input/rawdata

#New Output Directories
mkdir ${workdir}/output/annotation
annotdir=${workdir}/output/annotation

###Prokka

module load prokka/

for f in ${rawdir}/*_R1.fastq* #Listing all files in the ra$
do
R1=$(basename $f | cut -f1 -d.) #divide by the '.' and take t$
base=$(echo $R1 | sed 's/_R1//') #Removes the '_R1_ e..g viru$
echo ${base}

prokka --Kingdom Bacteria ${assdir}/${base}/assembly.fasta \
	--outdir ${annotdir}/${base}  \
	--prefix ${base}

done

module unload prokka/
