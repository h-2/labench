#!/bin/sh

create_indexes()
{
    echo ""
    echo "CREATING INDEXES..."
    echo ""
    echo ".--------------------------.---------------.--------------.------------."
    echo "|             MODULE       |      PROFILE  |     RAM [MB] |   TIME [s] |"
    echo "|--------------------------+---------------+--------------+------------|"

    for MODPROF in ${MODPROFS}; do

        # get MODULE and PROFILE variables from MODPROF which is MODULE:PROFILE
        MODULE=${MODPROF%%:*}
        if [ ! -d "${BENCHDIR}/modules/${MODULE}" ]; then
            echo "ERROR: Module ${MODULE} not found in ${BENCHDIR}/modules/"
            exit 100
        fi
        if [ ! -f "${BENCHDIR}/modules/${MODULE}/labench_${PROGRAMMODE}.sh" ]; then
            echo "ERROR: Module ${MODULE} does not contain script."
            exit 100
        fi

        PROFILE=${MODPROF#*:} # availability of PROFILE checked in module file

        # default variables and functions if not overwritten
        BINDIR="${BENCHDIR}/modules/${MODULE}/bin"
        INDEXIDENT=${PROFILE}
        LOGFILE="${OUTDIR}/createindex_${MODULE}:${INDEXIDENT}.log"
        OUTPUT=""
        pre_index() { :
        }
        post_index() { :
        }

        # load module and profile
        . "${BENCHDIR}/modules/${MODULE}/labench_${PROGRAMMODE}.sh"
        setupCommands

        ### now the indexing begins

        # if an index for this INDEXIDENT already exists, skip
        [ -d "${TMPDIR}/INDEX/${MODULE}:${INDEXIDENT}" ] && continue

        # prepare directory and change CWD
        mkdir -p "${TMPDIR}/INDEX/${MODULE}:${INDEXIDENT}"
        cd "${TMPDIR}/INDEX/${MODULE}:${INDEXIDENT}"
        ln -s "${DATABASE_FA}" db.fasta

        # run a module's custom preperation function if set
        pre_index || exit $(echo $? && echo "Error in ${MODPROF}'s preperation" > /dev/stderr)

        # create/clear logfile
        :> ${LOGFILE}

        echo "** Creating Index for ${INDEXIDENT} **" >> ${LOGFILE}
        echo "* Executing: ${DO_INDEX_DB}" >> ${LOGFILE}
        echo "" >> ${LOGFILE}

        # run the call and catch ram and runtime
        wrapper '${DO_INDEX_DB}' '${LOGFILE}'
        # function set global time and ram variables

        echo "* total time spent:\t${time}s" >> ${LOGFILE}
        echo "* max RAM used:\t${ram}KiB" >> ${LOGFILE}
        echo "" >> ${LOGFILE}

        post_index || exit $(echo $? && echo "Error in ${INDEXIDENT}'s post-processing" > /dev/stderr)

        # print diagnostics to stdout
        printf '|%25s |%14s |%13s |%11s |\n' ${MODULE} ${INDEXIDENT} ${ram} ${time}

    done
    echo "'--------------------------'---------------'--------------'------------'"
    echo ""
}
