#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

# Define variables
mirror=

# Use ISO as a base source of packages
if [ ! -z "${CENTOS_ISO:-}" ]
then
  mkdir -p $chroot/source
  iso_mount_dir=/source
  iso_mount_path=$chroot/${iso_mount_dir}

  echo "Mounting iso from $CENTOS_ISO at $iso_mount_path"
  mount -o loop -t iso9660 $CENTOS_ISO $iso_mount_path
  add_on_exit "umount $iso_mount_path"
  mirror="file://$iso_mount_path"
fi

RPM="rpm --root $chroot -i "
pkg_path=$iso_mount_path/Packages

# Initialize the rpm database
mkdir -p $chroot/var/lib/rpm
rpm --root $chroot --initdb

# Insert the iso mount paths into the yum configs.
sed -e "s:\[CDPATH\]:${iso_mount_path}:g" ${dir}/assets/yum_template.conf > ${dir}/assets/yum.conf
sed -e "s:\[CDPATH\]:${iso_mount_dir}:g" ${dir}/assets/yum_template.conf > ${chroot}/yum.conf

# Install the base system
$RPM $pkg_path/centos-release*.rpm

# Install yum in the chroot environment using yum on the build environment.  Once this is done, all future
# invokations of yum are done withing the chroot environment.
yum -q -y --config ${dir}/assets/yum.conf --disablerepo=\* --enablerepo=localrepo --installroot ${chroot} install yum
