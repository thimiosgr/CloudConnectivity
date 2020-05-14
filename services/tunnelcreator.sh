#!/bin/bash

# This is a script that fetches the VPN configuration files, creates the OVS bridge and connects to the VPN server.

VPN_IP=91.140.33.10 
USERNAME="client1" 

sudo mkdir /home/ubuntu/${USERNAME}
CHECK_FILE=/home/ubuntu/${USERNAME}/ca.crt
FILE=/home/ubuntu/temp

if [[ -f "$FILE" ]]; then
    if ! [ -f "${CHECK_FILE}" ]; then
        sleep 1
        sudo ip route add default via 192.168.1.1
        wget http://${VPN_IP}/${USERNAME}/ca.crt -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.crt -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.key -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.ovpn -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/vtep.sh -P /home/ubuntu/${USERNAME}/
        VTEP_IP=$(head -n1 /home/ubuntu/${USERNAME}/vtep.sh)
        IN_NET_IP="$(ip a | awk '/ens4/{getline;getline; print}' | awk -F/ '{print $1}' - | awk '{print $2}' -)/24"
        # OpenvSwitch configuration
        sudo ovs-vsctl add-br br0
        sudo ip addr flush dev ens4
        sudo ovs-vsctl add-port br0 ens4
        sudo ip addr add ${IN_NET_IP} dev br0
        sudo ip link set br0 up
        sudo ovs-vsctl add-port br0 vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=${VTEP_IP}
        sudo ip route add default via 192.168.1.1
        sudo openvpn /home/ubuntu/${USERNAME}/${USERNAME}.ovpn 
    fi
fi

