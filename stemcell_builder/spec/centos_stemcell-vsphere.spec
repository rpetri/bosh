# Setup base chroot
stage centos_base_bootstrap
stage centos_base_yum

# CentOS bosh setup
stage centos_bosh_users
stage centos_bosh_rpms
stage bosh_monit
stage bosh_ruby
stage bosh_agent
stage centos_bosh_agent
stage bosh_sysstat
stage centos_bosh_sysctl
stage centos_bosh_ntpdate
stage bosh_sudoers

# Micro BOSH
if [ ${bosh_micro_enabled:-no} == "yes" ]
then
  stage bosh_micro
fi

# Install GRUB/kernel/etc
stage centos_system_grub
stage centos_system_kernel
stage centos_system_open_vm_tools

# Misc
stage system_parameters

# Finalisation
stage bosh_clean
stage bosh_harden
stage bosh_tripwire
stage centos_bosh_rpm_list

# Image/bootloader
stage image_create
stage centos_image_install_grub

stage image_vsphere_vmx
stage image_vsphere_ovf
stage image_vsphere_prepare_stemcell

# Final stemcell
stage stemcell
