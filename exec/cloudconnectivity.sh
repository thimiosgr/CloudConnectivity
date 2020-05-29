#!/bin/bash

THE_PATH="$(pwd)/CloudConnectivity"
PARAMS=""
declare -a OPENSTACK_ARR

while (( "$#" )); do
  case "$1" in
    -def | -default)
      IP=$(ifconfig | grep "150.140.186" | awk '{print $2}' -)
      if [[ $IP == "150.140.186.115" ]]; then
        source ${THE_PATH}/credentials/vars/openstack1.sh
        source ${THE_PATH}/credentials/openstack/admin-openrc1.sh ${PASSWD}
      else
        source ${THE_PATH}/credentials/vars/openstack2.sh
        source ${THE_PATH}/credentials/openstack/admin-openrc2.sh ${PASSWD}
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
  printf "\t\033[0;33m-def\033[0m, \033[0;33m-default\033[0m  :  Run script with the default values.\n"
  printf "\t\033[0;33m-h\033[0m, \033[0;33m-help\033[0m       :  Shows all the available script options.\n"
  printf "If you want to change the default values, edit the openstack.sh file located in CloudConnectivity/credentials/vars directory.\n"
  exit 1
fi

# set positional arguments in their proper place
eval set -- "${PARAMS}"

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

# Openstack networks configuration
echo "Creating full network topology..."
PRIMARY_NETWORK_ID=$(openstack network create primary_network --provider-network-type vxlan | grep " id " | awk '{print $4}' -)
INTERNAL_NETWORK1_ID=$(openstack network create internal_network1 --provider-network-type vxlan --disable-port-security | grep " id " | awk '{print $4}' -)
OPENSTACK_ARR[0]=$INTERNAL_NETWORK1_ID
INTERNAL_NETWORK2_ID=$(openstack network create internal_network2 --provider-network-type vxlan --disable-port-security | grep " id " | awk '{print $4}' -)
OPENSTACK_ARR[1]=$INTERNAL_NETWORK2_ID
INTERNAL_NETWORK3_ID=$(openstack network create internal_network3 --provider-network-type vxlan --disable-port-security | grep " id " | awk '{print $4}' -)
OPENSTACK_ARR[2]=$INTERNAL_NETWORK3_ID
INTERNAL_NETWORK4_ID=$(openstack network create internal_network4 --provider-network-type vxlan --disable-port-security | grep " id " | awk '{print $4}' -)
OPENSTACK_ARR[3]=$INTERNAL_NETWORK4_ID
INTERNAL_NETWORK5_ID=$(openstack network create internal_network5 --provider-network-type vxlan --disable-port-security | grep " id " | awk '{print $4}' -)
OPENSTACK_ARR[4]=$INTERNAL_NETWORK5_ID
ROUTER_ID=$(openstack router create ROUTER | grep " id " | awk '{print $4}' -)
PRIMARY_NETWORK_SUBNET_ID=$(openstack subnet create primary_network_subnet --network $PRIMARY_NETWORK_ID --subnet-range 192.168.0.0/24 --dhcp --dns-nameserver 8.8.8.8 --gateway 192.168.0.1  | grep " id " | awk '{print $4}' -)

openstack subnet create internal_network1_subnet --network $INTERNAL_NETWORK1_ID --subnet-range 192.168.1.0/24 --dhcp --gateway none > /dev/null 2>&1
openstack subnet create internal_network2_subnet --network $INTERNAL_NETWORK2_ID --subnet-range 192.168.2.0/24 --dhcp --gateway none > /dev/null 2>&1
openstack subnet create internal_network3_subnet --network $INTERNAL_NETWORK3_ID --subnet-range 192.168.3.0/24 --dhcp --gateway none > /dev/null 2>&1
openstack subnet create internal_network4_subnet --network $INTERNAL_NETWORK4_ID --subnet-range 192.168.4.0/24 --dhcp --gateway none > /dev/null 2>&1
openstack subnet create internal_network5_subnet --network $INTERNAL_NETWORK5_ID --subnet-range 192.168.5.0/24 --dhcp --gateway none > /dev/null 2>&1
openstack router set $ROUTER_ID --external-gateway $PUBLIC_NETWORK > /dev/null 2>&1
openstack router add subnet $ROUTER_ID $PRIMARY_NETWORK_SUBNET_ID  > /dev/null 2>&1
printf "\033[0;32mDone\033[0m\n"

# Converting image and network names to ID's, so they can be passed to the JSON file that will be used by Packer.
IMAGE_ID=$(openstack image list | grep ${IMAGE_NAME} | awk '{print $2}' -)

# Modifying the Packer JSON file according to the user's preferences.
printf "Editing JSON files..."
IDENTITY="http://${OPENSTACK_IP}/identity"
TUNNEL_SCRIPT="${THE_PATH}/services/ovs-machine/tunnelcreator.sh"
TUNNEL_SERVICE="${THE_PATH}/services/ovs-machine/tunneling.service"
NETWORKING_SCRIPT="${THE_PATH}/services/ovs-machine/networkconfiguration.sh"
NETWORKING_SERVICE="${THE_PATH}/services/ovs-machine/networkconf.service"
WEBSERVER_SCRIPT="${THE_PATH}/services/httpserver/httpserver.sh"
WEBSERVER_SERVICE="${THE_PATH}/services/httpserver/httpserver.service"

