#!/bin/sh

BINDIR=${BENCHDIR}/modules/${MODULE}/
MALT=${BINDIR}

export JAVA_HOME=/srv/hdd/h4nn3s/java/jdk-10.0.2
export PATH=$JAVA_HOME/bin:$PATH



## for show-profiles
PROFILES="default load page mmap"

## must define DO_INDEX_DB for all profiles
setupCommands()
{

    case $PROFILE in
        "default" | "load" | "page" | "mmap")
            DO_INDEX_DB="${BINDIR}/malt-build -i ${DATABASE_FA} -d db --threads ${NCPU} --sequenceType Protein"
            INDEXIDENT="default"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

    BASECMD="${BINDIR}/malt-run --mode BlastX --inFile ${QUERY_FA} --index ${TMPDIR_DB}/INDEX/${MODULE}:${INDEXIDENT}/db
             --alignments output.m8 --format Tab -t ${NCPU} --maxAlignmentsPerQuery ${MAXDBENTRIES} --maxExpected ${EVALUE_ACTUAL}
             "

    case $PROFILE in
        "default")
            DO_SEARCH="${BASECMD}"
            ;;
        "load")
            DO_SEARCH="${BASECMD} --memoryMode load"
            ;;
        "page")
            DO_SEARCH="${BASECMD} --memoryMode page"
            ;;
        "mmap")
            DO_SEARCH="${BASECMD} --memoryMode map"
            ;;
        *)
            echo "ERROR: Profile ${PROFILE} does not exist."
            exit 100
            ;;
    esac

     post_search()
     {
         # convert diamond format to blast
         gunzip output.m8.gz 2>&1 > /dev/null
     }

}
