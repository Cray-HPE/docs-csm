# Post NCN Rebuild Validation

Perform the following steps after completing the NCN rebuild procedures to ensure the nodes rebuilt successfully.

## Prerequisites

The procedures outlined in [Rebuild NCNs](../Rebuild_NCNs.md) for the node type being rebuilt have been completed.

## Procedure

1. Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig after rebooting the node.
   
   > **NOTE:** The following command will indicate if a CFS job is currently in progress for this node.
   
   > **IMPORTANT:** This command assumes the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites) have been set.

   ```bash
   ncn# cray cfs components describe $XNAME --format json
   {
     "configurationStatus": "configured",
     "desiredConfig": "ncn-personalization-full",
     "enabled": true,
     "errorCount": 0,
     "id": "x3000c0s7b0n0",
     "retryPolicy": 3,
   ```

   * If the configurationStatus is `pending`:
     
     Wait for the job to finish before continuing. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus should be addressed now for this node. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.

   * If configurationStatus is `failed`:
     
     See [Troubleshoot Ansible Play Failures in CFS Sessions](../configuration_management/Troubleshoot_Ansible_Play_Failures_in_CFS_Sessions.md) to analyze the pod logs from `cray-cfs` to determine why the configuration may not have completed.

1. Collect data about the system management platform health \(can be run from a master or worker NCN\).

   ```bash
   ncn-mw# /opt/cray/platform-utils/ncnHealthChecks.sh
   ncn-mw# /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
   ```

1. Return to the [Rebuild NCNs](../Rebuild_NCNs.md) high-level procedure.


