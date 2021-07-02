#!/bin/bash
#set -x
# Check Memory Linux
# History
# Date    |   Authors   | Description
# --------+-------------+--------------------------------------------------
# 07/02/17| PADO        | Initial release
# 08/02/17| PADO        | Edit Output line as CMDB request
#         |             | 
#         |             |
#***************************************************************************

warn="$1"
crit="$2"

[ -z "$warn" ] && { typeset -i warn=90; }
[ -z "$crit" ] && { typeset -i crit=95; }

mem_usage_percent=$(free | grep ^Mem: | awk '{ printf "%.2f\n",(($3*100)/$2); }')
cached_percent=$(free | grep ^Mem: | awk '{ printf "%.2f\n",($7*100)/$2; }')
free_mem_percent=$(free | grep ^Mem: | awk '{ printf "%.2f\n",((($2-$3)*100)/$2); }')
total_mem=$(free -m | grep ^Mem: | awk '{ printf +$2}')
used_mem=$(free -m | grep ^Mem: | awk '{ printf +$3}')
cached_mem=$(free -m | grep ^Mem: | awk '{ printf +$6}')
free_mem=$(expr $total_mem - $used_mem)


if [ -z "$mem_usage_percent" ]
then
	echo "UNKNOWN - Could not gather memory usage percentage"
	exit 3
fi

if [ ! -z "$(echo "$mem_usage_percent $crit" | awk '{ if($1 > $2) { print "TRUE"; } }')" ]
then
	echo "CRITICAL Memory: Total=${total_mem}MB - Used=${used_mem}MB ($mem_usage_percent%) - Cached=${cached_mem}MB ($cached_percent%) - Free=${free_mem}MB ($free_mem_percent%) | 'Memory used %'=$mem_usage_percent%;$warn;$crit;0;100 'Cached %'=$cached_percent%;;;; 'Memory used MB'=${used_mem}MB;;;0;$total_mem" 
	exit 2

elif [ ! -z "$(echo "$mem_usage_percent $warn" | awk '{ if($1 > $2) { print "TRUE"; } }')" ]
then
	echo "WARNING Memory: Total=${total_mem}MB - Used=${used_mem}MB ($mem_usage_percent%) - Cached=${cached_mem}MB ($cached_percent%) - Free=${free_mem}MB ($free_mem_percent%) | 'Memory used %'=$mem_usage_percent%;$warn;$crit;0;100 'Cached %'=$cached_percent%;;;; 'Memory used MB'=${used_mem}MB;;;0;$total_mem" 
	exit 1

else
	echo "Memory OK: Total=${total_mem}MB - Used=${used_mem}MB ($mem_usage_percent%) - Cached=${cached_mem}MB ($cached_percent%) - Free=${free_mem}MB ($free_mem_percent%) | 'Memory used %'=$mem_usage_percent%;$warn;$crit;0;100 'Cached %'=$cached_percent%;;;; 'Memory used MB'=${used_mem}MB;;;0;$total_mem" 
	exit 0
fi