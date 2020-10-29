# MIPS_Basics

## Getting started

**Single Gene Analysis**  
All GOLab MIP data is stored on Beluga at ~/runs/go_lab/mips/unfiltered. **Do not modify these files!!** Create a directory for your project and gene within your own home directory, and send every output there.  
  
First, make a spreadsheet of the samples you are going to use (by Snumber), their phenotype (1 for control, 2 for case, -9 for unknown), and any sample covariates (usually sex and age). Your spreadsheet should include FID (Snumber), IID (Snumber again), and a column for each covariate. Make sure your covariates are clean (e.g. replace any 0's in age for NA).  
**GO LAB TIP:** In the database there is a column called "Exclude from analysis". When choosing your cohorts, only select those with "keep", "NA", or "blank" in this column. Samples who have been sent for GWAS genotyping have been vetted for duplicates, sex mismatch, and non-European ancestry; if they pass, they receive a "keep" label. Those who haven't gone for genotyping yet have no value (NA or blank), and we keep them for now. *You can download the latest database spreadsheet from the Slack channel #database_updates.*  
  
Once your cohort is ready, make the following files in your project/gene directory:
* *keep.txt*: the FID and IID of the samples you will keep.  
* *pheno.txt*: columns FID, IID, and PHENO (1, 2, -9).  
* *sex.txt*: columns FID, IID, and SEX (1, 2, or 0).  
* *covar.txt*: columns FID, IID, SEX, AGE, ...ANY OTHER COVARS.  
  
Now, select your gene from the MIP data by its coordinates (you can find these on https://genome.ucsc.edu/, choose hg19). Add a 100 bp window on either side, just to make sure you capture everything that the MIPs captured. 

````
# Example coordinates for gene PTRHD1 and RBD cohort 

module load vcftools

# --keep: keeps only your selected samples
# --minDP: chooses minimum depth of coverage for inclusion of variants. 
#           You can choose 15x, 30x, 50x. I like 30x, some people do all 3. 
# --recode + --recode-INFO-all: recodes a new VCF, including all annotations


vcftools --gzvcf ~/runs/go_lab/mips/unfiltered/all_genes.all_samples.up-to-MIP79_annotated.vcf.gz --chr 2 --from-bp 25013036 --to-bp 25016351 \
--keep keep.txt --minDP 30 --recode --recode-INFO-all --out rbd.PTRHD1.30x.up-to-MIP79_annotated
````

Now transform your VCF into plink files: 
````
cd YOUR_DIRECTORY
module load plink 

plink --vcf rbd.PTRHD1.30x.up-to-MIP79_annotated.recode.vcf --pheno pheno.txt \
--update-sex sex.txt --make-bed --out unfiltered_PTRHD1
````

Time for quality control! This script is also downloadable in this repository.  
This filters for:  
* genotype missingness (80% in this script)
* sample-level missingness (80% in this script)
* hardy-weinberg equilibrium 
* differential missingness in cases vs controls 
* any positions with no variants in this cohort

````
#!/bin/bash 

FILENAME=$1
COVAR=$2

mkdir UNFILTERED

awk '{print $1,$4,$3,$4,$5,$6}' ${FILENAME}.bim > rename.bim
mv rename.bim ${FILENAME}.bim

plink --bfile $FILENAME --missing --out miss1 

awk '{if ($5>0.2) print $2}' miss1.lmiss > exclude_geno80.txt

plink --bfile $FILENAME --exclude exclude_geno80.txt --make-bed --out geno80_${FILENAME}

plink --bfile geno80_${FILENAME} --missing --out miss2

awk '{if ($6>0.2) print $1,$2}' miss2.imiss > remove_sam80.txt

plink --bfile geno80_${FILENAME} --remove remove_sam80.txt --make-bed --out sam80_geno80_${FILENAME}

plink --bfile sam80_geno80_${FILENAME} --hardy --out hwe

awk '{if ($9<0.001) print $2}' hwe.hwe > exclude_hardy.txt

plink --bfile sam80_geno80_${FILENAME} --exclude exclude_hardy.txt --make-bed --out hwe_sam80_geno80_${FILENAME}

plink --bfile hwe_sam80_geno80_${FILENAME} --test-missing --out cc

awk '{if ($5<1E-9) print $2}' cc.missing > exclude_cc.txt

plink --bfile hwe_sam80_geno80_${FILENAME} --exclude exclude_cc.txt --make-bed --out cc_hwe_sam80_geno80_${FILENAME}

plink --bfile cc_hwe_sam80_geno80_${FILENAME} --freq --out all

awk '{if ($5==0) print $2}' all.frq > exclude_0frq.txt

plink --bfile cc_hwe_sam80_geno80_${FILENAME} --exclude exclude_0frq.txt --make-bed --out frq_cc_hwe_sam80_geno80_${FILENAME}

mv frq_cc_hwe_sam80_geno80_${FILENAME}.bim FILTERED_${FILENAME}.bim
mv frq_cc_hwe_sam80_geno80_${FILENAME}.fam FILTERED_${FILENAME}.fam
mv frq_cc_hwe_sam80_geno80_${FILENAME}.bed FILTERED_${FILENAME}.bed

rm geno80_${FILENAME}.*
rm sam80_geno80_${FILENAME}.*
rm hwe_sam80_geno80_${FILENAME}.*
rm cc_hwe_sam80_geno80_${FILENAME}.*
````
For a case control analysis, run logistic regression and fisher's exact test:

````
plink --bfile FILTERED_${FILENAME} --logistic --ci .95 --covar $COVAR --covar-name SEX,AGE --out log1
grep 'ADD' log1.assoc.logistic | sort -gk12 > p.log1.assoc.logistic
sed -i '/NA/d' p.log1.assoc.logistic

plink --bfile FILTERED_${FILENAME} --assoc fisher --out freq
````
