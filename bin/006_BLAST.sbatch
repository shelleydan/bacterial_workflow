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
mkdir ${workdir}/output/blast
blastdir=${workdir}/output/blast
spike=${workdir}/output/extracted_gene
rawdir=${workdir}/input/rawdata


touch ${blastdir}/all_blast_annotation.tsv
printf "LABEL\tGBID\tVIRUS\tVARIANT\tSTRAIN\tSOURCE\tDATE\n" > ${blastdir}/all_blast_annotation.tsv

#Loading Blast
module load blast-plus/

#Selecting our the base names  of our assembled files
for f in ${rawdir}/*_R1.fastq.gz #Listing all files in the rawdata directory
do
        R1=$(basename $f | cut -f1 -d.) #divide by the '.' and take t$
        base=$(echo $R1 | sed 's/_R1//') #Removes the '_R1_ e..g viru$

blastn \
	-db /mnt/scratch/c2006576/MMI-bioinformatics-training/.one_I_created_earlier/bin/.BLAST_DB/16S_ribosomal_RNA \
	-query ${spike}/${base}*.fasta \
	-out ${blastdir}/${base}_bln.txt \
	-outfmt "6 qseqid stitle" \
	-num_threads 8 \
	-max_target_seqs 1

done

cat ${blastdir}/*bln.txt >> ${blastdir}/all_blast_annotation.tsv

sed -i 's/|/\t/g' ${blastdir}/all_blast_annotation.tsv
#REMEMBER TO CHANGE THE LABELS
#{ echo -e "LABEL\tGBID\tVIRUS\tVARIANT\tSTRAIN\tSOURCE\tDATE"; cat ${blastdir}/all_blast_annotation.tsv; } >> ${blastdir}/head_all_blast_annotation.tsv

module unload blast-plus/


