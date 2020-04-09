#!/bin/bash

# Give permissions to the JSON and Service file.
sudo chmod 666 imagebuild.json connectivity.service

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -opip)
      OPENSTACK_IP=$2
      shift 2
      ;;
    -vpnip)
      VPN_IP=$2 
      shift 2
      ;;
    -image)
      IMAGE_NAME=$2
      shift 2
      ;;
    -network)
      NETWORK_NAME=$2
      shift 2
      ;;
    -help)
      COUNTER=1
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="${PARAMS} $1"
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "${PARAMS}"

if ! [[ -z $COUNTER ]]; then
  echo "Script options:"
  echo "  -opip : The IP of the machine that runs the Openstack cloud."
  echo "  -vpnip : The IP of the machine that runs the OpenVPN server."
  echo "  -image : The name of the image that will be used as source for the new image."
  echo "  -network : The name of the network on which the test server will be connected to."
  echo "  -help : Show all tha available script options."
  exit 1
fi

# Checking if command-line JSON processor jq is installed.
if ! dpkg -s jq >/dev/null 2>&1; then
    echo "Installing jq."
    sudo apt-get install jq -y
    printf "\033[0;32mInstalled jq.\033[0m\n"
else
    echo "Jq is already installed. Not installing."
fi

# Checking if moreutils package is installed.
if ! dpkg -s moreutils >/dev/null 2>&1; then
    echo "Installing moreutils."
    sudo apt-get install moreutils -y
    printf "\033[0;32mInstalled moreutils\033[0m\n"
else
    echo  "Package moreutils is already instaled. Not installing."
fi

# Regular expression to check if IP's given by user are correct.
IP_RE="^(([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])+$"

if ! [[ ${OPENSTACK_IP} =~ ${IP_RE} ]]; then
  printf "\033[0;31mThe Openstack IP is not correct\033[0m\n"
  exit 1
fi

if ! [[ ${VPN_IP} =~ ${IP_RE} ]]; then
  printf "\033[0;31mThe VPN server's IP is not correct.\033[0m\n"
  exit 1
fi

IMAGE_ID=$(openstack image list | grep ${IMAGE_NAME} | awk '{print $2}' -)
NETWORK_ID=$(openstack network list | grep ${NETWORK_NAME} | awk '{print $2}' -)

if [[ -z "${IMAGE_ID}" ]]; then
  printf "\033[0;31mThe image name you provided is not correct.\033[0m\n"
  exit 1
fi

if [[ -z "${NETWORK_ID}" ]]; then
  printf "\033[0;31mThe network name you provided is not correct.\033[0m\n"
  exit 1
fi

IDENTITY="http://${OPENSTACK_IP}/identity"
jq --arg v "${IDENTITY}" '.builders[].identity_endpoint = $v' imagebuild.json|sponge imagebuild.json
jq --arg v "${IMAGE_ID}" '.builders[].source_image = $v' imagebuild.json|sponge imagebuild.json
jq --arg v "${NETWORK_ID}" '.builders[].networks[] = $v' imagebuild.json|sponge imagebuild.json

THE_PATH=$('pwd')
BOOT_SCRIPT="${THE_PATH}/bootscript.sh"
jq --arg v "$BOOT_SCRIPT" '.provisioners[0].source = $v' imagebuild.json|sponge imagebuild.json

SERVICE="${THE_PATH}/connectivity.service"
jq --arg v "$SERVICE" '.provisioners[1].source = $v' imagebuild.json|sponge imagebuild.json

sed -i '5s/.*/VPN_IP='"$VPN_IP"'/' bootscript.sh

echo "Building image... This might take some minutes, depending on your hardware and your Internet connection."
packer build imagebuild.json > /dev/null 2>&1
printf "\033[0;32mCreated image: packerimage.\n\033[0mRun 'openstack image list' for confirmation.\n"

printf "\nCreating server for testing...\n"
openstack server create --image packerimage --flavor m1.heat_int --key-name KEYPAIR --user-data ${THE_PATH}/user-data.txt --network ${NETWORK_ID} testingserver
printf "\n\033[0;32mCreated server 'testingserver'.\033[0m\nRun 'openstack server list' for confirmation.\n"
