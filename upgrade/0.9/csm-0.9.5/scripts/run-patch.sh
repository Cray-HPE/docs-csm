#!/usr/bin/env bash

# Get the list of NCNs.
NCNS=$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  paste -sd ',')

function run_pdsh_command() {
    pdsh -S -b -w "$NCNS" "$1"
}

# Run sanity checks to see if we should even try to start.
if [[ -z "${TOKEN}" ]]; then
  echo "API token must be set in TOKEN environment variable!"
  exit 1
fi
if ! cray artifacts list ncn-images &> /dev/null
then
  echo "Cray CLI appears to not be setup correctly!"
  exit 1
fi
if ! command -v csi &> /dev/null
then
  echo "CSI appears to not be installed!"
  exit 1
fi

# Add the repos with the new RPMs and refresh them.
run_pdsh_command 'zypper ar https://packages.local/repository/SUSE-SLE-Module-Basesystem-15-SP2-x86_64-Updates SUSE-SLE-Module-Basesystem-15-SP2-x86_64-Updates'
run_pdsh_command 'zypper ar https://packages.local/repository/SUSE-SLE-Module-Development-Tools-15-SP2-x86_64-Updates SUSE-SLE-Module-Development-Tools-15-SP2-x86_64-Updates'

run_pdsh_command 'zypper refresh SUSE-SLE-Module-Basesystem-15-SP2-x86_64-Updates SUSE-SLE-Module-Development-Tools-15-SP2-x86_64-Updates'
if [ $? -gt 0 ]
then
  echo "Failed to refresh repositories on one or more NCNs!"
  exit 1
fi

# Remove the zypper lock on the kernel on every NCN.
run_pdsh_command 'zypper removelock kernel-default'
if [ $? -gt 0 ]
then
  echo "Failed to remove lock on kernel-default on one or more NCNs!"
  exit 1
fi

# Install patches.
run_pdsh_command 'zypper in -t patch -y SUSE-SLE-Module-Development-Tools-15-SP2-2021-2438 SUSE-SLE-Module-Basesystem-15-SP2-2021-2438 SUSE-SLE-Module-Basesystem-15-SP2-2021-1843'
patchRetVal=$?
# Check to see if one or both of these packages is missing or any other failures.
# Error code 102 is Zypper for "you need to reboot". We are not doing that now, so it is not actually an error.
if [ $patchRetVal -gt 0 ] && [ $patchRetVal -ne 102 ]
then
  if [ $patchRetVal -eq 104 ]
  then
    echo -n "Failed to find SUSE-SLE-Module-Development-Tools-15-SP2-2021-2438, "
    echo "SUSE-SLE-Module-Basesystem-15-SP2-2021-2438, and/or SUSE-SLE-Module-Basesystem-15-SP2-2021-1843 patch."
    echo "Please see section, \"Install SLE for V1.4.2A-security0821 Patch\" in the main patch README."
  else
    echo "The patch failed to install on one or more NCNs. Investigate the above output for any errors."
  fi

  exit $patchRetVal
else
  echo "Patch installed on all NCNs."
fi


# Put the kernel lock back in place.
run_pdsh_command 'zypper addlock kernel-default'
if [ $? -gt 0 ]
then
  echo "Failed to replace lock on kernel-default on one or more NCNs!"
  exit 1
fi

# Copy the kernel/initrd/squash update script to all the NCNs.
pdcp -pw "$NCNS" "${CSM_SCRIPTDIR}/update-kernel_squashfs.sh" /tmp
if [ $? -gt 0 ]
then
  echo "Failed to copy update-kernel_squashfs script to all NCNs!"
  exit 1
fi

# Update kernel/initrd/squash on all NCNs.
run_pdsh_command '/tmp/update-kernel_squashfs.sh'
if [ $? -gt 0 ]
then
  echo "Failed to update kernel/squashfs on one or more NCNs!"
  exit 1
fi


set -ex

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

# Push the new images into S3.
csi handoff ncn-images \
    --k8s-kernel-path    ${CSM_DISTDIR}/images/kubernetes/*.kernel \
    --k8s-initrd-path    ${CSM_DISTDIR}/images/kubernetes/initrd.img*.xz \
    --k8s-squashfs-path  ${CSM_DISTDIR}/images/kubernetes/*.squashfs \
    --ceph-kernel-path   ${CSM_DISTDIR}/images/storage-ceph/*.kernel \
    --ceph-initrd-path   ${CSM_DISTDIR}/images/storage-ceph/initrd.img*.xz \
    --ceph-squashfs-path ${CSM_DISTDIR}/images/storage-ceph/*.squashfs

# Should show all the assets from above.
cray artifacts list ncn-images


echo "Patch process completed!"