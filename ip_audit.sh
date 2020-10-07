#!/bin/bash
# Script written for GTSx Linux Engineering Exercise. 
# Takes list of hosts as STDIN (flatfile)
# Make sure able to connect to SSH PORT 22. otherwise skips (possible maint|FW) issue. 
# Script assumes host has opensource tool "ipcalc" installed which is available also for python.

display_usage() {
echo '====================================================='
echo 'Usage: ip_audit.sh [hostlist]'
echo '-----------------------------------------------------'
echo 'Example: ip_audit.sh hosts.txt'
    }

if [  $# -le 0 ] || [  $# -lt 1 ] ||[[ ( $# == "--help") ||  $# == "-h" ]]
    then
        display_usage
        exit 1
    fi

HOSTLIST=$1
SSHCMD=(/usr/bin/ssh -o 'StrictHostKeyChecking no')
LOG=out.IP_NET_Audit.`date +%Y-%m-%d`.log
FLOG=out.FINAL_REPORT.`date +%Y-%m-%d`.log

cat ${HOSTLIST}|while read host
do
    nc -z -w 3 ${host} 22 2>/dev/null > /dev/null
    if [[ $? -eq 0 ]]; then
      echo "IP and Network scan on ${host} "| tee -a ${$LOG}
      IFC=$(ssh -o 'StrictHostKeyChecking=no' -n root@${host} " ip -o ad |/usr/bin/egrep -vwi 'lo|inet6'| awk '{print \$2}'")
      for interface in ${IFC}
      do
          IPA=$(ssh -o 'StrictHostKeyChecking=no' -n root@${host} "ip -o ad |grep ${interface}|grep -vw inet6|awk '{print \$4}'")
          IFCNET=$(ssh -o 'StrictHostKeyChecking=no' -n root@${host} " /tmp/ipcalc -n ${IPA}|grep Network:|awk '{print \$2}'")
          IFCNET_LOG=out.IPS_`echo "${IFCNET}"|sed  's/\//_/g'`
          echo ${host} "," `echo ${IPA}|cut -d '/' -f 1` |tee -a ${IFCNET_LOG}
      echo ${host} ${interface} ${IPA} ${IFCNET} |tee -a ${LOG}
      done
    else
      echo -e "ISSUE w/ ${host} Skipping" | tee -a ${LOG}
    fi
done
for i in `ls  out.IPS_*`
do
  LOWEST_IP=$(cat ${i} |sort -t . -k 3,3n -k 4,4n|head -1 )
  NET=$(echo ${i}|cut -c9-32|sed 's/_/\//')
  echo  "${LOWEST_IP}" "${NET}" |tee -a ${FLOG}
done
