## Troubleshoot a Failed CRUS Session Because of Unmet Conditions

If a CRUS session has any unmet conditions, adding or fixing them will cause the session to continue from wherever it got stuck. Updating other parts of the system to meet the required conditions of a CRUS session will unblock the upgrade session.

The following are examples of unmet conditions:

-   Undefined groups in the Hardware State Manager \(HSM\).
-   No predefined Boot Orchestration Service \(BOS\) session template exists that describes the desired states of the nodes being upgraded.


### Prerequisites

-   A Compute Rolling Upgrade Service \(CRUS\) session was run and failed to complete.
-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Procedure

1.  View the details for the CRUS session that failed.

    ```bash
    ncn# cray crus session describe CRUS_UPGRADE_ID
    api_version = "1.0.0"
    completed = false
    failed_label = "failed-node-group"
    kind = "ComputeUpgradeSession"
    messages = [ "Processing step 0 in stage STARTING failed - failed to obtain Node Group named 'failed-node-group' - {"type":"about:blank","title":"Not Found","detail":"No such group: failed-node-group","status":404}\n[404]",]
    starting_label = "slurm-nodes"
    state = "UPDATING"
    upgrade_id = "2c7fdce6-0047-4421-9676-4301d411d14e"
    upgrade_step_size = 50
    upgrade_template_id = "dummy-boot-template"
    upgrading_label = "dummy-node-group"
    workload_manager_type = "slurm"
    ```

    The messages value returned in the output will provide details explaining where the job failed. In this example, there is a note stating the failed node group could not be obtained. This implies that the user forgot to create the failed node group before starting the job.

2.  Create a new node group for the missing group.

    Following the example in the previous step, the failed node group needs to be created.

    ```bash
    ncn# cray hsm groups create --label failed-node-group
    [[results]]
    URI = "/hsm/v1/groups/failed-node-group"
    ```

3.  View the details for the CRUS session again to see if the job started.

    ```bash
    ncn-w001# cray crus session describe CRUS_UPGRADE_ID
    api_version = "1.0.0"
    completed = false
    failed_label = "failed-node-group"
    kind = "ComputeUpgradeSession"
    messages = [ "Processing step 0 in stage STARTING failed - failed to obtain Node Group named 'failed-node-group' - {"type":"about:blank","title":"Not Found","detail":"No such group: failed-node-group","status":404}\n[404]", "Quiesce requested in step 0: moving to QUIESCING", "All nodes quiesced in step 0: moving to QUIESCED", "Began the boot session for step 0: moving to BOOTING",]
    starting_label = "slurm-nodes"
    state = "UPDATING"
    upgrade_id = "2c7fdce6-0047-4421-9676-4301d411d14e"
    upgrade_step_size = 50
    upgrade_template_id = "dummy-boot-template"
    upgrading_label = "dummy-node-group"
    workload_manager_type = "slurm"
    ```

    The messages value states that the job has resumed now that the error has been fixed.



