# Stage 3 - Kubernetes Upgrade

**The Kubernetes upgrade is done through IUF. This page exists in CSM 1.6 so that it can be referenced by [Management Rollout](../operations/iuf/workflows/management_rollout.md#31-management-nodes-rollout-with-csm-upgrade).
This page should NOT be followed in its entirety in CSM 1.6.** See [CSM 1.5 to 1.6 Upgrade Process](./Upgrade_Management_Nodes_and_CSM_Services.md) for more information.

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](Upgrade_Management_Nodes_and_CSM_Services.md#relevant-troubleshooting-links-for-upgrade-related-issues).

- [Start typescript on `ncn-m001`](#start-typescript-on-ncn-m001)
- [Stage 3.1 - Master node image upgrade](#stage-31---master-node-image-upgrade)
- [Argo workflows](#argo-workflows)
- [Stage 3.2 - Worker node image upgrade](#stage-32---worker-node-image-upgrade)
    - [Option 1 - Serial upgrade](#option-1---serial-upgrade)
    - [Option 2 - Parallel upgrade (Tech preview)](#option-2---parallel-upgrade-tech-preview)
        - [Restrictions](#restrictions)
        - [Example](#example)
- [Stage 3.3 - `ncn-m001` upgrade](#stage-33---ncn-m001-upgrade)
    - [Stop typescript on `ncn-m001`](#stop-typescript-on-ncn-m001)
    - [Backup artifacts on `ncn-m001`](#backup-artifacts-on-ncn-m001)
    - [Move to `ncn-m002`](#move-to-ncn-m002)
    - [Start typescript on `ncn-m002`](#start-typescript-on-ncn-m002)
    - [Prepare `ncn-m002`](#prepare-ncn-m002)
    - [Upgrade `ncn-m001`](#upgrade-ncn-m001)
- [Stage 3.4 - Upgrade `weave` and `multus`](#stage-34---upgrade-weave-and-multus)
- [Stage 3.5 - `coredns` anti-affinity](#stage-35---coredns-anti-affinity)
- [Stage 3.6 - Complete Kubernetes upgrade](#stage-36---complete-kubernetes-upgrade)
- [Stop typescript on `ncn-m002`](#stop-typescript-on-ncn-m002)
- [Stage completed](#stage-completed)

## Start typescript on `ncn-m001`

1. (`ncn-m001#`) If a typescript session is already running in the shell, then first stop it with the `exit` command.

1. (`ncn-m001#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).stage_3_ncn-m001.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

If additional shells are opened during this procedure, then record those with typescripts as well. When resuming a procedure
after a break, always be sure that a typescript is running before proceeding.

## Stage 3.1 - Master node image upgrade

> **`NOTE`** If Kubernetes encryption has been enabled via the [Kubernetes Encryption Documentation](../operations/kubernetes/encryption/README.md),
then backup the `/etc/cray/kubernetes/encryption` directory on the master node before upgrading and restore the directory after the node has been upgraded.

1. (`ncn-m001#`) Run `ncn-upgrade-master-nodes.sh` for `ncn-m002`.

   Follow output of the script carefully. The script will pause for manual interaction.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m002
   ```

   > **`NOTE`** The `root` user password for the node may need to be reset after it is rebooted. Additionally, the `/etc/cray/kubernetes/encryption` directory should be restored if it was backed up.
   Once it is restored, the `kube-apiserver` on the rebuilt node should be restarted.
   See [Kubernetes `kube-apiserver` Failing](../troubleshooting/kubernetes/Kubernetes_Kube_apiserver_failing.md) for details on how to restart the `kube-apiserver`.

1. Repeat the previous step for each other master node **excluding `ncn-m001`**, one at a time.

## Argo workflows

Before starting [Stage 3.2 - Worker node image upgrade](#stage-32---worker-node-image-upgrade), access the Argo UI to view the progress of this stage.
Note that the progress for the current stage will not show up in Argo before the worker node image upgrade script has been started.

For more information, see [Using the Argo UI](../operations/argo/Using_the_Argo_UI.md) and [Using Argo Workflows](../operations/argo/Using_Argo_Workflows.md).

> **`NOTE`** One of the Argo steps (`wait-for-cfs`) will prevent the upgrade of a worker node from proceeding if the CFS component status for that worker is in an `Error` state, and this must be fixed in order for the upgrade to continue.
The following steps can be used to reset the component state in CFS (replace `XNAME` below with the `XNAME` for the worker node:

```bash
cray cfs v3 components update --error-count 0 <XNAME>
cray cfs v3 components update --state '[]' <XNAME>
```

## Stage 3.2 - Worker node image upgrade

> **`NOTE`** When upgrading worker nodes which are running DVS, it is not recommended to simultaneously reboot compute nodes. This is to avoid restarting DVS clients and servers at the same time.

There are two options available for upgrading worker nodes.

### Option 1 - Serial upgrade

1. (`ncn-m001#`) Run `ncn-upgrade-worker-storage-nodes.sh` for `ncn-w001`.

   Follow output of the script carefully. The script will pause for manual interaction.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-w001
   ```

   > **`NOTE`** The `root` user password for the node may need to be reset after it is rebooted.

1. Repeat the previous steps for each other worker node, one at a time.

### Option 2 - Parallel upgrade (Tech preview)

Multiple workers can be upgraded simultaneously by passing them as a comma-separated list into the upgrade script.

#### Restrictions

In some cases, it is not possible to upgrade all workers in one request. It is system administrator's responsibility to
make sure that the following conditions are met:

- If the system has more than five workers, then they cannot all be upgraded with a single request.

    In this case, the upgrade should be split into multiple requests, with each request specifying no more than five workers.

- No single upgrade request should include all of the worker nodes that have DVS running on them.

#### Example

(`ncn-m001#`) An example of a single request to upgrade multiple worker nodes simultaneously:

```bash
/usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-w002,ncn-w003,ncn-w004
```

## Stage 3.3 - `ncn-m001` upgrade

By this point, all NCNs have been upgraded, except for `ncn-m001`. In the upgrade process so far, `ncn-m001`
has been the "stable node" -- that is, the node from which the other nodes were upgraded. At this point, the
upgrade procedure pivots to use `ncn-m002` as the new "stable node", in order to allow the upgrade of `ncn-m001`.

### Stop typescript on `ncn-m001`

For any typescripts that were started earlier on `ncn-m001`, stop them with the `exit` command.

### Backup artifacts on `ncn-m001`

1. (`ncn-m001#`) Create an archive of the artifacts.

    ```bash
    BACKUP_TARFILE="csm_upgrade.pre_m001_reboot_artifacts.$(date +%Y%m%d_%H%M%S).tgz"
    ls -d \
        /root/apply_csm_configuration.* \
        /root/csm_upgrade.* \
        /root/output.log 2>/dev/null |
    sed 's_^/__' |
    xargs tar -C / -czvf "/root/${BACKUP_TARFILE}"
    ```

1. (`ncn-m001#`) Upload the archive to S3 in the cluster.

    ```bash
    cray artifacts create config-data "${BACKUP_TARFILE}" "/root/${BACKUP_TARFILE}"
    ```

### Move to `ncn-m002`

1. Log out of `ncn-m001`.

1. Log in to `ncn-m002` from outside the cluster.

    > **`NOTE`** Very rarely, a password hash for the `root` user that works properly on a SLES SP2 NCN is
    > not recognized on a SLES SP3 NCN. If password login fails, then log in to `ncn-m002` from
    > `ncn-m001` and use the `passwd` command to reset the password. Then log in using the CMN IP address as directed
    > below. Once `ncn-m001` has been upgraded, log in from `ncn-m002` and use the `passwd` command to reset
    > the password. The other NCNs will have their passwords updated when NCN personalization is run in a
    > subsequent step.

    `ssh` to the `bond0.cmn0`/CMN IP address of `ncn-m002`.

### Start typescript on `ncn-m002`

1. (`ncn-m002#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).stage_3_ncn-m002.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

### Prepare `ncn-m002`

1. Authenticate with the Cray CLI on `ncn-m002`.

   See [Configure the Cray Command Line Interface](../operations/configure_cray_cli.md) for details on how to do this.

1. (`ncn-m002#`) Set upgrade variables.

   ```bash
   source /etc/cray/upgrade/csm/myenv
   ```

1. (`ncn-m002#`) Copy artifacts from `ncn-m001`.

    > A later stage of the upgrade expects the `docs-csm` and `libcsm` RPMs to be located at `/root/` on `ncn-m002`;
    > that is why this command copies them there.

   - Install `csi` and `docs-csm`.

       ```bash
       scp ncn-m001:/root/csm_upgrade.pre_m001_reboot_artifacts.*.tgz /root
       zypper --plus-repo="/etc/cray/upgrade/csm/media/${ACTIVITY_NAME}/csm-${CSM_RELEASE}/rpm/cray/csm/noos" --no-gpg-checks install -y cray-site-init
       scp ncn-m001:/root/*.noarch.rpm /root/
       rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
       ```

   - Install `libcsm`.

       > ***NOTE*** Since `libcsm` depends on versions of Python relative to what is included in the SLES service packs,
       > then in the event that `ncn-m002` is running a newer SLES distro a new `libcsm` must be downloaded. This will
       > often be the case when jumping to a new CSM minor version (e.g. CSM 1.3 to CSM 1.4).
       > e.g. if `ncn-m001` is running SLES15SP3, and `ncn-m002` is running SLES15SP4 then the SLES15SP4 `libcsm` is needed.
       > Follow the [Check for latest documentation](../update_product_stream/README.md#check-for-latest-documentation)
       > guide again, but from `ncn-m002`.

       ```bash
       rpm -Uvh --force /root/libcsm-latest.noarch.rpm
       ```

    If this step was executed as a result of the [`management-nodes-rollout` with CSM upgrade](../operations/iuf/workflows/management_rollout.md#31-management-nodes-rollout-with-csm-upgrade)
    instructions, return to that procedure and continue with the next step.
    Otherwise, if performing an upgrade of only CSM, proceed to the next step.

### Upgrade `ncn-m001`

> **`NOTE`** If Kubernetes encryption has been enabled via the [Kubernetes Encryption Documentation](../operations/kubernetes/encryption/README.md),
then backup the `/etc/cray/kubernetes/encryption` directory on the master node before upgrading and restore the directory after the node has been upgraded.

1. Upgrade `ncn-m001`.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m001
   ```

   > **`NOTE`** The `root` user password for the node may need to be reset after it is rebooted.
   Additionally, the `/etc/cray/kubernetes/encryption` directory should be restored if it was backed up.
   Once it is restored, the `kube-apiserver` on the rebuilt node should be restarted.
   See [Kubernetes `kube-apiserver` Failing](../troubleshooting/kubernetes/Kubernetes_Kube_apiserver_failing.md) for details on how to restart the `kube-apiserver`.

## Stage 3.4 - Upgrade `weave` and `multus`

Run the following command to complete the upgrade of the `weave` and `multus` manifest versions:

```bash
/srv/cray/scripts/common/apply-networking-manifests.sh
```

## Stage 3.5 - `coredns` anti-affinity

Run the following script to apply anti-affinity to `coredns` pods:

```bash
/usr/share/doc/csm/upgrade/scripts/k8s/apply-coredns-pod-affinity.sh
```

## Stage 3.6 - Complete Kubernetes upgrade

Complete the Kubernetes upgrade. This script will restart several pods on each master node to their new Docker containers.

```bash
/usr/share/doc/csm/upgrade/scripts/k8s/upgrade_control_plane.sh
```

> **`NOTE`**: `kubelet` has been upgraded already, ignore the warning to upgrade it.

If the previous three steps were executed as part of the IUF [Deploy Product](../operations/iuf/workflows/deploy_product.md)
procedure, return to the IUF [Deploy Product](../operations/iuf/workflows/deploy_product.md) procedure and
complete the remaining steps. Otherwise, proceed to the following topic.

### Stop typescript on `ncn-m002`

For any typescripts that were started during this stage on `ncn-m002`, stop them with the `exit` command.

## Stage completed

All Kubernetes nodes have been rebooted into the new image.

> **REMINDER**: If password for `ncn-m002` was reset during Stage 3.3, then also reset the password
> on `ncn-m001` at this time.

This stage is completed. Proceed to [Validate CSM health during an upgrade](Validate_CSM_Health_During_Upgrade.md)
