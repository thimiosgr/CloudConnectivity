#!/bin/bash

FILE=/home/ubuntu/temp

if ! [[ -f "$FILE" ]]; then
    sudo bash -c "echo auto ens4 >> /etc/network/interfaces.d/50-cloud-init.cfg"
    sudo bash -c "echo iface ens4 inet dhcp >> /etc/network/interfaces.d/50-cloud-init.cfg"
    touch /home/ubuntu/temp
    reboot
fi
