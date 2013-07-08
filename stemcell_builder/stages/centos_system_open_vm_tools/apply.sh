#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

run_in_chroot $chroot "yum -y install vmware-tools-esx-kmods vmware-tools-esx-nox"

#install -m 0777 ${dir}/assets/VMware-ovftool-3.0.1-801290-lin.x86_64.txt ${chroot}/VMware-ovftool-3.0.1-801290-lin.x86_64.txt
#chmod 777 ${chroot}/tmp
#run_in_chroot ${chroot} "/usr/bin/yes yes | /VMware-ovftool-3.0.1-801290-lin.x86_64.txt"
#rm ${chroot}/VMware-ovftool-3.0.1-801290-lin.x86_64.txt
