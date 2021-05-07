# Worker Specific Steps

1. Determine if the worker being rebuilt is running a `cray-cps-cm-pm` pod.  If so, there's a final step to re-deploy
   this pod once the worker is rebuilt. In the example below nodes ncn-w001, ncn-w002, and ncn-w003 have the pod.

   > NOTE: If the command below doesn't return any pod names, proceed to step 2.

   > NOTE: If `cray` is not intialized, please check [Initialize the CLI Configuration](https://stash.us.cray.com/projects/CSM/repos/docs-csm/browse/operations/validate_csm_health.md#uas-uai-init-cli-init)

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
   the administrator may want to tail the logs of the `cray-cps-cm-pm` pod running on that node to watch the job finish
   before rebooting this node.  If the state is `failed` for this node, then you'll know that the failed CFS job state
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

3. Ensure the nexus pod has the ability to start on any worker node by pre-pulling the `nexus-setup` image.  This command should be run from the stable node.

   ```bash
   ncn# pdsh -w ncn-w00[1-3] 'crictl pull registry.local/cray/cray-nexus-setup:0.3.2'
   ```
   > NOTE: If you get this error following errors, just ssh to each worker and make sure you have them in STABLE_NCN's *known_hosts*
   ```
   ncn-w001: Host key verification failed.
   pdsh@ncn-m001: ncn-w001: ssh exited with exit code 255
   ncn-w003: Host key verification failed.
   pdsh@ncn-m001: ncn-w003: ssh exited with exit code 255
   ncn-w002: Host key verification failed.
   pdsh@ncn-m001: ncn-w002: ssh exited with exit code 255
   ``` 

4. Gather any logs/info from pods in a `Completed` state on the worker node being updated.

   > NOTE: Pods in a `Completed` state are not moved to another worker node when the node being upgraded is drained, but rather they are deleted.  ***If the administrator would like to gather any information from pods in this state, now is the last chance to do so.***

5. Use the script provided in this repository to cordon/drain the node.  This will evacuate pods running on the node.

   ```bash
   ncn# /usr/share/doc/metal/upgrade/1.0/scripts/k8s/remove-k8s-node.sh $UPGRADE_NCN
   ```

Proceed to [Common Upgrade Steps](../common/upgrade-steps.md)
