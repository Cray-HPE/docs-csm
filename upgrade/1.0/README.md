# CSM 0.9.4 to 1.0.0 Upgrade Process

### Introduction

This document is intended to guide an administrator through the upgrade process going from Cray Systems Management 0.9 to v1.0.  When upgrading a system, this top-level README.md file should be followed top to bottom, and the content on this top level page is meant to be terse.  See the additional files in the various directories under the resource_material directory for additional reference material in support of the process/scripts mentioned explicitly on this page.

### Terminology

Throughout the guide the terms "stable" and "upgrade" are used in the context of the management nodes (NCNs). The
"stable" NCN is the master node from which all of these commands will be run and therefore cannot have its power state
affected.  Then the "upgrade" node is the node to next be upgraded.

When doing a rolling upgrade of the entire cluster, at some point you will need to transfer the
responsibility of the "stable" NCN to another master node. However, you do not need to do this before you are ready to
upgrade that node.
### Stage 0 - Prerequisites & Preflight Checks

> NOTE: CSM-0.9.4 is the version of CSM required in order to upgrade to CSM-1.0.0 (available with Shasta v1.5).

The following command can be used to check the CSM version on the system:

```
kubectl get cm -n services cray-product-catalog -o json | jq -r '.data.csm'
``` 

This check will also be conducted in the 'prerequisites.sh' script listed below and will fail if the system is not running CSM-0.9.4.

#### Option 1 - Internet Connected Environment
Install document rpm package:

`rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm`

Run: 

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]` <== ENDPOINT is optional for internal use. it is pointing to internal arti by default

#### Option 2 - Air Gapped Environment
Install document rpm package: 

`rpm -Uvh [PATH_TO_docs-csm-install-*.noarch.rpm]`

Run: 

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]`

Above script also runs the goss tests on the initial stable node (typically `ncn-m001`) where the latest version of CSM has been installed. Make sure the goss test pass before continue.

### Upgrade Stages

#### Stage 1.  Ceph upgrade from Nautilus (14.2.x) to Octopus (15.2.x)
#### Stage 1.1
Run: 

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph-initial.sh ncn-s001` <== run the script for all storage nodes

> NOTE: follow output of above script carefully. The script will pause for manual interaction

#### Stage 1.2
On ncn-s001 execute the ceph-upgrade.sh script:
```
cd /usr/share/doc/csm/upgrade/1.0/scripts/ceph

./ceph-upgrade.sh
```

**IMPORTANT NOTES**
> - At this point your ceph commands will still be working.  
> - You have a new way of executing ceph commands in addition to the traditional way.  
>   - Please see [cephadm-reference.md](resource_material/storage/cephadm-reference.md) for more information.
> - Both methods are dependent on the master nodes and storage nodes 001/2/3 have a ceph.client.admin.keyring and/or a ceph.conf file (cephadm will not require the ceph.conf). 
> - When you continue with Stage 2, you may have issues running your ceph commands.  
>   - If you are experiencing this, please double check that you restored your /etc/ceph directory from your tar backup.

#### Stage 2. Ceph image upgrade

For each storage node in the cluster, start by following the steps: 

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-ceph-nodes.sh ncn-s001` <==== ncn-s001, ncn-s002, ncn-s003
> NOTE: follow output of above script carefully. The script will pause for manual interaction

> Note that these steps should be performed on one storage node at a time.

#### Stage 3. Kubernetes Upgrade from 1.18.6 to 1.19.9

#### Stage 3.1. For each master node in the cluster (exclude m001), again follow the steps:

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m002` <==== ncn-m002, ncn-m003

> NOTE: follow output of above script carefully. The script will pause for manual interaction

#### Stage 3.2. For each worker node in the cluster, also follow the steps:

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-worker.sh ncn-w002` <==== ncn-w002, ncn-w003, ncn-w001
    
> NOTE: follow output of above script carefully. The script will pause for manual interaction

