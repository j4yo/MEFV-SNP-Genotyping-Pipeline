#!/bin/bash

###################### Required packages #################################

#guppy
#pycoQC
#Nanofilt (Conda)
#minimap2 (Conda)
#bcftools (Conda)
#bedtools (Conda)
#ANNOVAR

##########################################################################

###################### Set variables #####################################
#Working directory and FAST5 Input have to be defined
#Working directory
WD='/path/to/working_directory'

#FAST5 file directory
FAST5='/path/to/fast5_directory'

#Reference genome path
Ref_Gen_Path='/path/to/reference_genome.fa'

#Path to Amplicon Filter BED file
Bed_Path='/path/to/amplicon_filter.bed'

#Path to ANNOVAR executable (table_annovar.pl) and ANNOVAR DB
ANNOVAR_Path='/path/to/table_annovar.pl'
ANNOVAR_DB='/path/to/annovar/humandb/'

#Available Threads
NT='12'

#########################################################################

###################### Create directories ###############################
# Creates required directories within the working directory
cd $WD
mkdir ANNOVAR_Annotation
mkdir variant_calling
mkdir variant_filtering
mkdir alignment
mkdir filtered
mkdir demultiplexed
mkdir rebasecall

########################################################################

##################### Basecalling with Guppy ###########################
# Use Guppy in super high accuracy mode with GPU basecalling
# Based on the used GPU, it might be necessary to modify the Guppy default parameters

guppy_basecaller -c dna_r9.4.1_450bps_sup.cfg -i $FAST5 -s ./rebasecall -x auto -r


########################################################################

###################### Demultiplexing #################################
#Demuliplexing with Guppy. Arrangement files for barcode 1-24 in the barcoding kits are used.
#Barcodes are trimmed after demultiplexing

cd $WD
guppy_barcoder --require_barcodes_both_ends -i ./rebasecall/pass -s ./demultiplexed --arrangements_files "barcode_arrs_nb12.cfg barcode_arrs_nb24.cfg" --trim_barcodes -x auto

######################################################################

##################### QC #############################################
#Short QC Report is generated

cd $WD
pycoQC -f ./rebasecall/sequencing_summary*.txt -b ./demultiplexed/barcoding_summary.txt -o pycoQC_output.html

################## Filtering ######################################### 
# Combine individual read files per barcode using cat
# Filter by amplicon length and quality score to exclude chimeric reads and low quality reads
# Length filtering: 250 to 1200 bp
# Quality Filter: minimum Q Score 15

eval "$(conda shell.bash hook)"
conda activate Nanofilt

cd $WD
cd ./demultiplexed
for d in b*/ ; do
	n=`echo "$d" | sed 's/.$//'`
	cat "$d"/*.fastq | NanoFilt -l 250 --maxlength 1200 -q 15 > ../filtered/"$n"_filtered.fastq
done

conda deactivate

######################################################################

################# Alignment ##########################################
# Align reads to the reference sequence
# Directly sort and index the Bam file

eval "$(conda shell.bash hook)"
conda activate minimap2

cd $WD
cd ./alignment

for FILE in ../filtered/*.fastq; do
	filename=$(basename -- "$FILE" | sed 's/_filtered//' | sed 's/.fastq//')
	filelink=$(readlink -f "$FILE")

	minimap2 -t $NT -ax map-ont "$Ref_Gen_Path" "$filelink" | samtools sort -o "$filename".bam
	samtools index "$filename".bam

done

conda deactivate

######################################################################

############### Variant Calling ######################################
# BCFtools is used for variant calling
 
eval "$(conda shell.bash hook)"
conda activate bcftools

cd $WD
cd ./variant_calling

for FILE in ../alignment/*.bam; do 
	filename=$(basename -- "$FILE" | sed 's/.bam//')
	filelink=$(readlink -f "$FILE")
	
	bcftools mpileup -f "$Ref_Gen_Path" "$filelink" | bcftools call -mv -Ov --skip-variants indels -o "$filename".vcf

done


conda deactivate

######################################################################

############## Filter VCF files for target regions ############
# Amplicon regions are filtered based on the genomic regions in a bed file

eval "$(conda shell.bash hook)"
conda activate bedtools

cd $WD
cd ./variant_filtering

for FILE in ../variant_calling/*.vcf; do 
	filename=$(basename -- "$FILE" | sed 's/.vcf//')
	filelink=$(readlink -f "$FILE")
	
	bedtools intersect -a "$filelink" -b $Bed_Path -header > "$filename"_filtered.vcf

done


conda deactivate

#####################################################################

############## Variant Annotation ####################################
# Variant annotation is done by using ANNOVAR

cd $WD
cd ANNOVAR_Annotation

for FILE in ../variant_filtering/*.vcf; do 
	filename=$(basename -- "$FILE" | sed 's/_filtered.vcf//')
	filelink=$(readlink -f "$FILE")

	$ANNOVAR_Path "$filelink" $ANNOVAR_DB -buildver hg19 -out "$filename"_ANNOVAR_out -remove -protocol refGene,cytoBand,exac03,avsnp147,dbnsfp30a -operation g,r,f,f,f -nastring . -vcfinput

done

######################################################################

############### Shutdown when finished ###############################

#shutdown --p now

######################################################################