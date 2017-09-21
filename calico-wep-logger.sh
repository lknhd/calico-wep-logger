#!/bin/bash

set -o nounset
set -o pipefail

function get_weps {
  # get workloadendpoints, always retry unless success
  while true;
  do
    calicoctl get wep -o wide | grep -v WORKLOAD | sed '/^\s*$/d' 2>/dev/null && break
  done
}
function get_node {
  awk '{print $1}'
}
function get_workload {
  awk '{print $3}'
}
function get_addr {
  awk '{print $5}'
}

function wep_created {
  while true; do
    get_weps | while IFS= read -r wep
    do
      if ! ls "${tmpFolder}/${FUNCNAME[0]}_0" > /dev/null 2>&1; then
        touch "${tmpFolder}/${FUNCNAME[0]}_0"
      fi
      output=""
      output=$(grep $(echo ${wep} | get_workload) ${tmpFolder}/${FUNCNAME[0]}_0)
      if [[ $output == "" ]]; then
        echo "found new wep: $(echo ${wep} | get_workload)"
        echo "$(date --iso-8601=seconds) workload=$(echo ${wep} | get_workload) addr=$(echo ${wep} | get_addr) created on node $(echo ${wep} | get_node)" >> ${wepLogFile}
      fi
    done
    get_weps > ${tmpFolder}/${FUNCNAME[0]}_0
  done
}

function wep_released {
  while true; do
    get_weps > ${tmpFolder}/${FUNCNAME[0]}_1
    cat ${tmpFolder}/${FUNCNAME[0]}_0 | while IFS= read -r wep
    do
      if ! ls "${tmpFolder}/${FUNCNAME[0]}_0" > /dev/null 2>&1; then
        get_weps > "${tmpFolder}/${FUNCNAME[0]}_0"
      fi
      output=""
      output=$(grep $(echo ${wep} | get_workload) ${tmpFolder}/${FUNCNAME[0]}_1)
      if [[ $output == "" ]]; then
        echo "found deleted wep: $(echo ${wep} | get_workload)"
        echo "$(date --iso-8601=seconds) workload=$(echo ${wep} | get_workload) addr=$(echo ${wep} | get_addr) released from node $(echo ${wep} | get_node)" >> ${wepLogFile}
      fi
    done
    mv ${tmpFolder}/${FUNCNAME[0]}_1 ${tmpFolder}/${FUNCNAME[0]}_0
  done
}
############ main function ###############
#if [[ "$#" -ne 1 ]]; then
#  echo "Usage: calico-wep-logger.sh <created/released>"
#  exit 1
#fi
tmpFolder=/tmp
wepLogFile=/var/log/calico-wep.log
if [[ $# -eq 0 ]] ; then
    event="default"
  else
    event=$1
fi
if [[ "${event}" == "default" ]]; then
  wep_created & wep_released
elif [[ "${event}" == "created" ]]; then
  wep_created
elif [[ "${event}" == "released" ]]; then
  wep_released
else
  echo "Not supported."
fi
