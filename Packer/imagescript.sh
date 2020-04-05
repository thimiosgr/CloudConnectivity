#!/bin/bash

# This is a script that connects to the webserver and fetches the VPN configuration files.


USERNAME="ovs2"

sudo mkdir /home/ubuntu/${USERNAME}

echo "Fetching the VPN files..."
wget http://${VPN_IP}/${USERNAME}/ca.crt -P /home/ubuntu/${USERNAME}/
wget http://${VPN_IP}/${USERNAME}/${USERNAME}.crt -P /home/ubuntu/${USERNAME}/
wget http://${VPN_IP}/${USERNAME}/${USERNAME}.key -P /home/ubuntu/${USERNAME}/
wget http://${VPN_IP}/${USERNAME}/${USERNAME}.ovpn -P /home/ubuntu/${USERNAME}/
wget http://${VPN_IP}/${USERNAME}/where.txt -P /home/ubuntu/${USERNAME}/

PEER_IP=$(head -n1 /home/ubuntu/${USERNAME}/where.txt)
TUNNEL_IP=$(head -n2 /home/ubuntu/${USERNAME}/where.txt | tail -1)

sudo ovs-vsctl add-br br0
sudo ovs-vsctl add-port br0 vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=${PEER_IP}
sudo ovs-vsctl add-port br0 vi0 -- set interface vi0 type=internal
sudo ifconfig vi0 ${TUNNEL_IP}/24 up

echo "Establishing VPN connection..."
sudo openvpn /home/ubuntu/${USERNAME}/${USERNAME}.ovpn


