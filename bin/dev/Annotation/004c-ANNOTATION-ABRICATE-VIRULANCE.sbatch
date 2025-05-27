#!/bin/bash
#SBATCH --partition=defq                        # the requested queue
#SBATCH --nodes=1                               # number of nodes to use
#SBATCH --tasks-per-node=1                      #
#SBATCH --cpus-per-task=16                      #
#SBATCH --mem-per-cpu=10000                     # in megabytes, unless unit explicitly stated
#SBATCH --error=%J-ABRICATE-VIR-FACTORS.err     # redirect stderr to this file
#SBATCH --output=%J-ABRICATE-VIR-FACTORS.out    # redirect stdout to this file
#SBATCH --mail-user=shelleydr@Cardiff.ac.uk     # email address used for event notification
#SBATCH --mail-type=end                         # email on job end
#SBATCH --mail-type=fail                        # email on job failure

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

# Write jobscript to output file (good for reproducibility)
cat $0

module load abricate/

workdir=$(pwd)

mkdir ${workdir}/output/virulence_factors
vfdir=${workdir}/output/virulence_factors

for f in ${rawdir}/*_R1.fastq* #Listing all files in the ra$
do
R1=$(basename $f | cut -f1 -d.) #divide by the '.' and take t$
base=$(echo $R1 | sed 's/_R1//') #Removes the '_R1_ e..g viru$
echo ${base}

abricate --db vfdb --threads ${SLURM_CPUS_PER_TASK} ${workdir}/output/genomes/${base}/*.fasta > ${vfdir}/${base}.tab

done



abricate --summary ${vfdir}/*.tab > ${vfdir}/megares_summary.tab

rm -- ${vfdir}/'*-megares.tab'

module purge
