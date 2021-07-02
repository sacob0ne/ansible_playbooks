#!/bin/sh
#set -x

if [ $# -ne 2 ]
then
        echo "UNKNOWN - Missing Parameters: <WARNING %> <CRITICAL %>"
        exit 3
fi

Critical=$2
Warning=$1
python /usr/local/nagios/libexec/check_cpu.py -W ${Warning} -C ${Critical} 2>&1
