#!/bin/sh

## for show-profiles
PROFILES="default li10 bifm bifm-li10 dist2 bifm-dist2 bifm-fast bifm-slow faster"

## database command definitions
setupCommands()
{
    BASECMD="${BINDIR}/lambda3 mkindexp -d db.fasta"
    case $PROFILE in
        "default")
            DO_INDEX_DB="${BASECMD}"
            INDEXIDENT="default"
            ;;
        "li10" | "dist2")
            DO_INDEX_DB="${BASECMD} -r li10"
            ;;
        "bifm")
            DO_INDEX_DB="${BASECMD} --db-index-type bifm"
            ;;
        "bifm-li10" | "bifm-dist2" | "bifm-dist2" | "bifm-fast" | "bifm-slow" | "faster")
            DO_INDEX_DB="${BASECMD} --db-index-type bifm -r li10"
            INDEXIDENT="bifm-li10"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    ## run command definitions
    BASECMD="${BINDIR}/lambda3 searchp -q query.fasta -i ${TMPDIR_DB}/INDEX/${MODULE}:${INDEXIDENT}/db.fasta.lba -e ${EVALUE_ACTUAL} -v 2 -t ${NCPU} -o ${OUTPUT} -n ${MAXDBENTRIES}"

    case $PROFILE in
        "default" | "li10" | "bifm" | "bifm-li10")
            DO_SEARCH="${BASECMD}"
            ;;
        "dist2" | "bifm-dist2")
            DO_SEARCH="${BASECMD} --seed-offset 14 --seed-length 14 --seed-delta 2"
            ;;
        "bifm-fast")
            DO_SEARCH="${BASECMD} --seed-offset 11 --seed-length 11"
            ;;
        "faster")
            DO_SEARCH="${BASECMD} --seed-offset 12 --seed-length 12"
            ;;
        "bifm-slow")
            DO_SEARCH="${BASECMD} --seed-offset 5"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac
}
