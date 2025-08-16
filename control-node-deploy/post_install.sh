#!/bin/bash

# generate ssh keypair
< /dev/zero ssh-keygen -q -N "" -t ed25519 -C "control node key" 1>/dev/null

# get the Handsfree repo
git clone https://github.com/Cogohi/Handsfree-Proxmox.git

# install less old Ansible
UBUNTU_CODENAME=jammy
wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list
sudo apt update && sudo apt -y install ansible

# add ttafsir.sqlite_utils
ansible-galaxy collection install ttafsir.sqlite_utils

# remove the packer-temp-key added by the preseed
sed -i '/packer-temp-key/d' ~/.ssh/authorized_keys
