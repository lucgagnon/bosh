#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

# Explicit make the mount point for bind-mount
# Otherwise using none ubuntu host will fail creating vm
mkdir -p $chroot/warden-cpi-dev

# Run rsyslog and ssh using runit and replace /usr/sbin/service with a script which call runit
mkdir -p $chroot/etc/sv/ $chroot/etc/service/
cp -a $assets_dir/runit/rsyslog/ $chroot/etc/sv/rsyslog
cp -a $assets_dir/runit/ssh/ $chroot/etc/sv/ssh

run_in_chroot $chroot "
chmod +x /etc/sv/rsyslog/run
chmod +x /etc/sv/ssh/run
ln -s /etc/sv/rsyslog /etc/service/rsyslog
ln -s /etc/sv/ssh /etc/service/ssh
"

if grep -q -i ubuntu $chroot/etc/issue
# if this is Ubuntu stemcell
then
  # Replace /usr/sbin/service with a script which calls runit
  run_in_chroot $chroot "
  dpkg-divert --local --rename --add /usr/sbin/service
"
  # This is a Hacky way to force Warden in Warden to use overlayfs for now
  sed -i s/lucid/precise/ $chroot/etc/lsb-release
# Centos Stemcell
else
  # Centos stemcll hack to force Warden in Warden to use overlayfs for now
  echo "DISTRIB_CODENAME=precise" > $chroot/etc/lsb-release
  echo "Ubuntu 12.04.3 LTS" > $chroot/etc/issue
fi

cp -f $assets_dir/service $chroot/usr/sbin/service

run_in_chroot $chroot "
chmod +x /usr/sbin/service
"
