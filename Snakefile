sample = "SRR2584857"

rule all:
    input:
        "SRR2584857_quast.4000000",  # 4m lines
        "SRR2584857_annot.4000000",
        "SRR2584857_quast.3000000",  # 3m lines
        "SRR2584857_annot.3000000",
        "SRR2584857_quast.2000000",  # 2m lines
        "SRR2584857_annot.2000000",

wildcard_constraints:
    subset=r"\d+"

rule subset_reads:
    input:
        "{sample}.fastq.gz"
    output:
        "{sample}.{subset}.fastq.gz"
    shell: """
        gunzip -c {input} | head -{wildcards.subset} | gzip -9c > {output} || true
    """

rule annotate:
    conda:
        "prokka"
    input:
        f"{sample}-assembly.{{subset}}.fa"
    output:
        directory(f"{sample}_annot.{{subset}}")
    shell:
        """
        prokka --outdir {output} --prefix {sample} {input}
        """

rule assemble:
    input:
        r1 = "SRR2584857_1.{subset}.fastq.gz",
        r2 = "SRR2584857_2.{subset}.fastq.gz"
    output:
        dir = directory("SRR2584857_assembly.{subset}"),
        assembly = "SRR2584857-assembly.{subset}.fa"
    conda:
        "megahit"
    threads: 4
    shell: """
        megahit -1 {input.r1} -2 {input.r2} -m 5e9 -t {threads} -o {output.dir}
        cp {output.dir}/final.contigs.fa {output.assembly}
    """

rule quast:
    input:
        "SRR2584857-assembly.{subset}.fa"
    output:
        directory(f"{sample}_quast.{{subset}}")
    conda:
        "megahit"
    shell: """
        quast {input} -o {output}
    """
