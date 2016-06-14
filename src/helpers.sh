#!/bin/sh


############# ARBITRARY FUNCTIONS #####################

## maximum of two values. also works if one value is blank (i.e. only one arg)
max()
{
    if ( [ $# -eq 1 ] || [ $(echo "$1 > $2" | bc) -eq 1 ] ); then
        echo $1
    else
        echo $2
    fi
}

min()
{
    if ( [ $# -eq 1 ] || [ $(echo "$1 < $2" | bc) -eq 1 ] ); then
        echo $1
    else
        echo $2
    fi
}

pretty_print2() # INPUTFILE
{
    numcols=$(awk -F\\t '
    NF > maxColumns { maxColumns = NF};
    END { printf maxColumns }' ${1} )

    colwidths=$(awk -F\\t '
    {
        for (i=1; i<=NF; i++)
            if (w[i] < length($i))
                w[i] = length($i)
    };
    END {
        for (i=1; i<=length(w); i++)
            printf w[i] "|"
    }' ${1} )

    CHARMAP=${CHARMAP-$(locale charmap)}

    awk -F\\t -v cols="${numcols}" -v widths="${colwidths}" -v charmap="${CHARMAP}" '
    BEGIN {
        split(widths, w, "|")

        if (charmap == "UTF-8")
        {
            hChar = "─"
            vChar = "│"

            clChar = "├"
            ccChar = "┼"
            crChar = "┤"

            tlChar = "┌"
            tcChar = "┬"
            trChar = "┐"

            blChar = "└"
            bcChar = "┴"
            brChar = "┘"
        } else
        {
            hChar = "-"
            vChar = "|"

            clChar = "|"
            ccChar = "+"
            crChar = "|"

            tlChar = "."
            tcChar = "."
            trChar = "."

            blChar = "'"'"'"
            bcChar = "'"'"'"
            brChar = "'"'"'"
        }

        printf tlChar
        for (i=1; i <= cols; i++)
        {
            for (j=1; j <= (w[i]+2); j++)
                printf hChar
            if (i == cols)
                printf trChar
            else
                printf tcChar
        }
        printf "\n"
    }
    {
        printf vChar
        for (i=1; i <= cols; i++)
        {
            printf " %" w[i] "s " vChar, $i
        }
        printf "\n"
    }
    NR == 1 {
        for (i=1; i <= cols; i++)
        {
            printf clChar
            for (i=1; i <= cols; i++)
            {
                for (j=1; j <= (w[i]+2); j++)
                    printf hChar
                if (i == cols)
                    printf crChar
                else
                    printf ccChar
            }
            printf "\n"
        }
    }
    END {
        printf blChar
        for (i=1; i <= cols; i++)
        {
            for (j=1; j <= (w[i]+2); j++)
                printf hChar
            if (i == cols)
                printf brChar
            else
                printf bcChar
        }
        printf "\n"
    }
    ' ${1}
}


############# FILE FORMAT PROCESSING #####################

## filters a tabular format blast output file to contain only the best hit (by 
## evalue) per query sequence. using to sort and uniq is too slow and error
## prone (bad handling of scientific format floats &c)
# blast_tabular2uniq_blast_tabular() # INPUT OUTPUT
# {
#     if [ $# -ne 2 ]; then
#         echo "ERROR: wrong number of args passed to uniq_hits_blast_tabular()"
#         exit 127
#     fi
#     awk -F\\t '
#     $0 ~ /^ *$/ { next };
#     $0 ~ /^ *#/ { print $0; next };
#     (e[$1] > $11) || (e[$1]==0) {
#         e[$1] = $11;
#         s[$1] = $0;
#     };
#     END {
#         for (i in s)
#             print s[i];
#     };' "$1" > "$2"
#     return $?
# }
#
# blast_flat2blast_tabular() # INPUT OUTPUT
# {
#     awk '
#     $1 == "Query=" {
#         qry = $2
#     };
#
#     substr($1,1,1) == ">" {
#         if (subj != "")
#             print qry "\t" subj "\t" pI "\t-1\t-1\t-1\t" qStart "\t" qEnd "\t" sStart "\t" sEnd "\t" eval "\t" bits;
#
#     subj = substr($1,2)
#     qStart = 0;
#     sStart = 0;
#     };
#
#     ($1 == "Score") {
#         bits = $3
#         eval = $8
#     };
#
#     ($1 == "Identities") {
#         pI = substr($4,2,length($4)-4)
#     };
#
#     ($1 == "Query:") {
#         if (qStart == 0)
#             qStart = $2
#         qEnd = $4
#     };
#
#     ($1 == "Sbjct:") {
#         if (sStart == 0)
#             sStart = $2
#         sEnd = $4
#     }; ' "$1" > "$2"
#     return $?
# }
#
#
# filter_blast_tabular_eval() # INPUT OUTPUT EVALUE
# {
#     awk -F\\t ' $11 < '$3 "$1" > "$2"
#     return $?
# }
#
# ## COUNTING FUNCTIONS
#
# total_hits_blast_tabular() # INPUT
# {
#     grep -v -E '(^$|^ *#)' -c "$1"
#     return $?
# }


# count_hits() # INPUT
# {
#     uniqQry=$(awk -F\\t '  
#     $0 ~ /^ *$/ { next };
#     $0 ~ /^ *#/ { next };
#     $1 != lastQry { uniqQry = uniqQry + 1; lastSubj = "INVALID" };
#     ($1 == lastQry) && ($2 != lastSubj) { uniqQrySubj = uniqQrySubj + 1 };
#     { total = total + 1; lastQry = $1; lastSubj = $2 };
#     END { print total "\t" uniqQry "\t" uniqQrySubj };' ${INPUT})
# }

median_evalue_blast_tabular() # INPUT
{
    median_index=$(($(total_hits_blast_tabular ${1}) / 2))
    grep -v -E '(^$|^ *#)' $1 | sort -g -k11 -t"	" \
        | awk -F\\t 'NR == '$median_index' { print $11; exit }'
    return $?
}

bit_score_quartiles() # INPUT
{
    q025_index=$(($(zcat "${1}" | wc -l) / 4))
    zcat "${1}" | sort -g -k12 -t"	" | \
        awk -F\\t '
NR == '$q025_index' { printf "\t" $12 };
NR == '$q025_index'*2 { printf "\t" $12 };
NR == '$q025_index'*3 { printf "\t" $12 ; exit };'
    return $?
}

median_pI() # INPUT
{
    median_index=$(($(wc -l < "${1}") / 2))
    sort -g -k3 -t"	" "${1}" | \
        awk -F\\t 'NR == '$median_index' { print $3; exit }'
    return $?
}

shared_results() # INPUT1 INPUT2
{
    (cat "$1"; echo "---DELIM---"; cat "$2") | awk -F\\t '
BEGIN {
    secondfile = 0
    sharedSimilar = 0
    sharedFirstBetter = 0
    sharedSecondBetter = 0
    uniqFirst = 0
    uniqSecond = 0

};

$1 == "---DELIM---" {
    secondfile = 1;
    next;
};

secondfile == 0 {
#     subjects[$1] = $2
    inFirst[$1 $2] = 1
    bits[$1 $2] = $12
    next
};

secondfile == 1 {
    if (bits[$1 $2] != 0) {
        if (($12 > (bits[$1 $2] - (bits[$1 $2] * 0.1))) && ($12 < (bits[$1 $2] + (bits[$1 $2] * 0.1) ))) {
            sharedSimilar = sharedSimilar + 1
        } else if ($12 > bits[$1 $2]) {
            sharedSecondBetter = sharedSecondBetter + 1
        } else {
            sharedFirstBetter = sharedFirstBetter + 1
        }
        inFirst[$1 $2] = 0
    } else {
        
        uniqSecond = uniqSecond + 1
    }
};


END {
    for (i in inFirst) {
        if (inFirst[i] != 0)
            uniqFirst = uniqFirst + 1
    }
    print sharedSimilar "\t" sharedFirstBetter "\t" sharedSecondBetter "\t" uniqFirst "\t" uniqSecond
};
'

}


############# HELPERS FOR LOADERS #####################


fill_up_whitespace()
{
    lenname=$(echo -n "$1" | wc -c)
    if [ $lenname -lt 34 ]; then
        for i in $(seq $lenname 1 36); do printf ' '; done
    else
        printf "  "
    fi
}


## common startup
common_pre()
{
    rm -r "${OUTDIR}/${MODPROF}" 2> /dev/null
    mkdir -p  "${OUTDIR}/${MODPROF}"   || return 1
    cd "${OUTDIR}/${MODPROF}"          || return 1
    return 0
}

## common postproc
common_post()
{
    # strip comments and newlines
    grep -v -E '(^$|^ *#)' "${OUTPUT}" > "${OUTPUT}.nocomment"
    # filter out evalues that are too large
#    awk -F\\t ' $11 < '${EVALUE} "${OUTPUT}.nocomment" > "${OUTPUT}.evaled"
    # filter out bitscore that are too small
    awk -F\\t ' $12 > '${MINBITS} "${OUTPUT}.nocomment" > "${OUTPUT}.evaled"
    # sort
    sort "${OUTPUT}.evaled" > "${OUTPUT}.all"
    # only best hit per query
    awk -F\\t '
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
};' "${OUTPUT}.all" > "${OUTPUT}.bestPerQry"

    # only best hit per qry-subj combination
    awk -F\\t '
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
};' "${OUTPUT}.all" > "${OUTPUT}.bestPerQrySubj"
    



#     if [ ${MODE} -eq 2 ]; then
#         blast_tabular2uniq_blast_tabular "${OUTPUT}" "${OUTPUT}.uniq"
#         OUTPUT=${OUTPUT}.uniq
#     fi
    return $?
}
