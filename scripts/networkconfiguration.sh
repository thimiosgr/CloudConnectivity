#!/bin/bash

FFILE=/home/ubuntu/temp
SFILE=/home/ubuntu/temp2

if ! [[ -f "$SFILE" ]]; then
    if [[ -f "$FFILE" ]]; then
        touch /home/ubuntu/temp2
        reboot
    fi
    sudo bash -c "echo auto ens4 >> /etc/network/interfaces.d/50-cloud-init.cfg"
    sudo bash -c "echo iface ens4 inet dhcp >> /etc/network/interfaces.d/50-cloud-init.cfg"
    touch /home/ubuntu/temp
    reboot
fi
