#!/bin/sh

## for show-profiles
PROFILES="default fast"

## must define DO_INDEX_DB for all profiles
setupCommands()
{
    case $PROFILE in
        "default" | "fast")
            DO_INDEX_DB="${BINDIR}/prerapsearch -d ${DATABASE_FA} -n ./db"
            INDEXIDENT=default
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    # need to remove .m8 from file, because rapsearch always adds it
    BASECMD="${BINDIR}/rapsearch -q query.fasta -d ${TMPDIR}/INDEX/${MODULE}:${INDEXIDENT}/db -o ${OUTPUT%???}
           -z ${NCPU}
           -e $(echo ${EVALUE_ACTUAL} | awk '{ print log($0)/log(10) }')
           -v ${MAXDBENTRIES} -b 0"

    case $PROFILE in
        "default")
            DO_SEARCH="${BASECMD}"
            ;;
        "fast")
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
        }' "${OUTPUT}_log_e" > ${OUTPUT}
        rm "${OUTPUT}_log_e"
    }
}
