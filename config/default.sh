#!/bin/sh

# queryfile not set by default
#QUERY_FA=

# database not set by defualt
#DATABASE_FA=

TMPDIR=${TMPDIR-"/tmp"}

# outdir
OUTDIR=${OUTDIR-"${TMPDIR}/labench"}

# programmode
PROGRAMMODE=${PROGRAMMODE-"blastx"}

# e-value cut off
EVALUE=${EVALUE-0.1}

# maximum number of hits per query sequence
MAXDBENTRIES=${MAXDBENTRIES-256}

# number of cpus/cores in the system
if [ "$(uname)" = "Linux" ]; then
    NCPU=${NCPU-$(grep -c -P "processor\t:" /proc/cpuinfo)}
else # bsd and mac
    NCPU=${NCPU-$(sysctl -n hw.ncpu)}
fi
export OMP_NUM_THREADS=${NCPU}

# iterations of benchmark
REPEATS=${REPEATS-3}
