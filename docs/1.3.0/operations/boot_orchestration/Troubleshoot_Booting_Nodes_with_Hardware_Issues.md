# Troubleshoot Booting Nodes with Hardware Issues

> **`NOTE`** This section is for BOS V1 only.  Bad components will not impact the booting of other components in BOS V2.

How to identify a node with hardware issues and how to disable is via the HSM.

If a node included in a Boot Orchestration Service \(BOS\) session template is having hardware issues, it can prevent the node from powering back up correctly. The entire BOS session will fail with a timeout error waiting for the node to become ready.

The following is example log output from a node with hardware issues, resulting in a failed BOS session:

```bash
kubectl logs BOS_POD_ID
```

Example output:

```text
[...]

2020-10-03 17:47:30,053 - ERROR   - cray.boa.smd.wait_for_nodes - Number of retries: 361 exceeded allowed amount: 360; 2 nodes were not in the state: Ready
2020-10-03 17:47:30,054 - DEBUG   - cray.boa.smd.wait_for_nodes - These nodes were not in the state: Ready
x1003c0s1b1n1
x1001c0s2b1n1
```

Disabling nodes that have underlying hardware issues preventing them from booting will help resolve this issue. This can be done via the Hardware State Manager \(HSM\).
This method does not return the node with hardware issues to a healthy state, but it does enable a BOS session that was encountering issues to complete successfully.
