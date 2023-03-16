# Node Boot Root Cause Analysis

The first step in debugging compute node boot-related issues is to determine the underlying cause and the stage that
the issue was encountered at.

BOS v2 provides rich, per-component records for underlying actions that have been applied as part of BOS session
provisioning. Often, it is helpful to observe the set of operations that BOS has enacted on behalf of a session as they
apply to a single failing node. The records of operations that have been applied for a node, as well as the intended
next steps, can be viewed through the BOS v2 component information for the affected hardware.

(`ncn-mw#`) Verify the status of a BOS component.

```bash
cray bos v2 components describe x3000c0s1b0n0
enabled = false
error = ""
id = "x3000c0s1b0n0"
session = ""
[snip]
```

This command coupled with the Linux `watch` command are an often used way to get continued updates on the most recent
actions applied to the node.

If a node has been booted with BOS as part of a boot or reboot operation, and the node was powered on, but has not
begun configuring, the node may be stuck in early initialization (Failure to `iPXE` chain, network setup issues, failure to
obtain a root filesystem, or other dracut module specific issues). In this case, it is best to connect to the node's
console logs to obtain specific information about the failed node. To learn more about ConMan, refer to
[ConMan](../conman/ConMan.md). A node's console data can be accessed through its log file, as described in
[Access Compute Node Logs](../conman/Access_Compute_Node_Logs.md)). This information can also be accessed by connecting
to the node's console with `ipmitool`. Refer to online documentation to learn more about using `ipmitool`.

If the node has booted into a multi-user target phase, but BOS has not completed booting the node, the node may have
encountered a configuration error. A similar set of records for configuration for a given node can be obtained from
[CFS](../configuration_management) endpoint for the same hardware component. In this case, BOS will indicate the
component status is `configuring`, and further querying information from CFS for the same component may be in order.

(`ncn-mw#`) Verify the configuration status of a CFS component of the same name.

```bash
cray cfs components describe x3000c0s1b0n0
configurationStatus = "configured"
desiredConfig = "management-1.4"
enabled = false
errorCount = 0
id = "x3000c0s1b0n0"
[[state]]
cloneUrl = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
commit = "ae77176a946cc06aabde32e53815dc4dea8039dd"
lastUpdated = "2023-03-02T13:58:05Z"
playbook = "site.yml"
sessionName = "batcher-2df030b8-1bc5-4afb-ac29-df93815473f2"
```

Here, `sessionName` corresponds to the CFS session that is acting on the CFS component(`x3000c0s1b0n0`), and not the BOS
session.
