variable "iso_checksum" {
  type    = string
  default = "none"
}

# VyOS is Linux based.
variable "os" {
  type    = string
  default = "l26"
}

variable "iso_url" {
  type    = string
  default = "https://github.com/vyos/vyos-nightly-build/releases/download/2026.05.25-0048-rolling/vyos-2026.05.25-0048-rolling-generic-amd64.iso"
}

variable "iso_file" {
  type    = string
  default = "local:iso/vyos-2026.05.25-0048-rolling-generic-amd64.iso"
}

variable "vm_cpu_cores" {
  type    = string
  default = "2"
}

variable "vm_disk_size" {
  type    = string
  default = "10G"
}

variable "vm_memory" {
  type    = string
  default = "2048"
}

variable "vm_name" {
  type    = string
  default = "vyos-rolling-x64-router-template"
}

variable "ssh_password" {
  type    = string
  default = "vyos"
}

variable "ssh_username" {
  type    = string
  default = "vyos"
}

# This block has to be in each file or packer won't be able to use the variables
variable "proxmox_url" {
  type = string
}
variable "proxmox_host" {
  type = string
}
variable "proxmox_username" {
  type = string
}
variable "proxmox_password" {
  type      = string
  sensitive = true
}
variable "proxmox_storage_pool" {
  type = string
}
variable "proxmox_storage_format" {
  type = string
}
variable "proxmox_skip_tls_verify" {
  type = bool
}
variable "proxmox_pool" {
  type = string
}
variable "iso_storage_pool" {
  type = string
}
variable "ansible_home" {
  type = string
}
variable "ludus_nat_interface" {
  type = string
}
####

locals {
  template_description = "VyOS rolling router template built ${legacy_isotime("2006-01-02 03:04:05")} username:password => vyos:vyos"
}

source "proxmox-iso" "vyosrolling" {
  boot_wait = "20s"
  boot_command = [
    "<enter><wait90s>",
    "vyos<enter><wait>",
    "vyos<enter><wait5s>",
    "configure<enter><wait>",
    "set service ssh<enter><wait>",
    "set interfaces ethernet eth0 address dhcp<enter><wait>",
    "set system host-name vyos<enter><wait>",
    "commit<enter><wait>",
    "save<enter><wait>",
    "exit<enter><wait>",
    "echo vyos | sudo -S -v<enter><wait>",
    "printf '%s\\n' 'y' '' '' 'y' '' '' '' 'vyos' 'vyos' '' | install image<enter><wait180s>",
    "reboot<enter><wait>",
    "y<enter>"
  ]
  boot_key_interval      = "100ms"
  boot_keygroup_interval = "2s"

  boot_iso {
    type              = "ide"
    iso_file          = "${var.iso_file}"
    iso_storage_pool  = "${var.iso_storage_pool}"
    unmount           = true
    keep_cdrom_device = false
  }

  communicator    = "ssh"
  cores           = "${var.vm_cpu_cores}"
  cpu_type        = "host"
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "${var.vm_disk_size}"
    format       = "${var.proxmox_storage_format}"
    storage_pool = "${var.proxmox_storage_pool}"
    type         = "scsi"
    ssd          = true
    discard      = true
    io_thread    = true
  }
  pool                     = "${var.proxmox_pool}"
  insecure_skip_tls_verify = "${var.proxmox_skip_tls_verify}"
  memory                   = "${var.vm_memory}"
  network_adapters {
    bridge = "${var.ludus_nat_interface}"
    model  = "virtio"
  }
  node                 = "${var.proxmox_host}"
  os                   = "${var.os}"
  password             = "${var.proxmox_password}"
  proxmox_url          = "${var.proxmox_url}"
  template_description = "${local.template_description}"
  username             = "${var.proxmox_username}"
  vm_name              = "${var.vm_name}"
  ssh_password         = "${var.ssh_password}"
  ssh_username         = "${var.ssh_username}"
  ssh_wait_timeout     = "30m"
  task_timeout         = "20m" // On slow disks the imgcopy operation takes > 1m
}

build {
  sources = ["source.proxmox-iso.vyosrolling"]

  provisioner "shell" {
    inline = [
      "vbash -lc 'source /opt/vyatta/etc/functions/script-template; configure; set service ssh; set interfaces ethernet eth0 address dhcp; set system host-name vyos; commit; save'",
      "sudo rm -f /tmp/*"
    ]
  }
}
