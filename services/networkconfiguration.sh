#!/bin/bash

FILE=/home/ubuntu/temp

if ! [[ -f "$FILE" ]]; then
    sudo bash -c "echo auto ens4 >> /etc/network/interfaces.d/50-cloud-init.cfg"
    sudo bash -c "echo iface ens4 inet dhcp >> /etc/network/interfaces.d/50-cloud-init.cfg"
    sudo bash -c "echo auto ens5 >> /etc/network/interfaces.d/50-cloud-init.cfg"
    sudo bash -c "echo iface ens5 inet dhcp >> /etc/network/interfaces.d/50-cloud-init.cfg"
    sudo bash -c "echo auto ens6 >> /etc/network/interfaces.d/50-cloud-init.cfg"
    sudo bash -c "echo iface ens6 inet dhcp >> /etc/network/interfaces.d/50-cloud-init.cfg"
    sudo bash -c "echo auto ens7 >> /etc/network/interfaces.d/50-cloud-init.cfg"
    sudo bash -c "echo iface ens7 inet dhcp >> /etc/network/interfaces.d/50-cloud-init.cfg"
    touch $FILE
    reboot
fi
