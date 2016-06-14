#!/bin/sh

find_minbits()
{
    MINBITS=10000000
    if [ ${DEBUG:+x} ]; then
        echo "MINBIT computation"
        echo "  PROFILE                           MINBITS"
        echo "--------------------------------------------"
    fi

    for MODPROF in ${MODPROFS}; do

        _MINBITS=$(zcat "${TMPDIR}/SEARCH/${MODPROF}/output.m8.gz" | \
        awk '
        BEGIN { MINBITS=10000000 }
        $11 < '$EVALUE' && $12 < MINBITS { MINBITS=$12 }
        END { print MINBITS }')

        if [ ${DEBUG:+x} ]; then
            printf "${MODPROF}"
            fill_up_whitespace "${MODPROF}"
            printf "${_MINBITS}\n"
        fi

        MINBITS=$(min ${MINBITS} ${_MINBITS})
    done

    echo "Global MINBITS: ${MINBITS}"
    echo ""
}

filter_file() #INPUTFILE
{
    # strip comments and newlines filter out bitscore that are too small, sort
    # (note that the sorting is by IDs and not by evalue anymore (but we can't rely on that anyway)
    zgrep -v -E '(^$|^ *#)' "${1}.gz" | awk -F\\t ' $12 > '${MINBITS} | sort | gzip > "${1}.filtered.gz"
    # only best hit per query
    zcat "${1}.filtered.gz" | awk -F\\t '
$1 != lastQry {
    if (buffer != "")
        print buffer;

    lastQry = $1
    lastBitS = $12
    buffer = $0
};
($1 == lastQry) && ($12 > lastBitS) {
    buffer = $0;
    lastBitS = $12
};' | gzip > "${1}.bestPerQry.gz"

    # only best hit per qry-subj combination
    zcat "${1}.filtered.gz" | awk -F\\t '
($1 != lastQry) || ($2 != lastSubj)  {
    if (buffer != "")
        print buffer;

    lastQry = $1
    lastSubj = $2
    lastBitS = $12
    buffer = $0
};
($1 == lastQry) && ($2 == lastSubj) && ($12 > lastBitS) {
    buffer = $0;
    lastBitS = $12
};' | gzip > "${1}.bestPerQrySubj.gz"

}



create_report()
{
    echo ""
    echo "Preparing report..."

    find_minbits

    # HEADERS split over lines for readability:
    : > "${OUTDIR}/report.tab"
    printf "MODULE"         >> "${OUTDIR}/report.tab"
    printf "\tPROFILE"      >> "${OUTDIR}/report.tab"
    printf "\t# total"      >> "${OUTDIR}/report.tab"
    printf "\t# pairs"      >> "${OUTDIR}/report.tab"
    printf "\t# best"       >> "${OUTDIR}/report.tab"
    printf "\tbits Q1"      >> "${OUTDIR}/report.tab"
    printf "\tbits MED"     >> "${OUTDIR}/report.tab"
    printf "\tbits Q3"      >> "${OUTDIR}/report.tab"
    printf "\n"             >> "${OUTDIR}/report.tab"

    for MODPROF in ${MODPROFS}; do

        OUTPUT="${TMPDIR}/SEARCH/${MODPROF}/output.m8"

        # get MODULE and PROFILE variables from MODPROF which is MODULE:PROFILE
        MODULE=${MODPROF%%:*}
        PROFILE=${MODPROF#*:}

        filter_file "${OUTPUT}"

        # print diagnostics to stdout
        printf "${MODULE}"                                      >> "${OUTDIR}/report.tab"
        printf "\t${PROFILE}"                                   >> "${OUTDIR}/report.tab"
        printf "\t$(zcat "${OUTPUT}.filtered.gz" |wc -l)"       >> "${OUTDIR}/report.tab"
        printf "\t$(zcat "${OUTPUT}.bestPerQrySubj.gz" |wc -l)" >> "${OUTDIR}/report.tab"
        printf "\t$(zcat "${OUTPUT}.bestPerQry.gz" |wc -l)"     >> "${OUTDIR}/report.tab"
        bit_score_quartiles "${OUTPUT}.bestPerQry.gz"           >> "${OUTDIR}/report.tab"
        printf "\n"                                             >> "${OUTDIR}/report.tab"

    done

    pretty_print2 "${OUTDIR}/report.tab"
}

