#!/bin/sh

#Change if different
#BINDIR=${BENCHDIR}/modules/${MODULE}/bin

# Change if different
#OUTPUT="${OUTDIR}/SEARCH/${MODULE}-${PROFILE}/output.m8"
# if you do change this, make sure that after the search the
# file is named as above, e.g. by overloading post_search()

## for show-profiles
getProfiles()
{
    case $PROFILE in
        "BLASTN")
            PROFILES="blastn_default blastn_fast"
            ;;
        "BLASTX")
            PROFILES="blastx_default blastx_fast blastx_ultrafast"
            ;;
        *) # no other modes
            ;;
    esac
}

## must define DO_INDEX_DB for all profiles
setIndexCommands()
{
    # may define a function that will be run before indexing
#     pre_index()
#     {
#     }

    case $PROFILE in
        "blastn_default" | "blastn_fast")
            DO_INDEX_DB="${BINDIR}/my_prog_makedb --nucl --database db.fasta --num-threads ${NCPU}"
            INDEXIDENT=$MODULE:nucl # optional: enables reusage of index for all blastn_*
            ;;
        "blastx_default" | "blastx_fast" | "blastx_ultrafast")
            DO_INDEX_DB="${BINDIR}/my_prog_makedb --prot --database db.fasta --num-threads ${NCPU}"
            INDEXIDENT=$MODULE:prot
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    # may define a function that will be run after indexing
#     post_index()
#     {
#     }
}

## must define DO_SEARCH for all profiles
setRunCommands()
{
    # may define a function that will be run before search
#     pre_search()
#     {
#     }

    BASECMD="${BINDIR}/lambda -q query.fasta -d ${TMPDIR_DB}/INDEX/${INDEXIDENT}/db.fasta -e ${EVALUE} -v 2 -t ${NCPU} -o ${OUTPUT} -nm ${MAXDBENTRIES}"

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

    # may define a function that will be run before search
#     post_search()
#     {
#     }
}
