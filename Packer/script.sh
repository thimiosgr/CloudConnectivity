#!/bin/bash

sudo chmod 666 example.json connectivity.service

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

# Regular expression for IP matching/
IP_RE="^(([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[0-9]{2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])+$"

read -p "Openstack IP: " OP_IP

while ! [[ $OP_IP =~ $IP_RE ]]
do
	printf "\033[0;31mThe IP is not correct.\033[0m\n"
        read -p "Please type a correct IP (x.y.z.w): " OP_IP
done

IDENTITY="http://${OP_IP}/identity"

read -p "Source image name: " IMAGE_ID

while  [[ `openstack image list | grep -i $IMAGE_ID | head -c1` != "|" ]]
do
        printf "\033[0;31mThe image ID is not correct.\033[0m\n"
        read -p "Please type a correct image ID: " IMAGE_ID
done

read -p "Network ID: " NET_ID

while  [[ `openstack network list | grep -i $NET_ID | head -c1` != "|" ]]
do
        printf "\033[0;31mThe network ID is not correct.\033[0m\n"
        read -p "Please type a correct network ID: " NET_ID
done

jq --arg v "${IDENTITY}" '.builders[].identity_endpoint = $v' example.json|sponge example.json
jq --arg v "${IMAGE_ID}" '.builders[].source_image = $v' example.json|sponge example.json
jq --arg v "${NET_ID}" '.builders[].networks[] = $v' example.json|sponge example.json

THE_PATH=$('pwd')
SCRIPT="${THE_PATH}/imagescript.sh"
jq --arg v "$SCRIPT" '.provisioners[0].source = $v' example.json|sponge example.json

SERVICE="${THE_PATH}/connectivity.service"
jq --arg v "$SERVICE" '.provisioners[1].source = $v' example.json|sponge example.json

read -p "VPN server's IP: " VPN_IP

while ! [[ $VPN_IP =~ $IP_RE ]]
do
        read -p "Please type a correct IP (x.y.z.w): " VPN_IP
done

sed -i '5s/.*/VPN_IP='"$VPN_IP"'/' imagescript.sh

echo "Building image... This might take some minutes, depending on your hardware and your Internet connection."
packer build example.json > /dev/null 2>&1
printf "\033[0;32mCreated image: packerimage.\n\033[0mRun 'openstack image list' for confirmation.\n"

printf "\nCreating server for testing...\n"
openstack server create --image packerimage --flavor m1.heat_int --key-name KEYPAIR --user-data /home/comlab/Desktop/user-data.txt --network net1 testingserver
printf "\n\033[0;32mCreated server 'testingserver'.\033[0m\nRun 'openstack server list' for confirmation.\n"
