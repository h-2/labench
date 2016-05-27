#!/bin/sh

BINDIR=${BENCHDIR}/modules/${MODULE}/

## for show-profiles
getProfiles()
{
    case $PROGRAMMODE in
        "BLASTX")
            PROFILES="blastx_default blastx_slow"
            ;;
        *) # no other modes
            ;;
    esac
}

## must define DO_INDEX_DB for all profiles
setupCommands()
{

    case $PROFILE in
        "blastx_default" | "blastx_slow")
            DO_INDEX_DB="${BINDIR}/diamond makedb --in ${DATABASE_FA} --db db --threads ${NCPU}"
            INDEXIDENT=$MODULE:prot
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    case $PROFILE in
        "blastx_default")
            EXTRA_FLAGS=""
            ;;
        "blastx_slow")
            EXTRA_FLAGS="--sensitive"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    DO_SEARCH="${BINDIR}/diamond blastx --query ${QUERY_FA} --db ${TMPDIR}/INDEX/${INDEXIDENT}/db -a matches
               --threads ${NCPU} --max-target-seqs ${MAXDBENTRIES} --min-score ${MINBITS} ${EXTRA_FLAGS}
               && ${BINDIR}/diamond view -a matches.daa -o ${OUTPUT}"

}
