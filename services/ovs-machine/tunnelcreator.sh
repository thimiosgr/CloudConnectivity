#!/bin/bash
# This is a script that fetches the VPN configuration files, creates the OVS bridges and connects to the VPN server.
VPN_IP=91.140.33.10 
USERNAME="client1" 
sudo mkdir /home/ubuntu/${USERNAME}
CHECK_FILE=/home/ubuntu/${USERNAME}/ca.crt
FILE=/home/ubuntu/temp

if [[ -f "$FILE" ]]; then
    if ! [ -f "${CHECK_FILE}" ]; then

        # IP route configuration
        ip route del default
        ip route add default via 192.168.0.1

        # Fetching the VPN files
        wget http://${VPN_IP}/${USERNAME}/ca.crt -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.crt -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.key -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.ovpn -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/vtep.sh -P /home/ubuntu/${USERNAME}/
        VTEP_IP=$(head -n1 /home/ubuntu/${USERNAME}/vtep.sh)

        # Finding the internal network's IP's
        IN_NET_IP1="$(ip a | awk '/ens4/{getline;getline; print}' | awk -F/ '{print $1}' - | awk '{print $2}' -)/24"

        # Hashing the IP's
        IP1_MD5=$(md5sum <<<"${IN_NET_IP1}" | cut -c 1-10)

        # OpenvSwitch configuration
        sudo ovs-vsctl add-br "br${IP1_MD5}"
        ip addr flush dev ens4
        sudo ovs-vsctl add-port "br${IP1_MD5}" ens4
        sudo ovs-vsctl add-port "br${IP1_MD5}" "vxlan${IP1_MD5}"  -- set interface "vxlan${IP1_MD5}" type=vxlan options:remote_ip=${VTEP_IP} options:key=2000
        ip addr add ${IN_NET_IP1} dev "br${IP1_MD5}"
        ip link set "br${IP1_MD5}" up
        sudo openvpn /home/ubuntu/${USERNAME}/${USERNAME}.ovpn 
    fi
fi

