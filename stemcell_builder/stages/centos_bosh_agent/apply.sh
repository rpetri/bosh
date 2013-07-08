#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

# This stage does not replace the bosh_agent stage.  Both should be specified in the spec.

install -m 0755 ${dir}/assets/bosh_agent ${chroot}/etc/rc.d/init.d

# link to runlevel 4 & 5 too
ln -s ../init.d/bosh_agent ${chroot}/etc/rc.d/rc3.d/S50bosh_agent
ln -s ../init.d/bosh_agent ${chroot}/etc/rc.d/rc4.d/S50bosh_agent
ln -s ../init.d/bosh_agent ${chroot}/etc/rc.d/rc5.d/S50bosh_agent
