#!/bin/sh
set -eux

ANSWER_URL="${1:?answer file URL required}"
DISK="${DISK:-/dev/sda}"
TARGET="/mnt"

if ! ip addr show eth0 | grep -q "inet "; then
  ifconfig eth0 up
  udhcpc -i eth0
fi

wget "$ANSWER_URL" -O /tmp/answers
ERASE_DISKS="$DISK" setup-alpine -e -f /tmp/answers

mkdir -p "$TARGET"
mounted=0
for part in "${DISK}3" "${DISK}2" "${DISK}1"; do
  if mount "$part" "$TARGET"; then
    mounted=1
    break
  fi
done

if [ "$mounted" -ne 1 ]; then
  echo "Unable to mount installed Alpine root filesystem from $DISK" >&2
  exit 1
fi

mount -t proc proc "$TARGET/proc"
mount --rbind /sys "$TARGET/sys"
mount --rbind /dev "$TARGET/dev"
cp /etc/resolv.conf "$TARGET/etc/resolv.conf"

chroot "$TARGET" /bin/sh <<'CHROOT'
set -eux

apk update
apk add --no-cache acpid ca-certificates curl dbus eudev openssh python3 qemu-guest-agent sudo

adduser -D -s /bin/ash localuser || true
addgroup localuser wheel || true
echo "localuser:password" | chpasswd
echo "root:password" | chpasswd

# Ludus 2.3 runs range Ansible under its service account and resolves the
# default remote staging path to /home/ludus/.ansible/tmp before connecting as
# the template's localuser account. Other Linux templates already tolerate
# that contract. Create the exact private staging tree here so Alpine can pass
# fact gathering before any range role runs.
mkdir -p /home/ludus/.ansible/tmp
chown -R localuser:localuser /home/ludus
chmod 0700 /home/ludus /home/ludus/.ansible /home/ludus/.ansible/tmp

mkdir -p /etc/sudoers.d
echo "localuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/localuser
chmod 0440 /etc/sudoers.d/localuser

sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

rc-update add sshd default
rc-update add qemu-guest-agent default || true
rc-update add acpid default || true
CHROOT

umount -l "$TARGET/dev"
umount -l "$TARGET/sys"
umount -l "$TARGET/proc"
umount "$TARGET"

reboot
