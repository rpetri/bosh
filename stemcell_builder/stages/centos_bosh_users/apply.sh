#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

# Centos and Ubuntu use sligtly different toolsets to create users and groups.

ADDGROUP=/usr/sbin/groupadd
# assert that the select util is present and executable
[ -x ${chroot}/${ADDGROUP} ]

ADDUSER=/usr/sbin/adduser

# Set up users/groups
run_in_chroot $chroot "
${ADDGROUP} --system admin
${ADDUSER} --comment Centos vcap -G admin,adm,audio,cdrom,dialout,floppy,video,dip
echo \"vcap:${bosh_users_password}\" | /usr/sbin/chpasswd
echo \"root:${bosh_users_password}\" | /usr/sbin/chpasswd
"

cp $assets_dir/sudoers $chroot/etc/sudoers

echo "export PATH=$bosh_dir/bin:$PATH" >> $chroot/root/.bashrc
echo "export PATH=$bosh_dir/bin:$PATH" >> $chroot/home/vcap/.bashrc
