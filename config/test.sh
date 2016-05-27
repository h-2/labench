#!/bin/sh

QUERY_FA="~/takifugu/sequences/query/illumina/rapsearch_ref/illumina_1200k_len72.fasta"

DATABASE_FA="~/takifugu/sequences/db/uniprot_sprot.fasta"

TMPDIR=${TMPDIR-"/tmp"}

# outdir
OUTDIR=${OUTDIR-"${TMPDIR}/labench"}
