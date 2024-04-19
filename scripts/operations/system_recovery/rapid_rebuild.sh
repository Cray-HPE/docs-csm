#!/bin/bash
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
set -o pipefail

# Print an error message and exit
function err_exit {
  echo "ERROR: $*" >&2
  exit 1
}

# Must run from m001
if [[ $(hostname) != "ncn-m001" ]]; then
  err_exit "Must be run on m001"
fi

# Remove any strings 'registry.local' or 'packages.local' from any lines in /etc/hosts
# Add or replace the pit line to include 'registry.local' and 'packages.local'
cp /etc/hosts /etc/hosts."$(date +%Y%m%d_%H%M%S)"
IP=$(grep ncn-m001.nmn /etc/hosts | awk '{print $1}')
pitregistry="${IP}      pit.nmn pit registry.local packages.local"
sed -i -E -e 's/registry.local//g' -e 's/packages.local//g' /etc/hosts
grep -q pit /etc/hosts && sed -i "s/.*pit.*/${pitregistry}/" /etc/hosts || echo ${pitregistry} >> /etc/hosts

# Exit if required services are not running -- dnsmasq will be checked later
systemctl is-active --quiet nexus.service \
  && systemctl is-active --quiet minio.service \
  && systemctl is-active --quiet basecamp.service \
  && systemctl is-active --quiet apache2.service \
  && systemctl is-active --quiet conman.service \
  && systemctl is-active --quiet apparmor.service \
  && echo "Pit disk services are running" || err_exit "Not all pit disk services are running"

# Check that needed environment variables are set
env_vars=("IPMI_PASSWORD" "SYSTEM_NAME")
for each in "${env_vars[@]}"; do
  if [ -z "${!each}" ]; then
    err_exit "$each is not defined"
  fi
done

# Reset all the NCN keys
truncate --size=0 /root/.ssh/known_hosts 2>&1
grep -oP "(ncn-\w+)" /etc/hosts | sort -u | xargs -t -i ssh-keyscan -H \{\} >> /root/.ssh/known_hosts

# Disable/stop etcd on m001 and delete the database
systemctl disable --now etcd.service
rm -rf /var/lib/etcd/*

# Temporary backup of files
mkdir -p /tmp/backup_kubernetes
mv /etc/kubernetes/* /tmp/backup_kubernetes/

# Remove files in /etc/ceph from m001
rm -rf /etc/ceph/*

# Unmount /etc/cray/upgrade/csm on m001
umount /etc/cray/upgrade/csm --force

# Remove the all master and worker NCNs from the kubernetes cluster
pdsh -b -w "$(grep -oP '(ncn-m\w+|ncn-w\w+)' /etc/hosts | sort -u | tr -t '\n' ',')" 'kubeadm reset -f'

# Remove the kube-ipvs0 link -- https://github.com/k3s-io/k3s/issues/5643
pdsh -b -w "$(grep -oP '(ncn-m\w+|ncn-w\w+)' /etc/hosts | sort -u | tr -t '\n' ',')" 'ip link delete kube-ipvs0'

# Now that k8s is shutdown, start dnsmasq and setup the squash fs links
systemctl start dnsmasq.service

# Set network config for PIT/dnsmasq on m001
sed -i 's/^NETCONFIG_DNS_POLICY=.*/NETCONFIG_DNS_POLICY="auto"/' /etc/sysconfig/network/config
sed -i -E 's/NETCONFIG_DNS_FORWARDER="\w+"/NETCONFIG_DNS_FORWARDER="dnsmasq"/' /etc/sysconfig/network/config
netconfig update -f

# Setup links for NCN boot images and check DHCP
/root/bin/set-sqfs-links.sh

# Fix links for worker NCN images
echo "Updating boot artifact links for NCN worker nodes..."
pushd /var/www || err_exit "Failed changing directory to /var/www"
# shellcheck disable=SC2045
for WDIR in $(ls -d ncn-w*); do
  echo "Updating boot artifact links for $WDIR..."
  pushd $WDIR || err_exit "Failed changing directory to $(pwd)/$WDIR"
  # Modify links to point to worker images
  for art in kernel initrd.img.xz rootfs; do
    new_target=$(ls -l $art | awk '{ print $NF }' | sed 's#/data/k8s/#/data/worker/#') || err_exit "Error parsing symbolic link: $(pwd)/$art"
    [[ -n $new_target ]] || err_exit "Error finding target of symbolic link $(pwd)/$art"
    [[ -f $new_target ]] || err_exit "File does not exist: $(pwd)/$new_target"
    ln -snf $new_target $art || err_exit "Command failed: ln -snf $new_target $art"
  done
  popd || err_exit "Failed changing directory back to /var/www"
done
popd || err_exit "Failed returning to previous directory"

# Edit /etc/dnsmasq.d/statics.conf on m001 for pit nexus
DNSFILE="/etc/dnsmasq.d/statics.conf"
NMNIP=$(grep ncn-m001.nmn /etc/hosts | awk '{print $1}')
pitnexus="host-record=registry,registry.local,packages,packages.local,${NMNIP} # pit nexus"
sed -i "s/.*registry.*/${pitnexus}/" ${DNSFILE}
systemctl restart dnsmasq.service

# Edit m001 /etc/hosts to comment out ipv6 entry for ncn-m001 (.e.g. ::1 drax-ncn-m001.local drax-ncn-m001 ncn-m001 x3000c0s1b0n0)
sed -i '/^::1 '"${SYSTEM_NAME}"'/s/^/#/' /etc/hosts

# Exit if dnsmasq service is not running
systemctl is-active --quiet dnsmasq.service \
  && echo "Pit disk dnsmasq service is running" || err_exit "Pit disk dnsmasq service is not running"

export mtoken='ncn-m(?!001)\w+-mgmt'
export stoken='ncn-s\w+-mgmt'
export wtoken='ncn-w\w+-mgmt'
USERNAME=$(whoami)
export USERNAME

# Power off the NCNs (excluding ncn-m001)
ncn_list="$(grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u)"
echo "$ncn_list" | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off

# Wait for the NCNs to power off before powering back on. Exit if any NCNs still report as on after 1 minute.
count=0
powerStatus=$(echo "$ncn_list" | xargs -i ipmitool -I lanplus -U $USERNAME -E -H {} power status)
while [[ $count -lt 6 ]] && [[ $powerStatus =~ "is on" ]]; do
  sleep 10
  powerStatus=$(echo "$ncn_list" | xargs -i ipmitool -I lanplus -U $USERNAME -E -H {} power status)
  count=$((count + 1))
done
if [[ $powerStatus =~ "is on" ]]; then
  err_exit "Not all NCNs have powered off"
fi

# Set the NCNs to PXE boot
echo "$ncn_list" | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} chassis bootdev pxe options=efiboot

# Power on and rebuild the NCNs
echo "$ncn_list" | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power on
