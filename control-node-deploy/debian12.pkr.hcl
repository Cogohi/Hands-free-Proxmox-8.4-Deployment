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
    description = "The URL for the Ubuntu ISO image, to be found at https://www.debian.org/download"
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

variable "sshpubkey" {
    type = string
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

locals {
    info = {
        username = "${var.username}"
        sshpubkey = "${var.sshpubkey}"
        domain = "${var.domain}"
        hostname = "${var.hostname}"
		host_ip = "${var.host_nic_ip}"
    }
}

source "virtualbox-iso" "debian" {
    communicator = "none"
    guest_additions_mode = "disable"
    virtualbox_version_file = ""
	
    boot_wait = "10s"
    boot_keygroup_interval = "500ms"
    boot_command = [
        "<esc><wait>",
        "auto interface=enp0s8 packer/httpport={{.HTTPPort}} url=http://${var.host_nic_ip}:{{.HTTPPort}}/preseed.cfg",
        "<wait><enter>",
    ]
    guest_os_type = "Debian_64"
    iso_url = var.iso_url
    iso_checksum = var.iso_checksum
    iso_interface = "sata"
    http_content = {
        "/post_install.sh" = file("post_install.sh")
        "/preseed.cfg" = templatefile("${path.root}/preseed.pkrtpl", local.info)
    }
    cpus = var.cpus
    disk_size = "${var.disk_size}"
    memory = var.memory
	vboxmanage = [
        ["modifyvm", "{{.Name}}", "--nic1","bridged","--bridgeadapter1","${var.host_nic_name}"]
    ]
    headless = true
    vm_name = "control-node"
    keep_registered = true
    skip_export = true

    # No option to just create a VM and get out of the way
    disable_shutdown = true
    shutdown_timeout = "24h"
}

build {
    sources = ["sources.virtualbox-iso.debian"]
}
