#!/bin/bash

#SBATCH --partition=defq       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=1      #
#SBATCH --mem-per-cpu=1000     # in megabytes, unless unit explicitly stated
#SBATCH --error=ANI-%J.err         # redirect stderr to this file
#SBATCH --output=ANI-%J.out        # redirect stdout to this file
#SBATCH --mail-user=shelleydr@Cardiff.ac.uk  # email address used for event notification
#SBATCH --mail-type=end                                   # email on job end
#SBATCH --mail-type=fail                                  # email on job failure

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

# ~~~~~~~~~~ Variables ~~~~~~~~~~

workdir=$(pwd)                                                              # Assign Working directory
rawdir=${workdir}/input/rawdata                                             # Assign Rawdata directory
genomedir=${workdir}/output/genomes                                         # Assign Genome Assembly directory
FILE=${workdir}/.FastANI                                                    # Assign FastANI Direcotyr

## Making Output Directory
mkdir ${workdir}/output/FastANI                                             # Making a FastANI Output
mkdir ${workdir}/output/FastANI/all-samples                                 # Making a FastANI output for individual results
fastanidir=${workdir}/output/FastANI                                        # Assign the FastANI Dir variable. 

# ~~~~~~~~~~ FastANI Download ~~~~~~~~~~

if [ -d "${FILE}" ]; then
   echo "File ${FILE} exists."                                              # If the file exists, no need to Download.
   echo "If you have not previously installed FastANI..."
   echo "Remove your FastANI directory (rm -rf FastANI) and try again..."   # Ensuring FastANI is installed correcltly

else
   echo "File ${FILE} does not exist."
   echo "Creating Directory: ${FILE}"
   mkdir ${FILE}
   echo "Installing FastANI to ${FILE}"
   wget -P ${FILE}  https://github.com/ParBLiSS/FastANI/archive/master.zip  # Download FastANI from Repository
   sleep 5
   unzip ${FILE}/* -d ${FILE}                                               # Only one file is downloaded to this directory. 
   sleep 5
   rm ${FILE}/master.zip                                                    # Remove the original FastANI zip download.


   cd ${FILE}/FastANI-master                                                # Change Directory to the extracted tool. 
   sleep 1
   autoconf                                                                 # Generate configuration scripts for FastANI
   sleep 5 
   ./configure --with-gsl=/usr/                                             # Runs the configuration scripts.
   sleep 5
   make                                                                     # Compile FastANI into an excecutable code. 
   cd ${workdir}                                                            # Return to Working Directory
fi

# ~~~~~~~~~~ Performing FastANI Analysis ~~~~~~~~~~

FASTDIR=${FILE}/FastANI-master

cd ${FASTDIR}

for f in ${rawdir}/*_R1.fastq* #Listing all files in the ra$
do
R1=$(basename $f | cut -f1 -d.) #divide by the '.' and take t$
base=$(echo $R1 | sed 's/_R1//') #Removes the '_R1_ e..g viru$

./fastANI \
	-q ${genomedir}/${base}/assembly.fasta \
	-r ${workdir}/input/reference/*fasta \
	-o ${fastanidir}/all-samples/${base}.tsv
done

# ~~~~~~~~~~ Concatonate Output Files ~~~~~~~~~~

touch ${fastanidir}/compiled-FastANI.tsv

printf "QUERY-GENOME\tREF-GENOME\tANI-PERCENTAGE\tMATCHING-FRAGS\tTOTAL-FRAGS\n" > ${fastanidir}/compiled-FastANI.tsv

cat ${fastanidir}/all-samples/*.tsv >> ${fastanidir}/compiled-FastANI.tsv

