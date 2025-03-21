#!/bin/bash

#SBATCH --partition=defq       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=1      #
#SBATCH --mem-per-cpu=1000     # in megabytes, unless unit explicitly stated
#SBATCH --error=QC-%J.err         # redirect stderr to this file
#SBATCH --output=QC-%J.out        # redirect stdout to this file
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

#Defining variables
workdir=$(pwd) #Script can be run from any file as this always updates
rawdir=${workdir}/input/rawdata
mkdir ${workdir}/output/rawqc
rawqcdir=${workdir}/output/rawqc
mkdir ${workdir}/output/trimdata
trimdir=${workdir}/output/trimdata
mkdir ${workdir}/output/trimqc
trimqcdir=${workdir}/output/trimqc
mkdir ${workdir}/output/multiqc
multiqcdir=${workdir}/output/multiqc


#Creating a list of file names

#FastQC
module load fastqc/

for f in ${rawdir}/*_R1.fastq* #Listing all files in the rawdata directory
do
R1=$(basename $f | cut -f1 -d.) #divide by the '.' and take the first coloum 
base=$(echo $R1 | sed 's/_R1//') #Removes the '_R1_ e..g virus_1, virus_2 etc 

fastqc -q -t 2 ${rawdir}/${base}_R1.fastq* \
	 ${rawdir}/${base}_R2.fastq* \
	 -o ${rawqcdir}
done
#Unloading the QC module
module unload fastqc/

#End of FastQC
################
#Start of FastP
module load fastp/

for f in ${rawdir}/*_R1.fastq*
do
R1=$(basename $f | cut -f1 -d.)
base=$(echo $R1 | sed 's/_R1//')

fastp -q 20 -u 10 --cut_right\
	-i ${rawdir}/${base}_R1.fastq*\
	-I ${rawdir}/${base}_R2.fastq*\
	-o ${trimdir}/${base}_trim_R1.fastq.gz\
	-O ${trimdir}/${base}_trim_R2.fastq.gz\
	-h ${trimdir}/fastp_report.html \
	-j ${trimdir}/fastp_report.json
done

module unload fastp/
#################
#Rerunning the FastQC

module load fastqc/

for f in ${rawdir}/*_R1.fastq*
do
R1=$(basename $f | cut -f1 -d.)
base=$(echo $R1 | sed 's/_R1//')

fastqc -q -t 2 ${trimdir}/${base}_trim_R1.fastq.gz ${trimdir}/${base}_trim_R2.fastq.gz -o ${trimqcdir}

done

module unload fastqc/

#Using MultiQC

module load py-multiqc/
multiqc ${workdir} -o ${multiqcdir}

module purge
