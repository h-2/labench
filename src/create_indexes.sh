#!/bin/sh

create_indexes()
{
    echo ""
    echo "CREATING INDEXES..."
    echo ""
#     echo ".--------------------------.---------------.--------------.------------."
#     echo "|             MODULE       |      PROFILE  |     RAM [MB] |   TIME [s] |"
#     echo "|--------------------------+---------------+--------------+------------|"

        # HEADERS split over lines for readability:
    : > "${OUTDIR}/perf_index.tab"
    printf "MODULE"          >> "${OUTDIR}/perf_index.tab"
    printf "\tPROFILE"       >> "${OUTDIR}/perf_index.tab"
    printf "\tRAM [MB]"      >> "${OUTDIR}/perf_index.tab"
    printf "\tTIME [s]"      >> "${OUTDIR}/perf_index.tab"
    printf "\n"              >> "${OUTDIR}/perf_index.tab"


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
        [ -d "${TMPDIR_DB}/INDEX/${MODULE}:${INDEXIDENT}" ] && continue

        # prepare directory and change CWD
        mkdir -p "${TMPDIR_DB}/INDEX/${MODULE}:${INDEXIDENT}"
        cd "${TMPDIR_DB}/INDEX/${MODULE}:${INDEXIDENT}"
        ln -s "${DATABASE_FA}" db.fasta

        # run a module's custom preperation function if set
        pre_index || { echo "ERROR in ${INDEXIDENT}'s pre-processing; skipping." > /dev/stderr ; continue; }

        # create/clear logfile
        :> ${LOGFILE}

        # run the call and catch ram and runtime
        wrapper '${DO_INDEX_DB}' '${LOGFILE}' || { echo "ERROR creating index for ${MODPROF}, see ${LOGFILE} for details." > /dev/stderr ; continue; }
        # wrapper sets global time and ram variables

        post_index || { echo "ERROR in ${INDEXIDENT}'s post-processing; skipping." > /dev/stderr ; continue; }

        # print diagnostics to stdout
#         printf '|%25s |%14s |%13s |%11s |\n' ${MODULE} ${INDEXIDENT} ${ram} ${time}
        printf "${MODULE}"          >> "${OUTDIR}/perf_index.tab"
        printf "\t${INDEXIDENT}"    >> "${OUTDIR}/perf_index.tab"
        printf "\t${ram}"           >> "${OUTDIR}/perf_index.tab"
        printf "\t${time}"          >> "${OUTDIR}/perf_index.tab"
        printf "\n"                 >> "${OUTDIR}/perf_index.tab"

    done

    pretty_print2 "${OUTDIR}/perf_index.tab"
    echo ""
}
