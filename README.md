# UKBB PRS
A Snakemake pipeline for calculating polygenic risk scores from the PGS-Catalog on large sets of genomic data in plink2 binary format. This pipeline was developed for use with data from the UK-Biobank.
First, risk score variant weights are downloaded from PGS-Catalog, then lifted to the correct reference genome and formated such that plink2 can compute per sample risk scores in the final step.
# Usage
For use within the lab you can activate the conda environment *prs*:
```bash
conda activate prs
```
Given the polygenic score ID *PGS001954* for HDL-Cholesterol:
```bash
snakemake /some_dir/PGS001954.sscore
```
computes the polygenic risk scores for *PGS001954* on the plink2 genomic data specified in the config.yaml.