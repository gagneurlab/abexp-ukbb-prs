configfile: "config.yaml"

#Downloads the PGS-Score from https://www.pgscatalog.org for given Polygenic Score ID
rule download_PGS_catalog:
    threads: 1
    resources:
        mem_mb=500
    output:
        "{path_to_dir}PGS{id, [0-9]+}.txt.gz"
    shell:
        f"wget -O {{output}} 'https://ftp.ebi.ac.uk/pub/databases/spot/pgs/scores/PGS{{wildcards.id}}/ScoringFiles/PGS{{wildcards.id}}.txt.gz'"

#Lifts the PGS-Score into the reference genome specified in the config
rule harmonize_pgs:
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt, threads: (4000 * threads) * attempt
    input:
        "{dir}PGS{id, [0-9]+}.txt.gz"
    output:
        f"{{dir}}PGS{{id, [0-9]+}}_hmPOS_{config['reference_genome']}.txt"
    shell:
        f"python {config['pgs_harmonizer']}Harmonize.py HmPOS PGS{{wildcards.id}} {config['reference_genome']} -loc_files {{wildcards.dir}} -loc_hmoutput {{wildcards.dir}}"

#Removes header rows and sets variant-id column to match with UKBB format 
rule format_pgs_weights:
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt, threads: (4000 * threads) * attempt
    input:
        f"{{dir}}PGS{{id, [0-9]+}}_hmPOS_{config['reference_genome']}.txt"
    output:
        "{dir}PGS{id, [0-9]+}_weights.txt"
    shell:
        r"""
        sed -i '/^[@#]/ d' {input}
        awk -F '\t' 'BEGIN {{OFS=FS}} NR==1{{while((getline var<"columns.txt") > 0) {{for(i=1;i<=NF;i++) if($i==var) {{cols[i]=1;break}}}} close("columns.txt")}} {{for(i=1;i<=NF;i++) {{printf "%s%s", (cols[i]?$i:""), (i==NF?"\n":(cols[i]?OFS:""))}}}}' {input} > {input}.temp
        awk -vOFS="\t" '{{$6="chr"$4":"$5":"$2">"$1}}1' {input}.temp > {output}.temp
        awk -F'\t' 'FNR==1{{num_fields=NF}} {{ non_empty=0; for(i=1;i<=NF;i++) if($i!="") non_empty++; }} non_empty==num_fields' {output}.temp > {output}
        sed -i '/__/d' {output}
        rm {input}.temp
        rm {output}.temp
        """
        
#Computes risk scores for individuals in the plink2 binary genotype data specified in the config. Reads precomputed allele counts to fill in missing genotype data (see plink2 docs).
rule risk_score_calc:
    threads: 8
    resources:
        mem_mb=lambda wildcards, attempt, threads: (4000 * threads) * attempt
    input: 
        "{PGS_file}_weights.txt"
    output:
        "{PGS_file}.sscore"
    shell:
        f"plink2 --pfile {config['plink2_binary_files']} --read-freq {config['plink2_allele_counts']} --error-on-freq-calc --score {{input}} 6 1 3 header list-variants --out {{wildcards.PGS_file}}"
