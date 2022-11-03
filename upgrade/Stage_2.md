# Stage 2 - Kubernetes Upgrade

**Reminder:** If any problems are encountered and the procedure or command output does not provide relevant guidance, see
[Relevant troubleshooting links for upgrade-related issues](Upgrade_Management_Nodes_and_CSM_Services.md#relevant-troubleshooting-links-for-upgrade-related-issues).

- [Start typescript on `ncn-m001`](#start-typescript-on-ncn-m001)
- [Stage 2.1 - Master node image upgrade](#stage-21---master-node-image-upgrade)
- [Argo workflows](#argo-workflows)
- [Stage 2.2 - Worker node image upgrade](#stage-22---worker-node-image-upgrade)
  - [Option 1 - Serial upgrade](#option-1---serial-upgrade)
  - [Option 2 - Parallel upgrade (Tech preview)](#option-2---parallel-upgrade-tech-preview)
    - [Restrictions](#restrictions)
    - [Example](#example)
- [Stage 2.3 - `ncn-m001` upgrade](#stage-23---ncn-m001-upgrade)
  - [Remap `rbd` device from `ncn-m001` to `ncn-m002`](#remap-rbd-device-from-ncn-m001-to-ncn-m002)
  - [Stop typescript on `ncn-m001`](#stop-typescript-on-ncn-m001)
  - [Backup artifacts on `ncn-m001`](#backup-artifacts-on-ncn-m001)
  - [Move to `ncn-m002`](#move-to-ncn-m002)
  - [Start typescript on `ncn-m002`](#start-typescript-on-ncn-m002)
  - [Prepare `ncn-m002`](#prepare-ncn-m002)
  - [Upgrade `ncn-m001`](#upgrade-ncn-m001)
- [Stage 2.4 - Upgrade `weave` and `multus`](#stage-24---upgrade-weave-and-multus)
- [Stage 2.5 - `coredns` anti-affinity](#stage-25---coredns-anti-affinity)
- [Stage 2.6 - Complete Kubernetes upgrade](#stage-26---complete-kubernetes-upgrade)
- [Stop typescript on `ncn-m002`](#stop-typescript-on-ncn-m002)
- [Stage completed](#stage-completed)

## Start typescript on `ncn-m001`

1. (`ncn-m001#`) If a typescript session is already running in the shell, then first stop it with the `exit` command.

1. (`ncn-m001#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).stage_2_ncn-m001.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

If additional shells are opened during this procedure, then record those with typescripts as well. When resuming a procedure
after a break, always be sure that a typescript is running before proceeding.

## Stage 2.1 - Master node image upgrade

1. (`ncn-m001#`) Run `ncn-upgrade-master-nodes.sh` for `ncn-m002`.

   Follow output of the script carefully. The script will pause for manual interaction.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m002
   ```

   > **`NOTE`** The `root` user password for the node may need to be reset after it is rebooted.

1. Repeat the previous step for each other master node **excluding `ncn-m001`**, one at a time.

## Argo workflows

Before starting [Stage 2.2 - Worker node image upgrade](#stage-22---worker-node-image-upgrade), access the Argo UI to view the progress of this stage.
Note that the progress for the current stage will not show up in Argo before the worker node image upgrade script has been started.

For more information, see [Using the Argo UI](../operations/argo/Using_the_Argo_UI.md) and [Using Argo Workflows](../operations/argo/Using_Argo_Workflows.md).

> **`NOTE`** One of the Argo steps (`wait-for-cfs`) will prevent the upgrade of a worker node from proceeding if the CFS component status for that worker is in an `Error` state, and this must be fixed in order for the upgrade to continue.
The following steps can be used to reset the component state in CFS (replace `XNAME` below with the `XNAME` for the worker node:

```text
cray cfs components update --error-count 0 <XNAME>
cray cfs components update --state '[]' <XNAME>
```

## Stage 2.2 - Worker node image upgrade

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

## Stage 2.3 - `ncn-m001` upgrade

By this point, all NCNs have been upgraded, except for `ncn-m001`. In the upgrade process so far, `ncn-m001`
has been the "stable node" -- that is, the node from which the other nodes were upgraded. At this point, the
upgrade procedure pivots to use `ncn-m002` as the new "stable node", in order to allow the upgrade of `ncn-m001`.

### Remap `rbd` device from `ncn-m001` to `ncn-m002`

1. (`ncn-m001#`) Remap the CSM release `rbd` device to `ncn-m002`.

    This device was created in [Stage 0.1 - Prepare assets](Stage_0_Prerequisites.md#stage-01---prepare-assets).

    ```bash
    source /opt/cray/csm/scripts/csm_rbd_tool/bin/activate
    python /usr/share/doc/csm/scripts/csm_rbd_tool.py --rbd_action move --target_host ncn-m002
    deactivate
    ```

    **IMPORTANT:** This mounts the `rbd` device at `/etc/cray/upgrade/csm` on `ncn-m002`.

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
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).stage_2_ncn-m002.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

### Prepare `ncn-m002`

1. Authenticate with the Cray CLI on `ncn-m002`.

   See [Configure the Cray Command Line Interface](../operations/configure_cray_cli.md) for details on how to do this.

1. (`ncn-m002#`) Set upgrade variables.

   ```bash
   source /etc/cray/upgrade/csm/myenv
   echo "${CSM_REL_NAME}"
   ```

1. (`ncn-m002#`) Copy artifacts from `ncn-m001`.

   A later stage of the upgrade expects the `docs-csm` RPM to be located at `/root/docs-csm-latest.noarch.rpm` on `ncn-m002`; that is why this command copies it there.

   ```bash
   scp ncn-m001:/root/csm_upgrade.pre_m001_reboot_artifacts.*.tgz /root
   csi_rpm=$(find "/etc/cray/upgrade/csm/${CSM_REL_NAME}/tarball/${CSM_REL_NAME}/rpm/cray/csm/" -name 'cray-site-init*.rpm') &&
       scp ncn-m001:/root/docs-csm-*.noarch.rpm /root/docs-csm-latest.noarch.rpm &&
       rpm -Uvh --force "${csi_rpm}" /root/docs-csm-latest.noarch.rpm
   ```

### Upgrade `ncn-m001`

1. Upgrade `ncn-m001`.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m001
   ```

## Stage 2.4 - Upgrade `weave` and `multus`

Run the following command to complete the upgrade of the `weave` and `multus` manifest versions:

```bash
/srv/cray/scripts/common/apply-networking-manifests.sh
```

## Stage 2.5 - `coredns` anti-affinity

Run the following script to apply anti-affinity to `coredns` pods:

```bash
/usr/share/doc/csm/upgrade/scripts/k8s/apply-coredns-pod-affinity.sh
```

## Stage 2.6 - Complete Kubernetes upgrade

Complete the Kubernetes upgrade. This script will restart several pods on each master node to their new Docker containers.

```bash
/usr/share/doc/csm/upgrade/scripts/k8s/upgrade_control_plane.sh
```

> **`NOTE`**: `kubelet` has been upgraded already, ignore the warning to upgrade it.

### Stop typescript on `ncn-m002`

For any typescripts that were started during this stage on `ncn-m002`, stop them with the `exit` command.

## Stage completed

All Kubernetes nodes have been rebooted into the new image.

> **REMINDER**: If password for `ncn-m002` was reset during Stage 2.3, then also reset the password
> on `ncn-m001` at this time.

This stage is completed. Continue to [Stage 3](Stage_3.md).
