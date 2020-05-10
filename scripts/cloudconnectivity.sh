#!/bin/bash

# Give permissions to the JSON and Service file.
chmod 666 imagebuild.json
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -oi | -opip)
      OPENSTACK_IP=$2
      shift 2
      ;;
    -vi | -vpnip)
      VPN_IP=$2 
      shift 2
      ;;
    -i | -image)
      IMAGE_NAME=$2
      shift 2
      ;;
    -xn | -xnet)
      EXTERNAL_NETWORK=$2
      shift 2
      ;;
    -in | -inet)
      INTERNAL_NETWORK=$2
      shift 2
      ;;
    -p | -password)
      PASSWD=$2
      shift 2
      ;;
    -f | -filename)
      FILENAME=$2
      shift 2
      ;;
    -def | -default)
      IP=$(ifconfig | grep "150.140.186.127" | awk '{print $2}' -)
      if [[ $IP == "150.140.186.115" ]]; then
        source openstack1.sh
      else
        source openstack2.sh
      fi
      break
      ;;
    -h | -help)
      COUNTER=1
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      COUNTER=1
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="${PARAMS} $1"
      shift
      ;;
  esac
done

if ! [[ -z ${COUNTER} ]]; then
  echo "This is a script that provides Layer 2 connectivity between instances of two different Openstack clouds."
  echo "You have to copy the file with the Openstack credentials in the CloudConnectivity/Cloudconnectivity folder and name it admin-openrc.sh."
  echo "The user options are:"
  printf "\t\033[0;33m-oi\033[0m, \033[0;33m-opip\033[0m      :  The IP of the machine that runs the Openstack cloud.\n"
  printf "\t\033[0;33m-vi\033[0m, \033[0;33m-vpnip\033[0m     :  The IP of the machine that runs the OpenVPN server.\n"
  printf "\t\033[0;33m-i\033[0m, \033[0;33m-image\033[0m      :  The name of the image that will be used as source for the new image.\n"
  printf "\t\033[0;33m-xn\033[0m, \033[0;33m-xnet\033[0m      :  The name of the external network on which the OVS machine will be connected to.\n"
  printf "\t\033[0;33m-in\033[0m, \033[0;33m-inet\033[0m      :  The name of the internal network on which the OVS machine and the rest instances will be connected to.\n"
  printf "\t\033[0;33m-p\033[0m, \033[0;33m-password\033[0m   :  The password of the Openstack cloud.\n"
  printf "\t\033[0;33m-f\033[0m, \033[0;33m-filename\033[0m   :  The name of the VPN files that every instance must fetch.\n"
  printf "\t\033[0;33m-def\033[0m, \033[0;33m-default\033[0m  :  Run script with the default values.\n"
  printf "\t\033[0;33m-h\033[0m, \033[0;33m-help\033[0m       :  Shows all the available script options.\n"
  exit 1
fi

if [[ -z "$OPENSTACK_IP" ]]; then
  printf "\033[0;31mYou have not provided an Openstack IP. Use -oi or -opip to provide an IP.\033[0m\n"
  exit 1
fi

if [[ -z "$VPN_IP" ]]; then
  printf "\033[0;31mYou have not provided a VPN IP. Use -vi or -vpnip to provide an IP.\033[0m\n"
  exit 1
fi

if [[ -z "$IMAGE_NAME" ]]; then
  printf "\033[0;31mYou have not provided an image name. Use -i or -image to provide one.\033[0m\n"
  exit 1
fi

if [[ -z "$EXTERNAL_NETWORK" ]]; then
  printf "\033[0;31mYou have not provided a name for the external network. Use -ei or -xnet to provide one.\033[0m\n"
  exit 1
fi

if [[ -z "$INTERNAL_NETWORK" ]]; then
  printf "\033[0;31mYou have not provided a name for the internal network. Use -in or -inet to provide one.\033[0m\n"
  exit 1
fi

if [[ -z "$PASSWD" ]]; then
  printf "\033[0;31mYou have not provided a password for authentication. Use -p or -password to provide one.\033[0m\n"
  exit 1
fi

if [[ -z "$FILENAME" ]]; then
  printf "\033[0;31mYou have not provided a name for the VPN files. Use -f or -filename to provide one.\033[0m\n"
  exit 1
fi

# set positional arguments in their proper place
eval set -- "${PARAMS}"
source /home/comlab/Desktop/admin-openrc.sh ${PASSWD}

# Checking if Packer is installed.
if ! [ $(command -v packer) ]  ; then
  echo "Installing Packer..."
  export VER="1.5.5"
  wget https://releases.hashicorp.com/packer/${VER}/packer_${VER}_linux_amd64.zip
  unzip packer_${VER}_linux_amd64.zip
  sudo mv packer /usr/local/bin
  printf "\033[0;32mInstalled Packer.\033[0m\n"
