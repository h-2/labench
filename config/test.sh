#!/bin/sh

QUERY_FA="${HOME}/sequences/100k_long_reads.fna"
DATABASE_FA="${HOME}/sequences/uniprot_sprot.fasta"

# MODPROFS="lambda-0.9.4:blastx_default
# lambda-0.9.4:blastx_fast
# lambda-0.9.4:blastx_slow
# RAPSearch2.09_64bits:blastx_default
# RAPSearch2.09_64bits:blastx_fast"

MODPROFS="lambda-0.9.4:blastx_default
RAPSearch2.09_64bits:blastx_fast"

DEBUG=1
