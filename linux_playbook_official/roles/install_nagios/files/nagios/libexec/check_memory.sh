#!/bin/bash
#set -x

warn="$1"
crit="$2"

[ -z "$warn" ] && { typeset -i warn=90; }
[ -z "$crit" ] && { typeset -i crit=95; }

mem_usage=$(free | grep ^Mem: | awk '{ printf "%.2f\n",$3/$2*100; }')
#mem_usage=$(echo $mem_usage | sed -e 's/\./,/')

if [ -z "$mem_usage" ]
then
	echo "UNKNOWN - Could not gather memory usage"
	exit 3
fi

if [ ! -z "$(echo "$mem_usage $crit" | awk '{ if($1 > $2) { print "TRUE"; } }')" ]
then
	echo "CRITICAL - Memory Usage at $mem_usage% | Memory=$mem_usage%;$warn;$crit"
	exit 2

elif [ ! -z "$(echo "$mem_usage $warn" | awk '{ if($1 > $2) { print "TRUE"; } }')" ]
then
	echo "WARNING - Memory Usage at $mem_usage% | Memory=$mem_usage%;$warn;$crit"
	exit 1

else
	echo "OK - Memory Usage at $mem_usage% | Memory=$mem_usage%;$warn;$crit"
	exit 0
fi
