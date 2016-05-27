#!/bin/sh

create_indexes()
{
    echo "Running Benchmark..."
    echo "MODULE:PROFILE     MAXRAM       RUNTIME"
    echo "---------------------------------------"

    for MODPROF in ${MODPROFS}; do

        # get MODULE and PROFILE variables from MODPROF which is MODULE:PROFILE
        MODULE=${MODPROF#*:}
        if [ ! -d "${BENCHDIR}/modules/${MODULE}" ]; then
            echo "ERROR: Module ${MODULE} not found in ${BENCHDIR}/modules/"
            exit 100
        fi
        if [ ! -x "${BENCHDIR}/modules/${MODULE}/labench.sh" ]; then
            echo "ERROR: Module ${MODULE} does not contains script."
            exit 100
        fi

        PROFILE=${MODPROF%%:*} # availability of PROFILE checked in module file

        # default variables and functions if not overwritten
        BINDIR="${BENCHDIR}/modules/${MODULE}/bin"
        INDEXIDENT=${MODPROF}
        LOGFILE="${OUTDIR}/createindex_${INDEXIDENT}.log"
        pre_search() { }
        post_search() { }

        # load module and profile
        . "${BENCHDIR}/modules/${MODULE}/labench.sh"
        setupCommands

        ### now the indexing begins

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
        ramtime=$(wrapper "${DO_SEARCH} >> ${LOGFILE} 2>&1" 4>&1)
        time=$(max 0 ${ramtime#*'
'})
        ram=$(( $(max 0 ${ramtime%%'
'*})  / 1024 ))

        echo "* total time spent:\t${time}s" >> ${LOGFILE}
        echo "* max RAM used:\t${ram}KiB" >> ${LOGFILE}
        echo "" >> ${LOGFILE}

        post_search|| exit $(echo $? && echo "Error in ${MODPROF}'s post-processing" > /dev/stderr)

        # print diagnostics to stdout
        printf "${MODPROF}"
        fill_up_whitespace "${MODPROF}"
        echo "${ram}\t${time}"

    done
}
