# Worker-Specific Manual Steps

1. Determine if the worker being rebuilt is running a `cray-cps-cm-pm` pod.

   (`ncn#`) This is determined by running the `cray cps deployment list` command below. If so, there is a final step to redeploy this pod once the worker is rebuilt.
   In the example below, nodes `ncn-w001`, `ncn-w002`, and `ncn-w003` have the pod.

   > NOTES:
   >
   > * If the command below does not return any pod names, then skip this step and proceed to the next step.
   > * A 404 error is expected if the COS product is not installed on the system. In this case, then skip this step and proceed to the next step.
   > * If the `cray` command is not initialized, then see [Initialize the CLI Configuration](../../../operations/configure_cray_cli.md).

    ```bash
    cray cps deployment list --format json | jq '.[] | [.node,.podname]'
    ```

    Example output:

    ```json
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
   cray cps deployment update --nodes "ncn-w002"
   ```

1. Confirm the CFS `configurationStatus` for **all** worker nodes before shutting down this worker node.

   (`ncn#`) If the following command reports that the state is `pending`, then the administrator should tail the logs of the CFS pod running on that node
   in order to watch the job finish before rebooting this node. If the state is `failed` for this node, then this indicates that the failed CFS job state
   preceded this worker rebuild, and that it can be addressed independent of rebuilding this worker.

   This example uses `ncn-w002`.

   ```bash
   NODE=ncn-w002
   XNAME=$(ssh "${NODE}" cat /etc/cray/xname)
   cray cfs components describe "${XNAME}" --format json | jq .configurationStatus
   ```

   Example output:

   ```json
   "configured"
   ```
