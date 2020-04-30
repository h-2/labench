#!/bin/sh

## for show-profiles
PROFILES="default fast"

## database command definitions
setupCommands()
{
    BASECMD="${BINDIR}/makeblastdb -dbtype prot -in db.fasta -out db"
    case $PROFILE in
        "default" | "fast")
            DO_INDEX_DB="${BASECMD}"
            INDEXIDENT="default"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    ## run command definitions
    BASECMD="${BINDIR}/blastx -query query.fasta -db ${TMPDIR_DB}/INDEX/${MODULE}:${INDEXIDENT}/db -evalue ${EVALUE_ACTUAL} -comp_based_stats 0 -outfmt 6 -num_threads ${NCPU} -out ${OUTPUT} -num_alignments ${MAXDBENTRIES}"

    case $PROFILE in
        "default")
            DO_SEARCH="${BASECMD}"
            ;;
        "fast")
            DO_SEARCH="${BASECMD} -task blastx-fast"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac
}
