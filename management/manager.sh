#!/bin/bash

# This is a script that allow a remote host to execute the CloudConnectivity's scripts on one or more Openstack Clouds.

echo "The correct way of providing the Openstack IP's is by using only commas, dots and numbers. Example: 192.168.1.10,192.168.1.20"
declare -a OPENSTACK_ARR
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -ips | -opips)
      OPENSTACK_IP=$2
      shift 2
      ;;
    -h | -help)
      COUNTER=1
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
  esac
done

if ! [[ -z ${COUNTER} ]]; then
  echo "This is a script that runs CloudConnectivity on multiple Openstack clouds."
  echo "The user options are:"
  printf "\t\033[0;33m-ips\033[0m, \033[0;33m-opips\033[0m   :  The IP's of the machines that run the Openstack cloud. The IP's must be separated by commas. Example: 192.168.1.10,192.168.1.20\n"
  printf "\t\033[0;33m-h\033[0m, \033[0;33m-help\033[0m      :  Shows all the available script options.\n"
  printf "To get passwordless SSH connection while running this script, you must add this host's key to the authorizes_keys file on ever machine running Openstack.\n"
  exit 1
fi

# Regular expression to check if IP's given by user are correct.
IP_RE="^(([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5]){1}$"

# Checking if the IP's given by user have the correct format.
COUNTER=0
for WORD in $(echo $OPENSTACK_IP | sed -n 1'p' | tr ',' '\n')
do 
  if ! [[ ${WORD} =~ ${IP_RE} ]]; then
    printf "\033[0;31mOne of the Openstack IP's you provided is not correct\033[0m\n"
    exit 1
  fi
  OPENSTACK_ARR[$COUNTER]=$WORD
  COUNTER=$(($COUNTER+1))
done

COUNTER=0
while [ "$COUNTER" -lt "${#OPENSTACK_ARR[@]}" ]; 
do
  ssh comlab@${OPENSTACK_ARR[COUNTER]} > /dev/null 2>&1 << EOF
    rm -rf CloudConnectivity
    git clone https://github.com/thimiosgr/CloudConnectivity.git
    ./CloudConnectivity/packerfiles/cloudconnectivity.sh -def
EOF
COUNTER=$((COUNTER+1))
done