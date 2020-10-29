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
# --minDP: chooses minimum depth of coverage for inclusion of variants. You can choose 15x, 30x, 50x. I like 30x, some people do all 3. 
# --recode + --recode-INFO-all: recodes a new VCF, including all annotations


vcftools --gzvcf all_genes.all_samples.up-to-MIP79_annotated.vcf.gz --chr 2 --from-bp 25013036 --to-bp 25016351 --minDP 30 --keep keep.txt --recode --recode-INFO-all --out YOUR_DIRECTORY/rbd.PTRHD1.30x.up-to-MIP79_annotated
````
