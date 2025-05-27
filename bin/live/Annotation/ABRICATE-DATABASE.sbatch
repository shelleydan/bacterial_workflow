#!/bin/bash

# ~~~~~~~~~~ SLURM ~~~~~~~~~~ #

#SBATCH --partition=defq       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=4     #
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

# ~~~~~~~~~~ VARIABLES & CONFIG ~~~~~~~~~~ #

#source workflow.config

WORKDIR=$(pwd)
DB_FOLDER=/mnt/scratch/c2006576/bacterial_workflow/DB

# ~~~~~~~~~~ ABRICATE DATABASE ~~~~~~~~~~ #

module load abricate/ 
module load cdhit/

# ~~~~~ Installing Databases ~~~~~ #

AMR_DB_LIST=("argannot" "bacmet2" "card" "ncbi" "megares" "resfinder")
AMR_STRING=$(IFS=, ; echo "${AMR_DB_LIST[*]}")

for DB in ${AMR_DB_LIST[@]}; do
    abricate-get_db --db ${DB} --dbdir ${DB_FOLDER} --force
done

# ~~~~~ MANUAL DATABASE DOWNLOADS ~~~~~ #

# MEGARES
wget -P ${DB_FOLDER}/megares https://www.meglab.org/downloads/megares_v3.00.zip
unzip ${DB_FOLDER}/megares/megares_v3.00.zip -d ${DB_FOLDER}/megares
cp ${DB_FOLDER}/megares/megares_v3.00/megares_database_v3.00.fasta ${DB_FOLDER}/megares/sequences

# ARGANNOT
wget -P ${DB_FOLDER}/argannot https://www.mediterranee-infection.com/wp-content/uploads/2019/03/arg-annot-nt-v1-july2015.txt
cp ${DB_FOLDER}/argannot/arg-annot-nt-v1-july2015.txt ${DB_FOLDER}/argannot/sequences

# RESFINDER
wget -P ${DB_FOLDER}/resfinder https://bitbucket.org/genomicepidemiology/resfinder_db/get/852f367c4900530e797a48f3eedf010e6455ae16.zip
unzip ${DB_FOLDER}/resfinder/852f367c4900530e797a48f3eedf010e6455ae16.zip -d ${DB_FOLDER}/resfinder/database_all
cp ${DB_FOLDER}/resfinder/database_all/*/all.fsa ${DB_FOLDER}/resfinder/sequences

# NCBI
wget -P ${DB_FOLDER}/ncbi wget https://ftp.ncbi.nlm.nih.gov/pathogen/Antimicrobial_resistance/AMRFinderPlus/database/latest/AMR_CDS.fa
mv ${DB_FOLDER}/ncbi/AMR_CDS.fa ${DB_FOLDER}/ncbi/sequences

mkdir ${DB_FOLDER}/cardiffamr

eval "cat ${DB_FOLDER}/{${AMR_STRING}}/sequences > ${DB_FOLDER}/cardiffamr/cardiffamr.fa"

cd-hit-est -i ${DB_FOLDER}/cardiffamr/cardiffamr.fa -o ${DB_FOLDER}/cardiffamr/cdhit -c 0.95 -g 1 -T 4 -d 100

cp -fv ${DB_FOLDER}/cardiffamr/cdhit ${DB_FOLDER}/cardiffamr/sequences

makeblastdb -in ${DB_FOLDER}/cardiffamr/sequences -title cardiffamr -taxid 2 -dbtype nucl |& tee ${DB_FOLDER}/cardiffamr/makeblastdb.log

abricate --datadir ${DB_FOLDER}

module purge

