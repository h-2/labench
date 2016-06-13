#!/bin/sh

BINDIR=${BENCHDIR}/modules/${MODULE}/

## for show-profiles
PROFILES="default slow"

## must define DO_INDEX_DB for all profiles
setupCommands()
{

    case $PROFILE in
        "default" | "slow")
            DO_INDEX_DB="${BINDIR}/diamond makedb --in ${DATABASE_FA} --db db --threads ${NCPU}"
            INDEXIDENT="default"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    BASECMD="${BINDIR}/diamond blastx --query ${QUERY_FA} --db ${TMPDIR}/INDEX/${MODULE}:${INDEXIDENT}/db -a matches
               --threads ${NCPU} --max-target-seqs ${MAXDBENTRIES} --evalue ${EVALUE_ACTUAL}"

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

    post_search()
    {
        # convert diamond format to blast
        ${BINDIR}/diamond view -a matches.daa -o ${OUTPUT} 2>&1 > /dev/null
    }

}
