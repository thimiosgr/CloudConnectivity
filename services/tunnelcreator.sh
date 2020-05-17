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

        IP1_MD5=$(md5sum <<<"${IN_NET_IP1}" | cut -c 1-10)
        IP2_MD5=$(md5sum <<<"${IN_NET_IP2}" | cut -c 1-10)
        IP3_MD5=$(md5sum <<<"${IN_NET_IP3}" | cut -c 1-10)
        IP4_MD5=$(md5sum <<<"${IN_NET_IP4}" | cut -c 1-10)

        ip link add $IP1_MD5 type veth peer name "V${IP1_MD5}"
        ip link add $IP2_MD5 type veth peer name "V${IP2_MD5}"
        ip link add $IP3_MD5 type veth peer name "V${IP3_MD5}"
        ip link add $IP4_MD5 type veth peer name "V${IP4_MD5}"
        
        # OpenvSwitch configuration
        sudo ovs-vsctl add-br "br${IP1_MD5}"
        ip addr flush dev ens4
        sudo ovs-vsctl add-port "br${IP1_MD5}" ens4
        sudo ovs-vsctl add-port "br${IP1_MD5}" $IP1_MD5
        ifconfig $IP1_MD5 up
        ip addr add ${IN_NET_IP1} dev "br${IP1_MD5}"
        ip link set "br${IP1_MD5}" up

        sudo ovs-vsctl add-br "br${IP2_MD5}"
        ip addr flush dev ens5
        sudo ovs-vsctl add-port "br${IP2_MD5}" ens5
        sudo ovs-vsctl add-port "br${IP2_MD5}" $IP2_MD5
        ifconfig $IP2_MD5 up
        ip addr add ${IN_NET_IP2} dev "br${IP2_MD5}"
        ip link set "br${IP2_MD5}" up

        sudo ovs-vsctl add-br "br${IP3_MD5}"
        ip addr flush dev ens6
        sudo ovs-vsctl add-port "br${IP3_MD5}" ens6
        sudo ovs-vsctl add-port "br${IP3_MD5}" $IP3_MD5
        ifconfig $IP3_MD5 up
        ip addr add ${IN_NET_IP3} dev "br${IP3_MD5}"
        ip link set "br${IP3_MD5}" up

        sudo ovs-vsctl add-br "br${IP4_MD5}"
        ip addr flush dev ens7
        sudo ovs-vsctl add-port "br${IP4_MD5}" ens7
        sudo ovs-vsctl add-port "br${IP4_MD5}" $IP4_MD5
        ifconfig $IP4_MD5 up
        ip addr add ${IN_NET_IP4} dev "br${IP4_MD5}"
        ip link set "br${IP4_MD5}" up

        sudo ovs-vsctl add-br tunnelbr
        sudo ovs-vsctl add-port tunnelbr "V${IP1_MD5}"
        ifconfig "V${IP1_MD5}" up
        sudo ovs-vsctl add-port tunnelbr "V${IP2_MD5}"
        ifconfig "V${IP1_MD5}" up
        sudo ovs-vsctl add-port tunnelbr "V${IP3_MD5}"
        ifconfig "V${IP3_MD5}" up
        sudo ovs-vsctl add-port tunnelbr "V${IP4_MD5}"
        ifconfig "V${IP4_MD5}" up
        sudo ovs-vsctl add-port tunnelbr vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=${VTEP_IP}
        openvpn /home/ubuntu/${USERNAME}/${USERNAME}.ovpn 

    fi
fi

