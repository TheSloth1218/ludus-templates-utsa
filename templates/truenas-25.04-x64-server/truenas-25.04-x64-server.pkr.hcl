variable "iso_checksum" {
  type    = string
  default = "sha256:c766aed47ec6cd872a7c9159929280245c4f5a26a0358f5522e3245f04be54cc"
}

# TrueNAS SCALE/CE is Linux based.
variable "os" {
  type    = string
  default = "l26"
}

variable "iso_url" {
  type    = string
  default = "https://download.sys.truenas.net/TrueNAS-SCALE-Fangtooth/25.04.2.6/TrueNAS-SCALE-25.04.2.6.iso"
}

variable "vm_cpu_cores" {
  type    = string
  default = "4"
}

variable "vm_disk_size" {
  type    = string
  default = "64G"
}

variable "vm_memory" {
  type    = string
  default = "8192"
}

variable "vm_name" {
  type    = string
  default = "truenas-25.04-x64-server-template"
}

variable "truenas_password" {
  type    = string
  default = "password"
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
  template_description = "TrueNAS SCALE 25.04.2.6 template built ${legacy_isotime("2006-01-02 03:04:05")} username:password => truenas_admin:password"
}

source "proxmox-iso" "truenas2504" {
  # TrueNAS does not publish a preseed/autoinstall interface. This drives the
  # official installer TUI with the default choices: install, first disk,
  # clean install, create truenas_admin, UEFI boot, then reboot.
  boot_wait = "20s"
  boot_command = [
    "<enter><wait120s>",
    "<enter><wait5s>",
    "<spacebar><enter><wait5s>",
    "<left><enter><wait5s>",
    "<enter><wait5s>",
    "${var.truenas_password}<enter><wait>",
    "${var.truenas_password}<enter><wait5s>",
    "<enter><wait900s>",
    "<enter><wait5s>",
    "<enter>"
  ]
  boot_key_interval      = "100ms"
  boot_keygroup_interval = "2s"

  boot_iso {
    type              = "ide"
    iso_checksum      = "${var.iso_checksum}"
    iso_url           = "${var.iso_url}"
    iso_storage_pool  = "${var.iso_storage_pool}"
    iso_download_pve  = true
    unmount           = true
    keep_cdrom_device = false
  }

  bios       = "ovmf"
  qemu_agent = false
  efi_config {
    efi_storage_pool  = "${var.proxmox_storage_pool}"
    pre_enrolled_keys = false
    efi_type          = "4m"
  }

  communicator    = "none"
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
  task_timeout         = "20m" // On slow disks the imgcopy operation takes > 1m
}

build {
  sources = ["source.proxmox-iso.truenas2504"]
}
