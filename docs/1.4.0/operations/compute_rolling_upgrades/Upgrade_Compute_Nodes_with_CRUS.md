# Upgrade Compute Nodes with CRUS

> **`NOTE`** CRUS was deprecated in CSM 1.2.0. It will be removed in a future CSM release and replaced with BOS V2, which will provide similar functionality.
> See the following links for more information:
>
> - [Rolling Upgrades with BOS V2](../boot_orchestration/Rolling_Upgrades.md)
> - [Deprecated features](../../introduction/differences.md#deprecated-features)

Upgrade a set of compute nodes with the Compute Rolling Upgrade Service \(CRUS\). Manage the workload management status of nodes and quiesce each node before taking the node
out of service and upgrading it. Then reboot it into the upgraded state and return it to service within the workload manager \(WLM\).

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray Command Line Interface](../configure_cray_cli.md).
- A Boot Orchestration Service \(BOS\) session template describing the desired states of the nodes being upgraded must exist.

## Procedure

This procedure can be run on any master or worker NCN.

1. Create and populate the starting node group.

    This is the group of nodes that will be upgraded.

    1. Create a starting node group \(starting label\).

        Label names are defined by the user. The names used in this procedure are only examples. The label name used in this example is `slurm-nodes`.

        ```bash
        cray hsm groups create --label slurm-nodes --description 'Starting Node Group for my Compute Node upgrade'
        ```

    1. Add members to the group.

        Add compute nodes to the group by using the component name (xname) for each node being added.

        ```bash
        cray hsm groups members create slurm-nodes --id XNAME --format toml
        ```

        Example output:

        ```toml
        [[results]]
        URI = "/hsm/v2/groups/slurm-nodes/members/x0c0s28b0n0"
        ```

1. Create a group for upgrading nodes \(upgrading label\).

    The label name used in this example is `upgrading-nodes`.

    ```bash
    cray hsm groups create --label upgrading-nodes --description 'Upgrading Node Group for my Compute Node upgrade'
    ```

    Do not add members to this group; it should be empty when the compute rolling upgrade process begins.

1. Create a group for failed nodes \(failed label\).

    The label name used in this example is `failed-nodes`.

    ```bash
    cray hsm groups create --label failed-nodes --description 'Failed Node Group for my Compute Node upgrade'
    ```

    Do not add members to this group; it should be empty when the compute rolling upgrade process begins.

1. Create an upgrade session with CRUS.

    The following example is upgrading 50 nodes per step. The `--upgrade-template-id` value should be the name of the Boot Orchestration Service \(BOS\) session template
    being used to reboot the nodes.

    ```bash
    cray crus session create \
        --starting-label slurm-nodes \
        --upgrading-label upgrading-nodes \
        --failed-label failed-nodes \
        --upgrade-step-size 50 \
        --workload-manager-type slurm \
        --upgrade-template-id=BOS_SESSION_TEMPLATE_NAME \
        --format toml
    ```

    Example output:

    ```toml
    api_version = "1.0.0"
    completed = false
    failed_label = "failed-nodes"
    kind = "ComputeUpgradeSession"
    messages = []
    starting_label = "slurm-nodes"
    state = "UPDATING"
    upgrade_id = "e0131663-dbee-47c2-aa5c-13fe9b110242"
    upgrade_step_size = 50
    upgrade_template_id = "boot-template"
    upgrading_label = "upgrading-nodes"
    workload_manager_type = "slurm"
    ```

1. Note the `upgrade_id` in the returned data of the previous command.

    ```bash
    UPGRADE_ID=e0131663-dbee-47c2-aa5c-13fe9b110242
    ```

1. Monitor the status of the upgrade session.

    The progress of the session through the upgrade process is described in the `messages` field of the session. This is a list of messages, in chronological order, containing
    information about stage transitions, step transitions, and other conditions of interest encountered by the session as it progresses. It is cleared once the session completes.

    ```bash
    cray crus session describe $UPGRADE_ID --format toml
    ```

    Example output:

    ```toml
    api_version = "1.0.0"
    completed = false
    failed_label = "failed-nodes"
    kind = "ComputeUpgradeSession"
    messages = [ "Quiesce requested in step 0: moving to QUIESCING", "All nodes quiesced in step 0: moving to QUIESCED", "Began the boot session for step 0: moving to BOOTING",]
    starting_label = "slurm-nodes"
    state = "UPDATING"
    upgrade_id = "e0131663-dbee-47c2-aa5c-13fe9b110242"
    upgrade_step_size = 50
    upgrade_template_id = "boot-template"
    upgrading_label = "upgrading-nodes"
    workload_manager_type = "slurm"
    ```

    A CRUS session goes through a number of steps \(approximately the number of nodes to be upgraded divided by the requested step size\) to complete an upgrade. Each step
    moves through the following stages, unless the boot session is interrupted by being deleted.

    1. `Starting` - Preparation for the step; CRUS initiates WLM quiescing of nodes.
    1. `Quiescing` - Waits for all WLM nodes in the step to reach a quiesced \(not busy\) state.
    1. `Quiesced` - The nodes in the step are all quiesced and CRUS initiates booting the nodes into the upgraded environment.
    1. `Booting` - Waits for the boot session to complete.
    1. `Booted` - The boot session has completed. Check the success or failure of the boot session. Mark all nodes in the step as failed if the boot session failed.
    1. `WLM Waiting` - The boot session succeeded. Wait for nodes to reach a ready state in the WLM. All nodes in the step that fail to reach a ready state within 10 minutes of
       entering this stage are marked as failed.
    1. `Cleanup` - The upgrade step has finished. Clean up resources to prepare for the next step.

    When a step moves from one stage to the next, CRUS adds a message to the `messages` field of the upgrade session to mark the progress.

1. Delete the CRUS upgrade session. (Optional)

    Once a CRUS upgrade session has completed, it can no longer be used. It can be kept for historical purposes if desired, or it can be deleted.

    ```bash
    cray crus session delete $UPGRADE_ID --format toml
    ```

    Example output:

    ```toml
    api_version = "1.0.0"
    completed = true
    failed_label = "failed-nodes"
    kind = "ComputeUpgradeSession"
    messages = [ "Upgrade Session Completed",]
    starting_label = "slurm-nodes"
    state = "DELETING"
    upgrade_id = "e0131663-dbee-47c2-aa5c-13fe9b110242"
    upgrade_step_size = 50
    upgrade_template_id = "boot-template"
    upgrading_label = "upgrading-nodes"
    workload_manager_type = "slurm"
    ```

    The session may be visible briefly after it is deleted. This allows for orderly cleanup of the session.
