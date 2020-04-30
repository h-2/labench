#!/bin/sh

## for show-profiles
PROFILES="default fast slow bifm l3"

## database command definitions
setupCommands()
{
    BASECMD="${BINDIR}/lambda2 mkindexp -d db.fasta -t ${NCPU}"
    case $PROFILE in
        "default" | "slow" | "fast" | "l3")
            DO_INDEX_DB="${BASECMD}"
            INDEXIDENT="default"
            ;;
        "bifm")
            DO_INDEX_DB="${BASECMD} --db-index-type bifm"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    ## run command definitions
    BASECMD="${BINDIR}/lambda2 searchp -q query.fasta -i ${TMPDIR_DB}/INDEX/${MODULE}:${INDEXIDENT}/db.fasta.lambda -e ${EVALUE_ACTUAL} -v 2 -t ${NCPU} -o ${OUTPUT} -n ${MAXDBENTRIES}"

    case $PROFILE in
        "default" | "bifm" )
            DO_SEARCH="${BASECMD}"
            ;;
        "slow")
            DO_SEARCH="${BASECMD} --seed-offset 3"
            ;;
        "l3")
            DO_SEARCH="${BASECMD} --seed-offset 10 --seed-half-exact 0"
            ;;
        "fast")
            DO_SEARCH="${BASECMD} --seed-delta-increases-length on"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac
}
