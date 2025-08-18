# Control Node Deployment

## Intro
The control node VM will be used to manage the Proxmox Automated Installation
process.  This directory contains files to create that VM with the needed
packages.  It will create the user account needed to run the ansible playbooks
that will configure itself and the proxmox target machine.

## Contents
This directory contains files used by Packer to create the VM and set up the
user.  The `post-install.sh` script will set up the machine for the next steps
in `control-node-init`

## Pre-reqs
* VirtualBox
* Packer
* SSH client with a key-pair
* An additional key-pair for use by Packer

## Steps
* Copy the files in this directory to a working dir on your workstation
* You will need the name and IP address of the Network Interface attached
  to the network where the target machine will be connected.

  For us poor souls stuck on Windows here's a Powershell recipe:

  `VBoxManage.exe -list -l bridgeifs | Select-String -Pattern "^(Name|Status|IPA)"`
* Copy `debian12.pkrvar.hcl.template` to `debain12.pkrvar.hcl`
* Edit `debian12.pkrvar.hcl` and put your values in the appropriate spots
* Run the build. 
  `packer init -var-file debian12.pkvar.hcl debian12.pkr.hcl`
  `packer build -var-file debian12.pkvar.hcl debian12.pkr.hcl`
* Packer will shut the machine down and create a `control-node.ova` file.
* VirtualBox Manager -> File -> Import Appliance and choose that .ova file
* Start the machine and use your SSH client to log into it using the username
  and IP Address you supplied in `debian12.pkrvar.hcl`
  `ssh username@ip-address`
* See `control-node-init/README.md` for the next steps.
