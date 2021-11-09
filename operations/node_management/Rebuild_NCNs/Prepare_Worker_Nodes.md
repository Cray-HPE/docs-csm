# Prepare Worker Node

Prepare a worker node before rebuilding it.

## Procedure

### Step 1 - Determine if the worker being rebuilt is running the `cray-cps-cm-pm` pod

If the `cray-cps-cm-pm` pod is running, there will be an extra step to redeploy this pod after the node is rebuilt.

1. Run the following on any node where the `cray cli` has been initialized:

    ```bash
    cray cps deployment list --format json | grep -C1 podname
    ```

    Example output:
  
    ```screen
    "node": "ncn-w002",
    "podname": "cray-cps-cm-pm-j7td7"
      },
    --
      "node": "ncn-w001",
      "podname": "cray-cps-cm-pm-lzbhm"
    },
    --
      "node": "ncn-w003",
      "podname": "NA"
    },
    --
      "node": "ncn-w004",
      "podname": "NA"
    },
    --
      "node": "ncn-w005",
      "podname": "NA"
    }
    ```
  
    * In this case, the `ncn-w001` and `ncn-w002` nodes have the pod.
    * A `404 Not Found` error is expected when the Content Projection Service (CPS) is not installed on the system. CPS is part of the COS product so if this worker node is being rebuilt before the COS product has been installed, CPS will not be installed yet.

### Step 2 - Confirm what the Configuration Framework Service (CFS) configurationStatus is for the desiredConfig before shutting down the node

> **IMPORTANT:** The following command will indicate if a CFS job is currently in progress for this node. This command assumes the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites) are set.

Run the following on any node where the `cray cli` has been initialized:

  ```bash
   cray cfs components describe $XNAME --format json
  ```

Expected output:
  
  ```screen
    {
      "configurationStatus": "configured",
      "desiredConfig": "ncn-personalization-full",
      "enabled": true,
      "errorCount": 0,
      "id": "x3000c0s7b0n0",
      "retryPolicy": 3,
  ```

If the configurationStatus is `pending`, wait for the job finish before rebooting this node. If the configurationStatus is `failed`, this means the failed CFS job configurationStatus preceded this worker rebuild, and that can be addressed independent of rebuilding this worker. If the configurationStatus is `unconfigured` and the NCN personalization procedure has not been done as part of an install yet, this can be ignored.

### Step 3 - Drain the node to clear any pods running on the node

> **IMPORTANT:** The following command will cordon and drain the node. 

> **NOTE:** This command assumes the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites) are set.

Run the following from a master node:

  ```bash
  ncn-m# kubectl drain --ignore-daemonsets --delete-local-data $NODE
  ```

**Troubleshooting:** There may be pods that cannot be gracefully evicted due to Pod Disruption Budgets (PDB). For example:

    ```screen
    error when evicting pod "<pod>" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
    ```

  In this case, there are some options. First, if the service is scalable, increase the scale to start up another pod on another node, and then the drain will be able to delete it. However, it will probably be necessary to force the deletion of the pod:

    ```bash
    kubectl delete pod [-n <namespace>] --force --grace-period=0 <pod>
    ```

  This will delete the offending pod, and Kubernetes should schedule a replacement on another node. Then, rerun the `kubectl drain` command, and it should report that the node is drained.

### Step 4 - Remove the node from the cluster after the node is drained

This command assumes the variables from [the prerequisites section](../Rebuild_NCNs.md#Prerequisites) are set.

  ```bash
  kubectl delete node $NODE
  ```

### Step 5 - Proceed to the next step in the NCN rebuild procedure

Proceed to the [Identify Nodes and Update Metadata](Identify_Nodes_and_Update_Metadata.md) procedure
or return to high-level [NCN Rebuild](../Rebuild_NCNs.md) procedure.

