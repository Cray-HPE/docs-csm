# Troubleshoot Nodes Failing to Upgrade in a CRUS Session

> **`NOTE`** CRUS was deprecated in CSM 1.2.0. It will be removed in a future CSM release and replaced with BOS V2, which will provide similar functionality.
> See the following links for more information:
>
> - [Rolling Upgrades with BOS V2](../boot_orchestration/Rolling_Upgrades.md)
> - [Deprecated features](../../introduction/differences.md#deprecated-features)

Troubleshoot compute nodes failing to upgrade during a Compute Rolling Upgrade Service \(CRUS\) session and rerun the session on the failed nodes.

When nodes are marked as failed they are added to the failed node group associated with the upgrade session, and the nodes are marked as down in the workload manager \(WLM\).
If the WLM supports some kind of reason string, that string contains the cause of the down status.

Complete a CRUS session that did not successfully upgrade all of the intended compute nodes.

## Prerequisites

- A CRUS upgrade session has completed with a group of nodes that failed to upgrade.
- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray Command Line Interface](../configure_cray_cli.md).

## Procedure

- A CRUS upgrade session has completed with a group of nodes that failed to upgrade.
- The Cray command line interface \(CLI\) tool is initialized and configured on the system.

1. Determine which nodes failed the upgrade by listing the contents of the Hardware State Manager \(HSM\) group that was set up for failed nodes.

    ```bash
    cray hsm groups describe FAILED_NODES_GROUP
    ```

    Example output:

    ```toml
    label = "failed-nodes"
    description = ""

    [members]
    ids = [ "x0c0s28b0n0",]
    ```

1. Determine the cause of the failed nodes and fix it.

    Failed nodes result from the following:

    - Failure of the BOS upgrade session for a given step of the upgrade causes all of the nodes in that step to be marked as failed.
    - Failure of any given node in a step to reach a ready state in the workload manager within 10 minutes of detecting that the BOS boot session has completed causes that node
      to be marked as failed.
    - Deletion of a CRUS session while the current step is at or beyond the `Booting` stage causes all of the nodes in that step that have not reached a ready state in the
      workload manager to be marked as failed.

1. Create a new CRUS session on the failed nodes.

    1. Create a new failed node group with a different name.

        This group should be empty.

        ```bash
        cray hsm groups create --label NEW_FAILED_NODES_GROUP --description 'Failed Node Group for my Compute Node upgrade'
        ```

    1. Create a new CRUS session.

        Use the label of the failed node group from the original upgrade session as the starting label, and use the new failed node group as the failed label.
        The rest of the parameters need to be the same ones that were used in the original upgrade.

        ```bash
        cray crus session create \
            --starting-label OLD_FAILED_NODES_GROUP \
            --upgrading-label node-group \
            --failed-label NEW_FAILED_NODES_GROUP \
            --upgrade-step-size 50 \
            --workload-manager-type slurm \
            --upgrade-template-id boot-template
        ```

        Example output:

        ```toml
        api_version = "1.0.0"
        completed = false
        failed_label = "NEW_FAILED_NODES_GROUP"
        kind = "ComputeUpgradeSession"
        messages = []
        starting_label = "OLD_FAILED_NODES_GROUP"
        state = "UPDATING"
        upgrade_id = "135f9667-6d33-45d4-87c8-9b09c203174e"
        upgrade_step_size = 50
        upgrade_template_id = "boot-template"
        upgrading_label = "node-group"
        workload_manager_type = "slurm"
        ```
