# Management rollout

This section updates the software running on management NCNs.

- [1. Update management host firmware (FAS)](#1-update-management-host-firmware-fas)
- [2. Execute the IUF `management-nodes-rollout` stage](#2-execute-the-iuf-management-nodes-rollout-stage)
    - [2.1 `management-nodes-rollout` with CSM upgrade](#21-management-nodes-rollout-with-csm-upgrade)
    - [2.2 `management-nodes-rollout` without CSM upgrade](#22-management-nodes-rollout-without-csm-upgrade)
    - [2.3 NCN worker nodes](#23-ncn-worker-nodes)
- [3. Restart `goss-servers` on all NCNs](#3-restart-goss-servers-on-all-ncns)
- [4. Update management host Slingshot NIC firmware](#4-update-management-host-slingshot-nic-firmware)
- [5. Next steps](#5-next-steps)

## 1. Update management host firmware (FAS)

**`NOTE`** This subsection is optional and can be skipped if upgrading only CSM through IUF.

Refer to [Update Non-Compute Node (NCN) BIOS and BMC Firmware](../../firmware/FAS_Use_Cases.md#update-non-compute-node-ncn-bios-and-bmc-firmware) for details on how to upgrade the firmware on management nodes.

Once this step has completed:

- Host firmware has been updated on management nodes

Note: In CSM 1.6.0, all the worker nodes were configured as iSCSI SBPS targets by default. In CSM 1.7.0, selective worker
node personalization is supported where if user/admin wants to limit some worker nodes to be configured as iSCSI targets,
then it requires to create an HSM group by name `iscsi_worker` and add the worker node xnames to this group which are required to be configured as iSCSI targets. For the steps/procedure for the same, see [HSM groups iSCSI](https://github.com/Cray-HPE/docs-csm/blob/release/1.7/operations/iscsi_sbps/HSM_groups_iscsi.md)

This has to be done before "management-nodes-rollout" stage during upgrade. If this is not done, all the worker nodes will be configured as iSCSI targets. But this HSM group can be created post upgrade and re-run iSCSI CFS layer to avail this
selective node personalization. Procedure/steps for the same are at:

TBD

For more information on iSCSI SBPS, see [iSCSI SBPS](https://github.com/Cray-HPE/docs-csm/blob/release/1.7/operations/iscsi_sbps/iscsi_sbps.md)

## 2. Execute the IUF `management-nodes-rollout` stage

This section describes how to update software on management nodes. It describes how to test a new image and CFS configuration on a single node first to ensure they work as expected before rolling the changes out to the other management
nodes. This initial test node is referred to as the "canary node". Modify the procedure as necessary to accommodate site preferences for rebuilding management nodes. The images and CFS configurations used are created by the
`prepare-images` and `update-cfs-config` stages respectively; see the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation for details on how to query the images and CFS configurations and see the
[update-cfs-config](../stages/update_cfs_config.md) documentation for details about how the CFS configuration is updated.

**`NOTE`** Additional arguments are available to control the behavior of the `management-nodes-rollout` stage, for example `--limit-management-rollout` and `-cmrp`. See the
[`management-nodes-rollout` stage documentation](../stages/management_nodes_rollout.md) for details and adjust the examples below if necessary.

**`NOTE`** When using the option `--limit-management-rollout` to pass the list of nodes for `management-nodes-rollout`, ensure that the label `iuf-prevent-rollout=true` is not set on any of the nodes passed in the list.

1. (`ncn-m001#`) Verify if any nodes are labeled with `iuf-prevent-rollout=true`.

    ```bash
    kubectl get nodes --show-labels | grep iuf-prevent-rollout
    ```

1. (`ncn-m001#`) Use `kubectl` to remove the `iuf-prevent-rollout=true` label from the node.

    ```bash
    kubectl label nodes "${NODE}" --overwrite iuf-prevent-rollout-
    ```

**`IMPORTANT`** There is a different procedure for `management-nodes-rollout` depending on whether or not CSM is being upgraded. The two procedures differ in the handling of NCN storage nodes and NCN master nodes. If CSM is not
being upgraded, then NCN storage nodes and NCN master nodes will not be upgraded with new images and will be updated by the CFS configuration created in [update-cfs-config](../stages/update_cfs_config.md) only. If CSM is being
upgraded, the NCN storage nodes and NCN master nodes will be upgraded with new images and the new CFS configuration. Both procedures use the same steps for rebuilding/upgrading NCN worker nodes. Select **one** of the following
procedures based on whether or not CSM is being upgraded:

- [`management-nodes-rollout` with CSM upgrade](#21-management-nodes-rollout-with-csm-upgrade)
- [`management-nodes-rollout` without CSM upgrade](#22-management-nodes-rollout-without-csm-upgrade)

### Note for CSM `V1.7.0`

Starting with CSM `V1.7.0`, administrators can use an IMS image and configuration from CFS built outside of IUF to perform the `management-nodes-rollout` stage. The image and configuration can be explicitly passed in the IUF CLI command.

For example, to upgrade a storage node using an image and CFS configuration created outside of the `prepare-images` stage, the command could look like this:

```bash
iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run \
    --set-management-config "configuration_name" \
    --set-management-image "image_ID" \
    -r management-nodes-rollout --limit-management-rollout ${STORAGE_CANARY}
```

The CFS configuration and IMS image being used can be described like shown below:

```bash
ncn-m001:~ # cray cfs configurations describe management-main-1.7-1715924
lastUpdated = "2025-04-14T19:22:00Z"
name = "management-main-1.7-1715924"
[[layers]]
cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
commit = "c5b9a27fd4ab86bb38e03346b4ed464a04d3799c"
name = "csm-ncn-nodes-1.7.0-alpha.11"
playbook = "ncn_nodes.yml"

[[layers]]
cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/slingshot-host-software-config-management.git"
commit = "caa82a0b793288aeedfa75f8804dd528cae08bcd"
name = "shs-mellanox_install-integration-12.0.0"
playbook = "shs_mellanox_install.yml"
```

```bash
ncn-m001:~ # cray ims images describe f9fb3b2b-5527-47cb-a2de-8fa9dec7cec6
arch = "x86_64"
created = "2025-04-14T19:44:21.862319"
id = "f9fb3b2b-5527-47cb-a2de-8fa9dec7cec6"
name = "master-secure-kubernetes-7.1.6-x86_64.squashfs-1715924"

[link]
etag = "b49ef59b6c0099cd6e237b1e44bf19e8"
path = "s3://boot-images/f9fb3b2b-5527-47cb-a2de-8fa9dec7cec6/manifest.json"
type = "s3"

[metadata]
```

> **Important:** There is no built-in mechanism to validate the image and configuration being passed belong to the same role and subrole. Administrators must ensure that the correct image and configuration are used for the corresponding node and subrole.

For the new parameters added, please refer to the command information in the [IUF run command details](../IUF.md#run) documentation.

### 2.1 `management-nodes-rollout` with CSM upgrade

All management nodes will be upgraded to a new image because CSM itself is being upgraded.
This section describes how to test a new image and CFS configuration on a single canary node first before rolling it out to the other management nodes of the same management type.
Follow the steps below to upgrade all management nodes.

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `management-nodes-rollout` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Perform the NCN storage node upgrades. This upgrades a single storage node first to test the storage node image and then upgrades the remaining storage nodes.

    **`NOTE`** The `management-nodes-rollout` stage creates additional separate Argo workflows when rebuilding NCN storage nodes. The Argo workflow names will include the string `ncn-lifecycle-rebuild`.
    If monitoring progress with the Argo UI, remember to include these workflows.

    1. (`ncn-m001#`) Execute the `management-nodes-rollout` stage with a single NCN storage node.

        ```bash
        STORAGE_CANARY=ncn-s001
        ```

        ```bash
        iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout ${STORAGE_CANARY}
        ```

    1. (`ncn-m#`) Verify that the storage canary node booted successfully with the desired CFS configuration.

        ```bash
        XNAME=$(ssh $STORAGE_CANARY 'cat /etc/cray/xname')
        echo "${XNAME}"
        cray cfs components describe "${XNAME}"
        ```

        The desired value for `configuration_status` is `configured`. If it is `pending`, then wait for the status to change to `configured`.

    1. (`ncn-m001#`) Upgrade the remaining NCN storage nodes once the first has upgraded successfully. This upgrades NCN storage nodes serially.
    Get the number of storage nodes based on the cluster and verify that it is correct. The storage canary node should not be in the list since it has already been upgraded.
    The list of storage nodes can be manually entered if it is not desired to upgrade all of the remaining storage nodes.

        ```bash
        STORAGE_NODES="$(ceph orch host ls | grep ncn-s | grep -v "$STORAGE_CANARY" | awk '{print $1}' | xargs echo)"
        echo "$STORAGE_NODES"
        ```

        ```bash
        iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout ${STORAGE_NODES}
        ```

    1. (`ncn-m001#`) Verify that all storage nodes configured successfully.

        ```bash
        for ncn in $(cray hsm state components list --subrole Storage --type Node \
           --format json | jq -r .Components[].ID | grep b0n | sort); do cray cfs components describe \
           $ncn --format json | jq -r ' .id+" "+.desiredConfig+" status="+.configurationStatus'; done
        ```

1. Perform the NCN master node upgrade of `ncn-m002` and `ncn-m003`.

    > **`NOTE`** If Kubernetes encryption has been enabled via the [Kubernetes Encryption Documentation](../../kubernetes/encryption/README.md),
    then backup the `/etc/cray/kubernetes/encryption` directory on the master node before upgrading and restore the directory after the node has been upgraded.

    1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on `ncn-m002`. This will rebuild `ncn-m002` with the new CFS configuration and image built in
    previous steps of the workflow.

        (`ncn-m001#`) Execute the `management-nodes-rollout` stage with `ncn-m002`.

        ```bash
        iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout ncn-m002
        ```

        > **`NOTE`** The `/etc/cray/kubernetes/encryption` directory should be restored if it was backed up. Once it is restored, the `kube-apiserver` on the rebuilt node should be restarted.
        See [Kubernetes `kube-apiserver` Failing](../../../troubleshooting/kubernetes/Kubernetes_Kube_apiserver_failing.md) for details on how to restart the `kube-apiserver`.

    1. Verify that `ncn-m002` booted successfully with the desired image and CFS configuration.

        ```bash
        XNAME=$(ssh ncn-m002 'cat /etc/cray/xname')
        echo "${XNAME}"
        cray cfs components describe "${XNAME}"
        ```

    1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on `ncn-m003`. This will rebuild `ncn-m003` with the new CFS configuration and image built in
    previous steps of the workflow.

        (`ncn-m001#`) Execute the `management-nodes-rollout` stage with `ncn-m003`.

        ```bash
        iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout ncn-m003
        ```

        > **`NOTE`** The `/etc/cray/kubernetes/encryption` directory should be restored if it was backed up. Once it is restored, the `kube-apiserver` on the rebuilt node should be restarted.

    1. Verify that `ncn-m003` booted successfully with the desired image and CFS configuration.

        ```bash
        XNAME=$(ssh ncn-m003 'cat /etc/cray/xname')
        echo "${XNAME}"
        cray cfs components describe "${XNAME}"
        ```

1. Perform the NCN worker node upgrade. To upgrade worker nodes, follow the procedure in section [2.3 NCN worker nodes](#23-ncn-worker-nodes) and then return to this procedure to complete the next step.

1. Perform the NCN master node upgrade of `ncn-m001`.

    > **`NOTE`** If Kubernetes encryption has been enabled via the [Kubernetes Encryption Documentation](../../kubernetes/encryption/README.md),
    then backup the `/etc/cray/kubernetes/encryption` directory on the master node before upgrading and restore the directory after the node has been upgraded.

    1. Authenticate with the Cray CLI on `ncn-m002`.

        See [Configure the Cray Command Line Interface](../../configure_cray_cli.md) for details on how to do this.

    1. Invoke `iuf run` with `-r` to execute the [`management-nodes-rollout`](../stages/management_nodes_rollout.md) stage on `ncn-m001`. This will rebuild `ncn-m001` with the    new CFS configuration and image built in
    previous steps of the workflow.

        (`ncn-m002#`) Upgrade `ncn-m001`. This **must** be executed on **`ncn-m002`**.

        1. Run `upload-rebuild-templates.sh` to update all the workflows that will be used by IUF and to ensure the correct CSM product versions will be used by IUF.

            (`ncn-m002#`) Execute the `upload-rebuild-templates.sh` script.

            ```bash
            /usr/share/doc/csm/workflows/scripts/upload-rebuild-templates.sh
            ```

        (`ncn-m002#`) Execute the `management-nodes-rollout` stage with `ncn-m001`.

        ```bash
        iuf -a "${ACTIVITY_NAME}" --media-host ncn-m002 run -r management-nodes-rollout --limit-management-rollout ncn-m001
        ```

        > **`NOTE`** The `/etc/cray/kubernetes/encryption` directory should be restored if it was backed up. Once it is restored, the `kube-apiserver` on the rebuilt node should    be restarted.
        See [Kubernetes `kube-apiserver` Failing](../../../troubleshooting/kubernetes/Kubernetes_Kube_apiserver_failing.md) for details on how to restart the `kube-apiserver`.

    1. Verify that `ncn-m001` booted successfully with the desired image and CFS configuration.

        ```bash
        XNAME=$(ssh ncn-m001 'cat /etc/cray/xname')
        echo "${XNAME}"
        cray cfs components describe "${XNAME}"
        ```

    > **`NOTE`** After `management-nodes-rollout` stage for management NCNs is completed, re-initialize cray CLI. Refer to [Configure the Cray Command Line Interface (cray CLI)](../../configure_cray_cli.md)

    Once this step has completed:

     - All management NCNs have been upgraded to the image and CFS configuration created in the previous steps of this workflow
     - Per-stage product hooks have executed for the `management-nodes-rollout` stage

Continue to the next section [3. Restart `goss-servers` on all NCNs](#3-restart-goss-servers-on-all-ncns).

### 2.2 `management-nodes-rollout` without CSM upgrade

This is the procedure to rollout management nodes if CSM is not being upgraded. NCN worker node images contain kernel module content from non-CSM products and need to be rebuilt as part of the workflow.
Unlike NCN worker nodes, NCN master nodes and storage nodes do not contain kernel module content from non-CSM products. However, user-space non-CSM product content is still provided on NCN master nodes and storage nodes and thus the `prepare-images` and `update-cfs-config`
stages create a new image and CFS configuration for NCN master nodes and storage nodes. The CFS configuration layers ensure the non-CSM product content is applied correctly for both
image customization and node personalization scenarios. As a result, the administrator
can update NCN master and storage nodes using CFS configuration only.
Follow the following steps to complete the `management-nodes-rollout` stage.

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `management-nodes-rollout` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. Rebuild the NCN worker nodes. Follow the procedure in section [2.3 NCN worker nodes](#23-ncn-worker-nodes) and then return to this procedure to complete the next step.

1. Configure NCN master nodes.

    1. (`ncn-m#`) Create a comma-separated list of the xnames for all NCN master nodes and verify they are correct.

        ```bash
        MASTER_XNAMES=$(cray hsm state components list --role Management --subrole Master --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
        echo "Master node xnames: $MASTER_XNAMES"
        ```

    1. Get the CFS configuration created for management nodes during the `prepare-images` and `update-cfs-config` stages. Follow the instructions in the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created)
       documentation to get the value for `configuration` for the image with a `configuration_group_name` value matching `Management_Master`.

    1. (`ncn-m#`) Set `CFS_CONFIG_NAME` to the value for `configuration` found in the previous step.

        ```bash
        CFS_CONFIG_NAME=<appropriate configuration value>
        ```

    1. (`ncn-m#`) Apply the CFS configuration to NCN master nodes.

        ```bash
        /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
        --no-config-change --config-name "${CFS_CONFIG_NAME}" --xnames $MASTER_XNAMES --clear-state
        ```

        Sample output for configuring multiple management nodes is:

          ```bash
          Taking snapshot of existing management-23.11.0 configuration to /root/apply_csm_configuration.20240305_173700.vKxhqC backup-management-23.11.0.json
          Setting desired configuration, clearing state, clearing error count, enabling components in CFS
          desiredConfig = "management-23.11.0"
          enabled = true
          errorCount = 0
          id = "x3700c0s16b0n0"
          state = []

          [tags]

          desiredConfig = "management-23.11.0"
          enabled = true
          errorCount = 0
          id = "x3701c0s16b0n0"
          state = []

          [tags]

          desiredConfig = "management-23.11.0"
          enabled = true
          errorCount = 0
          id = "x3702c0s16b0n0"
          state = []

          [tags]

          Waiting for configuration to complete. 3 components remaining.
          Configuration complete. 3 component(s) completed successfully.  0 component(s) failed.
          ```

1. Configure NCN storage nodes.

    1. (`ncn-m#`) Create a comma-separated list of the xnames for all NCN storage nodes and verify they are correct.

        ```bash
        STORAGE_XNAMES=$(cray hsm state components list --role Management --subrole Storage --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
        echo "Storage node xnames: $STORAGE_XNAMES"
        ```

    1. Get the CFS configuration created for management storage nodes during the `prepare-images` and `update-cfs-config` stages. Follow the instructions in the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created)
       documentation to get the value for `configuration` for the image with a `configuration_group_name` value matching `Management_Storage`.

    1. (`ncn-m#`) Set `CFS_CONFIG_NAME` to the value for `configuration` found in the previous step.

        ```bash
        CFS_CONFIG_NAME=<appropriate configuration value>
        ```

    1. (`ncn-m#`) Apply the CFS configuration to NCN storage nodes.

        ```bash
        /usr/share/doc/csm/scripts/operations/configuration/apply_csm_configuration.sh \
        --no-config-change --config-name "${CFS_CONFIG_NAME}" --xnames $STORAGE_XNAMES --clear-state
        ```

        Sample output for configuring multiple management nodes is:

          ```text
          Taking snapshot of existing minimal-management-23.11.0 configuration to /root/apply_csm_configuration.20240305_173700.vKxhqC backup-minimal-management-23.11.0.json
          Setting desired configuration, clearing state, clearing error count, enabling components in CFS
          desiredConfig = "minimal-management-23.11.0"
          enabled = true
          errorCount = 0
          id = "x3700c0s16b0n0"
          state = []

          [tags]

          desiredConfig = "minimal-management-23.11.0"
          enabled = true
          errorCount = 0
          id = "x3701c0s16b0n0"
          state = []

          [tags]

          desiredConfig = "minimal-management-23.11.0"
          enabled = true
          errorCount = 0
          id = "x3702c0s16b0n0"
          state = []

          [tags]

          Waiting for configuration to complete. 3 components remaining.
          Configuration complete. 3 component(s) completed successfully.  0 component(s) failed.
          ```

Once this step has completed:

- Management NCN worker nodes have been rebuilt with the image and CFS configuration created in previous steps of this workflow
- Management NCN storage and NCN master nodes have be updated with the CFS configuration created in the previous steps of this workflow.
- Per-stage product hooks have executed for the `management-nodes-rollout` stage

Continue to the next section [3. Restart `goss-servers` on all NCNs](#3-restart-goss-servers-on-all-ncns).

### 2.3 NCN worker nodes

NCN worker node images contain kernel module content from non-CSM products and need to be rebuilt as part of the workflow. This section describes how to test a new image and CFS configuration on a single canary node (`ncn-w001`) first before
rolling it out to the other NCN worker nodes. Modify the procedure as necessary to accommodate site preferences for rebuilding NCN worker nodes.

The images and CFS configurations used are created by the `prepare-images` and `update-cfs-config` stages respectively; see the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation
for details on how to query the images and CFS configurations and see the [update-cfs-config](../stages/update_cfs_config.md) documentation for details about how the CFS configuration is updated.

**`NOTE`** The `management-nodes-rollout` stage creates additional separate Argo workflows when rebuilding NCN worker nodes. The Argo workflow names will include the string `ncn-lifecycle-rebuild`. If monitoring progress with the Argo UI,
remember to include these workflows.

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table that summarizes which product documents contain information or actions for the `management-nodes-rollout` stage.
Refer to that table and any corresponding product documents before continuing to the next step.

1. (`ncn-m001#`) Execute the `management-nodes-rollout` stage with a single NCN worker node.
This will rebuild the canary node with the new CFS configuration and image built in previous steps of the workflow.
The worker canary node can be any worker node and does not have to be `ncn-w001`.

    ```bash
    WORKER_CANARY=ncn-w001
    ```

    ```bash
    iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout ${WORKER_CANARY}
    ```

1. Verify the canary node booted successfully with the desired image and CFS configuration.

    ```bash
    XNAME=$(ssh $WORKER_CANARY 'cat /etc/cray/xname')
    echo "${XNAME}"
    cray cfs components describe "${XNAME}"
    ```

1. (`ncn-m001#`) Use `kubectl` to apply the `iuf-prevent-rollout=true` label to the canary node to prevent it from unnecessarily rebuilding again.

    ```bash
    kubectl label nodes "${WORKER_CANARY}" --overwrite iuf-prevent-rollout=true
    ```

1. (`ncn-m001#`) Verify the IUF node labels are present on the desired node.

    ```bash
    kubectl get nodes --show-labels | grep iuf-prevent-rollout
    ```

1. (`ncn-m001#`) Execute the `management-nodes-rollout` stage on all remaining worker nodes.

    **`NOTE`** For this step, the argument to `--limit-management-rollout` can be `Management_Worker` or a list of worker
    node names separated by spaces. If `Management_Worker` is supplied, all worker nodes that are not labeled
    with `iuf-prevent-rollout=true` will be rebuilt/upgraded. If a list of worker node names is supplied, then those worker nodes will be rebuilt/upgraded.

    **Choose one** of the following two options. The difference between the options is the `limit-management-rollout` argument, but the two options do the same thing.

    1. (`ncn-m001#`) Execute `management-nodes-rollout` on all `Management_Worker` nodes.

        ```bash
        iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout Management_Worker
        ```

    1. (`ncn-m001#`) Execute `management-nodes-rollout` on a group of worker nodes. The list of worker nodes can be manually edited if it is undesirable to rebuild/upgrade all of the workers with one execution.

        ```bash
        WORKER_NODES=$(kubectl get node | grep -P 'ncn-w\d+' | grep -v $WORKER_CANARY |  awk '{print $1}' | xargs)
        echo $WORKER_NODES
        ```

        ```bash
        iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r management-nodes-rollout --limit-management-rollout $WORKER_NODES
        ```

1. (`ncn-m001#`) Use `kubectl` to remove the `iuf-prevent-rollout=true` label from the canary node.

    ```bash
    kubectl label nodes "${WORKER_CANARY}" --overwrite iuf-prevent-rollout-
    ```

1. (`ncn-m001#`) Verify that all worker nodes configured successfully.

    ```bash
    for ncn in $(cray hsm state components list --subrole Worker --type Node \
      --format json | jq -r .Components[].ID | grep b0n | sort); do cray cfs components describe \
      $ncn --format json | jq -r ' .id+" "+.desiredConfig+" status="+.configurationStatus'; done
    ```

Once this step has completed:

- Management NCN worker nodes have been rebuilt with the image and CFS configuration created in previous steps of this workflow
- Per-stage product hooks have executed for the `management-nodes-rollout` stage

Return to the procedure that was being followed for `management-nodes-rollout` to complete the next step, either [Management-nodes-rollout with CSM upgrade](#21-management-nodes-rollout-with-csm-upgrade) or
[Management-nodes-rollout without CSM upgrade](#22-management-nodes-rollout-without-csm-upgrade).

## 3. Restart `goss-servers` on all NCNs

**`NOTE`** Skip this step if the CSM version is 1.6.1 or above. This step will cause no harm if done on CSM 1.6.1 or higher, but it is unnecessary.

If the CSM version is 1.6.0 or lower, then the `goss-servers` service needs to be restarted on all NCNs. This ensures the correct tests are run on each NCN. This is necessary due to a timing issue that is fixed in CSM 1.6.1.

(`ncn-m001#`) Restart `goss-servers`.

```bash
ncn_nodes=$(grep -oP "(ncn-s\w+|ncn-m\w+|ncn-w\w+)" /etc/hosts | sort -u | tr -t '\n' ',')
ncn_nodes=${ncn_nodes%,}
pdsh -S -b -w $ncn_nodes 'systemctl restart goss-servers'
```

## 4. Update management host Slingshot NIC firmware

**`NOTE`** This subsection is optional and can be skipped if upgrading only CSM through IUF.

If new Slingshot NIC firmware was provided, refer to the "200Gbps NIC Firmware Management" section of the _HPE Slingshot Installation Guide for CSM_ for details on how to update NIC firmware on management nodes.

After updating management host Slingshot NIC firmware, all nodes where the firmware was updated must be power cycled.  

Choose one of the below options to reboot worker nodes:
To manually reboot the nodes follow the [Reboot NCNs manually](../../node_management/Reboot_NCNs_manual.md#ncn-worker-nodes) for all nodes where the firmware was updated.  
To use IUF to reboot the nodes, follow the [Reboot NCNs with IUF](../../node_management/Reboot_NCNs_iuf.md#ncn-worker-nodes) for all nodes where the firmware was updated.

Once this step has completed:

- New versions of product microservices have been deployed
- Service checks have been run to verify product microservices are executing as expected
- Per-stage product hooks have executed for the `deploy-product` and `post-install-service-check` stages

## 5. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the
  [Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md)
  workflow to continue the install or upgrade.

- If performing an upgrade that includes upgrading CSM and additional products with IUF,
  return to the [Upgrade CSM and additional products with IUF](upgrade_csm_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.

- If performing an upgrade that includes upgrading only CSM, return to the
  [Upgrade only CSM through IUF](../../../upgrade/Upgrade_Only_CSM_with_iuf.md)
  workflow to continue the upgrade.
