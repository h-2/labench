#!/bin/sh

run_benchmark()
{
    echo ""
    echo "RUNNING BENCHMARK..."
    echo "[${REPEATS} iterations per module]"
    echo ""
#     echo ".--------------------------.---------------.--------------.------------."
#     echo "|             MODULE       |      PROFILE  |     RAM [MB] |   TIME [s] |"
#     echo "|--------------------------+---------------+--------------+------------|"

    # HEADERS split over lines for readability:
    : > "${OUTDIR}/perf_search.tab"
    printf "MODULE\t"        >> "${OUTDIR}/perf_search.tab"
    printf "PROFILE\t"       >> "${OUTDIR}/perf_search.tab"
    printf "RAM [MB]: min\t" >> "${OUTDIR}/perf_search.tab"
    printf "med\t"           >> "${OUTDIR}/perf_search.tab"
    printf "max\t"           >> "${OUTDIR}/perf_search.tab"
    printf "TIME [s]: min\t" >> "${OUTDIR}/perf_search.tab"
    printf "med\t"           >> "${OUTDIR}/perf_search.tab"
    printf "max\n"           >> "${OUTDIR}/perf_search.tab"

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
        LOGFILE="${OUTDIR}/run_${MODPROF}.log" # is overwritten by each iteration

        for IT in $(seq 1 ${REPEATS}); do

            OUTPUT="${TMPDIR}/SEARCH/${MODPROF}/${IT}/output.m8"
            pre_search() { :
            }
            post_search() { :
            }

            # load module and profile
            . "${BENCHDIR}/modules/${MODULE}/labench_${PROGRAMMODE}.sh"
            setupCommands

            ### now the search begins

            if [ -d "${TMPDIR}/SEARCH/${MODPROF}/${IT}" ]; then
                echo "ERROR: The target directory already exists!"
                cleanup
                exit 123
            fi

            # prepare directory and change CWD
            mkdir -p "${TMPDIR}/SEARCH/${MODPROF}/${IT}"
            cd "${TMPDIR}/SEARCH/${MODPROF}/${IT}"
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

            # print diagnostics to temporary files
            echo "${ram}"     >> "${TMPDIR}/SEARCH/${MODPROF}/ram"
            echo "${time}"    >> "${TMPDIR}/SEARCH/${MODPROF}/time"

        done

        # print diagnostics to table
        printf "${MODULE}\t"                            >> "${OUTDIR}/perf_search.tab"
        printf "${PROFILE}\t"                           >> "${OUTDIR}/perf_search.tab"
        min_med_max "${TMPDIR}/SEARCH/${MODPROF}/ram"   >> "${OUTDIR}/perf_search.tab"
        printf "\t"                                     >> "${OUTDIR}/perf_search.tab"
        min_med_max "${TMPDIR}/SEARCH/${MODPROF}/time"  >> "${OUTDIR}/perf_search.tab"
        printf "\n"                                     >> "${OUTDIR}/perf_search.tab"
    done

    pretty_print2 "${OUTDIR}/perf_search.tab"
    echo ""
}
