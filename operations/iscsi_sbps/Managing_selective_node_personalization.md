# Managing Selective Node Personalization

* [Overview](#overview)
* [Group commands](#group-commands)
    * [Creating the group](#creating-the-group)
    * [Adding a worker to the group](#adding-a-worker-to-the-group)
    * [Listing group members](#listing-group-members)
    * [Removing a worker from the group](#removing-a-worker-from-the-group)
    * [Deleting the group](#deleting-the-group)
* [Procedures](#procedures)
    * [CSM install](#csm-install)
    * [CSM upgrade from 1.6 to 1.7](#csm-upgrade-from-16-to-17)
    * [Adding or removing worker NCN](#adding-or-removing-worker-ncn)
        * [Adding worker NCN when `iscsi_sbps` group does not exist](#adding-worker-ncn-when-iscsi_sbps-group-does-not-exist)
        * [Adding worker NCN when `iscsi_sbps` group exists](#adding-worker-ncn-when-iscsi_sbps-group-exists)
        * [Removing worker NCN when `iscsi_sbps` group does not exist](#removing-worker-ncn-when-iscsi_sbps-group-does-not-exist)
        * [Removing worker NCN when `iscsi_sbps` group exists](#removing-worker-ncn-when-iscsi_sbps-group-exists)
    * [After initial CSM 1.7 install or upgrade](#after-initial-csm-17-install-or-upgrade)
* [Manual DNS records update](#manual-dns-records-update)

## Overview

The selective iSCSI worker node personalization feature allows administrators to specify which worker NCNs are enabled as
iSCSI targets. The mechanism by which an administrator specifies this is the `iscsi_worker` [component group](../hardware_state_manager/Component_Groups_and_Partitions.md#groups) in the [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm).
The existence of this group on the system means that selective iSCSI worker node personalization is enabled.
If the group does not exist, then the feature is disabled, and all worker nodes will be enabled as iSCSI targets.
While it is technically possible to create this group and leave it empty, this will mean that no worker nodes will be
enabled as iSCSI targets, which in turn will mean that no managed nodes will be able to boot. Therefore CSM generally
treats it as an error if the HSM group exists but it contains no worker nodes.

The [Group commands](#group-commands) section goes over the commands used to create, remove, or modify the group.
The [Procedures](#procedures) section discusses the different contexts in which this may be done, and any additional
steps that must be performed to effectuate the changes.

## Group commands

This section contains example commands for managing selective worker node personalization for iSCSI SBPS.

For more in-depth information on managing HSM groups in general, see
[Manage Component Groups](../hardware_state_manager/Manage_Component_Groups.md).

* [Creating the group](#creating-the-group)
* [Adding a worker to the group](#adding-a-worker-to-the-group)
* [Listing group members](#listing-group-members)
* [Removing a worker from the group](#removing-a-worker-from-the-group)
* [Deleting the group](#deleting-the-group)

### Creating the group

(`ncn-mw#`) Create the `iscsi_worker` group.

```bash
cray hsm groups create --label iscsi_worker --description "iscsi node personalization" --members-ids x3000c0s5b0n0,x3001c0s35b0n0
```

Example output:

```toml
[[results]]
URI = "/hsm/v2/groups/iscsi_worker"
```

The output does not contain the list of members in the group. If an administrator wishes to confirm that the group was created with the correct members, see [Listing group members](#listing-group-members).

### Adding a worker to the group

(`ncn-mw#`) Add one more worker node to the `iscsi_worker` group.

> Note: Each command may only add a single worker.

```bash
cray hsm groups members create --id x3000c0s18b0n0 iscsi_worker
```

Example output:

```toml
[[results]]
URI = "/hsm/v2/groups/iscsi_worker/members/x3000c0s18b0n0"
```

### Listing group members

(`ncn-mw#`) List the members of the `iscsi_worker` group.

```bash
cray hsm groups members list iscsi_worker
```

Example output:

```toml
ids = [ "x3000c0s5b0n0", "x3001c0s35b0n0", "x3000c0s18b0n0",]
```

### Removing a worker from the group

(`ncn-mw#`) Remove a worker node from the `iscsi_worker` group.

> Each command may only remove a single worker.

```bash
cray hsm groups members delete x3000c0s18b0n0 iscsi_worker
```

Example output:

```toml
code = 0
message = "deleted 1 entry"
```

### Deleting the group

(`ncn-mw#`) Delete the `iscsi_worker` group.

```bash
cray hsm groups delete iscsi_worker
```

Example output:

```toml
code = 0
message = "deleted 1 entry"
```

## Procedures

The procedures vary for enabling or disabling this feature, or modifying the set of worker nodes that are enabled as iSCSI
targets. It depends on whether this is being done during a fresh install of CSM, an upgrade from CSM 1.6 to CSM 1.7,
as part of adding or removing a worker NCN, or on an operational CSM 1.7+ system.

* [CSM install](#csm-install)
* [CSM upgrade from 1.6 to 1.7](#csm-upgrade-from-16-to-17)
* [Adding or removing worker NCN](#adding-or-removing-worker-ncn)
    * [Adding worker NCN when `iscsi_sbps` group does not exist](#adding-worker-ncn-when-iscsi_sbps-group-does-not-exist)
    * [Adding worker NCN when `iscsi_sbps` group exists](#adding-worker-ncn-when-iscsi_sbps-group-exists)
    * [Removing worker NCN when `iscsi_sbps` group does not exist](#removing-worker-ncn-when-iscsi_sbps-group-does-not-exist)
    * [Removing worker NCN when `iscsi_sbps` group exists](#removing-worker-ncn-when-iscsi_sbps-group-exists)
* [After initial CSM 1.7 install or upgrade](#after-initial-csm-17-install-or-upgrade)

### CSM install

During a CSM install, if the administrator wants to enable this feature, they should
[create the `iscsi_worker` HSM group](#creating-the-group) as part of
[Configure Administrative Access](../../install/configure_administrative_access.md)

The feature will take effect when
[Management Node Personalization](../configuration_management/Management_Node_Personalization.md)
runs on the NCNs, after [SAT Bootprep](../system_admin_toolkit/usage/SAT_Bootprep.md) has run.

If the group is not created at this time, and an administrator wishes to enable this feature post-install, additional
manual steps are required. This is also true if an administrator creates the group during the install, but later wants
to disable iSCSI on some of the workers where it had previously been enabled.

For details, see [After initial CSM 1.7 install or upgrade](#after-initial-csm-17-install-or-upgrade).

### CSM upgrade from 1.6 to 1.7

During an upgrade from CSM 1.6 to CSM 1.7, if the administrator does not wish to enable this feature, no special steps need to be taken. If the administrator does wish to enable this feature, then the following steps need to be followed at the
beginning of [2. Execute the IUF `management-nodes-rollout` stage](../iuf/workflows/management_rollout.md#2-execute-the-iuf-management-nodes-rollout-stage).

1. Create the `iscsi_worker` HSM group.

   See [Creating the group](#creating-the-group).

1. Perform manual DNS update.

   This step is required any time a worker node is changed from being enabled for iSCSI to being disabled for iSCSI.
   In CSM 1.6, all worker nodes were enabled for iSCSI. Therefore, this step will always be required when first enabling
   this feature on a system that previously was running CSM 1.6.

   See [Manual DNS records update](#manual-dns-records-update).

### Adding or removing worker NCN

When [adding or removing a worker NCN](../node_management/Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md),
additional steps may be required. **Before** performing the add or remove procedure for the worker NCN,
read the section that applies to the current operation and whether or not the `iscsi_sbps` group currently exists:

> If unsure whether or not the group exists, try [Listing the group members](#listing-group-members).
> If it succeeds, the group exists (and its member list will be shown). If the group does not exist,
> the command will fail with an error that it cannot find the group.

* [Adding worker NCN when `iscsi_sbps` group does not exist](#adding-worker-ncn-when-iscsi_sbps-group-does-not-exist)
* [Adding worker NCN when `iscsi_sbps` group exists](#adding-worker-ncn-when-iscsi_sbps-group-exists)
* [Removing worker NCN when `iscsi_sbps` group does not exist](#removing-worker-ncn-when-iscsi_sbps-group-does-not-exist)
* [Removing worker NCN when `iscsi_sbps` group exists](#removing-worker-ncn-when-iscsi_sbps-group-exists)

#### Adding worker NCN when `iscsi_sbps` group does not exist

This means that all current worker NCNs are enabled as iSCSI targets.
If the new worker NCN being added should also be enabled as an iSCSI target, then no additional steps are required.
Skip the rest of this document and perform the procedure to add the worker NCN to the system.

Otherwise (if the new worker NCN should NOT be configured as an iSCSI target), perform the following steps **before**
following the add NCN procedure:

1. (`ncn-mw#`) Get the xnames of all of the worker NCNs currently in the system.

    ```bash
    WORKER_XNAMES=$(cray hsm state components list --role Management --subrole Worker --type Node --format json \
                    | jq -r .Components[].ID | sort -u | tr '\n' , | sed 's/,$//')
    echo ${WORKER_XNAMES}
    ```

    Example output:

    ```text
    x3000c0s7b0n0,x3000c0s9b0n0,x3000c0s38b0n0,x3000c0s11b0n0
    ```

1. Create the `iscsi_sbps` group.

    The `iscsi_sbps` group needs to be created and contain the xnames of all of the worker NCNs except the one being added
    (the same list obtained in the previous step). See [Creating the group](#creating-the-group).

1. Skip the rest of this document and perform the procedure to add the worker NCN to the system. When the new worker performs
   [Management Node Personalization](../configuration_management/Management_Node_Personalization.md), it will not be
   enabled as an iSCSI target.

#### Adding worker NCN when `iscsi_sbps` group exists

If the new worker NCN being added should not be configured as an iSCSI target, then no additional steps are required.
Skip the rest of this document and perform the procedure to add the worker NCN to the system.

Otherwise (if the new worker NCN should be configured as an iSCSI target), perform the following steps:

1. (`ncn-mw#`) Get the xnames of all of the worker NCNs currently in the system.

    ```bash
    echo $(cray hsm state components list --role Management --subrole Worker --type Node --format json \
           | jq -r .Components[].ID | sort -u)
    ```

    Example output:

    ```text
    x3000c0s11b0n0 x3000c0s38b0n0 x3000c0s7b0n0 x3000c0s9b0n0
    ```

1. Proceed with the add worker NCN procedure until the xname for the new worker NCN exists in HSM.

    This can be checked by running the same command as in the previous step, and comparing the output.
    As soon as a new xname shows up in the list, that is the xname of the worker being added.

1. Add the xname of the new worker node to the `iscsi_sbps` group.

    See [Adding a worker to the group](#adding-a-worker-to-the-group).

1. Skip the rest of this document and perform the rest of the procedure to add the worker NCN to the system. When new worker performs
   [Management Node Personalization](../configuration_management/Management_Node_Personalization.md), it will be
   enabled as an iSCSI target.

#### Removing worker NCN when `iscsi_sbps` group does not exist

This means that all worker NCNs are configured as iSCSI targets.
In this scenario, the remove NCN procedure can be performed as usual. After it is done, the
administrator must manually update DNS records. See [Manual DNS records update](#manual-dns-records-update).

#### Removing worker NCN when `iscsi_sbps` group exists

1. Check if the worker being removed is not a member of the `iscsi_sbps` group.

    See [Listing group members](#listing-group-members) for how to see the current members of the group.

1. If the worker being removed is not a member of the group, then skip the rest of this document and perform the procedure to
   remove the worker NCN from the system. No additional steps are required in this case. Otherwise, if the worker being removed
   is a member of the group, then proceed with the remaining steps in this section.

1. Remove the worker being removed from the group.

    See [Removing a worker from the group](#removing-a-worker-from-the-group).

1. Instruct the [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) to update
   the iSCSI configuration.

   > The latest CSM documentation RPM must be installed on the node where this step is being performed.
   > See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

   (`ncn-mw#`) The `refresh_worker_iscsi_config.py` script is provided to modify the CFS state of the worker NCNs to
   force them to re-run the iSCSI configuration layer. It is run without arguments.

   ```bash
   /usr/share/doc/csm/scripts/operations/configuration/refresh_worker_iscsi_config.py
   ```

1. Manually update the DNS records.

    See [Manual DNS records update](#manual-dns-records-update).

1. Skip the rest of this document and perform the procedure to remove the worker NCN from the system.

### After initial CSM 1.7 install or upgrade

**IMPORTANT**: If this is being done in the context of adding or removing a worker NCN, see
[Adding or removing worker NCN](#adding-or-removing-worker-ncn) instead.

During normal system operation, this feature can be enabled or disabled, or the set of worker nodes being enabled
for iSCSI can be changed. To do this, use the following procedure:

1. Create, modify, or delete the `iscsi_worker` HSM group.

    * If this feature is currently disabled (meaning that all worker nodes are enabled as iSCSI targets), then it can be
      enabled by creating the HSM group and specifying which worker nodes should be enabled for iSCSI.
      See [Creating the group](#creating-the-group).
    * If this feature is currently enabled (meaning that the `iscsi_worker` HSM group exists),
      then there are two options:
        * The feature can be disabled (meaning that all worker nodes will be enabled as iSCSI targets) by deleting
          the group. See [Deleting the group](#deleting-the-group).
        * The set of worker NCNs being enabled for iSCSI can be modified by changing the membership of the group.
          This can be done by adding workers to it, removing workers from it, or a combination of both.
          See [Adding a worker to the group](#adding-a-worker-to-the-group) and
          [Removing a worker from the group](#removing-a-worker-from-the-group).

1. Instruct the [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs) to update
   the iSCSI configuration.

   > The latest CSM documentation RPM must be installed on the node where this step is being performed.
   > See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

   (`ncn-mw#`) The `refresh_worker_iscsi_config.py` script is provided to modify the CFS state of the worker NCNs to
   force them to re-run the iSCSI configuration layer. It is run without arguments.

   ```bash
   /usr/share/doc/csm/scripts/operations/configuration/refresh_worker_iscsi_config.py
   ```

   Post personalization verification [Node Personalization Verification](Node_Personalization_Verification.md)is optional if the above script is run.

1. Manually update DNS records, if needed.

    If the changes made in the first step result in a worker being disabled as an iSCSI target when previously
    it had been enabled as an iSCSI target, then an additional manual procedure is required.
    See [Manual DNS records update](#manual-dns-records-update).

## Manual DNS records update

One of the things that the iSCSI Ansible playbook does is to add DNS entries for the workers that are enabled for iSCSI.
However, this playbook does not have logic to remove these entries, in the case where a worker had previously been enabled for iSCSI but now is not. In this case, the administrator must manually remove these entries.

These entries are added by the `csm.sbps.dns_srv_records` Ansible role in the `csm-config-management` repository in the [Version Control Service (VCS)](../../glossary.md#version-control-service-vcs).
See that role to determine which entries must be manually removed.
