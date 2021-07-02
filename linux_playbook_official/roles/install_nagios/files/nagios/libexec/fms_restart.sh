#!/usr/bin/sh
#
#	ReStart a FMS Component
#
#	ARGS:	httpd (Apache)
#		jasper_gateway	
#		redis-server	
#

#exec >/usr/local/nagios/libexec/logs/fms_restart.log 2>&1

if [ -z "$1" ]
then
	echo "CRITICAL: Missing Parameter: Component to re-start"
	exit 2

elif [ "$1" == "httpd" -o "$1" == "jasper_gateway" -o "$1" == "redis-server" ]
then
	Component="$1"

else
	echo "CRITICAL: Component '$1' Not Supported"
	exit 2
fi

if [ "`id -u -n`" != "httpadm" ]
then
	echo "CRITICAL: Wrong User '`id -u -n`' Not Supported, use 'httpadm'"
	exit 2
fi

if [ "${Component}" == "httpd" ]
then
	PSstr='httpd -k start'
	STARTcmd="/sw/apache2.2/bin/apachectl -k start"

elif [ "${Component}" == "jasper_gateway" ]
then
	PSstr='it.fbit.py4j.JasperReportEntryPoint'
	STARTcmd="/sw/py4j_jasper_gateway/bin/runGateway.sh"

elif [ "${Component}" == "redis-server" ]
then
	PSstr='/sw/redis-2.4.15/bin/redis-server /sw/redis-2.4.15/redis.conf'
	STARTcmd="/sw/redis-2.4.15/bin/redis-server /sw/redis-2.4.15/redis.conf"
fi

log="/usr/local/nagios/libexec/logs/${Component}.restart.`date '+%Y%m%d_%H%M%S'`.log"

echo -e "`date '+%Y%m%d_%H:%M:%S'`\tReStart Launched on '${Component}'" 		 >${log}

if [ ! -z "`ps -ef | egrep httpd | egrep /sw/apache2.2/conf/maint_httpd.conf | egrep -v grep`" ]
then
	echo -e "`date '+%Y%m%d_%H:%M:%S'`\tApache in Maintenance Mode, Abort !!!"	>>$log}
	echo "CRITICAL: Apache in Maintenance Mode, ABORT !!!"		
	exit 2
fi

echo -e "`date '+%Y%m%d_%H:%M:%S'`\tis ${Component} Running ? .... checking ..."	>>${log}
echo -e "`date '+%Y%m%d_%H:%M:%S'`\tPSstr: ${PSstr}"					>>${log}
echo -e "`date '+%Y%m%d_%H:%M:%S'`\tPS CMD: 'ps -ef | egrep ${PSstr} | egrep -v grep'"	>>${log}
ps -ef | egrep "${PSstr}" | egrep -v grep						>>${log} 2>&1
if [ -z "`ps -ef | egrep "${PSstr}" | egrep -v grep`" ]
then

	echo -e "`date '+%Y%m%d_%H:%M:%S'`\tyes, NOT Running ... exe Start ..."		>>${log}
	${STARTcmd}									>>${log} 2>&1
	if [ $? != 0 ]
	then
		echo -e "`date '+%Y%m%d_%H:%M:%S'`\tStart Failed"			>>${log}
		echo "CRITICAL: Start FAILED for '${Component}'"		
		exit 2
	fi
	echo -e "`date '+%Y%m%d_%H:%M:%S'`\tSuccesfully Started '${Component}'"		>>${log}
	exit 0
else
	echo -e "`date '+%Y%m%d_%H:%M:%S'`\t'${Component}' Seems Already Running"	>>${log}
	ps -ef | egrep "${PSstr}" | egrep -v grep					>>${log} 2>&1
	#echo -e "`date '+%Y%m%d_%H:%M:%S'`\tAborting Start"				>>${log}
	echo "CRITICAL: ${Component} Already Running"
	exit 2
fi
