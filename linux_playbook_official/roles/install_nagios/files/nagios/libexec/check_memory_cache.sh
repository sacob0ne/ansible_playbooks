#!/bin/bash
#set -x

warn="$1"
crit="$2"

[ -z "$warn" ] && { typeset -i warn=90; }
[ -z "$crit" ] && { typeset -i crit=95; }

mem_usage=$(free | grep ^Mem: | awk '{ printf "%.2f\n",(($4+$7)*100)/$2; }')

if [ -z "$mem_usage" ]
then
	echo "UNKNOWN - Could not gather cached memory usage"
	exit 3
fi

if [ ! -z "$(echo "$mem_usage $crit" | awk '{ if($1 > $2) { print "TRUE"; } }')" ]
then
	#echo "CRITICAL - Cached Memory Usage at $mem_usage% | 'Chached Memory'=$mem_usage%"
	echo "CRITICAL - Cached Memory Usage at $mem_usage% | Chache=$mem_usage%"
	exit 2

elif [ ! -z "$(echo "$mem_usage $warn" | awk '{ if($1 > $2) { print "TRUE"; } }')" ]
then
	#echo "WARNING - Cached Memory Usage at $mem_usage% | 'Cached Memory'=$mem_usage%"
	echo "WARNING - Cached Memory Usage at $mem_usage% | Cache=$mem_usage%"
	exit 1

else
	#echo "OK - Cached Memory Usage at $mem_usage% | 'Cached Memory'=$mem_usage%"
	echo "OK - Cached Memory Usage at $mem_usage% | Cache=$mem_usage%"
	exit 0
fi
