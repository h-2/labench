#!/bin/sh

## USAGE: ./wrapper.sh 'my_command --with-args foobar possible>redirect' 4>&1

## * the command will be run as usual
## * stdout and stderr are preserved (and can be redirected as part of the
##   command invocation)
## * repeatedly the sum of the resident set memory usage of the spawned process
##   and all its children is computed and the maximum over these sums is saved
## * the total time and this memory sum are printed to FD4,
##   after the program terminates
## * FD4 needs to be redirected, e.g. to stdout or an extra file

## maximum of two values. also works if one value is blank (i.e. only one arg)
# max()
# {
#     if ( [ $# -eq 1 ] || [ $1 -gt $2 ] ); then
#         echo $1
#         return $1;
#     fi
#     echo $2
#     return $2;
# }

## get child processes recursively
getChildren()
{
    echo $1
    pgrep -P $1 | while read -r line; do getChildren $line; done
    return $?
}

wrapper()
{
    t=`date +%s`

    CMD="$1 &"

#     echo $CMD

    eval $CMD
    mPID=$!
    maxRAM=0

    # echo "mPID = $mPID" >/dev/stderr
    if [ $(uname -s) = "Linux" ]; then
        while [ -d /proc/$mPID ]; do
            sumRAM=$(getChildren $mPID | while read -r line; \
        do awk ' $1 == "VmRSS:" { print $2; exit }' "/proc/$line/status" 2>/dev/null;\
        done | awk '{ SUM = SUM + $1 }; END { print SUM };')
            maxRAM=$(max $maxRAM $sumRAM)
        #     echo "maxRAM = $maxRAM  sumRAM = $sumRAM"
            sleep 0.3
        done
    else
        wait $mPID
    fi

    t=$((`date +%s`-t))

    echo $maxRAM >&4
    echo $t >&4
}
