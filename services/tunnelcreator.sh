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
        ip route del default
        ip route add default via 192.168.1.1
        wget http://${VPN_IP}/${USERNAME}/ca.crt -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.crt -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.key -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.ovpn -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/vtep.sh -P /home/ubuntu/${USERNAME}/
        VTEP_IP=$(head -n1 /home/ubuntu/${USERNAME}/vtep.sh)
        IN_NET_IP1="$(ip a | awk '/ens4/{getline;getline; print}' | awk -F/ '{print $1}' - | awk '{print $2}' -)/24"
        IN_NET_IP2="$(ip a | awk '/ens5/{getline;getline; print}' | awk -F/ '{print $1}' - | awk '{print $2}' -)/24"
        IN_NET_IP3="$(ip a | awk '/ens6/{getline;getline; print}' | awk -F/ '{print $1}' - | awk '{print $2}' -)/24"
        IN_NET_IP4="$(ip a | awk '/ens7/{getline;getline; print}' | awk -F/ '{print $1}' - | awk '{print $2}' -)/24"

        # OpenvSwitch configuration
        sudo ovs-vsctl add-br br0
        ip addr flush dev ens4
        sudo ovs-vsctl add-port br0 ens4
        ip addr add ${IN_NET_IP1} dev br0
        ip link set br0 up
        sudo ovs-vsctl add-port br0 vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=${VTEP_IP}

        sudo ovs-vsctl add-br br1
        ip addr flush dev ens5
        sudo ovs-vsctl add-port br1 ens5
        ip addr add ${IN_NET_IP2} dev br1
        ip link set br1 up
        sudo ovs-vsctl add-port br1 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=${VTEP_IP}

        sudo ovs-vsctl add-br br2
        ip addr flush dev ens6
        sudo ovs-vsctl add-port br2 ens6
        ip addr add ${IN_NET_IP3} dev br2
        ip link set br2 up
        sudo ovs-vsctl add-port br2 vxlan2 -- set interface vxlan2 type=vxlan options:remote_ip=${VTEP_IP}

        sudo ovs-vsctl add-br br3
        ip addr flush dev ens7
        sudo ovs-vsctl add-port br3 ens7
        ip addr add ${IN_NET_IP4} dev br3
        ip link set br3 up
        sudo ovs-vsctl add-port br3 vxlan3 -- set interface vxlan3 type=vxlan options:remote_ip=${VTEP_IP}
        openvpn /home/ubuntu/${USERNAME}/${USERNAME}.ovpn 
    fi
fi

