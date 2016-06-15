#!/bin/sh

BINDIR=${BENCHDIR}/modules/${MODULE}/

## for show-profiles
PROFILES="default slow"

## must define DO_INDEX_DB for all profiles
setupCommands()
{

    case $PROFILE in
        "default" | "slow")
            DO_INDEX_DB="${BINDIR}/diamond makedb --in ${DATABASE_FA} --db db --threads ${NCPU} --tmpdir ${TMPDIR}"
            INDEXIDENT="default"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    # the minimum bit-score is too strict so we set it to 40 and hope its ok
    BASECMD="${BINDIR}/diamond blastx --query ${QUERY_FA} --db ${TMPDIR}/INDEX/${MODULE}:${INDEXIDENT}/db
             -o ${OUTPUT} --threads ${NCPU} --max-target-seqs ${MAXDBENTRIES} --evalue ${EVALUE_ACTUAL}
             --tmpdir ${TMPDIR} --min-score 40"

    case $PROFILE in
        "default")
            DO_SEARCH="${BASECMD}"
            ;;
        "slow")
            DO_SEARCH="${BASECMD} --sensitive"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

}
