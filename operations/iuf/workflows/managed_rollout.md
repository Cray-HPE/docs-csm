# Managed Rollout

This section updates the software running on managed [compute][cn] and [application][an] ([UAN][uan], etc.) nodes.

1. [Update managed host firmware (FAS)](#1-update-managed-host-firmware-fas)
1. [Execute the IUF `managed-nodes-rollout` stage](#2-execute-the-iuf-managed-nodes-rollout-stage)
    1. [LNet router nodes and gateway nodes](#21-lnet-router-nodes-and-gateway-nodes)
    1. [Compute nodes](#22-compute-nodes)
        1. [Preparation](#221-preparation)
        1. [Reboot compute nodes](#222-reboot-compute-nodes)
            - [Reboot compute nodes with PBS](#reboot-compute-nodes-with-pbs)
            - [Reboot compute nodes with Slurm](#reboot-compute-nodes-with-slurm)
        1. [Compute reboot complete](#223-compute-reboot-complete)
    1. [Application nodes](#23-application-nodes)
1. [Update managed host Slingshot NIC firmware](#3-update-managed-host-slingshot-nic-firmware)
1. [Execute the IUF `post-install-check` stage](#4-execute-the-iuf-post-install-check-stage)
1. [Next steps](#5-next-steps)

## 1. Update managed host firmware (FAS)

Refer to [Update Firmware with FAS](../../firmware/Update_Firmware_with_FAS.md) for details on how to upgrade the
firmware on managed nodes using [FAS][fas].

Once this step has completed:

- Host firmware has been updated on managed nodes.

## 2. Execute the IUF `managed-nodes-rollout` stage

This section describes how to update software on managed nodes. It describes how to test a new [IMS][ims] image
and [CFS][cfs] [configuration][cfs-configs] on a single "canary node" first before rolling it out to the other
managed nodes. Modify the procedure as necessary to accommodate site preferences for rebooting managed nodes.
If the system has heterogeneous nodes, it may be desirable to repeat this process with multiple canary nodes,
one for each distinct node configuration. The [IMS][ims] images, [CFS][cfs] [configurations][cfs-configs], and
[BOS][bos] [session templates][bos-templates] used are created by the `prepare-images` stage; see the
[`prepare-images` Artifacts created](../stages/prepare_images.md#artifacts-created) documentation for details on
how to query the [IMS][ims] images and [CFS][cfs] [configurations][cfs-configs].

**NOTE** Additional arguments are available to control the behavior of the `managed-nodes-rollout` stage. See
the [`managed-nodes-rollout` stage documentation][managed-nodes-rollout] for details and adjust the
examples below if necessary.

### 2.1 LNet router nodes and gateway nodes

LNet router nodes or gateway nodes should be upgraded before rebooting compute nodes to new [IMS][ims] images and
[CFS][cfs] [configurations][cfs-configs]. Because LNet routers and gateway nodes are examples of [application nodes][an],
the instructions in this section are the same as in [2.3 Application nodes](#23-application-nodes).

Because LNet router nodes and gateway nodes are not managed by workload managers, the [IUF][iuf]
`managed-nodes-rollout` stage cannot reboot them in a controlled manner via the `-mrs stage` argument. The
[IUF][iuf] `managed-nodes-rollout` stage can reboot LNet router and gateway nodes using the `-mrs reboot` argument;
however, this is not recommended, because an immediate reboot of the nodes is likely to be disruptive to users and
overall system health. Administrators should determine the best approach for rebooting LNet router and gateway nodes
outside of [IUF][iuf] that aligns with site preferences.

Once this step has completed:

- Managed LNet router and gateway nodes (if any) have been rebooted to the [IMS][ims] images and [CFS][cfs]
  [configurations][cfs-configs] created in previous steps of this workflow.
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage if [IUF][iuf]
  `managed-nodes-rollout` procedures were used to perform the reboots.

### 2.2 Compute nodes

#### 2.2.1 Preparation

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special
   actions that need to be performed outside of [IUF][iuf] for a stage. The "IUF Stage Documentation Per Product"
   section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table
   that summarizes which product documents contain information or actions for the `managed-nodes-rollout` stage. Refer
   to that table and any corresponding product documents before continuing to the next step.

1. Before booting computes, consider if [SMA][sma] `OpenSearch` needs to be tuned.
   Refer to the "Configure `OpenSearch`" section in the _HPE Cray EX System Monitoring Application Administration Guide_
   for instructions on tuning `OpenSearch`.

1. Invoke `iuf run` with `-r` to execute the [`managed-nodes-rollout`][managed-nodes-rollout] stage on a
   single node to ensure the node reboots successfully with the desired [IMS][ims] image and [CFS][cfs]
   [configuration][cfs-configs]. This node is referred to as the "canary node" in the remainder of this section. Use
   `--limit-managed-rollout` to target the canary node only and use `-mrs reboot` to reboot the canary node immediately.

   (`ncn-m001#`) Execute the `managed-nodes-rollout` stage with a single [xname][xname], rebooting the canary node
   immediately. Replace the example value of `${XNAME}` with the [xname][xname] of the canary node.

   ```bash
   XNAME=x3000c0s29b1n0
   iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r managed-nodes-rollout --limit-managed-rollout "${XNAME}" -mrs reboot
   ```

1. Verify that the canary node booted successfully with the desired [IMS][ims] image and [CFS][cfs] [configuration][cfs-configs].

#### 2.2.2 Reboot compute nodes

If PBS is the workload manager, then proceed to [Reboot compute nodes with PBS](#reboot-compute-nodes-with-pbs).
If Slurm is the workload manager, then proceed to [Reboot compute nodes with Slurm](#reboot-compute-nodes-with-slurm).

##### Reboot compute nodes with PBS

1. Create a maintenance reservation in PBS. For more information on maintenance reservations, see the
   [_PBS Professional Administrator's Guide_](https://community.altair.com/community?id=altair_product_documentation&spa=1&filter=language%3Denglish%5Eproduct%3D20069018db0348102af07608f4961995%5Eguide_type%3DAdministration&p=1&d=asc).

1. (`ncn-m001#`) After the reservation has started, execute the `managed-nodes-rollout` stage with the `-mrs reboot`
   option to immediately reboot all compute nodes.

   ```bash
   iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r managed-nodes-rollout -mrs reboot
   ```

1. Proceed to [2.2.3 Compute reboot complete](#223-compute-reboot-complete).

##### Reboot compute nodes with Slurm

1. Configure Slurm to [stage data][bos-stage] in [BOS][bos].

   Follow the instructions in the section
   [Using staged sessions with Slurm](../../boot_orchestration/Rolling_Upgrades.md#using-staged-sessions-with-slurm)
   of the [Rolling Upgrades using BOS](../../boot_orchestration/Rolling_Upgrades.md) documentation. These instructions
   describe two parameters that must be set in the `slurm.conf` file. Return to these instructions after setting them.

1. (`ncn-m001#`) Execute the `managed-nodes-rollout` stage.

   This will not reboot the nodes immediately; instead, it will [stage data][bos-stage] to [BOS][bos] and allow the
   workload manager to reboot the nodes when it is ready to do so.

   If an immediate reboot of [compute nodes][cn] is desired instead, add `-mrs reboot` to the `iuf run` command.
   **NOTE:** If the `-mrs reboot` option is used with Slurm, then skip the remaining steps in this section and proceed
   directly to [2.2.3 Compute reboot complete](#223-compute-reboot-complete).

   ```bash
   iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r managed-nodes-rollout
   ```

1. List all of the compute nodes in the system by their [node IDs (NIDs)][nid].

   > **NOTE:** If the `-mrs reboot` option was used with Slurm in the previous step, then skip the remaining steps in
   > this section and proceed directly to [2.2.3 Compute reboot complete](#223-compute-reboot-complete).

   1. (`ncn-m001#`) Enter the [SAT][sat] container.

      ```bash
      sat bash
      ```

   1. (`sat-container#`) Fetch the [compute][cn] list:

      ```bash
      sat status --fields xname --filter role=compute --no-headings --no-borders | xargs sat xname2nid
      ```

      Example output:

      ```text
      nid[000001-000004]
      ```

   1. (`sat-container#`) Exit the SAT container.

      ```bash
      exit
      ```

1. Tell Slurm to reboot the [compute nodes][cn].

    This only works for compute nodes, and they must be specified explicitly.
    Use the [compute][cn] list output from the previous step as the last argument.

    (`compute#`) A sample reboot command to reboot [NIDs][nid] 1 through 4.

    ```bash
    scontrol reboot nextstate=Resume Reason="IUF Managed Nodes Rollout" nid[000001-000004]
    ```

1. Proceed to [2.2.3 Compute reboot complete](#223-compute-reboot-complete).

#### 2.2.3 Compute reboot complete

Once this step has completed:

- Managed [compute nodes][cn] have been rebooted to the [IMS][ims] images and [CFS][cfs]
 [configurations][cfs-configs] created in previous steps of this workflow.
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage.

### 2.3 Application nodes

**NOTE** If LNet router or gateway nodes were upgraded in
the [2.1 LNet router nodes and gateway nodes](#21-lnet-router-nodes-and-gateway-nodes) section, there is no need to
upgrade them again in this section. Follow the instructions in this section to upgrade any remaining
[application nodes][an] ([UANs][uan], etc.) that have not been upgraded yet.

Because [application nodes][an] are not managed by workload managers, the [IUF][iuf] `managed-nodes-rollout` stage
cannot reboot them in a controlled manner via the `-mrs stage` argument. The [IUF][iuf] `managed-nodes-rollout` stage
can reboot [application nodes][an] using the `-mrs reboot` argument; however, this is not recommended, because an
immediate reboot of the nodes is likely to be disruptive to users and overall system health. Administrators should
determine the best approach for rebooting [application nodes][an] outside of [IUF][iuf] that aligns with site preferences.

Once this step has completed:

- Managed [application nodes][an] ([UAN][uan], etc.) have been rebooted to the [IMS][ims] images and [CFS][cfs]
  [configurations][cfs-configs] created in previous steps of this workflow.
- Per-stage product hooks have executed for the `managed-nodes-rollout` stage if [IUF][iuf] `managed-nodes-rollout`
  procedures were used to perform the reboots.

## 3. Update managed host Slingshot NIC firmware

If new [Slingshot][slingshot] NIC firmware was provided, refer to the "200Gbps NIC Firmware Management" section of the
_HPE Slingshot Operations Guide_ for details on how to update NIC firmware on managed nodes.

Once this step has completed:

- Slingshot NIC firmware has been updated on managed nodes.

## 4. Execute the IUF `post-install-check` stage

1. The "Install and Upgrade Framework" section of each individual product's installation document may contain special
   actions that need to be performed outside of [IUF][iuf] for a stage. The "IUF Stage Documentation Per Product"
   section of the _HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_ provides a table
   that summarizes which product documents contain information or actions for the `post-install-check` stage. Refer to
   that table and any corresponding product documents before continuing to the next step.

1. Invoke `iuf run` with `-r` to execute the [`post-install-check`](../stages/post_install_check.md) stage.

   (`ncn-m001#`) Execute the `post-install-check` stage.

    ```bash
    iuf -a "${ACTIVITY_NAME}" -m "${MEDIA_DIR}" run -r post-install-check
    ```

Once this step has completed:

- Per-stage product hooks have executed for the `post-install-check` stage to verify product software is executing as
  expected.

## 5. Next steps

- If performing an initial install or an upgrade of non-CSM products only, return to the
  [Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md)
  workflow to continue the install or upgrade.

- If performing an upgrade that includes upgrading CSM with [IUF][iuf], return to the
  [Upgrade CSM and additional products with IUF](upgrade_csm_and_additional_products_with_iuf.md)
  workflow to continue the upgrade.

<!--- Define the reference-style Markdown links used to make the page easier to edit -->

[bos-stage]: ../../boot_orchestration/Stage_Changes_with_BOS.md
[bos-templates]: ../../boot_orchestration/Session_Templates.md
[cfs-configs]: ../../configuration_management/CFS_Configurations.md
[managed-nodes-rollout]: ../stages/managed_nodes_rollout.md

<!-- markdownlint-disable MD053 -->
<!---
    For references that are likely to appear on a lot of pages (glossary references, for example),
    we allow definitions for entries that are not used on the page, as a convenience.
-->

<!-- non-glossary common links -->

[config-cli]: ../../configure_cray_cli.md
[check-latest-docs]: ../../../update_product_stream/README.md#check-for-latest-documentation

<!-- glossary entries -->

[aee]: ../../../glossary.md#ansible-execution-environment-aee
[an]: ../../../glossary.md#application-node-an
[ara]: ../../../glossary.md#ara-records-ansible-ara
[bmc]: ../../../glossary.md#baseboard-management-controller-bmc
[bos]: ../../../glossary.md#boot-orchestration-service-bos
[bss]: ../../../glossary.md#boot-script-service-bss
[can]: ../../../glossary.md#customer-access-network-can
[canu]: ../../../glossary.md#csm-automatic-network-utility-canu
[capmc]: ../../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc
[cdu]: ../../../glossary.md#coolant-distribution-unit-cdu
[cec]: ../../../glossary.md#cabinet-environmental-controller-cec
[cfs]: ../../../glossary.md#configuration-framework-service-cfs
[chn]: ../../../glossary.md#customer-high-speed-network-chn
[cli]: ../../../glossary.md#cray-cli-cray
[cn]: ../../../glossary.md#compute-node-cn
[csi]: ../../../glossary.md#cray-site-init-csi
[fas]: ../../../glossary.md#firmware-action-service-fas
[hbtd]: ../../../glossary.md#heartbeat-tracker-daemon-hbtd
[hmn]: ../../../glossary.md#hardware-management-network-hmn
[hsm]: ../../../glossary.md#hardware-state-manager-hsm
[hsn]: ../../../glossary.md#high-speed-network-hsn
[ims]: ../../../glossary.md#image-management-service-ims
[iuf]: ../../../glossary.md#install-and-upgrade-framework-iuf
[meds]: ../../../glossary.md#mountain-endpoint-discovery-service-meds
[mgmt-ncns]: ../../../glossary.md#management-nodes
[mountain]: ../../../glossary.md#mountain-cabinet
[ncn]: ../../../glossary.md#non-compute-node-ncn
[nid]: ../../../glossary.md#node-id-nid
[nmn]: ../../../glossary.md#node-management-network-nmn
[pcs]: ../../../glossary.md#power-control-service-pcs
[pdu]: ../../../glossary.md#power-distribution-unit-pdu
[pit]: ../../../glossary.md#pre-install-toolkit-pit
[river]: ../../../glossary.md#river-cabinet
[rts]: ../../../glossary.md#redfish-translation-service-rts
[s3]: ../../../glossary.md#simple-storage-service-s3
[sat]: ../../../glossary.md#system-admin-toolkit-sat
[scsd]: ../../../glossary.md#system-configuration-service-scsd
[shcd]: ../../../glossary.md#shasta-cabling-diagram-shcd
[slingshot]: ../../../glossary.md#slingshot
[sls]: ../../../glossary.md#system-layout-service-sls
[sma]: ../../../glossary.md#system-monitoring-application-sma
[smd]: ../../../glossary.md#hardware-state-manager-smd
[tapms]: ../../../glossary.md#tenant-and-partition-management-system-tapms
[uan]: ../../../glossary.md#user-access-node-uan
[uss]: ../../../glossary.md#user-services-software-uss
[vcs]: ../../../glossary.md#version-control-service-vcs
[vnid]: ../../../glossary.md#virtual-network-identifier-daemon-vnid
[xname]: ../../../glossary.md#xname

<!-- markdownlint-restore -->
