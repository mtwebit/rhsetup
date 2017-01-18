#!/bin/bash
#
# description: Install a service to mount a Ceph Storage (using rbd module only)
#   created by Tamas Meszaros <meszaros@mit.bme.hu>
#
# Version 20141211
#
# References
#   http://cephnotes.ksperis.com/blog/2014/01/09/map-rbd-kernel-without-install-ceph-common
#   https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-bus-rbd
#
# This script can be freely distributed and modified under GPLv2.
# See http://www.gnu.org/licenses/gpl-2.0.html
#

# Ask a question and provide a default answer
# Sets the variable to the answer or the default value
# 1:varname 2:question 3:default value
function ask() {
  echo -n "${2}: [$3] "
  read pp
  if [ "$pp" == "" ]; then
    eval ${1}=$3
  else
    eval ${1}=$pp
  fi
}

# Ask a yes/no question, returns true on answering y
# 1:question 2:default answer
function askif() {
  ask ypp "$1" "$2"
  [ "$ypp" == "y" ]
}

echo "Gathering configuration data:"
ask ceph_mon_ip "IP address(es) of the monitors" "IP1,IP2"
ask ceph_admin "Client admin name" admin
ask ceph_key "${ceph_admin}'s key" ""
ask ceph_pool "Ceph pool"
ask ceph_image "Image name"

echo "Creating systemd service for ${ceph_image}"
cat <<EOF >/etc/systemd/system/rbd-${ceph_pool}-${ceph_image}.service
[Unit]
Description=RADOS block device mapping for "${ceph_image}" image in "${ceph_pool}" pool
Conflicts=shutdown.target
Wants=network-online.target
# Remove this if you don't have Networkmanager
After=NetworkManager-wait-online.service

[Service]
Type=oneshot
ExecStart=/sbin/modprobe rbd
ExecStart=/bin/sh -c "/bin/echo ${ceph_mon_ip} name=${ceph_admin},secret=${ceph_key} ${ceph_pool} ${ceph_image} >/sys/bus/rbd/add"
TimeoutSec=0
RemainAfterExit=yes

[Install]
WantedBy=remote-fs-pre.target
WantedBy=multi-user.target
EOF

if askif "Do you want to automatically mount ${ceph_image} on boot?" y; then
  ask local_mount "Local mount point" "/storage/${ceph_pool}/${ceph_image}"
  if [ ! -d ${local_mount} ]; then
    if askif "${local_mount} does not exists. Create?" y; then
      mkdir -p ${local_mount}
      echo "${local_mount} created."
    fi
  fi
  ask ceph_fstype "Filesystem type" "xfs"
  ask ceph_fslabel "Filesystem label" "$ceph_image"
  echo "Enabling NetworkManager-wait-online.service to help boot time startup."
  systemctl enable NetworkManager-wait-online.service
  echo "Enabling rbd-${ceph_pool}-${ceph_image} service."
  systemctl enable rbd-${ceph_pool}-${ceph_image}
  echo "LABEL=${ceph_fslabel} ${local_mount} ${ceph_fstype} rw,noauto,x-systemd.automount,x-systemd.device-timeout=10,seclabel,relatime,attr2,inode64,sunit=8192,swidth=8192,noquota 0 2" >> /etc/fstab
  echo "Mount point added to /etc/fstab. It requires the '"${ceph_fslabel}"' label to work."
fi
cat <<EOF
All set up. Here's what to do:
1. Create the block storage image in your Ceph cluster (on the admin node).
   rbd --pool=${ceph_pool} --size={size} create ${ceph_image}
2. Start the local rbd client service.
   systemctl start rbd-${ceph_pool}-${ceph_image}.service
3. Create and label the filesystem on this machine.
   mkfs.xfs -L ${ceph_fslabel} /dev/rbd/${ceph_pool}/${ceph_image}
   You can also create a complete disk label and partition table if you like.
4. Mount the new filesystem.
   mount ${local_mount}
5. If you run out of space...
   Ceph admin node: rbd --pool=${ceph_pool} --size={new-size} resize ${ceph_image}
   Local system: xfs_growfs ${local_mount}
Happy cehping!
EOF


