# Hands-free-Proxmox-8.4-Deployment
Scripts and documentation on how to leverage iPXE and Proxmox Automated Install to deploy Proxmox 8.4

## Introduction
To achieve a (nearly) Handsfree Proxmox 8.4 deployment we need to
* Boot iPXE via PXE on the target
* Netboot a Live environment on the target to run the registration script
* Netboot the Proxmox Installer and its Automated Installation answerfile

To accomplish that we will configure a VM with
* Dnsmasq in a proxydhcp configuration (so we don't need to muck with router DHCP configs)
* Dnsmasq configured to provide TFTP
* Serve the iPXE firmware via TFTP
* Apache2, php, and SQLite as the CMDB registration server
* Serve the iPXE netbooted services via http
* A clone of this repo for the Ansible scripts to configure the target

## Requirements
* A target machine to install Proxmox
* A host machine with VirtualBox and Packer installed
* A SSH keypair used to log into the control node and target machine
* An additional SSH keypair for use by Packer
* The contents of control-node-deploy/ placed in a working directory

## Steps
* Set up the control-node VM.  see control-node-deploy/README.md
* Import and boot the control-node.
* PXE boot the target machine and select Register
* Reboot the target machine and select deploy Proxmox
* When Proxmox is installed see proxmox-init/README.md to complete the installation
