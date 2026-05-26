# TrueNAS 25.04 Ludus Template

This template builds a TrueNAS SCALE/Community Edition 25.04.2.6 VM from the
official ISO.

Default credentials created by the installer automation:

- Username: `truenas_admin`
- Password: `password`

Notes:

- TrueNAS is an appliance OS, not a normal Debian/Ubuntu server. It does not
  provide a supported cloud-init, preseed, or kickstart interface.
- The Packer template uses keyboard automation against the official installer
  TUI. If iXsystems changes the installer screens, adjust `boot_command`.
- The template intentionally uses `communicator = "none"` because SSH is not a
  reliable default service during TrueNAS installation. After cloning the
  template in Ludus, enable SSH/API access in TrueNAS and run Ansible against
  the appliance using the TrueNAS API or SSH-compatible playbooks.
- TrueNAS requires at least 8 GB RAM and a 20 GB boot device; this template
  allocates 8 GB RAM and a 64 GB boot disk by default.
