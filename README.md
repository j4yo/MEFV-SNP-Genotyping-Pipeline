# MEFV-SNP-Genotyping-Pipeline
A basic shell pipeline for data analysis of ONT sequencing data 

The pipeline was used for SNP genotyping of the MEFV gene by amplicon sequencing on a MinION sequencing device. However, after slight modification, it can also be applied for other amplicon sequencing experiments which were performed on a Nanopore sequencing device. 

# Preparation
The pipeline was tested under Ubuntu 18.04.6 LTS.

Installations of the following packages are required:

- Guppy
- pycoQC
- Nanofilt
- minimap2
- bcftools
- bedtools
- ANNOVAR

Nanofilt, minimap2, bcftools and bedtools should by installed in individual conda environments.


# Usage
1. Define path variables in the section "Set variables" of the .sh file.
  - "WD": The working directory in which all generated files are saved.
  - "FAST5": Path to the directory, which contains the FAST5 raw data files produced by a MinION sequencing device.
  - "Ref_Gen_Path": Path to the reference genome file in FASTA file format.
  - "Bed_Path": Path to the BED file containg the genomic positions of the amplicons.
  - "ANNOVAR_Path": Path to the table_annovar.pl file.
  - "ANNOVAR_DB": Path to the ANNOVAR "humandb" directory. 

2. Set number of availabel CPU threads on the system ("NT").

3. Save changes and execute the script from the terminal.
