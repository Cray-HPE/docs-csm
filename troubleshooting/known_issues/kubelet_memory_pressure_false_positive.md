# Kubelet Memory Pressure False Positive

Worker nodes may show memory pressure taints and extremely high memory usage percentages (>100%) in `kubectl top node`, even though the actual memory usage on the node is within normal limits. This prevents pods from being scheduled and can cause pod evictions.

## Symptoms

- `kubectl top node` shows worker nodes with memory usage over 100%:

    ```text
    NAME       CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)
    ncn-w002   8334m        10%      265883Mi        103%
    ncn-w003   5199m        6%       262045Mi        102%
    ncn-w004   9350m        9%       255843Mi        99%
    ```

- Pods fail to schedule with `node(s) had untolerated taint {node.kubernetes.io/memory-pressure: }`:

    ```text
    Warning  FailedScheduling  96s (x221 over 76m)  default-scheduler  0/8 nodes are available: 2 Insufficient cpu, 3 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }, 3 node(s) had untolerated taint {node.kubernetes.io/memory-pressure: }. preemption: 0/8 nodes are available: 2 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
    ```

- Pods are evicted due to low memory:

    ```text
    Warning  Evicted  31s  kubelet  The node was low on resource: memory. Threshold quantity: 100Mi, available: -9315068Ki.
    ```

- Checking the node with `kubectl describe node` shows memory requests/limits are reasonable and within capacity.

## Root cause

This is a bug in kubelet's cadvisor component that incorrectly processes cgroup v2 memory statistics on certain nodes. The calculated
available memory can show astronomically incorrect values (e.g., 16 Exabytes) or negative values, causing kubelet to believe the node is
under memory pressure when it is not.

This bug was introduced in Kubernetes 1.28 and remains unresolved as of Kubernetes 1.32.

**Reference:** [https://github.com/kubernetes/kubernetes/issues/118916](https://github.com/kubernetes/kubernetes/issues/118916)

## Diagnosis

### Quick check

Use the following script to check node memory statistics from kubelet's perspective. This will reveal if kubelet is reporting incorrect memory values:

1. (`ncn-mw#`) Check a specific node (replace `ncn-w002` with the node name):

    ```bash
    NODE="ncn-w002"
    kubectl get --raw /api/v1/nodes/$NODE/proxy/stats/summary | \
      jq -r '.node.memory |
        "Available Bytes:    (.availableBytes) (((.availableBytes/1073741824)|tostring) GiB)\n" +
        "Usage Bytes:        (.usageBytes) (((.usageBytes/1073741824)|tostring) GiB)\n" +
        "Working Set Bytes:  (.workingSetBytes) (((.workingSetBytes/1073741824)|tostring) GiB)\n" +
        "RSS Bytes:          (.rssBytes) (((.rssBytes/1073741824)|tostring) GiB)"'
    ```

    Expected output for a healthy node:

    ```text
    Available Bytes:    179290914816 (166.97767639160156 GiB)
    Usage Bytes:        204545458176 (190.497802734375 GiB)
    Working Set Bytes:  89942437888 (83.76542282104492 GiB)
    RSS Bytes:          64370589696 (59.94978332519531 GiB)
    ```

    Output indicating the bug is present:

    ```text
    Available Bytes:    18446744064664707000 (17179869175.576332 GiB)
    Usage Bytes:        346945814528 (323.11846923828125 GiB)
    Working Set Bytes:  278278184960 (259.16675567626953 GiB)
    RSS Bytes:          263990247424 (245.86007690429688 GiB)
    ```

    The available bytes showing values like 18 quintillion (approximately 16 Exabytes) or negative values indicates the bug is present.

1. (`ncn-mw#`) Check all nodes:

    ```bash
    for NODE in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
        echo "=== $NODE ==="
        kubectl get --raw /api/v1/nodes/$NODE/proxy/stats/summary | \
          jq -r '.node.memory |
            "Available Bytes:    (.availableBytes) (((.availableBytes/1073741824)|tostring) GiB)",
            "Usage Bytes:        (.usageBytes) (((.usageBytes/1073741824)|tostring) GiB)",
            "Working Set Bytes:  (.workingSetBytes) (((.workingSetBytes/1073741824)|tostring) GiB)",
            "RSS Bytes:          (.rssBytes) (((.rssBytes/1073741824)|tostring) GiB)"'
        echo ""
    done
    ```

### Additional Checks

1. (`ncn-mw#`) Check for memory pressure taints on nodes:

    ```bash
    kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
    ```

    Look for `node.kubernetes.io/memory-pressure` taints.

1. (`ncn-mw#`) View node conditions:

    ```bash
    kubectl describe node <node-name> | grep -A 10 "^Conditions:"
    ```

    The `MemoryPressure` condition may show `False` (correct) even though kubelet is still incorrectly calculating memory statistics.

1. (`ncn-mw#`) Compare with actual node memory usage:

    ```bash
    ssh <node-name> free -h
    ```

## Resolution

The workaround is to reboot the affected worker nodes. This resets kubelet's memory statistics and resolves the issue.

1. (`ncn-mw#`) Identify affected nodes using the quick check script above.

1. (`ncn-mw#`) Follow the standard NCN worker node reboot procedure for each affected node.

    See [Reboot NCNs](../../operations/node_management/Reboot_NCNs.md) for detailed instructions.

1. (`ncn-mw#`) After the node comes back online, verify the memory statistics are correct:

    ```bash
    NODE="ncn-w002"
    kubectl get --raw /api/v1/nodes/$NODE/proxy/stats/summary | \
      jq -r '.node.memory |
        "Available Bytes:    (.availableBytes) (((.availableBytes/1073741824)|tostring) GiB)\n" +
        "Usage Bytes:        (.usageBytes) (((.usageBytes/1073741824)|tostring) GiB)\n" +
        "Working Set Bytes:  (.workingSetBytes) (((.workingSetBytes/1073741824)|tostring) GiB)\n" +
        "RSS Bytes:          (.rssBytes) (((.rssBytes/1073741824)|tostring) GiB)"'
    ```

1. (`ncn-mw#`) Verify the node no longer has memory pressure taint:

    ```bash
    kubectl describe node <node-name> | grep -i taint
    ```

1. (`ncn-mw#`) Verify pending pods can now schedule:

    ```bash
    kubectl get pods --all-namespaces --field-selector status.phase=Pending
    ```

## Prevention

This is a known upstream Kubernetes bug. Until a fix is available in the Kubernetes release used by CSM, monitor nodes for this condition and reboot as needed.

Consider setting up monitoring alerts for:

- Nodes with memory-pressure taints
- Memory usage percentages over 100% in `kubectl top node` output
- High numbers of pending pods due to memory pressure scheduling failures
