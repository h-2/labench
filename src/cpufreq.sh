#!/bin/sh

set +e

RET=1

if [ "$(uname -s)" = "Linux" ]; then
    RET=0
    sudo -n cpufreq-info -l >/dev/null 2>&1
    # cpufreq-info -l >/dev/null 2>&1
    [ $? -eq 0 ] && echo "No sudo rights for cpufreq-tools or cpufreq-tools not available :(" && RET=1
    GOVERNORS=$(cpufreq-info -g)
    [ "${GOVERNORS#*userspace}" = "${GOVERNORS}" ] && echo "No userspace cpu governor available :(" && RET=1
fi

if [ $RET -eq 0 ]; then # there were no problems
    setCpuFreqFixed()
    {
        if [ $# -eq 1 ]; then
            MAXCPU=$1
        else
            # get maximal non-turbo frequency
            MAXCPU=$(cpufreq-info -s | sed -e 's/000\:[0-9]*\,//g' | awk '{print $1}')
            MAX2CPU=$(cpufreq-info -s | sed -e 's/000\:[0-9]*\,//g' | awk '{print $2}')
            # highest frequency is second highest frequency + 1
            if [ $(($MAXCPU + 1)) -eq $MAX2CPU ]; then
                # MAXCPU is actually indicator for Turbo-frequency which we DONT want
                MAXCPU=$MAX2CPU
            fi
        fi

        echo "Fixing all CPUs to ${MAXCPU}Mhz"

        for i in $(awk ' $1 == "processor" { print $3}' /proc/cpuinfo); do
            sudo /usr/bin/cpufreq-set -g userspace -c $i
            [ $? -ne 0 ] && echo "Failed to set userspace gov on CPU${i}" > /dev/stderr
            sudo /usr/bin/cpufreq-set -f ${MAXCPU}000 -c $i
            [ $? -ne 0 ] && echo "Failed to set clock on CPU${i}" > /dev/stderr
        done
    }

    setCpuFreqOnDemand()
    {
        for i in $(awk ' $1 == "processor" { print $3}' /proc/cpuinfo); do
            sudo /usr/bin/cpufreq-set -g ondemand -c $i
            [ $? -ne 0 ] && echo "Failed to set ondemand gov on CPU${i}" > /dev/stderr
        done
    }
else
    setCpuFreqFixed() { }
    setCpuFreqOnDemand() { }
fi

set -e
