#!/bin/sh
rm /etc/resolv.conf
touch /etc/resolv.conf
rm /etc/ssh/ssh_host*key*

# Regenerate the host keys
/etc/init.d/sshd restart

/etc/init.d/network restart

