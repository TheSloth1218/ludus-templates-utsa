variable "description" {
  type    = string
  default = "Rocky Linux 10.2 minimal x64 server."
}

variable "icon_path" {
  type    = string
  default = "icon.png"
}

variable "iso_checksum" {
  type    = string
  default = "file:https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10.2-x86_64-minimal.iso.CHECKSUM"
}

# Proxmox guest operating-system classification.
variable "os" {
  type    = string
  default = "l26"
}

variable "iso_url" {
  type    = string
  default = "https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10.2-x86_64-minimal.iso"
}

variable "vm_cpu_cores" {
  type    = string
  default = "4"
}

variable "vm_disk_size" {
  type    = string
  default = "60G"
}

variable "vm_memory" {
  type    = string
  default = "8192"
}

variable "vm_name" {
  type    = string
  default = "rocky-10-x64-server-template"
}

# Build-time SSH access. AWX will replace this bootstrap access later.
variable "ssh_password" {
  type    = string
  default = "root"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

# Variables supplied by Ludus.
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

locals {
  template_description = "Rocky Linux 10.2 template built ${legacy_isotime("2006-01-02 03:04:05")} username:password => localuser:password"
}

source "proxmox-iso" "rocky10" {
  # Rocky 10 uses a GRUB2 menu. Enter the GRUB command prompt and boot the
  # installer kernel directly with the Packer-hosted Kickstart URL.
  boot_wait         = "10s"
  boot_key_interval = "50ms"

  boot_command = [
    "c<wait>",
    "linux /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=Rocky-10-2-x86_64-dvd inst.text rd.neednet=1 ip=dhcp inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rocky-10-preseed.cfg quiet<enter><wait>",
    "initrd /images/pxeboot/initrd.img<enter><wait>",
    "boot<enter><wait>"
  ]

  http_directory = "./http"

  communicator = "ssh"

  cores    = var.vm_cpu_cores
  cpu_type = "host"
  memory   = var.vm_memory

  scsi_controller = "virtio-scsi-single"

  disks {
    disk_size    = var.vm_disk_size
    format       = var.proxmox_storage_format
    storage_pool = var.proxmox_storage_pool
    type         = "scsi"
    ssd          = true
    discard      = true
    io_thread    = true
  }

  network_adapters {
    bridge = var.ludus_nat_interface
    model  = "virtio"
  }

  pool                     = var.proxmox_pool
  node                     = var.proxmox_host
  os                       = var.os
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = var.proxmox_skip_tls_verify

  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  iso_storage_pool = var.iso_storage_pool
  unmount_iso      = true

  vm_name              = var.vm_name
  template_description = local.template_description

  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_wait_timeout = "45m"

  # Shared NFS and nested environments can need additional time for disk copy.
  task_timeout = "30m"
}

build {
  sources = [
    "source.proxmox-iso.rocky10"
  ]

  provisioner "ansible" {
    playbook_file = "ansible/generalize.yml"
    use_proxy     = false
    user          = var.ssh_username

    extra_arguments = [
      "--extra-vars",
      "{ansible_python_interpreter: /usr/bin/python3, ansible_password: ${var.ssh_password}, ansible_sudo_pass: ${var.ssh_password}}"
    ]

    ansible_env_vars = [
      "ANSIBLE_HOME=${var.ansible_home}",
      "ANSIBLE_LOCAL_TEMP=${var.ansible_home}/tmp",
      "ANSIBLE_PERSISTENT_CONTROL_PATH_DIR=${var.ansible_home}/pc",
      "ANSIBLE_SSH_CONTROL_PATH_DIR=${var.ansible_home}/cp"
    ]

    skip_version_check = true
  }
}
