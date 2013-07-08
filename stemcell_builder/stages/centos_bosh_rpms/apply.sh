#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

# Install additional rpm packages required by bosh.
rpms="mg htop"

run_in_chroot ${chroot} "yum -y install ${rpms}"
