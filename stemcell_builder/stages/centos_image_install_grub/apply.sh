#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

disk_image_name=root.img

# unmap the loop device in case it's already mapped
kpartx -dvs $work/$disk_image_name

# Map partition in image to loopback
dev=$(kpartx -avs $work/$disk_image_name | grep "^add" | cut -d" " -f3)
loopback_dev="/dev/mapper/$dev"

# Mount partition
mnt=$work/mnt

mkdir -p $mnt
mount $loopback_dev $mnt

# Install bootloader
mkdir -p $mnt/tmp/grub

touch $mnt/tmp/grub/$disk_image_name

mount --bind $work/$disk_image_name $mnt/tmp/grub/$disk_image_name


cat > $mnt/tmp/grub/device.map <<EOS
(hd0) $disk_image_name
EOS

run_in_chroot $mnt "
cd /tmp/grub
/sbin/grub --device-map=device.map --batch <<EOF
root (hd0,0)
setup (hd0)
EOF
"

# Figure out uuid of partition
uuid=$(blkid -c /dev/null -sUUID -ovalue /dev/mapper/$dev)

# Link the kernel and initrd to their generic names.
run_in_chroot $mnt "
ln -f /boot/vmlinuz-* /boot/vmlinuz
ln -f /boot/initramfs-* /boot/initramfs
"

# Generate basic grub.conf which boots root based on the UUID of the image fs.
cat > $mnt/boot/grub/grub.conf << EOF
default=0
timeout=1
title CentOS
  root (hd0,0)
  kernel /boot/vmlinuz ro root=UUID=$uuid
  initrd /boot/initramfs
EOF

# NOTE: Don't change "groot" to use a UUID. The pv-boot grub mechanism on EC2
# can't use this to figure out which device contains the kernel. It does
# understand "root (hd0,0)", which is the default.

# Clean up bootloader stuff
umount $mnt/tmp/grub/$disk_image_name
rm -rf $mnt/tmp/grub

# Unmount partition
echo "Unmounting $mnt"
for try in $(seq 0 9); do
  sleep $try
  echo -n "."
  umount $mnt || continue
  break
done
echo

if mountpoint -q $mnt; then
  echo "Could not unmount $mnt after 10 tries"
  exit 1
fi

# Unmap partition
echo "Removing device mappings for $disk_image_name"
for try in $(seq 0 9); do
  sleep $try
  echo -n "."
  kpartx -dvs $work/$disk_image_name || continue
  break
done

if [ -b $loopback_dev ]; then
  echo "Could not remove device mapping at $loopback_dev"
  exit 1
fi
