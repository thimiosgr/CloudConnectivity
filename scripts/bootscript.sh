#!/bin/bash

# This is a script that connects to the webserver and fetches the VPN configuration files.

VPN_IP=91.140.33.10
USERNAME="client1"

sudo mkdir /home/ubuntu/${USERNAME}
CHECK_FILE=/home/ubuntu/${USERNAME}/ca.crt

if [[ -f "$FILE" ]]; then
    if ! [ -f "${CHECK_FILE}" ]; then
        echo "Fetching the VPN files..."
        wget http://${VPN_IP}/${USERNAME}/ca.crt -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.crt -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.key -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/${USERNAME}.ovpn -P /home/ubuntu/${USERNAME}/
        wget http://${VPN_IP}/${USERNAME}/where.txt -P /home/ubuntu/${USERNAME}/
        # PEER_IP=$(head -n1 /home/ubuntu/${USERNAME}/where.txt)
        # TUNNEL_IP=$(head -n2 /home/ubuntu/${USERNAME}/where.txt | tail -1)
        sleep 3
        # OpenvSwitch configuration
    fi
fi

echo "Establishing VPN connection..."
sudo openvpn /home/ubuntu/${USERNAME}/${USERNAME}.ovpn
