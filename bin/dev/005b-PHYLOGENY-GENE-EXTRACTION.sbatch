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

#Making Directories and Definin Variables
workdir=$(pwd)
rawdir=${workdir}/input/rawdata
annotdir=${workdir}/output/annotation
assdir=${workdir}/output/genomes
trimdir=${workdir}/output/trimdata

#New Directories
#Making directories for outputs
mkdir ${workdir}/output/extracted_gene
spike=${workdir}/output/extracted_gene
mkdir ${workdir}/output/bedtools_fast_out
bedoutdir=${workdir}/output/bedtools_fast_out


#Using Bedtools

module load bedtools2/

#Selecting our the base names  of our assembled files

for f in ${rawdir}/*_R1.fastq* #Listing all files in the ra$
do
R1=$(basename $f | cut -f1 -d.) #divide by the '.' and take t$
base=$(echo $R1 | sed 's/_R1//') #Removes the '_R1_ e..g viru$
echo ${base}

#Taking out the Spike and making a gff file
grep "product=16S ribosomal RNA" ${annotdir}/${base}/*.gff > ${spike}/${base}_16S.gff

#Combining the assembly and the gene annotation only
bedtools getfasta \
	-fi ${assdir}/${base}/assembly.fasta \
	-bed ${spike}/${base}_16S.gff \
	-s > ${spike}/${base}_16S.fasta


sed -i "s/>.*/>${base}/g" ${spike}/${base}_16S.fasta

done

module unload bedtools2/
