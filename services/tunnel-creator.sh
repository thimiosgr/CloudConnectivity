#!/bin/bash

# This is a script that connects to the webserver and fetches the VPN configuration files.

VPN_IP=91.140.33.10
USERNAME="client1"

sudo mkdir /home/ubuntu/${USERNAME}
CHECK_FILE=/home/ubuntu/${USERNAME}/ca.crt
FILE=/home/ubuntu/temp

if [[ -f "$FILE" ]]; then
    if ! [ -f "${CHECK_FILE}" ]; then
#        wget http://${VPN_IP}/${USERNAME}/ca.crt -P /home/ubuntu/${USERNAME}/
#        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.crt -P /home/ubuntu/${USERNAME}/
#        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.key -P /home/ubuntu/${USERNAME}/
#        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.ovpn -P /home/ubuntu/${USERNAME}/
#        wget http://${VPN_IP}/${USERNAME}/vtep.txt -P /home/ubuntu/${USERNAME}/
#        VTEP_IP=$(head -n1 /home/ubuntu/${USERNAME}/vtep.txt)
        sleep 3
        IN_NET_IP="$(ip a | awk '/ens4/{getline;getline; print}' | awk -F/ '{print $1}' - | awk '{print $2}' -)/24"
        # OpenvSwitch configuration
        sudo ovs-vsctl add-br br0
        sudo ip addr flush dev ens4
        sudo ovs-vsctl add-port br0 ens4
        sudo ip addr add ${IN_NET_IP} dev br0
        sudo ip link set br0 up
        touch /home/ubuntu/client1/ca.crt
#        sudo openvpn /home/ubuntu/${USERNAME}/${USERNAME}.ovpn
    fi
fi

