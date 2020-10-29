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

# assoc 

plink --bfile FILTERED_${FILENAME} --logistic --ci .95 --covar $COVAR --covar-name SEX,AGE --out log1
grep 'ADD' log1.assoc.logistic | sort -gk12 > p.log1.assoc.logistic
sed -i '/NA/d' p.log1.assoc.logistic

plink --bfile FILTERED_${FILENAME} --assoc fisher --out freq
