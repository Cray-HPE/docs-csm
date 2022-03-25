# Upgrade Compute Nodes with CRUS

Upgrade a set of compute nodes with the Compute Rolling Upgrade Service \(CRUS\). Manage the workload management status of nodes and quiesce each node before taking the node out of service and upgrading it. Then reboot it into the upgraded state and return it to service within the workload manager \(WLM\).

### Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system.
- A Boot Orchestration Service \(BOS\) session template describing the desired states of the nodes being upgraded must exist.

### Procedure

1.  Create and populate the starting node group.

    This will be the group of nodes that will be upgraded.

    1.  Create a starting node group \(starting label\).

        Label names are defined by the user and the names used in this procedure are only examples. The label name used in this example is slurm-nodes.

        ```bash
        ncn# cray hsm groups create --label slurm-nodes \
        --description 'Starting Node Group for my Compute Node upgrade'
        ```

    2.  Add members to the group.

        Add compute nodes to the group by using the component name (xname) for each node being added.

        ```bash
        ncn# cray hsm groups members create slurm-nodes --id XNAME
        ```

        Example output:

        ```
        [[results]]
        URI = "/hsm/v2/groups/slurm-nodes/members/x0c0s28b0n0"
        ```

2.  Create a group for upgrading nodes \(upgrading label\).

    The label name used in this example is upgrading-nodes.

    ```bash
    ncn-w001# cray hsm groups create --label upgrading-nodes \
    --description 'Upgrading Node Group for my Compute Node upgrade'
    ```

    There is no need to add members to this group because it should be empty when the compute rolling upgrade process begins.

3.  Create a group for failed nodes \(failed label\).

    The label name used in this example is failed-nodes.

    ```bash
    ncn# cray hsm groups create --label failed-nodes \
    --description 'Failed Node Group for my Compute Node upgrade'
    ```

    There is no need to add members to this group because it should be empty when the compute rolling upgrade process begins.

4.  Create an upgrade session with CRUS.

    The following example is upgrading 50 nodes at a step. The `--upgrade-template-id` value should be the name of the Boot Orchestration Service \(BOS\) session template being used.

    ```bash
    ncn# cray crus session create \
    --starting-label slurm-nodes \
    --upgrading-label upgrading-nodes \
    --failed-label failed-nodes \
    --upgrade-step-size 50 \
    --workload-manager-type slurm \
    --upgrade-template-id=BOS_SESSION_TEMPLATE_NAME
    ```

    Example output:

    ```
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

    If successful, note the upgrade\_id in the returned data.

    ```bash
    ncn-w001# export UPGRADE_ID=e0131663-dbee-47c2-aa5c-13fe9b110242
    ```

5.  Monitor the status of the upgrade session.

    The progress of the session through the upgrade process is described in the messages field of the session. This is a list of messages, in chronological order, containing information about stage transitions, step transitions, and other conditions of interest encountered by the session as it progresses. It is cleared once the session completes.

    ```bash
    ncn-w001# cray crus session describe $UPGRADE_ID
    ```

    Example output:

    ```
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

    A CRUS session goes through a number of steps \(approximately the number of nodes to be upgraded divided by the requested step size\) to complete an upgrade. Each step moves through the following stages, unless the boot session is interrupted by being deleted.

    1.  Starting - Preparation for the step and CRUS initiates WLM quiescing of nodes.
    2.  Quiescing - Waits for all WLM nodes in the step to reach a quiesced \(not busy\) state.
    3.  Quiesced - The nodes in the step are all quiesced and CRUS initiates booting the nodes into the upgraded environment.
    4.  Booting - Waits for the boot session to complete.
    5.  Booted - The boot session has completed. Check the success or failure of the boot session. Mark all nodes in the step as failed if the boot session failed.
    6.  WLM Waiting - The boot session succeeded. Wait for nodes to reach a ready state in the WLM. All nodes in the step that fail to reach a ready state within 10 minutes of entering this stage are marked as failed.
    7.  Cleanup - The upgrade step has finished. Clean up resources to prepare for the next step.
    When a step moves from one stage to the next, CRUS adds a message to the messages field of the upgrade session to mark the progress.

6.  Optional: Delete the CRUS upgrade session.

    Once a CRUS upgrade session it is complete, it can no longer be used. It can be kept for historical purposes if desired, or it can be deleted.

    ```bash
    ncn-w001# cray crus session delete $UPGRADE_ID
    ```

    Example output:

    ```
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

