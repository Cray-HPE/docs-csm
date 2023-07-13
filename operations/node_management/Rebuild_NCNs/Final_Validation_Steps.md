# Final Validation Steps

Use this procedure to finish validating the success of rebuilt NCNs.

## Procedure

1. Confirm what the Configuration Framework Service (CFS) `configurationStatus` is for the `desiredConfig` after rebooting the node.

   **`NOTE`** The following command will indicate if a CFS job is currently in progress for this node.

   **IMPORTANT:** The following command assumes that the variables from [the prerequisites section](Rebuild_NCNs.md#prerequisites) have been set.

   ```bash
   cray cfs components describe "${XNAME}" --format json | jq .configurationStatus
   ```

   Example output:

   ```json
   "configured"
   ```

   * If the `configurationStatus` is `pending`, wait for the job to finish before continuing. If the `configurationStatus` is `failed`, this means the failed CFS job
     `configurationStatus` should be addressed now for this node. If the `configurationStatus` is `unconfigured` and the NCN personalization procedure has not been done
     as part of an install yet, this can be ignored.

   * If `configurationStatus` is `failed`, then see
     [Troubleshoot Failed CFS Sessions](../../configuration_management/Troubleshoot_CFS_Session_Failed.md) for how to analyze the pod logs
     from `cray-cfs` in order to determine why the configuration may not have completed.

1. Collect data about the system management platform health \(can be run from a master or worker NCN\).

   ```bash
   /opt/cray/platform-utils/ncnHealthChecks.sh
   /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
   ```

## Next step

Return to the main [Rebuild NCNs](Rebuild_NCNs.md) page.
