# Building out the Control Node

## Debian 12
1. Cry because Debian 13 just released
1. A non-root user with sudo permissions
1. `sudo apt install git`
1. Create a working directory and cd into it
1. git clone this project and cd into it
1. create a directory outside of this tree for your network's ansible inventory
1. cp -r inventory-skeleton/ <PATH_TO_YOUR_INVENTORY_DIR> 
1. Edit <INVENTORY_DIR>/inventory.yaml to add the target machine(s) to the proxmox group
1. run control-node/install-ansible.sh
1. run ansible-playbook -i control-node/inventory.yaml prepare-control-node-playbook.yaml
1. run ansible-playbook -i control-node/inventory.yaml prepare-proxmox-installer-playbook.yaml

### install-ansible.sh does the following:
1. From Ansible's [Installing Ansible on Debian](https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-debian)
```
  UBUNTU_CODENAME=jammy
  wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list
  sudo apt update && sudo apt install ansible
```

### prepare-control-node-playbook.yaml does the following: 
1. `sudo apt install apache2 dnsmasq squashfs-tools xorriso`
1. Sets up dnsmasq for proxydhcp and tftp
1. creats /var/tftproot /var/www/html/iPXE /var/www/html/proxmox /var/local/control-node
1. Downloads iPXE's `snponly.efi` and `undionly.kpxe` and adds them to /var/tftproot
1. cp files/netinfo.db /var/local/control-node
1. cp files/boot.php /var/www/html/iPXE
1. cp -r files/cnmanager /var/www/html/ <- TODO web app to manage network inventory
1. generates /etc/dnsmasq.d/dhcpproxy from files/dhcpproxy.tmpl (unless we can get away with a straight cp)

### prepare-proxmox-installer-playbook.yaml does the following:
1. sudo mkdir /mnt/cdrom
1. cd tmp  (make sure the filesystem has a few Gb of free space)
1. wget https://enterprise.proxmox.com/iso/proxmox-ve_8.4-1.iso
1. sudo mount -o loop proxmox-ve_8.4-1.iso /mnt/cdrom
1. mkdir pxeboot/
1. cp /mnt/cdrom/boot/initrd.img .
1. cp /mnt/cdrom/boot/linux26 pxeboot/
1. cp /mnt/cdrom/pve-installer.squashfs .
1. sudo umount /mnt/cdrom
1. sudo unsquashfs -d tmp-pve-installer pveinstaller.squashfs
1. sudo patch tmp-pve-installer/usr/sbin/unconfigured.sh < ../files/unconfigured.sh.patch

If this kicks out errors you'll need to apply the changes manually 

1. sudo mksquashfs tmp-pve-installer pve-installer-super.squashfs -comp zstd -Xcompression-level 19
1. `VOL_DATE=$(xorriso -dev proxmox-ve_8.4-1.iso -report_system_area cmd 2>/dev/null)`
1. `xorriso -boot_image any keep $VOL_DATE -dev proxmox-ve_8.4-1.iso -outdev promox-ve_8.4-1-updated.iso -update pve-installer-updated.squashfs /pve-installer.squashfs`

See: [This gist](https://gist.github.com/Cogohi/b26fd0859c171c82efa6873479cdb158#usage) for how to use the new ISO

1. ln -s proxmox-ve_8.4-1-updated.iso proxmox.iso
1. zstd -d initrd.img -c > prxeboot/initrd
1. cd pxeboot
1. echo "../proxmox.iso | cpio -L -H newc -o >> initrd
1. mkdir /var/www/html/proxmox
1. cp initrd linux26 /var/www/html/proxmox
1. cd ..
1. cp files/answer.php /var/www/html/proxmox
1. cp files/first-boot.php /var/www/html/proxmox

Theory of Operation
* When a host PXE boots it will be given the iPXE boot loader which will hit boot.php
* boot.php will check /var/local/control-node/netinfo.db
* if the booting host is matched and has boot data indicating a proxmox installtion it will give add a menu option to install proxmox
* otherwise it'll gather machine info or boot into something that can gather that data and preset cnmanager so the host can be configured
