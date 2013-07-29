#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

# This stage does not replace the bosh_agent stage.  Both should be specified in the spec.

install -m 0755 ${dir}/assets/boshagent-start ${chroot}/usr/sbin/
cp ${dir}/assets/bosh_agent.conf ${chroot}/etc/init/bosh_agent.conf
