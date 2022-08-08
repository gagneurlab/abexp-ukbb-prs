configfile: "config.yaml"

rule risk_score_calc:
	input: 
		"{PGS_file}_weights.txt"
	output:
		"{PGS_file}.sscore"
	shell:
		"""srun -c8 --mem 32G plink2 --pfile """ +config["plink2_binary_files"]+ """ --score {input} 6 1 3 header list-variants --out {wildcards.PGS_file}"""
	
rule download_PGS_catalog:
	output:
		"{path_to_dir}PGS{id, [0-9]+}.txt.gz"
	shell:
		"""wget -O {output} 'https://ftp.ebi.ac.uk/pub/databases/spot/pgs/scores/PGS{wildcards.id}/ScoringFiles/PGS{wildcards.id}.txt.gz'"""

rule harmonize_pgs:
	input:
		"{dir}PGS{id, [0-9]+}.txt.gz"
	output:
		"{dir}PGS{id, [0-9]+}_hmPOS_GRCh38.txt"
	shell:
		"python " +config["pgs_harmonizer"] + "Harmonize.py HmPOS PGS{wildcards.id} GRCh38 -loc_files {wildcards.dir} -loc_hmoutput {wildcards.dir}"

rule format_pgs_weights:
	input:
		"{dir}PGS{id, [0-9]+}_hmPOS_GRCh38.txt"
	output:
		"{dir}PGS{id, [0-9]+}_weights.txt"
	shell:
		"""
		sed -i '/^[@#]/ d' {input}
		cut -f4,5,6,9,10 {input} > {input}.temp
		awk -vOFS="\""\t"\"" '{{$6="\""chr"\""$4"\""_"\""$5"\""_"\""$2"\""_"\""$1}}1' {input}.temp > {output}
		sed -i '/__/d' {output}
		rm {input}.temp
		"""