else
  echo "Packer is already installed. Not installing."
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
    echo "Installing moreutils..."
    sudo apt-get install moreutils -y
    printf "\033[0;32mInstalled moreutils\033[0m\n"
else
    echo  "Package moreutils is already instaled. Not installing."
fi

# Regular expression to check if IP's given by user are correct.
IP_RE="^(([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5]){1}$"

if ! [[ ${OPENSTACK_IP} =~ ${IP_RE} ]]; then
  printf "\033[0;31mThe Openstack IP is not correct.\033[0m\n"
  exit 1
fi

if ! [[ ${VPN_IP} =~ ${IP_RE} ]]; then
  printf "\033[0;31mThe VPN server's IP is not correct.\033[0m\n"
  exit 1
fi

# Converting image and network names to ID's, so they can be passed to Packer JSON file.
IMAGE_ID=$(openstack image list | grep ${IMAGE_NAME} | awk '{print $2}' -)
EXTERNAL_NETWORK_ID=$(openstack network list | grep ${EXTERNAL_NETWORK} | awk '{print $2}' -)
INTERNAL_NETWORK_ID=$(openstack network list | grep ${INTERNAL_NETWORK} | awk '{print $2}' -)

# Checking if the image and network given by user are correct.
if [[ -z "${IMAGE_ID}" ]]; then
  printf "\033[0;31mThe image name you provided is not correct.\033[0m\n"
  exit 1
fi

if [[ -z "${EXTERNAL_NETWORK_ID}" ]]; then
  printf "\033[0;31mThe external network name you provided is not correct.\033[0m\n"
  exit 1
fi

if [[ -z "${INTERNAL_NETWORK_ID}" ]]; then
  printf "\033[0;31mThe internal network name you provided is not correct.\033[0m\n"
  exit 1
fi

# Modifying the Packer JSON file according to the user's preferences.
IDENTITY="http://${OPENSTACK_IP}/identity"
jq --arg v "${IDENTITY}" '.builders[].identity_endpoint = $v' imagebuild.json|sponge imagebuild.json
jq --arg v "${IMAGE_ID}" '.builders[].source_image = $v' imagebuild.json|sponge imagebuild.json
jq --arg v "${EXTERNAL_NETWORK_ID}" '.builders[].networks[] = $v' imagebuild.json|sponge imagebuild.json

THE_PATH=$('pwd')
TUNNEL_SCRIPT="${THE_PATH}/bootscript.sh"
jq --arg v "${TUNNEL_SCRIPT}" '.provisioners[0].source = $v' imagebuild.json|sponge imagebuild.json

TUNNEL_SERVICE="${THE_PATH}/connectivity.service"
jq --arg v "${TUNNEL_SERVICE}" '.provisioners[1].source = $v' imagebuild.json|sponge imagebuild.json

NETWORKING_SCRIPT="${THE_PATH}/networkconfiguration.sh"
jq --arg v "${NETWORKING_SCRIPT}" '.provisioners[2].source = $v' imagebuild.json|sponge imagebuild.json

NETWORKING_SERVICE="${THE_PATH}/networkconf.service"
jq --arg v "${NETWORKING_SERVICE}" '.provisioners[3].source = $v' imagebuild.json|sponge imagebuild.json

# Edit the boot script of the new image, providing it with the IP of the VPN server and the username that it will use to fetch the VPN files.
sed -i '5s/.*/VPN_IP='"${VPN_IP}"'/' bootscript.sh
sed -i '6s/.*/USERNAME='"${FILENAME}"'/' bootscript.sh

echo "Building image... This might take some time, depending on your hardware and your Internet connection."
packer build imagebuild.json > /dev/null 2>&1
printf "\033[0;32mCreated image: packerimage.\n\033[0mRun 'openstack image list' for confirmation.\n"

printf "\nCreating server for testing...\n"
openstack server create --image packerimage --flavor m1.heat_int --key-name KEYPAIR --user-data ${THE_PATH}/user-data.txt --network $EXTERNAL_NETWORK_ID --network $INTERNAL_NETWORK_ID ovsmachine
printf "\n\033[0;32mCreated server 'testingserver'.\033[0m\nRun 'openstack server list' for confirmation.\n"

sleep 10
SERVER_ID=$(openstack server list | grep "ovsmachine" | awk '{print $2}' -)
PORT_ID=$(openstack port list --network internal --server $SERVER_ID | grep "ip_address" | awk '{print $2}' -)
openstack port set --no-security-group --disable-port-security $PORT_ID