#### Stage 3.3. For ncn-m001, use ncn-m002 as the stable NCN:
> NOTE: using vlan007/CAN IP to ssh to ncn-m002 for ncn-m001 install
    
#### Option 1 - Internet Connected Environment
Install document rpm package:

`rpm -Uvh https://storage.googleapis.com/csm-release-public/shasta-1.5/docs-csm-install/docs-csm-install-latest.noarch.rpm`

Run: 

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --endpoint [ENDPOINT]` <== ENDPOINT is optional for internal use. it is pointing to internal arti by default
#### Option 2 - Air Gapped Environment
Install document rpm package: 

`rpm -Uvh [PATH_TO_docs-csm-install-*.noarch.rpm]`

Run: 

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/prerequisites.sh --csm-version [CSM_RELEASE] --tarball-file [PATH_TO_CSM_TARBALL_FILE]`
> NOTE: follow output of above script carefully. The script will pause for manual interaction

#### Upgrade ncn-m001

`/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/ncn-upgrade-k8s-master.sh ncn-m001`

#### Stage 3.4. For each master node in the cluster, run the following command to complete the kubernetes upgrade _(this will restart several pods on each master to their new docker containers)_:

   ```bash
   ncn# kubeadm upgrade apply v1.19.9 -y
   ```

<a name="deploy-manifests"></a>
#### Stage 4. CSM Service Upgrades

Run `csm-service-upgrade.sh` to deploy upgraded CSM applications and services:

```bash
/usr/share/doc/csm/upgrade/1.0/scripts/upgrade/csm-service-upgrade.sh
```

### Troubleshooting and Recovering from Errors During or After Upgrade

##### General Kubernetes Commands for Troubleshooting
Please see [Kubernetes_Troubleshooting_Information.md](../../operations/kubernetes/Kubernetes_Troubleshooting_Information.md).

##### Troubleshooting PXE Boot Issues
If execution of the upgrade procedures results in NCNs that have errors booting, please refer to these troubleshooting procedures: 
[PXE Booting Runbook](https://connect.us.cray.com/confluence/display/CASMNET/PXE+Booting+Runbook)

##### Troubleshooting NTP
During execution of the upgrade procedure, if it is noted that there is clock skew on one or more NCNs, the following procedure can be used to troubleshoot NTP config or to sync time:
[configure_ntp_on_ncns.md](../../operations/configure_ntp_on_ncns.md)

##### Bare-Metal Etcd Recovery
If in the upgrade process of the master nodes, it is found that the bare-metal etcd cluster (that houses values for the kubernetes cluster) has a failure,
it may be necessary to restore that cluster from back-up.  Please see
[Restore_Bare-Metal_etcd_Clusters_from_an_S3_Snapshot.md](../../operations/kubernetes/Restore_Bare-Metal_etcd_Clusters_from_an_S3_Snapshot.md) for that procedure.

##### Back-ups for Etcd-Operator Clusters
After upgrading, if health checks indicate that etcd pods are not in a healthy/running state, recovery procedures may be needed.  Please see
[Backups_for_etcd-operator_Clusters.md](../../operations/kubernetes/Backups_for_etcd-operator_Clusters.md) for these procedures.

##### Recovering from Postgres Dbase Issues
After upgrading, if health checks indicate the postgres pods are not in a healthy/running state, recovery procedures may be needed.
Please see [Troubleshoot_Postgres_Databases_with_the_Patroni_Tool.md](../../operations/kubernetes/Troubleshoot_Postgres_Databases_with_the_Patroni_Tool.md) for troubleshooting and recovery procedures.

##### Troubleshooting Spire Pods Not Staring on NCNs
Please see [Troubleshoot_SPIRE_Failing_to_Start_on_NCNs.md](../../operations/security_and_authentication/Troubleshoot_SPIRE_Failing_to_Start_on_NCNs.md).

