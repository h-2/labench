#!/bin/sh

## for show-profiles
PROFILES="default fast slow sa-di"

## database command definitions
setupCommands()
{
    BASECMD="${BINDIR}/lambda_indexer -d db.fasta -t ${NCPU}"
    case $PROFILE in
        "default" | "slow")
            DO_INDEX_DB="${BASECMD}"
            INDEXIDENT="default"
            ;;
        "fast")
            DO_INDEX_DB="${BASECMD} -ar none"
            ;;
        "sa-di")
            DO_INDEX_DB="${BASECMD} -di sa "
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    ## run command definitions
    BASECMD="${BINDIR}/lambda -q query.fasta -d ${TMPDIR_DB}/INDEX/${MODULE}:${INDEXIDENT}/db.fasta -e ${EVALUE_ACTUAL} -v 2 -t ${NCPU} -o ${OUTPUT} -nm ${MAXDBENTRIES}"

    case $PROFILE in
        "default")
            DO_SEARCH="${BASECMD}"
            ;;
        "slow")
            DO_SEARCH="${BASECMD} -so 5"
            ;;
        "fast")
            DO_SEARCH="${BASECMD} -ar none -sl 7 -sd 0"
            ;;
        "sa-di")
            DO_SEARCH="${BASECMD} -di sa -qi radix"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac
}
