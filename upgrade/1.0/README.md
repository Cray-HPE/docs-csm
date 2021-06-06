# CSM 0.9.3 to 1.0.0 Upgrade Process

### Introduction

This document is intended to guide an administrator through the upgrade process going from Cray Systems Management 0.9 to v1.0.  When upgrading a system, this top-level README.md file should be followed top to bottom, and the content on this top level page is meant to be terse.  See the additional files (like KNOWN_ISSUES.md and REFERENCE_MATERIAL.md in the various directories under the linked resource_material sub-directories.

### Terminology

Throughout the guide the terms "stable" and "upgrade" are used in the context of NCNs. The "stable" NCN is the master
node you will be running all of these commands from and therefore will not be affecting the power state of. Clearly
then the "upgrade" node is the node you will be next upgrading.

In this way when doing a rolling upgrade of the entire cluster at some point you will need to transfer the
responsibility of the "stable" NCN to another master. However, you do not need to do this before you are ready to
upgrade that node.

It is also possible to do this from a "remote" node (like the PIT during a normal install) however this is beyond the
scope of this documentation.

### Terminal Output
<span style="color: while"> White </span>: output of logs are in white

<span style="color: green"> Green </span>: output of upgrade states are in green

<span style="color: yellow"> Yellow </span>: Your action is required, read and react carefully with the output

<span style="color: red"> Red </span>: Unexpeted errors are in red

### Prerequisites & Preflight Checks

> NOTE: CSM-0.9.3 is the version of CSM required in order to upgrade to CSM-1.0.0 (available with Shasta v1.5).

The following command can be used to check the CSM version on the system:

```
kubectl get cm -n services cray-product-catalog -o json | jq -r '.data.csm'
``` 

This check will also be conducted in the 'prerequisites.sh' script listed below and will fail if the system is not running CSM-0.9.3.

Install documents: 

`rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm`

Run: 

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh [CSM_RELEASE] [ENDPOINT]` <== ENDPOINT is optional for internal use. it is pointing to arti by default

Above script also runs the goss tests on the initial stable node (typically `ncn-m001`) where the latest version of CSM has been installed. Make sure the goss test pass before continue.

### Upgrade Stages

#### Stage 1.  Ceph upgrade from Nautilus (14.2.x) to Octopus (15.2.x)

Run: 

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph-initial.sh ncn-s001` <== run the script for all storage nodes

> NOTE: follow output of above script carefully. The script will pause for manual interaction

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

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph-nodes.sh ncn-s001` <==== ncn-s001, ncn-s002, ncn-s003
> NOTE: follow output of above script carefully. The script will pause for manual interaction

> Note that these steps should be performed on one storage node at a time.

#### Stage 3. Kubernetes Upgrade from 1.18.6 to 1.19.9

1. For each master node in the cluster (exclude m001), again follow the steps:

    `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m002` <==== ncn-m002, ncn-m003
    > NOTE: follow output of above script carefully. The script will pause for manual interaction

2. For each worker node in the cluster, also follow the steps:

    `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-worker.sh ncn-w002` <==== ncn-w002, ncn-w003, ncn-w001
    > NOTE: follow output of above script carefully. The script will pause for manual interaction

3. For master 001, Use m002 as stable ncn:
    
    Install documents: 

    `rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm`

    Run: 

    `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh [CSM_RELEASE]`

    upgrade ncn-m001:

    `/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m001`
    > NOTE: follow output of above script carefully. The script will pause for manual interaction

4. For each master node in the cluster, run the following command to complete the kubernetes upgrade _(this will restart several pods on each master to their new docker containers)_:

   ```bash
   ncn# kubeadm upgrade apply v1.19.9 -y
   ```

#### Stage 4. Service Upgrades

Run `upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m002# ./${CSM_RELEASE}/upgrade.sh
```

### Post-Upgrade Health Checks

> **`IMPORTANT:`** Wait at least 15 minutes after
> [`upgrade.sh`](#deploy-manifests) completes to let the various Kubernetes
> resources get initialized and started.

Run the following validation checks to ensure that everything is still working
properly after the upgrade:

1. [Platform health checks](../../operations/validate_csm_health.md#platform-health-checks)
2. [Network health checks](../../operations/validate_csm_health.md#network-health-checks)

Other health checks may be run as desired.


### Troubleshooting and Recovering from Failed Upgrades

