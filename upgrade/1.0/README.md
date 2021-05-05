# CSM 1.4 to 1.5 Upgrade Process

### Introduction

This document is intended to guide an administrator through the upgrade process going from Cray Shasta v1.4 to v1.5.  When upgrading a system, this top-level README.md file should be followed top to bottom, and the content on this top level page is meant to be terse.  See the additional files (like KNOWN_ISSUES.md and REFERENCE_MATERIAL.md in the various directories under the linked resource_material sub-directories.

> **NOTE**: This document is a work in progress, and these items are outstanding:
> 1. PowerDNS -- Need to add content
> 1. Preflight checks -- these haven't yet been implmented, and when they are they should be added to this flow where appropriate.
> 1. Additional automation -- hopefully we'll add some more scripting as we refine this process.  There's alot of copy/pasting which will frustrate adminstrators, especially on larger systems.

### Terminology

Throughout the guide the terms "stable" and "upgrade" are used in the context of NCNs. The "stable" NCN is the master
node you will be running all of these commands from and therefore will not be affecting the power state of. Clearly
then the "upgrade" node is the node you will be next upgrading.

In this way when doing a rolling upgrade of the entire cluster at some point you will need to transfer the
responsibility of the "stable" NCN to another master. However, you do not need to do this before you are ready to
upgrade that node.

It is also possible to do this from a "remote" node (like the PIT during a normal install) however this is beyond the
scope of this documentation.

### Prerequisites

Begin by [downloading and configuring the latest version of CSM](resource_material/prereqs/get-csm.md)


**PLEASE NOTE THAT THE NEXT LINE IS NOT READY FOR EXECUTION** with respect to exporting critical site data.  It is experimental and is undergoing internal testing.
For protection against unexpected upgrade issues, follow the recommended steps to [export critical site data](resource_material/prereqs/export-critical-data.md).

### Preflight Checks

CSI or other tool needs the most love here. At a minimum we want to ensure general cluster health but we also need NCN specific checks that are run right before rebooting. Should this be part of a fully automated procedure? How do we determine compability between two image versions and whether we should "allow" that setting?

### Upgrade Stages

#### Stage 1.  Ceph upgrade from Nautilus (14.2.11) to Octopus (15.2.8)

> **WARNING**: This upgrade step requires that all `cephfs` traffic be quiesced for the duration of this stage.  As a result pods in the following deployments will be scaled down and then back up and their services will be unavailable during this time:
> 1. nexus
> 1. cray-cfs
> 1. cray-conman
> 1. cray-ims
> 1. cray-ipxe
> 1. cray-tftp
> 1. gitea-vcs

Follow the steps at: [Initial Ceph Upgrade](resource_material/stage1/initial-ceph-upgrade.md)

#### Stage 2. Ceph image upgrade

For each storage node in the cluster, start by following the steps at: [Common Prerequisite Steps](resource_material/common/prerequisite-steps.md). Note that these steps should be performed on one storage node at a time.

#### Stage 3. Kubernetes Upgrade from 1.18.6 to 1.19.9

1. For each master node in the cluster, again follow the steps at: [Common Prerequisite Steps](resource_material/common/prerequisite-steps.md)

2. Determine worker rebuild order, attempt to minimize moves of key pxe boot related pods.  Run the following command for locations of key pods and recommendation of rebuild order:

   ```bash
   ncn# /usr/share/doc/metal/upgrade/1.0/scripts/k8s/determine-worker-order.sh
   ```

3. For each worker node in the cluster, also follow the steps at: [Common Prerequisite Steps](resource_material/common/prerequisite-steps.md)

4. For each master node in the cluster, run the following command to complete the kubernetes upgrade _(this will restart several pods on each master to their new docker containers)_:

   ```bash
   ncn# kubeadm upgrade apply v1.19.9 -y
   ```

#### Stage 4. Service Upgrades

Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m001# ./${CSM_RELEASE}/upgrade.sh
```

### Post-Upgrade Health Checks


### Troubleshooting and Recovering from Failed Upgrades

**PLEASE NOTE THAT THE NEXT LINE IS NOT READY FOR EXECUTION** with respect to executing recovery procedures.  It is experimental and is undergoing internal testing.
Please see the [Upgrade Recovery and Troubleshooting](resource_material/recovery/troubleshoot_recovery.md) procedures in the event of failures or issues encountered during the upgrade.
