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


#defines a function wrapper() that expects a command and a log file as parameters



case $(uname -s) in
    "Linux")
        if [ ${RECURSIVE_TRACK:+x} ]; then

            ## get child processes recursively
            getChildren()
            {
                echo $1
                pgrep -P $1 | while read -r line; do getChildren $line; done
                return $?
            }
            wrapper()
            {
                ##TODO still something wrong with this one
                [ $# -eq 2 ] || return $(echo $? && echo "ERROR: Wrong number or args to wrapper (two expected)." > /dev/stderr)
                time=$(date +%s)

                CMD="$1 2>&1 > $2 &"

            #     echo $CMD

                eval $CMD
                mPID=$!
                ram=0

                # echo "mPID = $mPID" >/dev/stderr
                while [ -d /proc/$mPID ]; do
                    sumRAM=$(getChildren $mPID | while read -r line; \
                do awk ' $1 == "VmRSS:" { print $2; exit }' "/proc/$line/status" 2>/dev/null;\
                done | awk '{ SUM = SUM + $1 }; END { print SUM };')
                    ram=$(max $ram $sumRAM)
                #     echo "ram = $ram  sumRAM = $sumRAM"
                    sleep 0.3
                done
                ram=$((ram / 1024))
                time=$((`date +%s`-time))

#                 echo $ram
#                 echo $t
            }
        else
            wrapper()
            {
                [ $# -eq 2 ] || return $(echo $? && echo "ERROR: Wrong number or args to wrapper (two expected)." > /dev/stderr)

                # prefix with command to get ram
                CMD="/usr/bin/time --quiet -f '%M'  -o \"${TMPDIR}/_time\" $1 > $2 2>&1"
                ram=0
                time=$(date +%s)

                set +e
                eval $CMD
                _retval=$?
                set -e

                time=$(($(date +%s)-time))

                # ram is in kilobytes, transform to megabyts
                ram=$(($(cat "${TMPDIR}/_time") / 1024))
                : ${ram:=0} # ensure numeric value
                rm "${TMPDIR}/_time"

#                 echo $ram
#                 echo $t
                return $_retval
            }
        fi
        ;;
    "FreeBSD" | "Darwin")
        wrapper()
        {
            [ $# -eq 2 ] || return $(echo $? && echo "ERROR: Wrong number or args to wrapper (two expected)." > /dev/stderr)

            # prefix with command to get ram
            CMD="{ /usr/bin/time -l $1 2>&1; echo "'$?'" > ${TMPDIR}/_retval ; } | tee $2 | tail -n 20 > ${TMPDIR}/_time"
            ram=0
            time=$(date +%s)

            set +e
            eval $CMD
            set -e

            time=$(($(date +%s)-time))

            # ram is in kilobytes, transform to megabyts
            ram=$(($(grep "maximum resident set size" "${TMPDIR}/_time" | awk '{print $1}') / 1024))
            : ${ram:=0} # ensure numeric value
            rm "${TMPDIR}/_time"

#             echo $ram
#             echo $t
            return $(cat "${TMPDIR}/_retval" && rm "${TMPDIR}/_retval")
        }
        ;;
    *)
        # for unknown OS, just track time
        wrapper()
        {
            CMD="$1 2>&1 > $2"
            ram=0
            time=$(date +%s)

            eval $CMD

            time=$(($(date +%s)-time))

#             echo $time
#             echo 0
        }
esac
