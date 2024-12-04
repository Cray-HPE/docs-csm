# Manual NCN upgrade

**This page should NOT be used for a normal CSM upgrade.**

This page provides instructions for doing a manual upgrade of NCN nodes.
There is a section for upgrading worker nodes, storage nodes, and master nodes.
All NCN upgrades in CSM 1.6 and later are done through IUF.
This page provides instructions in case a manual NCN upgrade is needed for an unusual situation.
As we have removed all of our manual CSM upgrade documentation, it is important that we have documentation
describing this process in case of an emergency.

If you are performing a regular CSM upgrade, this should be done through IUF.
Follow [upgrade management nodes and CSM services](../upgrade/Upgrade_Management_Nodes_and_CSM_Services.md) to perform a normal CSM upgrade.

- [Storage node manual upgrade](#storage-node-manual-upgrade)
- [Worker node manual upgrade](#worker-node-manual-upgrade)
- [Master node manual upgrade](#master-node-manual-upgrade)

## Storage node manual upgrade

**In CSM 1.6 and later, the storage node upgrades should be executed by IUF.
See [upgrade management nodes and CSM services](../upgrade/Upgrade_Management_Nodes_and_CSM_Services.md) to perform a normal CSM upgrade.**

Storage node upgrades are done using an IUF Argo workflow. See [using the Argo UI](../operations/argo/Using_the_Argo_UI.md) to access the UI and [using Argo workflows](../operations/argo/Using_Argo_Workflows.md) for more information about Argo workflows.

1. (`ncn-m001#`) Set the storage node name for the node that is being upgraded.

    ```bash
    storage_node=ncn-s00x
    ```

1. (`ncn-m001#`) Execute the storage node upgrade.

    > **NOTE:** If `--image-id` and/or `--desired-cfs-conf` is not supplied, then the storage node will be upgraded to the image that is already set in BSS and the CFS configuration already set in CFS.
    > Additionally, the `--image-id` and `--desired-cfs-conf` can be set manually in BSS and in CFS respectively.
    > See [set the image ID and CFS configuration manually](#set-the-image-id-and-cfs-configuration-manually) for the manual process.
    > If the manual process is used, then omit `--image-id` and `--desired-cfs-conf` from the command below.

    ```bash
    /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh $storage_node --upgrade --image-id $image --desired-cfs-conf $configuration
    ```

## Worker node manual upgrade

**In CSM 1.6 and later, the worker node upgrades should be executed by IUF.
See [upgrade management nodes and CSM services](../upgrade/Upgrade_Management_Nodes_and_CSM_Services.md) to perform a normal CSM upgrade.**

Worker node upgrades are done using an IUF Argo workflow. See [using the Argo UI](../operations/argo/Using_the_Argo_UI.md) to access the UI and [using Argo workflows](../operations/argo/Using_Argo_Workflows.md) for more information about Argo workflows.

1. (`ncn-m001#`) Set a worker node name for the node that is being upgraded.

    ```bash
    worker_node=ncn-w00x
    ```

1. (`ncn-m001#`) Execute a worker node upgrade.

    > **NOTE:** If `--image-id` and/or `--desired-cfs-conf` is not supplied, then the worker node will be upgraded to the image that is already set in BSS and the CFS configuration already set in CFS.
    > Additionally, the `--image-id` and `--desired-cfs-conf` can be set manually in BSS and in CFS respectively.
    > See [set the image ID and CFS configuration manually](#set-the-image-id-and-cfs-configuration-manually) for the manual process.
    > If the manual process is used, then omit `--image-id` and `--desired-cfs-conf` from the command below.

    ```bash
    /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh $worker_node --image-id $image --desired-cfs-conf $configuration
    ```

## Master node manual upgrade

**In CSM 1.6 and later, the master node upgrades should be executed by IUF.
See [upgrade management nodes and CSM services](../upgrade/Upgrade_Management_Nodes_and_CSM_Services.md) to perform a normal CSM upgrade.**

A master node upgrade is not executed by Argo workflows, instead the master node upgrade is a bash script.
IUF can use Argo workflows to execute a master node upgrade but it does this by executing the master node upgrade script.
The script keeps track of steps that have been completed and prints them to a state file in the `/etc/cray/upgrade/csm/csm-${CSM_RELEASE}/<node-name>` directory on the node where the script is executed.
If the master node upgrade fails partway through, it is safe to re-execute the upgrade script because the state is being tracked and steps will not be re-executed if they have already run successfully.

There are two different processes for upgrading master nodes depending on if `ncn-m001` is being upgraded or if `ncn-m002` or `ncn-m003` is being upgraded.

Follow one of two procedures below.

- [Manually upgrade `ncn-m002` or `ncn-m003`](#manually-upgrade-ncn-m002-or-ncn-m003)
- [Manually upgrade `ncn-m001`](#manually-upgrade-ncn-m001)

### Manually upgrade `ncn-m002` or `ncn-m003`

> **`NOTE`** If Kubernetes encryption has been enabled via the [Kubernetes Encryption Documentation](../operations/kubernetes/encryption/README.md),
then backup the `/etc/cray/kubernetes/encryption` directory on the master node before upgrading and restore the directory after the node has been upgraded.

1. (`ncn-m001#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).upgrade-m0023.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

1. [Set the image ID and CFS configuration manually.](#set-the-image-id-and-cfs-configuration-manually)

1. (`ncn-m001#`) Set upgrade variables.

   ```bash
   source /etc/cray/upgrade/csm/myenv
   ```

1. (`ncn-m001#`) Set the master node name for the node that is being upgraded (`ncn-m002` or `ncn-m003`).

    ```bash
    master_node=ncn-m00x
    ```

1. (`ncn-m001#`) Run `ncn-upgrade-master-nodes.sh` for `ncn-m002` or `ncn-m003`.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-master-nodes.sh $master_node
   ```

   > **`NOTE`** The `root` user password for the node may need to be reset after it is rebooted. Additionally, the `/etc/cray/kubernetes/encryption` directory should be restored if it was backed up.
   Once it is restored, the `kube-apiserver` on the rebuilt node should be restarted.
   See [Kubernetes `kube-apiserver` Failing](../troubleshooting/kubernetes/Kubernetes_Kube_apiserver_failing.md) for details on how to restart the `kube-apiserver`.

### Manually upgrade `ncn-m001`

To manually upgrade `ncn-m001`, the CFS configuration and node image need to be set for `ncn-m001`, the artifacts on `ncn-m001` need to be backed up, `ncn-m002` needs to be prepared to execute the upgrade, and the `ncn-m001` upgrade needs to be executed.
Follow the steps below to upgrade `ncn-m001`.

1. [Set the image ID and CFS configuration manually.](#set-the-image-id-and-cfs-configuration-manually)

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

1. Log out of `ncn-m001`.

1. Log in to `ncn-m002` from outside the cluster.

    > **`NOTE`** Very rarely, a password hash for the `root` user that works properly on a SLES SP2 NCN is
    > not recognized on a SLES SP3 NCN. If password login fails, then log in to `ncn-m002` from
    > `ncn-m001` and use the `passwd` command to reset the password. Then log in using the CMN IP address as directed
    > below. Once `ncn-m001` has been upgraded, log in from `ncn-m002` and use the `passwd` command to reset
    > the password. The other NCNs will have their passwords updated when NCN personalization is run in a
    > subsequent step.

    `ssh` to the `bond0.cmn0`/CMN IP address of `ncn-m002`.

1. (`ncn-m002#`) Start a typescript.

    ```bash
    script -af /root/csm_upgrade.$(date +%Y%m%d_%H%M%S).upgrade-m001.txt
    export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

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
       zypper --plus-repo="/etc/cray/upgrade/csm/csm-${CSM_RELEASE}/tarball/csm-${CSM_RELEASE}/rpm/cray/csm/sle-$(awk -F= '/VERSION=/{gsub(/["-]/, "") ; print tolower($NF)}' /etc/os-release)" --no-gpg-checks install -y cray-site-init
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

1. (`ncn-m002#`) Upgrade `ncn-m001`.

   > **`NOTE`** If Kubernetes encryption has been enabled via the [Kubernetes Encryption Documentation](../operations/kubernetes/encryption/README.md),
    then backup the `/etc/cray/kubernetes/encryption` directory on the master node before upgrading and restore the directory after the node has been upgraded.

   ```bash
   /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-master-nodes.sh ncn-m001
   ```

   > **`NOTE`** The `root` user password for the node may need to be reset after it is rebooted.
   Additionally, the `/etc/cray/kubernetes/encryption` directory should be restored if it was backed up.
   Once it is restored, the `kube-apiserver` on the rebuilt node should be restarted.
   See [Kubernetes `kube-apiserver` Failing](../troubleshooting/kubernetes/Kubernetes_Kube_apiserver_failing.md) for details on how to restart the `kube-apiserver`.

## Set the image ID and CFS configuration manually

(`ncn-m001#`) Set `XNAME` to the xname of the node that is being upgraded.

```bash
XNAME=<node_xname>
```

### Set the image ID in BSS

1. (`ncn-m001#`) Set `IMS_IMAGE_ID` to the image ID that should be upgraded to.

    ```bash
    IMS_IMAGE_ID=<image_id>
    ```

1. (`ncn-m001#`) Set the image ID in BSS.

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/assign-ncn-images.sh -p $IMS_IMAGE_ID $XNAME
    ```

### Set the CFS configuration in CFS

The following steps will update the node's desired configuration but will leave it disabled.
It will automatically enable and be applied after the node is upgraded.

1. (`ncn-m001#`) Set `CFS_CONFIG_NAME` to the configuration that should be used once the node has been upgraded.

    ```bash
    CFS_CONFIG_NAME=<cfs_configuration>
    ```

1. (`ncn-m001#`) Set CFS configuration.

    ```bash
    /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
        --no-config-change --no-enable --config-name $CFS_CONFIG_NAME --xnames $XNAME
    ```
