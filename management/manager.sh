#!/bin/bash

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
      COUNTER=1
      break
      ;;
  esac
done

if ! [[ -z ${COUNTER} ]]; then
  echo "This is a script that runs CloudConnectivity on multiple Openstack clouds."
  echo "The user options are:"
  printf "\t\033[0;33m-ips\033[0m, \033[0;33m-opips\033[0m   :  The IP's of the machines that run the Openstack cloud. The IP's must be separated by commas. Example: 192.168.1.10,192.168.1.20\n"
  printf "\t\033[0;33m-h\033[0m, \033[0;33m-help\033[0m      :  Shows all the available script options.\n"
  exit 1
fi

# Regular expression to check if IP's given by user are correct.
IP_RE="^(([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])+$"
# READ_RE="^([0-9]\.\,)*"
# if ! [[ -z $1 ]]
# then
#     printf "\033[0;31mYou provided the IP's in the wrong way. You must only use commas, dots and numbers.\033[0m\n"
#     echo "Example: 192.168.1.10,192.168.1.20"
#     exit 1
# fi

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
