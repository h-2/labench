#!/bin/sh

create_indexes()
{
    echo "CREATING INDEXES..."
    echo "INDEXIDENT     MAXRAM       RUNTIME"
    echo "-----------------------------------"

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
        pre_index() { }
        post_index() { }

        # load module and profile
        . "${BENCHDIR}/modules/${MODULE}/labench.sh"
        setIndexCommands

        ### now the indexing begins

        # if an index for this INDEXIDENT already exists, skip
        [ -d "${TMPDIR}/${INDEXIDENT}" ] && continue

        # prepare directory and change CWD
        mkdir -p "${TMPDIR}/INDEX/${INDEXIDENT}"
        cd "${TMPDIR}/INDEX/${INDEXIDENT}"
        ln -s "${DATABASE_FA}" db.fasta

        # run a module's custom preperation function if set
        pre_index || exit $(echo $? && echo "Error in ${MODPROF}'s preperation" > /dev/stderr)

        # create/clear logfile
        :> ${LOGFILE}

        echo "** Creating Index for ${INDEXIDENT} **" >> ${LOGFILE}
        echo "* Executing: ${DO_INDEX_DB}" >> ${LOGFILE}
        echo "" >> ${LOGFILE}

        # run the call and catch ram and runtime
        ramtime=$(wrapper "${DO_INDEX_DB} >> ${LOGFILE} 2>&1" 4>&1)
        time=$(max 0 ${ramtime#*'
'})
        ram=$(( $(max 0 ${ramtime%%'
'*})  / 1024 ))

        echo "* total time spent:\t${time}s" >> ${LOGFILE}
        echo "* max RAM used:\t${ram}KiB" >> ${LOGFILE}
        echo "" >> ${LOGFILE}

        post_index || exit $(echo $? && echo "Error in ${INDEXIDENT}'s post-processing" > /dev/stderr)

        # print diagnostics to stdout
        printf "${INDEXIDENT}"
        fill_up_whitespace "${INDEXIDENT}"
        echo "${ram}\t${time}"

    done
}
