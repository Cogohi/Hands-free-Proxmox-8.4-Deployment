# Control Node Deployment

## Intro
To achieve a (nearly) Handsfree Proxmox 8.4 deployment we need to
* Boot iPXE via PXE on the target
* Netboot a Live environment on the target to run the registration script
* Netboot the Proxmox Installer and its Automated Installation answerfile

To accomplish that we will configure a VM with
* Dnsmasq in a proxydhcp configuration (so we don't need to muck with router DHCP configs)
* Dnsmasq configured to provide TFTP
* Apache2, php, and SQLite as the CMDB registration server
* ... and ... http netboot server

## Contents
This directory contains files used by Packer to create the VM and set up the
user.  The `post-install.sh` script will set up the machine for the next step
in `control-node-init`

## Pre-reqs
* Virtualbox
* Packer
* SSH client with a key-pair

## Steps
* Copy the files in this directory to a working dir on your workstation
* You will need the name and IP address of the Netwwork Interface attached
  to the network where the target machine will be connected.

  For us poor souls stuck on Windows here's a Powershell recipe:

  `VBoxManage.exe -list -l bridgeifs | Select-String -Pattern "^(Name|Status|IPA)"`
* Edit `debian12.pkrvar.hcl` and put your values in the appropriate spots
* Let 'er rip.  Do not use `-force`.  See `Packer Notes` for details

  `packer -build -var-file debian.pkvar.hcl debian.pkr.hcl`
* Once the install is completed the machine it will shut iteself down so that
  Packer will detach and not blow out the new VM.
* Start the `control-node` VM.  It will print the IP Address it has been assigned
  on the login console.
* Use your ssh client to log in.
* Run `bash ./post_install.sh`

The following instructions will be printed out when `post-install.sh`
* cd to `Handsfree-Proxmox` and run `bash control-node-init.sh`
* Enable PXE on your target machine and boot it via PXE
* Select "Register Node"
* On the target machine run `wget -O registration.sh http://<your control node's ip>/net-info/registration.php`
* Enter the info and the machine should reboot
* Select "Install Node"

Once Proxmox 8.4 has been installed on the target see the README.md in `proxmox-init` 

## Packer Notes
* The philosophy seems to be that Packer is a tool to create VM *templates*
* Its `virtualbox-iso` plugin *requires* the machine to shut down even if you tell it not to export an image
* The plugin will **also** export said image regardless
### Don't use `--force`, manually delete the VM using VirtualBox tools
... but make sure the directory where the image is stored is not set to **Read Only**

* VirtualBox considers the exported image as part of the files that belong to the VM
* When the `-force` option is given to `packer build` it removes the exported image _first_ then tells VirtualBox to delete the VM
* BUT the image that VirtualBox considers it's solemn property is gone and it pitches a fit
* The VM is removed from the inventory but all the files are left behind
