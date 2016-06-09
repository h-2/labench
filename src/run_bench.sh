#!/bin/sh

run_benchmark()
{
    echo ""
    echo "RUNNING BENCHMARK..."
    echo "  PROFILE                     MAXRAM    RUNTIME"
    echo "-------------------------------------------------"

    for MODPROF in ${MODPROFS}; do

        # get MODULE and PROFILE variables from MODPROF which is MODULE:PROFILE
        MODULE=${MODPROF%%:*}
        if [ ! -d "${BENCHDIR}/modules/${MODULE}" ]; then
            echo "ERROR: Module ${MODULE} not found in ${BENCHDIR}/modules/"
            exit 100
        fi
        if [ ! -f "${BENCHDIR}/modules/${MODULE}/labench.sh" ]; then
            echo "ERROR: Module ${MODULE} does not contains script."
            exit 100
        fi

        PROFILE=${MODPROF#*:} # availability of PROFILE checked in module file

        # default variables and functions if not overwritten
        BINDIR="${BENCHDIR}/modules/${MODULE}/bin"
        INDEXIDENT=${MODPROF}
        LOGFILE="${OUTDIR}/run_${INDEXIDENT}.log"
        OUTPUT="${TMPDIR}/SEARCH/${MODPROF}/output.m8"
        pre_search() { :
        }
        post_search() { :
        }

        # load module and profile
        . "${BENCHDIR}/modules/${MODULE}/labench.sh"
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
        pre_search || exit $(echo $? && echo "Error in ${MODPROF}'s preperation" > /dev/stderr)

        # create/clear logfile
        :> ${LOGFILE}

        echo "** Running Benchmark for ${MODPROF} **" >> ${LOGFILE}
        echo "* Executing: ${DO_SEARCH}" >> ${LOGFILE}
        echo "" >> ${LOGFILE}

        # run the call and catch ram and runtime
        wrapper '${DO_SEARCH}' '${LOGFILE}'
        # function set global time and ram variables

        echo "* total time spent:\t${time}s" >> ${LOGFILE}
        echo "* max RAM used:\t${ram}KiB" >> ${LOGFILE}
        echo "" >> ${LOGFILE}

        post_search|| exit $(echo $? && echo "Error in ${MODPROF}'s post-processing" > /dev/stderr)

        # print diagnostics to stdout
        printf "${MODPROF}"
        fill_up_whitespace "${MODPROF}"
        printf "${ram}\t${time}\n"

    done
}
