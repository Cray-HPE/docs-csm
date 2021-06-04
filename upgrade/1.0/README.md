# CSM 1.4 to 1.5 Upgrade Process

### Introduction

This document is intended to guide an administrator through the upgrade process going from Cray Shasta v1.4 to v1.5.  When upgrading a system, this top-level README.md file should be followed top to bottom, and the content on this top level page is meant to be terse.  See the additional files (like KNOWN_ISSUES.md and REFERENCE_MATERIAL.md in the various directories under the linked resource_material sub-directories.

> **NOTE**: This document is a work in progress, and these items are outstanding:
> 1. Additional automation -- hopefully we'll add some more scripting as we refine this process.  There's a lot of copy/pasting which will frustrate administrators, especially on larger systems.

### Terminology

Throughout the guide the terms "stable" and "upgrade" are used in the context of NCNs. The "stable" NCN is the master
node you will be running all of these commands from and therefore will not be affecting the power state of. Clearly
then the "upgrade" node is the node you will be next upgrading.

In this way when doing a rolling upgrade of the entire cluster at some point you will need to transfer the
responsibility of the "stable" NCN to another master. However, you do not need to do this before you are ready to
upgrade that node.

It is also possible to do this from a "remote" node (like the PIT during a normal install) however this is beyond the
scope of this documentation.

### Prerequisites & Preflight Checks

Before upgrading to CSM-1.0, please ensure that the latest CSM-0.9.x patches and hot-fixes have been applied.  These upgrade instructions assume that the latest released CSM-0.9.x patch and any applicable hot-fixes for CSM-0.9.x, have been applied.

Install documents: `rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm`

Run: `./prerequisites.sh [CSM_RELEASE]`
> NOTE: make sure your current working dir is `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade`

Above script also runs the goss tests on the initial stable node (typically `ncn-m001`) where the latest version of CSM has been installed. Make sure the goss test pass before continue.

### Upgrade Stages

#### Stage 1.  Ceph upgrade from Nautilus (14.2.x) to Octopus (15.2.x)

`./ncn-upgrade-ceph-initial.sh ncn-s001` <== run the script for all storage nodes

> NOTE: follow output of above script carefully. The script will pause for manual interaction

> NOTE: make sure your current working dir is `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade`

On ncn-s001 execute the ceph-upgrade.sh script:
```
cd /usr/share/doc/csm/upgrade/1.0/scripts/ceph

./ceph-upgrade.sh
```

**IMPORTANT NOTES**
> - At this point your ceph commands will still be working.  
> - You have a new way of executing ceph commands in addition to the traditional way.  
>   - Please see [cephadm-reference.md](resource_material/common/cephadm-reference.md) for more information.
> - Both methods are dependent on the master nodes and storage nodes 001/2/3 have a ceph.client.admin.keyring and/or a ceph.conf file (cephadm will not require the ceph.conf). 
> - When you continue with Stage 2, you may have issues running your ceph commands.  
>   - If you are experiencing this, please double check that you restored your /etc/ceph directory from your tar backup.

#### Stage 2. Ceph image upgrade

For each storage node in the cluster, start by following the steps: 

`./ncn-upgrade-ceph-nodes.sh ncn-s001` <==== ncn-s001, ncn-s002, ncn-s003
> NOTE: follow output of above script carefully. The script will pause for manual interaction

> NOTE: make sure your current working dir is `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade`

> Note that these steps should be performed on one storage node at a time.

#### Stage 3. Kubernetes Upgrade from 1.18.6 to 1.19.9

1. For each master node in the cluster (exclude m001), again follow the steps:

`./ncn-upgrade-k8s-master.sh ncn-m002` <==== ncn-m002, ncn-m003
> NOTE: follow output of above script carefully. The script will pause for manual interaction

> NOTE: make sure your current working dir is `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade`

2. For each worker node in the cluster, also follow the steps:

`./ncn-upgrade-k8s-worker.sh ncn-w002` <==== ncn-w002, ncn-w003, ncn-w001
> NOTE: follow output of above script carefully. The script will pause for manual interaction

> NOTE: make sure your current working dir is `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade`

3. For master 001, follow the steps:

Use m002 as stable ncn:
    
Install documents: `rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm`

Run: `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh [CSM_RELEASE]`

upgrade ncn-m001 `./ncn-upgrade-k8s-master.sh ncn-m001`
> NOTE: follow output of above script carefully. The script will pause for manual interaction

> NOTE: make sure your current working dir is `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade`

4. For each master node in the cluster, run the following command to complete the kubernetes upgrade _(this will restart several pods on each master to their new docker containers)_:

   ```bash
   ncn# kubeadm upgrade apply v1.19.9 -y
   ```

#### Stage 4. Service Upgrades

Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m002# ./${CSM_RELEASE}/upgrade.sh
```
> NOTE: make sure your current working dir is `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade`
### Post-Upgrade Health Checks


### Troubleshooting and Recovering from Failed Upgrades

