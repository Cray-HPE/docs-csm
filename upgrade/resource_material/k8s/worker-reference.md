# Worker-Specific Manual Steps

1. Confirm the CFS `configuration_status` for **all** worker nodes before shutting down this worker node.

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
