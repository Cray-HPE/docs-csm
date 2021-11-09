# 7.1. Validate Worker Node

Validate the worker node rebuilt successfully.

> **NOTE:** Skip this section if a master or storage node was rebuilt.

## Procedure

1. Verify the new node is in the cluster.
   
   Run the following command from any master or worker node that is already in the cluster. It is helpful to run this command several times to watch for the newly rebuilt node to join the cluster. This should occur within 10 to 20 minutes.
   
   ```bash
   ncn-mw# kubectl get nodes
   NAME       STATUS   ROLES    AGE    VERSION
   ncn-m001   Ready    master   113m   v1.19.9
   ncn-m002   Ready    master   113m   v1.19.9
   ncn-m003   Ready    master   112m   v1.19.9
   ncn-w001   Ready    <none>   112m   v1.19.9
   ncn-w002   Ready    <none>   112m   v1.19.9
   ncn-w003   Ready    <none>   112m   v1.19.9
   ```

1. Ensure there is proper routing set up for liquid-cooled hardware.

1. Confirm /var/lib/containerd is on overlay on the node which was rebooted.
   
   Run the following command on the rebuilt node.
   
   ```bash
   ncn-w# df -h /var/lib/containerd
   Filesystem            Size  Used Avail Use% Mounted on
   containerd_overlayfs  378G  245G  133G  65% /var/lib/containerd
   ```
   
   After several minutes of the node joining the cluster, pods should be in a `Running` state for the worker node.

1. Confirm the pods are beginning to get scheduled and reach a `Running` state on the worker node.
   
   Run this command on any master or worker node. This command assumes the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites) are set.
   
   ```bash
   ncn# kubectl get po -A -o wide | grep $NODE
   ```

1. Confirm BGP is healthy.
   
   Follow the steps in the [Check BGP Status and Reset Sessions](../../network/metallb_bgp/Check_BGP_Status_and_Reset_Sessions.md#Prerequisites) to verify and fix BGP if needed.

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

1. Redeploy the `cray-cps-cm-pm` pod.
   
   This step is only required if the `cray-cps-cm-pm` pod was running on the node before it was rebuilt.
   > The Content Projection Service (CPS) is part of the COS product so if this worker node is being rebuilt before the COS product has been installed, CPS will not be installed yet.
   
   The following command can be run from any node:
   
   ```bash
   ncn# cray cps deployment update --nodes "ncn-w001,ncn-w002"
   ```

1. Collect data about the system management platform health \(can be run from a master or worker NCN\).
   
   ```bash
   ncn-mw# /opt/cray/platform-utils/ncnHealthChecks.sh
   ncn-mw# /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
   ```

1. Return to the [Rebuild NCNs](../Rebuild_NCNs.md) high-level procedure and perform the "Final Validation" steps.

