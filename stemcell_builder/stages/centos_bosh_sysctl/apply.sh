#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

# Setup kernel parameters
sed -i -e 's/net.ipv4.conf.default.rp_filter = 1.*/net.ipv4.conf.default.rp_filter = 2/' ${chroot}/etc/sysctl.conf

if ! grep -q "net.ipv4.conf.all.rp_filter = 2" ${chroot}/etc/sysctl.conf  ; then
	echo "net.ipv4.conf.all.rp_filter = 2" >> ${chroot}/etc/sysctl.conf
fi

cp ${assets_dir}/network ${chroot}/etc/sysconfig/network

