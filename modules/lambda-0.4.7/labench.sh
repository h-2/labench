#!/bin/sh

## for show-profiles
getProfiles()
{
    if [ ${PROGRAMMODE} = "BLASTX" ]; then
        PROFILES="blastx_default blastx_fast blastx_slow blastx_sa-di"
    fi
}

## database command definitions
setupCommands()
{
    BASECMD="${BINDIR}/lambda_indexer -d db.fasta -t ${NCPU}"
    case $PROFILE in
        "blastx_default" | "blastx_slow")
            DO_INDEX_DB="${BASECMD}"
            INDEXIDENT="${MODULE}:redaa"
            ;;
        "blastx_fast")
            DO_INDEX_DB="${BASECMD} -ar none"
            INDEXIDENT="${MODULE}:aa"
            ;;
        "blastx_sa-di")
            DO_INDEX_DB="${BASECMD} -di sa "
            INDEXIDENT="${MODULE}:redaa_sa"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    ## run command definitions
    BASECMD="${BINDIR}/lambda -q query.fasta -d ${TMPDIR}/INDEX/${INDEXIDENT}/db.fasta -e ${EVALUE} -v 2 -t ${NCPU} -o ${OUTPUT}.m8 -nm ${MAXDBENTRIES}"

    case $PROFILE in
        "blastx_default")
            DO_SEARCH="${BASECMD}"
            ;;
        "blastx_slow")
            DO_SEARCH="${BASECMD} -so 5"
            ;;
        "blastx_fast")
            DO_SEARCH="${BASECMD} -ar none -sl 7 -sd 0"
            ;;
        "blastx_sa-di")
            DO_SEARCH="${BASECMD} -di sa -qi radix"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac
}
