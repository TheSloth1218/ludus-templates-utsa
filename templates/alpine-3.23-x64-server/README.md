# Alpine 3.23 Ludus template

This template provides the `localuser` SSH/bootstrap identity recorded in its
Proxmox description. It also creates `/home/ludus/.ansible/tmp`, owned by
`localuser:localuser` with mode `0700`. Ludus 2.3 resolves that path before
range fact gathering, so it must be usable before any per-range Ansible role
can run.

The final Packer provisioner forces `ansible_remote_tmp` to that exact path and
runs an Ansible module plus read-only account, ownership, mode, Python, and
non-interactive sudo checks. A template build must fail rather than publish an
image when any part of that contract regresses.

The Proxmox builder also waits one minute for the Alpine live ISO login prompt
before entering `root`. This keeps commands from being typed into the username
field when ISO startup or backing storage is slower than usual.

## Replace the built image

Existing linked clones must be destroyed before removing their base template.
Then, from an authenticated Ludus CLI, refresh the registered source and build
the replacement serially so its validation log is retained:

```console
ludus templates rm -n alpine-3.23-x64-server-template
ludus source sync thesloth1218-ludus-templates-utsa --force
ludus templates build -n alpine-3.23-x64-server-template
ludus templates logs -f
ludus templates list
```

Do not select the template for a range unless the build succeeds and
`ludus templates list` reports it as built.
