variable "iso_checksum" {
  type    = string
  default = "file:https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-virt-3.23.4-x86_64.iso.sha256"
}

# The operating system. Can be wxp, w2k, w2k3, w2k8, wvista, win7, win8, win10, win11, l24 (Linux 2.4), l26 (Linux 2.6+), solaris or other. Defaults to other.
variable "os" {
  type    = string
  default = "l26"
}

variable "iso_url" {
  type    = string
  default = "https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-virt-3.23.4-x86_64.iso"
}

variable "vm_cpu_cores" {
  type    = string
  default = "2"
}

variable "vm_disk_size" {
  type    = string
  default = "20G"
}

variable "vm_memory" {
  type    = string
  default = "2048"
}

variable "vm_name" {
  type    = string
  default = "alpine-3.23-x64-server-template"
}

variable "ssh_password" {
  type    = string
  default = "password"
}

variable "ssh_username" {
  type    = string
  default = "localuser"
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
  template_description = "Alpine 3.23 template built ${legacy_isotime("2006-01-02 03:04:05")} username:password => localuser:password"
}

source "proxmox-iso" "alpine323" {
  boot_command = [
    "<wait10>root<enter><wait5>",
    "ifconfig eth0 up && udhcpc -i eth0<enter><wait5>",
    "wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh -O /tmp/install.sh<enter><wait>",
    "sh /tmp/install.sh http://{{ .HTTPIP }}:{{ .HTTPPort }}/answers<enter>"
  ]
  boot_key_interval      = "100ms"
  boot_keygroup_interval = "2s"
  http_directory         = "./http"

  boot_iso {
    type              = "ide"
    iso_checksum      = "${var.iso_checksum}"
    iso_url           = "${var.iso_url}"
    iso_storage_pool  = "${var.iso_storage_pool}"
    iso_download_pve  = true
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
  sources = ["source.proxmox-iso.alpine323"]

  provisioner "ansible" {
    playbook_file      = "ansible/reset-machine-id.yml"
    use_proxy          = false
    user               = "${var.ssh_username}"
    extra_arguments    = ["--extra-vars", "{ansible_python_interpreter: /usr/bin/python3, ansible_password: ${var.ssh_password}, ansible_sudo_pass: ${var.ssh_password}}"]
    ansible_env_vars   = ["ANSIBLE_HOME=${var.ansible_home}", "ANSIBLE_LOCAL_TEMP=${var.ansible_home}/tmp", "ANSIBLE_PERSISTENT_CONTROL_PATH_DIR=${var.ansible_home}/pc", "ANSIBLE_SSH_CONTROL_PATH_DIR=${var.ansible_home}/cp"]
    skip_version_check = true
  }

  provisioner "ansible" {
    playbook_file      = "ansible/reset-ssh-host-keys.yml"
    use_proxy          = false
    user               = "${var.ssh_username}"
    extra_arguments    = ["--extra-vars", "{ansible_python_interpreter: /usr/bin/python3, ansible_password: ${var.ssh_password}, ansible_sudo_pass: ${var.ssh_password}}"]
    ansible_env_vars   = ["ANSIBLE_HOME=${var.ansible_home}", "ANSIBLE_LOCAL_TEMP=${var.ansible_home}/tmp", "ANSIBLE_PERSISTENT_CONTROL_PATH_DIR=${var.ansible_home}/pc", "ANSIBLE_SSH_CONTROL_PATH_DIR=${var.ansible_home}/cp"]
    skip_version_check = true
  }

  provisioner "ansible" {
    playbook_file      = "ansible/validate-ludus-runtime.yml"
    use_proxy          = false
    user               = "${var.ssh_username}"
    extra_arguments    = ["--extra-vars", "{ansible_python_interpreter: /usr/bin/python3, ansible_password: ${var.ssh_password}, ansible_sudo_pass: ${var.ssh_password}, ansible_remote_tmp: /home/ludus/.ansible/tmp}"]
    ansible_env_vars   = ["ANSIBLE_HOME=${var.ansible_home}", "ANSIBLE_LOCAL_TEMP=${var.ansible_home}/tmp", "ANSIBLE_PERSISTENT_CONTROL_PATH_DIR=${var.ansible_home}/pc", "ANSIBLE_SSH_CONTROL_PATH_DIR=${var.ansible_home}/cp"]
    skip_version_check = true
  }
}
