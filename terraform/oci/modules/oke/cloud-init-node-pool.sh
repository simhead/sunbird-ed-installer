#!/bin/bash

# This script runs on OKE worker nodes during provisioning.
# It ensures iptable_nat and ip_tables kernel modules are loaded and persist across reboots.

# Log a message to indicate script execution has started (optional, but good for debugging)
echo "Cloud-init script: Starting iptables module loading and persistence." >> /var/log/cloud-init-output.log 2>&1

lsmod | grep iptable
sudo modprobe iptable_nat
sudo modprobe ip_tables
echo "iptable_nat" | sudo tee -a /etc/modules-load.d/iptables.conf
echo "ip_tables" | sudo tee -a /etc/modules-load.d/iptables.conf

# Log a message when script execution is complete (optional)
echo "Cloud-init script: iptables module configuration complete." >> /var/log/cloud-init-output.log 2>&1
