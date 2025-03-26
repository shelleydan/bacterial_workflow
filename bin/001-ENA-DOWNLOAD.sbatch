#!/usr/bin/env bash

# ~~~~~~~~~~ User Variables ~~~~~~~~~~

# C.acnes is 1747
# B.cenocepacia is 95486

TAXAID="28131" 
ASSENSIONCSV="accession.csv"

# ~~~~~~~~~~ Variables ~~~~~~~~~~

workdir=$(pwd)                                                              # Assign Working directory
rawdir=${workdir}/input/rawdata                                             # Assign Rawdata directory
genomedir=${workdir}/output/genomes                                         # Assign Genome Assembly directory
FILE=${workdir}/.NCBI-Genome-Download                                       # Assign FastANI Direcotyr

## Making Output Directory
mkdir ${workdir}/output/NCBI-Genomes                                        # Making a FastANI Output
NCBIdir=${workdir}/output/NCBI-Genomes                                      # Assign the FastANI Dir variable.

# ~~~~~~~~~~ FastANI Download ~~~~~~~~~~

if [ -d "${FILE}" ]; then
   echo "File ${FILE} exists."                                              # If the file exists, no need to Download.
   echo "If you have not previously installed NCBI Genome Download Tools..."
   echo "Remove your .NCBI-Genome-Download directory and try again..."      # Ensuring FastANI is installed correcltly

else
   echo "File ${FILE} does not exist."
   echo "Creating Directory: ${FILE}"
   mkdir ${FILE}
   echo "Installing NCBI Genome Downloader to ${FILE}"
   echo "Downloading Datasets..."
   wget -P ${FILE} https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/datasets
   sleep 5
   chmod 777 ${FILE}/datasets

   echo "Downloading Dataformats..."
   wget -P ${FILE} https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/dataformat
   sleep 5
   chmod 777 ${FILE}/dataformat
fi

# ~~~~~~~~~~ Downloading Preview Information ~~~~~~~~~~

# This is a function to preview the number of genomes you are about to download. This script has been designed to take in a .csv.
# This method forces the user to review the preview file and provide a .csv with assension IDs to download. 

if [ -f ${workdir}/${ASSENSIONCSV} ]; then
	echo "${ASSENSIONCSV} exists. Therefore, no need to preview."

else
	cd ${FILE}
	./datasets summary genome taxon "${TAXAID}" --as-json-lines > ${TAXAID}-summary.json     # Stored summary in .NCBI-Genome-Download as this is not human-readable. 
	./dataformat tsv genome --inputfile ${TAXAID}-summary.json > ${workdir}/${TAXAID}-summary.tsv
	sleep 2
	cd ${workdir}
	echo "Exit: Please preview ${TAXAID}-summary.tsv and generate an accession.csv (with accession IDs) to download genomes!"
	exit
fi

# ~~~~~~~~~~ Genome Downloading from Assension ~~~~~~~~~~

cd ${FILE}

for ID in $(cat ${workdir}/${ASSENSIONCSV}); do
	rm README.md
	rm md5sum.txt
	rm ncbi_dataset -rf
	echo "Processing Assension ID: ${ID}"
	./datasets download genome accession ${ID} --filename ${ID}-NCBI-dataset.zip --mag exclude --include genome
	sleep 2
	unzip ${ID}-NCBI-dataset.zip
	sleep 2 
	mv ncbi_dataset/data/${ID}/* ${NCBIdir}/${ID}.fasta
	sleep 2
	rm ${ID}-NCBI-dataset.zip
done

#rm ncbi_dataset -rf

cd ${workdir}