jq --arg v "${IDENTITY}" '.builders[].identity_endpoint = $v' ${THE_PATH}/templates/ovsimage.json | sponge ${THE_PATH}/templates/ovsimage.json
jq --arg v "${IMAGE_ID}" '.builders[].source_image = $v' ${THE_PATH}/templates/ovsimage.json | sponge ${THE_PATH}/templates/ovsimage.json
jq --arg v "${PRIMARY_NETWORK_ID}" '.builders[].networks[] = $v' ${THE_PATH}/templates/ovsimage.json | sponge ${THE_PATH}/templates/ovsimage.json
jq --arg v "${TUNNEL_SCRIPT}" '.provisioners[0].source = $v' ${THE_PATH}/templates/ovsimage.json | sponge ${THE_PATH}/templates/ovsimage.json
jq --arg v "${TUNNEL_SERVICE}" '.provisioners[1].source = $v' ${THE_PATH}/templates/ovsimage.json | sponge ${THE_PATH}/templates/ovsimage.json
jq --arg v "${NETWORKING_SCRIPT}" '.provisioners[2].source = $v' ${THE_PATH}/templates/ovsimage.json | sponge ${THE_PATH}/templates/ovsimage.json
jq --arg v "${NETWORKING_SERVICE}" '.provisioners[3].source = $v' ${THE_PATH}/templates/ovsimage.json | sponge ${THE_PATH}/templates/ovsimage.json

jq --arg v "${IDENTITY}" '.builders[].identity_endpoint = $v' ${THE_PATH}/templates/httpserverimage.json | sponge ${THE_PATH}/templates/httpserverimage.json
jq --arg v "${IMAGE_ID}" '.builders[].source_image = $v' ${THE_PATH}/templates/httpserverimage.json | sponge ${THE_PATH}/templates/httpserverimage.json
jq --arg v "${PRIMARY_NETWORK_ID}" '.builders[].networks[] = $v' ${THE_PATH}/templates/httpserverimage.json | sponge ${THE_PATH}/templates/httpserverimage.json
jq --arg v "${WEBSERVER_SCRIPT}" '.provisioners[0].source = $v' ${THE_PATH}/templates/httpserverimage.json | sponge ${THE_PATH}/templates/httpserverimage.json
jq --arg v "${WEBSERVER_SERVICE}" '.provisioners[1].source = $v' ${THE_PATH}/templates/httpserverimage.json | sponge ${THE_PATH}/templates/httpserverimage.json
printf "\033[0;32m Done\033[0m\n"

# Edit the boot script of the new image, providing it with the IP of the VPN server and the username that it will use to fetch the VPN files.
sed -i '3s/.*/VPN_IP='"${VPN_IP}"'/' ${THE_PATH}/services/ovs-machine/tunnelcreator.sh
sed -i '4s/.*/USERNAME='"${FILENAME}"'/' ${THE_PATH}/services/ovs-machine/tunnelcreator.sh

echo "Building images... This might take some time, depending on your hardware and your Internet connection."
packer build ${THE_PATH}/templates/ovsimage.json > /dev/null 2>&1
packer build ${THE_PATH}/templates/httpserverimage.json > /dev/null 2>&1
printf "\033[0;32mCreated images: OVSimage,SimpleHTTPserver.\n\033[0mRun 'openstack image list' for confirmation.\n"

printf "\nCreating server for Open vSwitch..."
SERVER_ID=$(openstack server create --image OVSimage --flavor m1.heat_int --key-name KEYPAIR --user-data ${THE_PATH}/cloud-configuration/user-data.txt --network ${PRIMARY_NETWORK_ID} --network ${INTERNAL_NETWORK1_ID} --network ${INTERNAL_NETWORK2_ID} --network ${INTERNAL_NETWORK3_ID} --network ${INTERNAL_NETWORK4_ID} --network ${INTERNAL_NETWORK5_ID} OVSmachine | grep " id " | awk '{print $4}' -)
printf "\033[0;32m Done\033[0m\n"

printf "Creating instances on each internal network..."
COUNTER=0
while [ "$COUNTER" -lt "${#OPENSTACK_ARR[@]}" ]; 
do
  for i in $(seq 1 4)
  do
    RANDOM_INTEGER=$(echo $((1 + RANDOM)))
    openstack server create --image cirros-0.4.0-x86_64-disk --flavor m1.nano --network ${OPENSTACK_ARR[COUNTER]} "cirros_instance_${RANDOM_INTEGER}" > /dev/null 2>&1
  done
  openstack server create --image SimpleHTTPserver --flavor m1.heat_int --network ${OPENSTACK_ARR[COUNTER]} "httpserver_${RANDOM_INTEGER}" > /dev/null 2>&1
COUNTER=$((COUNTER+1))
done
printf "\033[0;32m Done\033[0m\n"