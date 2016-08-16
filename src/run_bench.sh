#!/bin/sh

run_benchmark()
{
    echo ""
    echo "RUNNING BENCHMARK..."
    echo ""
#     echo ".--------------------------.---------------.--------------.------------."
#     echo "|             MODULE       |      PROFILE  |     RAM [MB] |   TIME [s] |"
#     echo "|--------------------------+---------------+--------------+------------|"

    # HEADERS split over lines for readability:
    : > "${OUTDIR}/perf_search.tab"
    printf "MODULE"          >> "${OUTDIR}/perf_search.tab"
    printf "\tPROFILE"       >> "${OUTDIR}/perf_search.tab"
    printf "\tRAM [MB]"      >> "${OUTDIR}/perf_search.tab"
    printf "\tTIME [s]"      >> "${OUTDIR}/perf_search.tab"
    printf "\n"              >> "${OUTDIR}/perf_search.tab"

    for MODPROF in ${MODPROFS}; do

        # get MODULE and PROFILE variables from MODPROF which is MODULE:PROFILE
        MODULE=${MODPROF%%:*}
        if [ ! -d "${BENCHDIR}/modules/${MODULE}" ]; then
            echo "ERROR: Module ${MODULE} not found in ${BENCHDIR}/modules/"
            exit 100
        fi
        if [ ! -f "${BENCHDIR}/modules/${MODULE}/labench_${PROGRAMMODE}.sh" ]; then
            echo "ERROR: Module ${MODULE} does not contains script."
            exit 100
        fi

        PROFILE=${MODPROF#*:} # availability of PROFILE checked in module file

        # default variables and functions if not overwritten
        BINDIR="${BENCHDIR}/modules/${MODULE}/bin"
        INDEXIDENT=${PROFILE}
        LOGFILE="${OUTDIR}/run_${MODPROF}.log"
        OUTPUT="${TMPDIR}/SEARCH/${MODPROF}/output.m8"
        pre_search() { :
        }
        post_search() { :
        }

        # load module and profile
        . "${BENCHDIR}/modules/${MODULE}/labench_${PROGRAMMODE}.sh"
        setupCommands

        ### now the search begins

        if [ -d "${TMPDIR}/SEARCH/${MODPROF}" ]; then
            echo "ERROR: The target directory already exists!"
            cleanup
            exit 123
        fi

        # prepare directory and change CWD
        mkdir -p "${TMPDIR}/SEARCH/${MODPROF}"
        cd "${TMPDIR}/SEARCH/${MODPROF}"
        ln -s "${QUERY_FA}" query.fasta

        # run a module's custom preperation function if set
        pre_search || { echo "ERROR in ${MODPROF}'s pre-processing; skipping." > /dev/stderr ; continue; }

        # create/clear logfile
        :> ${LOGFILE}

        # run the call and catch ram and runtime
        wrapper '${DO_SEARCH}' '${LOGFILE}' || { echo "ERROR running bench for ${MODPROF}, see ${LOGFILE} for details." > /dev/stderr ; continue; }

        # wrapper sets global time and ram variables

        post_search || { echo "ERROR in ${MODPROF}'s post-processing; skipping." > /dev/stderr ; continue; }
        # remove comments, blank lines and compress
        grep -v -E '(^$|^ *#)' "${OUTPUT}" | gzip > "${OUTPUT}.gz"
        rm "${OUTPUT}"

        # print diagnostics to stdout
#         printf '|%25s |%14s |%13s |%11s |\n' ${MODULE} ${PROFILE} ${ram} ${time}
        printf "${MODULE}"          >> "${OUTDIR}/perf_search.tab"
        printf "\t${PROFILE}"       >> "${OUTDIR}/perf_search.tab"
        printf "\t${ram}"           >> "${OUTDIR}/perf_search.tab"
        printf "\t${time}"          >> "${OUTDIR}/perf_search.tab"
        printf "\n"                 >> "${OUTDIR}/perf_search.tab"

    done

    pretty_print2 "${OUTDIR}/perf_search.tab"
    echo ""
}
