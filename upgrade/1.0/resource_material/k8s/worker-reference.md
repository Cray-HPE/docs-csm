# Worker-Specific Manual Steps

1. Determine if the worker being rebuilt is running a `cray-cps-cm-pm` pod. If so, there is a final step to re-deploy
   this pod once the worker is rebuilt. In the example below nodes ncn-w001, ncn-w002, and ncn-w003 have the pod.

   > NOTE: If the command below does not return any pod names, proceed to step 2.

   > NOTE: A 404 error is expected if the COS product is not installed on the system. In this case, proceed to step 2.

   > NOTE: If `cray` is not initialized, please check [Initialize the CLI Configuration](https://stash.us.cray.com/projects/CSM/repos/docs-csm/browse/operations/validate_csm_health.md#uas-uai-init-cli-init)

    ```text
    ncn# cray cps deployment list --format json | jq '.[] | [.node,.podname]'
    [
      "ncn-w003",
      "cray-cps-cm-pm-9tdg5"
    ]
    [
      "ncn-w001",
      "cray-cps-cm-pm-fsd8w"
    ]
    [
      "ncn-w002",
      "cray-cps-cm-pm-sg954"
    ]
    ```

    If the node being rebuilt is one of those three, this step should be run **after** the completion of the common
   upgrade steps below.

    ```bash
    ncn# cray cps deployment update --nodes "ncn-w001,ncn-w002,ncn-w003"
    ```

2. Confirm what the CFS setting is for `configurationStatus` before shutting down the node. If the state is `pending`,
   the administrator may want to tail the logs of the CFS pod running on that node to watch the job finish
   before rebooting this node. If the state is `failed` for this node, then you will know that the failed CFS job state
   preceded this worker rebuild, and that can be addressed independent of rebuilding this worker.

   ```text
   ncn# cray cfs components describe $UPGRADE_XNAME --format json
   {
     "configurationStatus": "configured",
     "desiredConfig": "ncn-personalization-full",
     "enabled": true,
     "errorCount": 0,
     "id": "x3000c0s7b0n0",
     "retryPolicy": 3,
    ```
