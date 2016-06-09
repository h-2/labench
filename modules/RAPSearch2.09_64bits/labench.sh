#!/bin/sh

#Change if different
#BINDIR=${BENCHDIR}/modules/${MODULE}/bin

# Change if different
#OUTPUT="${OUTDIR}/SEARCH/${MODULE}-${PROFILE}/output"
# if you do change this, make sure that after the search the
# file is named as above, e.g. by overloading post_search()

## for show-profiles
getProfiles()
{
    case $PROGRAMMODE in
        "BLASTX")
            PROFILES="blastx_default blastx_fast"
            ;;
        *) # no other modes
            ;;
    esac
}

## must define DO_INDEX_DB for all profiles
setupCommands()
{
    # may define a function that will be run before indexing
#     pre_index()
#     {
#     }

    case $PROFILE in
        "blastx_default" | "blastx_fast")
            DO_INDEX_DB="${BINDIR}/prerapsearch -d ${DATABASE_FA} -n ./db"
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


    # may define a function that will be run before search
#     pre_search()
#     {
#     }

    # need to remove .m8 from file, because rapsearch always adds it
    BASECMD="${BINDIR}/rapsearch -q query.fasta -d ${TMPDIR}/INDEX/${INDEXIDENT}/db -o ${OUTPUT%???}
           -z ${NCPU}
           -e $(echo ${EVALUE} | awk '{ print log($0)/log(10) }')
           -v ${MAXDBENTRIES} -b 0"

    case $PROFILE in
        "blastx_default")
            DO_SEARCH="${BASECMD}"
            ;;
        "blastx_fast")
            DO_SEARCH="${BASECMD} -a t"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    # may define a function that will be run before search
    post_search()
    {
        ## convert the log(eval) in output file to regular eval BEFORE OTHER STUFF
        mv "${OUTPUT}" "${OUTPUT}_log_e"
        awk -F\\t '
        $0 ~ /^ *$/ { next };
        $0 ~ /^ *#/ { print $0; next };
        {
            print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" \
                $7 "\t" $8 "\t" $9 "\t" $10 "\t" 10^($11) "\t"  $12
        }' "${OUTPUT}_log_e" > ${OUTPUT} ## Rapsearch2 writes to OUTPUT.m8 by default
    }
}
