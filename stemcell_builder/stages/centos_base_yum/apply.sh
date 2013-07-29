#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

# Required packages for a stemcell.  Translated from the list of .deb pkg used in ubuntu stemcells
rpms="gcc-c++ kernel-devel openssl-devel lsof strace bind bind-utils tcpdump \
iputils curl libcurl libcurl-devel wget bison readline-devel libxml2 libxml2-devel \
libxslt libxslt-devel zip unzip nfs-utils flex psmisc iptables sysstat rsync \
openssh-server traceroute ncurses-devel quota libaio gdb tripwire \
libyaml-devel cmake sudo tar make vi vim glibc-static syslinux-devel"

# Setup repos.
mkdir -p ${chroot}/etc
cp /etc/resolv.conf ${chroot}/etc/

# The extra packages repo is used to get third party packages such as tripwire
cp ${dir}/assets/epel.repo ${chroot}/etc/yum.repos.d/epel.repo
cp ${dir}/assets/RPM-GPG-KEY-EPEL-6 ${chroot}/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6

# The vmware repo is used to get the vmware tools and kernel modules.
cp ${dir}/assets/vmware.repo ${chroot}/etc/yum.repos.d/vmware.repo
run_in_chroot ${chroot} "rpm --import http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub"
run_in_chroot ${chroot} "rpm --import http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub"

# Install basic package groups.
run_in_chroot $chroot "yum -y groupinstall Base"
run_in_chroot $chroot "yum -y groupinstall 'Development Tools'"

# Install the additional rpms
run_in_chroot $chroot "yum -y install ${rpms}"

# Firstboot script
cp $assets_dir/etc/rc.local $chroot/etc/rc.local
cp $assets_dir/root/firstboot.sh $chroot/root/firstboot.sh
chmod 0755 $chroot/root/firstboot.sh
