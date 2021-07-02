#!/bin/bash
#set -x

if [ -z "$1" ]
then
	echo "ERROR: Missing process"
	exit 3
else
	PROC="$1"
fi

pfd=$(ps -e -o comm,pcpu,pmem,nlwp | egrep ^$PROC)

procs=$(ps -e -o comm,pcpu,pmem,nlwp | egrep ^$PROC | wc -l | awk '{printf $1}')

tmp=$(echo "$pfd" | awk '{printf $2"+";}' | sed -e 's/+$//') 
cpu=$(echo $tmp | bc | awk '{printf "%.1f",$0; }')

tmp=$(echo "$pfd" | awk '{printf $4"+";}' | sed -e 's/+$//')
threads=$(echo $tmp | bc)

tmp=$(echo "$pfd" | awk '{printf $3"+";}' | sed -e 's/+$//')
mem=$(echo $tmp | bc | awk '{printf "%.1f",$0; }')

if [ ! -z "$pfd" ]
then
	echo "OK - $PROC | CPU=$cpu% MEM=$mem% PROCS=${procs} THREADS=${threads}"
	exit 0
else
	echo "WARNING - Could not gather performance data for $PROC"
	exit 1
fi
