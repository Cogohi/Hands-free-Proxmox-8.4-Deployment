packer {
    required_plugins {
        virtualbox = {
            version = "~> 1"
            source = "github.com/hashicorp/virtualbox"
        }
    }
}

variable "iso_url" {
    type = string
    description = "The URL for the Debian ISO image, to be found at https://www.debian.org/download"
}

variable "iso_checksum" {
    type = string
    description = "The checksum of the ISO image (see variable 'iso_url') with a prefix like sha256: or md5:"
}

variable "cpus" {
    type = number
    description = "The number of CPU cores"
}

variable "disk_size" {
    type = number 
    description = "The disk size in megabytes"
}

variable "memory" {
    type = number
    description = "The memory size in megabytes"
}

variable "domain" {
    type = string
}

variable "hostname" {
    type = string
}

variable "address" {
    type = string
}

variable "netmask" {
    type = string
}

variable "gateway" {
    type = string
}

variable "nameservers" {
    type = string
}

variable "sshpubkey" {
    type = string
}

# Note: If this is set it must have the trailing directory separator (e.g. C:/path/to/keys/)
variable "packer_keydir" {
    type = string
    default = ""
    description = "The directory where the keypair is stored.  If the path is blank, Packer will look in this directory."
}

variable "packer_keyfile" {
    type = string
    description = "The ssh private key's filename (e.g. id_ed25519).  The public key must be the same with a .pub extension (e.g. id_ed25519.pub)"
}

variable "username" {
    type = string
}

variable "host_nic_ip" {
    type = string
}

variable "host_nic_name" {
    type = string
}

variable "iso-cache-file" {
    type = string
}

variable "ova-export-dir" {
    type = string
}

locals {
    info = {
        username = "${var.username}"
        sshpubkey = "${var.sshpubkey}"
        domain = "${var.domain}"
        hostname = "${var.hostname}"
        address = "${var.address}"
        netmask = "${var.netmask}"
        gateway = "${var.gateway}"
        nameservers = "${var.nameservers}"
        host_ip = "${var.host_nic_ip}"
    }
}

# Packer's ephemeral keys are generated at build time while this section
# apparently is set in stone long before then.  The only way to pass them
# to the preseed is via the kernel command line which we're already abusing
# to work around debian-installer netcfg issues.
#
# Workaround: Have the user generate a separate keypair just for this.

source "virtualbox-iso" "debian" {
    communicator = "ssh"
    ssh_host = var.address
    ssh_username = var.username
    ssh_keypair_name = var.packer_keyfile
    ssh_private_key_file = "${var.packer_keydir}${var.packer_keyfile}"
    ssh_timeout = "2h"
    ssh_skip_nat_mapping = true

    guest_additions_mode = "disable"
    virtualbox_version_file = ""
    format = "ova"
    iso_target_path = var.iso-cache-file
    output_directory = var.ova-export-dir

    boot_wait = "10s"
    boot_keygroup_interval = "500ms"

    # Passing the static address config on the kernel command line
    # is less than ideal but I just could not convince the debian
    # installer to honor it in the preseed.

    boot_command = [
        "<esc><wait>",
        "auto interface=enp0s3 <wait>",
        "packer/httpport={{.HTTPPort}} <wait>",
        "url=http://${var.host_nic_ip}:{{.HTTPPort}}/preseed.cfg <wait>",
        "hostname=${var.hostname} <wait>",
        "netcfg/get_ipaddress=${var.address} <wait>",
        "netcfg/get_netmask=${var.netmask} <wait>",
        "netcfg/get_gateway=${var.gateway} <wait>",
        "netcfg/get_nameservers=${var.nameservers} <wait>",
        "netcfg/disable_dhcp=true <wait>",
        "<wait><enter>",
    ]
    guest_os_type = "Debian_64"
    iso_url = var.iso_url
    iso_checksum = var.iso_checksum
    iso_interface = "sata"
    http_content = {
        "/packer-temp-key.pub" = file("${var.packer_keydir}${var.packer_keyfile}.pub")
        "/preseed.cfg" = templatefile("${path.root}/preseed.pkrtpl", local.info)
    }
    cpus = var.cpus
    disk_size = "${var.disk_size}"
    memory = var.memory
    vboxmanage = [
        ["modifyvm", "{{.Name}}", "--nic1","bridged","--bridgeadapter1","${var.host_nic_name}"],
        ["modifyvm", "{{.Name}}", "--vram","20"]
    ]
    headless = true
    vm_name = "control-node"

    # Would have preferred that Packer just create the VM and get out of the way.
    keep_registered = false
    skip_export = false

    shutdown_command = "sudo shutdown -P now"
    shutdown_timeout = "24h"
}

build {
    sources = ["sources.virtualbox-iso.debian"]

    provisioner "shell" {
      script = "post_install.sh"
    }
}
