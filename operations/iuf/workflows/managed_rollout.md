# Managed rollout

This section updates the software running on managed compute and application (UAN, etc.) nodes.

- [1. Update managed host firmware (FAS)](#1-update-managed-host-firmware-fas)
- [2. Execute the IUF `managed-nodes-rollout` stage](#2-execute-the-iuf-managed-nodes-rollout-stage)
  - [2.1 LNet router nodes and gateway nodes](#21-lnet-router-nodes-and-gateway-nodes)
  - [2.2 Compute nodes](#22-compute-nodes)
  - [2.3 Application nodes](#23-application-nodes)
- [3. Update managed host Slingshot NIC firmware](#3-update-managed-host-slingshot-nic-firmware)
- [4. Execute the IUF `post-install-check` stage](#4-execute-the-iuf-post-install-check-stage)
- [5. Next steps](#5-next-steps)

## 1. Update managed host firmware (FAS)

Refer to [Update Firmware with FAS](../../firmware/Update_Firmware_with_FAS.md) for details on how to upgrade the firmware on managed nodes.

Once this step has completed:

- Host firmware has been updated on managed nodes

## 2. Execute the IUF `managed-nodes-rollout` stage

This section describes how to update software on managed nodes. It describes how to test a new image and CFS configuration on a single "canary node" first before rolling it out to the other managed nodes. Modify the procedure
as necessary to accommodate site preferences for rebooting managed nodes. If the system has heterogeneous nodes, it may be desirable to repeat this process with multiple canary nodes, one for each distinct node configuration.
The images, CFS configurations, and BOS session templates used are created by the `prepare-images` stage; see the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation for details on how to query the
images and CFS configurations.

**`NOTE`** Additional arguments are available to control the behavior of the `managed-nodes-rollout` stage. See the [`managed-nodes-rollout` stage documentation](../stages/managed_nodes_rollout.md) for details and adjust the
examples below if necessary.

### 2.1 LNet router nodes and gateway nodes

LNet router nodes or gateway nodes should be upgraded before rebooting compute nodes to new images and CFS configurations. Since LNet routers and gateway nodes are examples of application nodes, the instructions in this section
are the same as in [2.3 Application nodes](#23-application-nodes).

Since LNet router nodes and gateway nodes are not managed by workload managers, the IUF `managed-nodes-rollout` stage cannot reboot them in a controlled manner via the `-mrs stage` argument. The IUF `managed-nodes-rollout` stage
can reboot LNet router and gateway nodes using the `-mrs reboot` argument, but an immediate reboot of the nodes is likely to be disruptive to users and overall system health and is not recommended. Administrators should determine
the best approach for rebooting LNet router and gateway nodes outside of IUF that aligns with site preferences.

Once this step has completed:

- Managed LNet router and gateway nodes (if any) have been rebooted to the images and CFS configurations created in previous steps of this workflow
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage if IUF `managed-nodes-rollout` procedures were used to perform the reboots

### 2.2 Compute nodes

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `managed-nodes-rollout` stage.

1. Invoke `iuf run` with `-r` to execute the [`managed-nodes-rollout`](../stages/managed_nodes_rollout.md) stage on a single node to ensure the node reboots successfully with the desired image and CFS configuration. This node is
referred to as the "canary node" in the remainder of this section. Use `--limit-managed-rollout` to target the canary node only and use `-mrs reboot` to reboot the canary node immediately.

    (`ncn-m001#`) Execute the `managed-nodes-rollout` stage with a single xname, rebooting the canary node immediately. Replace the example value of `${XNAME}` with the xname of the canary node.

    ```bash
    XNAME=x3000c0s29b1n0
    iuf -a "${ACTIVITY_NAME}" -r managed-nodes-rollout --limit-managed-rollout "${XNAME}" -mrs reboot
    ```

1. Verify the canary node booted successfully with the desired image and CFS configuration.

1. Invoke `iuf run` with `-r` to execute the [`managed-nodes-rollout`](../stages/managed_nodes_rollout.md) stage on all nodes, rebooting the nodes in the default staged manner in conjunction with the workload manager.

    (`ncn-m001#`) Execute the `managed-nodes-rollout` stage.

    ```bash
    iuf -a "${ACTIVITY_NAME}" -r managed-nodes-rollout
    ```

Once this step has completed:

- Managed compute nodes have been rebooted to the images and CFS configurations created in previous steps of this workflow
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage

### 2.3 Application nodes

**`NOTE`** If LNet router or gateway nodes were upgraded in the [2.1 LNet router nodes and gateway nodes](#21-lnet-router-nodes-and-gateway-nodes) section, there is no need to upgrade them again in this section. Follow the
instructions in this section to upgrade any remaining applications (UANs, etc.) that have not been upgraded yet.

Since applications nodes are not managed by workload managers, the IUF `managed-nodes-rollout` stage cannot reboot them in a controlled manner via the `-mrs stage` argument. The IUF `managed-nodes-rollout` stage can reboot application
nodes using the `-mrs reboot` argument, but an immediate reboot of application nodes is likely to be disruptive to users and overall system health and is not recommended. Administrators should determine the best approach for rebooting
application nodes outside of IUF that aligns with site preferences.

Once this step has completed:

- Managed application (UAN, etc.) nodes have been rebooted to the images and CFS configurations created in previous steps of this workflow
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage if IUF `managed-nodes-rollout` procedures were used to perform the reboots

## 3. Update managed host Slingshot NIC firmware

If new Slingshot NIC firmware was provided, refer to the "200Gbps NIC Firmware Management" section of the  _Slingshot Operations Guide for Customers_ for details on how to update NIC firmware on managed nodes.

Once this step has completed:

- Slingshot NIC firmware has been updated on managed nodes

## 4. Execute the IUF `post-install-check` stage

1. Refer to the "Install and Upgrade Framework" section of each individual product's installation documentation to determine if any special actions need to be performed outside of IUF for the `post-install-check` stage.

1. Invoke `iuf run` with `-r` to execute the [`post-install-check`](../stages/post_install_check.md) stage.

    (`ncn-m001#`) Execute the `post-install-check` stage.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r post-install-check
    ```

Once this step has completed:

- Per-stage product hooks have executed for the `post-install-check` stage to verify product software is executing as expected

## 5. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the IUF [Initial install](initial_install.md) workflow to continue the install.

- If performing an upgrade that includes upgrading CSM, return to the IUF [Upgrade](upgrade.md) workflow to continue the upgrade.
