#!/bin/bash

declare -a OPENSTACK_ARR
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -oi | -opip)
      OPENSTACK_IP=$2
      shift 2
      ;;
  esac
done

COUNTER=0
for WORD in $(echo $OPENSTACK_IP | sed -n 1'p' | tr ',' '\n')
do 
OPENSTACK_ARR[$COUNTER]=$WORD
COUNTER=$(($COUNTER+1))
done
echo ${OPENSTACK_ARR[0]}
i=0
while [ "$i" -lt "${#OPENSTACK_ARR[@]}" ]; 
do
  ssh comlab@${OPENSTACK_ARR[i]} << EOF
    rm -rf CloudConnectivity
    git clone https://github.com/thimiosgr/CloudConnectivity.git
    cd CloudConnectivity/CloudConnectivity
    ./cloudconnectivity.sh -def
EOF
i=$((i+1))
done