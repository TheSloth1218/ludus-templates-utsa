# VyOS Rolling Ludus Template

This template builds a minimal VyOS rolling router image from the public current
branch ISO.

Default credentials:

- Username: `vyos`
- Password: `vyos`

Notes:

- This template uses the local Proxmox ISO file
  `local:iso/vyos-2026.05.25-0048-rolling-generic-amd64.iso` to avoid repeated
  remote downloads from GitHub release redirect URLs.
- The source URL for that ISO was the official rolling `version.json` feed:
  `https://github.com/vyos/vyos-nightly-build/releases/download/2026.05.25-0048-rolling/vyos-2026.05.25-0048-rolling-generic-amd64.iso`.
- VyOS is a network appliance. Use VyOS-aware Ansible modules/connection
  settings for post-deploy configuration instead of normal Linux package/config
  roles.
