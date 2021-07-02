#!/bin/bash
#set -x

if [ -z "$1" ]
then
	echo "ERROR: Missing IP to check"
	exit 3
else
	IP="$1"
fi

nconntypes=$(netstat -a | egrep "$1" | awk '{ print $(NF); }' | sort | uniq -c | awk '{ printf $2"@"$1"\n"; }')
#echo -e "\nConns to $IP\n\n$nconntypes\n"

LISTEN=0
TIME_WAIT=0
ESTABLISHED=0
FIN_WAIT2=0
OTHERS=0

TOTAL=0

for line in ${nconntypes}
do
	type=$(echo $line | awk -F'@' '{ printf $1; }')	
	num=$(echo $line | awk -F'@' '{ printf $2; }')	
	#echo -e "\nType: $type   Num: $num\n"

	let TOTAL=$TOTAL+$num

	if  [ "$type" == "TIME_WAIT" ]
	then
		TIME_WAIT=$num

	elif  [ "$type" == "ESTABLISHED" ]
	then
		ESTABLISHED=$num

	elif  [ "$type" == "FIN_WAIT2" ]
	then
		FIN_WAIT2=$num

	else
		OTHERS=$num
	fi
done

echo "OK - Connections to $IP (Total: $TOTAL) | ESTABLISHED=$ESTABLISHED TIME_WAIT=$TIME_WAIT FIN_WAIT2=$FIN_WAIT2 OTHERS=$OTHERS"
exit 0
