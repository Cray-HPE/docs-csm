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

Refer to [Update Firmware with FAS](../../firmware/Update_Firmware_with_FAS.md) for details on how to upgrade the
firmware on managed nodes.

Once this step has completed:

- Host firmware has been updated on managed nodes

## 2. Execute the IUF `managed-nodes-rollout` stage

This section describes how to update software on managed nodes. It describes how to test a new image and CFS
configuration on a single "canary node" first before rolling it out to the other managed nodes. Modify the procedure as
necessary to accommodate site preferences for rebooting managed nodes. If the system has heterogeneous nodes, it may be
desirable to repeat this process with multiple canary nodes, one for each distinct node configuration. The images, CFS
configurations, and BOS session templates used are created by the `prepare-images` stage; see
the [`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation for details on how
to query the images and CFS configurations.

**`NOTE`** Additional arguments are available to control the behavior of the `managed-nodes-rollout` stage. See
the [`managed-nodes-rollout` stage documentation](../stages/managed_nodes_rollout.md) for details and adjust the
examples below if necessary.

### 2.1 LNet router nodes and gateway nodes

LNet router nodes or gateway nodes should be upgraded before rebooting compute nodes to new images and CFS
configurations. Since LNet routers and gateway nodes are examples of application nodes, the instructions in this section
are the same as in [2.3 Application nodes](#23-application-nodes).

Since LNet router nodes and gateway nodes are not managed by workload managers, the IUF `managed-nodes-rollout` stage
cannot reboot them in a controlled manner via the `-mrs stage` argument. The IUF `managed-nodes-rollout` stage can
reboot LNet router and gateway nodes using the `-mrs reboot` argument, but an immediate reboot of the nodes is likely to
be disruptive to users and overall system health and is not recommended. Administrators should determine the best
approach for rebooting LNet router and gateway nodes outside of IUF that aligns with site preferences.

Once this step has completed:

- Managed LNet router and gateway nodes (if any) have been rebooted to the images and CFS configurations created in
  previous steps of this workflow
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage if IUF `managed-nodes-rollout` procedures
  were used to perform the reboots

### 2.2 Compute nodes

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special
   actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
   section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table
   that summarizes which product documents contain information or actions for the `managed-nodes-rollout` stage. Refer
   to that table and any corresponding product documents before continuing to the next step.

1. Before booting computes, consider if SMA `OpenSearch` needs to be tuned.
Refer to the "Configure `OpenSearch`" section in the _HPE Cray EX System Monitoring Application Administration Guide_ for instructions on tuning `OpenSearch`.

1. Invoke `iuf run` with `-r` to execute the [`managed-nodes-rollout`](../stages/managed_nodes_rollout.md) stage on a
   single node to ensure the node reboots successfully with the desired image and CFS configuration. This node is
   referred to as the "canary node" in the remainder of this section. Use `--limit-managed-rollout` to target the canary
   node only and use `-mrs reboot` to reboot the canary node immediately.

   (`ncn-m001#`) Execute the `managed-nodes-rollout` stage with a single xname, rebooting the canary node immediately.
   Replace the example value of `${XNAME}` with the xname of the canary node.

   ```bash
   XNAME=x3000c0s29b1n0
   iuf -a "${ACTIVITY_NAME}" run -r managed-nodes-rollout --limit-managed-rollout "${XNAME}" -mrs reboot
   ```

1. Verify the canary node booted successfully with the desired image and CFS configuration.

1. Invoke `iuf run` with `-r` to execute the [managed-nodes-rollout](../stages/managed_nodes_rollout.md) stage on all
   nodes. This will stage data to BOS and allow the workload manager to reboot the nodes when it is ready to do so. The
   workload manager must be configured to tell BOS to reboot nodes using this staged data.

   - If PBS is the workload manager:

     1. Create a maintenance reservation in PBS. For more information on maintenance reservations, see the
        [_PBS Professional Administrator's Guide_](https://community.altair.com/community?id=altair_product_documentation&spa=1&filter=language%3Denglish%5Eproduct%3D20069018db0348102af07608f4961995%5Eguide_type%3DAdministration&p=1&d=asc).

     1. (`ncn-m001#`) After the reservation has started, execute the `managed-nodes-rollout` stage with the `-mrs reboot` option to
        immediately reboot all compute nodes.

        ```bash
        iuf -a "${ACTIVITY_NAME}" run -r managed-nodes-rollout -mrs reboot
        ```

   - If Slurm is the workload manager:

     1. Follow the instructions in the section
        [Using staged sessions with Slurm](../../boot_orchestration/Rolling_Upgrades.md#using-staged-sessions-with-slurm)
        of the [Rolling Upgrades using BOS](../../boot_orchestration/Rolling_Upgrades.md) documentation. These instructions
        describe two parameters that must be set in the `slurm.conf` file. Return to these instructions after setting them.

     1. (`ncn-m001#`) Execute the `managed-nodes-rollout` stage. If an immediate reboot of compute nodes is desired instead,
        add `-mrs reboot` to the `iuf run` command.

        ```bash
        iuf -a "${ACTIVITY_NAME}" run -r managed-nodes-rollout
        ```

        **NOTE:** If the `-mrs reboot` option is used with Slurm, skip the following step.

     1. Tell Slurm to reboot the compute nodes. This only works for compute nodes, and they must be specified
        explicitly.

        - Use this command to list all of the compute nodes in the system using their Node Identities (NIDs). First, enter the
          SAT bash shell using `sat bash`.

          (`ncn-m001#`) Enter the sat container and fetch the compute list

          ```bash
          sat bash
          (ef637ae8a8b5) sat-container:/sat/share # sat status --fields xname --filter role=compute --no-headings --no-borders | xargs sat xname2nid
          nid[000001-000004]
          (ef637ae8a8b5) sat-container:/sat/share # exit
          logout
          ```

        - Now, tell the workload manager to reboot the compute nodes. Paste the output from the previous step as the last
          argument.

          (`compute#`) A sample reboot command to reboot NIDs 1 through 4.

          ```bash
          scontrol reboot nextstate=Resume Reason="IUF Managed Nodes Rollout" nid[000001-000004]
          ```

Once this step has completed:

- Managed compute nodes have been rebooted to the images and CFS configurations created in previous steps of this
  workflow
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage

### 2.3 Application nodes

**`NOTE`** If LNet router or gateway nodes were upgraded in
the [2.1 LNet router nodes and gateway nodes](#21-lnet-router-nodes-and-gateway-nodes) section, there is no need to
upgrade them again in this section. Follow the instructions in this section to upgrade any remaining applications (UANs,
etc.) that have not been upgraded yet.

Since application nodes are not managed by workload managers, the IUF `managed-nodes-rollout` stage cannot reboot them
in a controlled manner via the `-mrs stage` argument. The IUF `managed-nodes-rollout` stage can reboot application nodes
using the `-mrs reboot` argument, but an immediate reboot of application nodes is likely to be disruptive to users and
overall system health and is not recommended. Administrators should determine the best approach for rebooting
application nodes outside of IUF that aligns with site preferences.

Once this step has completed:

- Managed application (UAN, etc.) nodes have been rebooted to the images and CFS configurations created in previous
  steps of this workflow
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage if IUF `managed-nodes-rollout` procedures
  were used to perform the reboots

## 3. Update managed host Slingshot NIC firmware

If new Slingshot NIC firmware was provided, refer to the "200Gbps NIC Firmware Management" section of
the _HPE Slingshot Installation Guide for Bare Metal_ for details on how to update NIC firmware on managed nodes.

Once this step has completed:

- Slingshot NIC firmware has been updated on managed nodes

## 4. Execute the IUF `post-install-check` stage

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special
   actions that need to be performed outside of IUF for a stage. The "IUF Stage Documentation Per Product"
   section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table
   that summarizes which product documents contain information or actions for the `post-install-check` stage. Refer to
   that table and any corresponding product documents before continuing to the next step.

1. Invoke `iuf run` with `-r` to execute the [`post-install-check`](../stages/post_install_check.md) stage.

   (`ncn-m001#`) Execute the `post-install-check` stage.

    ```bash
    iuf -a "${ACTIVITY_NAME}" run -r post-install-check
    ```

Once this step has completed:

- Per-stage product hooks have executed for the `post-install-check` stage to verify product software is executing as
  expected

## 5. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the
  [Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md)
  workflow to continue the install or upgrade.

- If performing an upgrade that includes upgrading CSM and additional products with IUF,
  return to the [Upgrade CSM and additional products with IUF](upgrade_csm_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.
