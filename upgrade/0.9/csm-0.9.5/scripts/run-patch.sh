#!/usr/bin/env bash

# Get the list of NCNs.
NCNS=$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  paste -sd ',')

function run_pdsh_command() {
    pdsh -b -w "$NCNS" "$1"
}

set -x

# Add the repos with the new RPMs and refresh them.
run_pdsh_command 'zypper ar https://packages.local/repository/SUSE-SLE-Module-Basesystem-15-SP2-x86_64-Updates SUSE-SLE-Module-Basesystem-15-SP2-x86_64-Updates'
run_pdsh_command 'zypper ar https://packages.local/repository/SUSE-SLE-Module-Development-Tools-15-SP2-x86_64-Updates SUSE-SLE-Module-Development-Tools-15-SP2-x86_64-Updates'
run_pdsh_command 'zypper refresh SUSE-SLE-Module-Basesystem-15-SP2-x86_64-Updates SUSE-SLE-Module-Development-Tools-15-SP2-x86_64-Updates'

# Remove the zypper lock on the kernel on every NCN.
run_pdsh_command 'zypper removelock kernel-default'

# Install patches.
run_pdsh_command 'zypper in -t patch -y SUSE-SLE-Module-Development-Tools-15-SP2-2021-2438 SUSE-SLE-Module-Basesystem-15-SP2-2021-2438'

# Put the kernel lock back in place.
run_pdsh_command 'zypper addlock kernel-default'


# Copy the kernel/initrd/squash update script to all the NCNs.
pdcp -pw "$NCNS" update-kernel_squashfs.sh /tmp

# Update kernel/initrd/squash on all NCNs.
run_pdsh_command '/tmp/update-kernel_squashfs.sh'

# Remove any existing artifacts in S3.
cray artifacts delete ncn-images k8s-kernel
cray artifacts delete ncn-images k8s-initrd.img.xz
cray artifacts delete ncn-images k8s-filesystem.squashfs
cray artifacts delete ncn-images ceph-initrd.img.xz
cray artifacts delete ncn-images ceph-kernel
cray artifacts delete ncn-images ceph-filesystem.squashfs

# This should return nothing (empty).
cray artifacts list ncn-images

# Make sure we can use the kubeconfig.
if [ ! -f ~/.kube/config ]
then
  ln -snf /etc/kubernetes/admin.conf ~/.kube/config
fi

csi handoff ncn-images \
    --k8s-kernel-path    ${CSM_DISTDIR}/kubernetes/*.kernel \
    --k8s-initrd-path    ${CSM_DISTDIR}/kubernetes/initrd.img*.xz \
    --k8s-squashfs-path  ${CSM_DISTDIR}/kubernetes/*.squashfs \
    --ceph-kernel-path   ${CSM_DISTDIR}/storage-ceph/*.kernel \
    --ceph-initrd-path   ${CSM_DISTDIR}/storage-ceph/initrd.img*.xz \
    --ceph-squashfs-path ${CSM_DISTDIR}/storage-ceph/*.squashfs

# Should show all the assets from above.
cray artifacts list ncn-images

# Add priority class and classify essential deployments as such.
./add_pod_priority.sh