# Troubleshoot a Failed CRUS Session Because of Bad Parameters

> **`NOTE`** CRUS was deprecated in CSM 1.2.0. It will be removed in a future CSM release and replaced with BOS V2, which will provide similar functionality.
> See the following links for more information:
>
> - [Rolling Upgrades with BOS V2](../boot_orchestration/Rolling_Upgrades.md)
> - [Deprecated features](../../introduction/differences.md#deprecated-features)

A CRUS session must be deleted and recreated if it does not start or complete because of parameters having incorrect values.

The following are examples of incorrect parameters:

- Choosing the wrong Boot Orchestration Service \(BOS\) session template.
- Choosing the wrong group labels.
- Improperly defined BOS session template. For example, specifying nodes in the template instead of using the label of the upgrading group.

## Prerequisites

- A Compute Rolling Upgrade Service \(CRUS\) session was run and failed to complete.
- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray Command Line Interface](../configure_cray_cli.md).

## Procedure

1. Delete the failed session.

    Deleting a CRUS session that is in progress will terminate the session and move all of the unfinished nodes into the group said up for failed nodes. The time frame for
    recognizing a delete request, cleaning up, and deleting the session is roughly a minute. A session being deleted will move to a `DELETING` status immediately upon receiving
    a delete request, which will prevent further processing of the upgrade in that session.

    ```bash
    cray crus session delete CRUS_UPGRADE_ID
    ```

    Example output:

    ```toml
    api_version = "1.0.0"
    completed = false
    failed_label = "failed-node-group"
    kind = "ComputeUpgradeSession"
    messages = [ "Processing step 0 in stage STARTING failed - failed to obtain Node Group named 'slurm-node-group' - {"type":"about:blank","title":"Not Found","detail":"No such group: slurm-node-group","status":404}\n[404]",]
    starting_label = "slurm-node-group"
    state = "DELETING"
    upgrade_id = "d388c6f5-be67-4a31-87a9-819bb4fa804c"
    upgrade_step_size = 50
    upgrade_template_id = "boot-template"
    upgrading_label = "node-group"
    workload_manager_type = "slurm"
    ```

1. Recreate the session that failed.

    Ensure that the correct parameters are used when restarting the session.

    ```bash
    cray crus session create \
        --starting-label slurm-nodes \
        --upgrading-label node-group \
        --failed-label failed-node-group \
        --upgrade-step-size 50 \
        --workload-manager-type slurm \
        --upgrade-template-id boot-template
    ```

    Example output:

    ```toml
    api_version = "1.0.0"
    completed = false
    failed_label = "failed-node-group"
    kind = "ComputeUpgradeSession"
    messages = []
    starting_label = "slurm-nodes"
    state = "UPDATING"
    upgrade_id = "135f9667-6d33-45d4-87c8-9b09c203174e"
    upgrade_step_size = 50
    upgrade_template_id = "boot-template"
    upgrading_label = "node-group"
    workload_manager_type = "slurm"
    ```
