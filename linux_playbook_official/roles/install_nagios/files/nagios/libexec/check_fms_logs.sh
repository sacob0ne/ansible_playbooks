#!/bin/sh

#logs="/sw/apache2.2/logs/error_log.*"
logs="/work/apps/apache/logs/error_log.*"

FoundError="false"

bseconds=3600

ets=$(date +%s)
ets=$(echo ${ets}-${bseconds} | bc -l)

#echo "Checking ... ${ets} = $(date -d @${ets})"

let errs=0
for file in ${logs}
do
	#echo "checking logfile: $file"
	IFS=$'\n'
	for err in $(egrep IOError: ${file})
	do
		time=$(echo ${err} | sed -e 's/\] .*$//' -e 's/\[//')
		etime=$(date -d "${time}" +%s)
		#echo "Time: $time = $etime VS $ets"
		if [ $etime -gt $ets ]
		then
			FoundError="true"
			let errs=$((errs+1))
			#echo "Error: ($time) $err"
		fi
	done
	unset IFS
done

if [ "${FoundError}" == "true" ]
then
	echo "CRITICAL - Found Error(s): 'IOError: failed to write data' (Num. Errors: $errs)"
	exit 1
else
	echo "OK - No Errors Found"
	exit 0
fi

