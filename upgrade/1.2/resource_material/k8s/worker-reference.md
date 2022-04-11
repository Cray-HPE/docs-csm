# Worker-Specific Manual Steps

1. Determine if the worker being rebuilt is running a `cray-cps-cm-pm` pod, by running the `cray cps deployment list`
   command below. If so, there is a final step to redeploy this pod once the worker is rebuilt. In the example below,
   nodes `ncn-w001`, `ncn-w002`, and `ncn-w003` have the pod.

   > NOTE: If the command below does not return any pod names, proceed to step 2.

   > NOTE: A 404 error is expected if the COS product is not installed on the system. In this case, proceed to step 2.

   > NOTE: If the `cray` command is not initialized, see [Initialize the CLI Configuration](../../../../operations/configure_cray_cli.md)

    ```bash
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

   If the node being rebuilt is in the output from the `cray cps deployment list` command above, then the `cray cps deployment update` command should be run **after** the node has been upgraded and is back online.

   > Do not run this command now. It is part of the manual instructions for upgrading a worker node. This example uses `ncn-w002`.

   ```bash
   ncn# cray cps deployment update --nodes "ncn-w002"
   ```

2. Confirm the CFS `configurationStatus` for **all** worker nodes before shutting down this worker node. If the state is `pending`,
   the administrator may want to tail the logs of the CFS pod running on that node to watch the job finish
   before rebooting this node. If the state is `failed` for this node, then you will know that the failed CFS job state
   preceded this worker rebuild, and that can be addressed independent of rebuilding this worker.

   This example uses `ncn-w002`.

   ```bash
   ncn# export NODE=ncn-w002
   ncn# export XNAME=$(ssh $NODE cat /etc/cray/xname)
   ncn# cray cfs components describe $XNAME --format json
   {
     "configurationStatus": "configured",
     "desiredConfig": "ncn-personalization-full",
     "enabled": true,
     "errorCount": 0,
     "id": "x3000c0s7b0n0",
     "retryPolicy": 3,
   ```

