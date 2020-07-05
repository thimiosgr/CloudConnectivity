# Cloud Connectivity

This is a thesis of an undergraduate student studying at the department of Electrical and Computer Engineering of the University of Patras (UoP).

The purpose of the thesis is to provide L2 connectivity between two or more cloud using pure software virtual switches. Switches are based on OpenVSwitch, a proven solution for implementing software-based data planes. Goal is to package OVS in a way that can implement the gateway role for multiple data paths that may serve different purposes in each cloud


![Imgur](https://imgur.com/iPavtfq.png)


Assuming that the network topology of each cloud is similar to the below topology, then every Virtual Machine (VM) running on the first cloud can communicate with the VM's of the second cloud via the central VM which is using virtual switches with VXLAN tunnels. Only the central VM is connected to the outside world, as the yellow arrow indicates. This VM plays the gateway role for the isolated networks machines.


![Imgur](https://imgur.com/xl3i9CF.png)
