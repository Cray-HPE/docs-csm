# Node Boot Root Cause Analysis

The first step in debugging compute node boot-related issues is to determine the underlying cause, and the stage that the issue was encountered at.

## Examine the BOS components

BOS v2 provides rich [component](Components.md) records for underlying actions that have been applied as part of BOS
[session](Sessions.md) provisioning. Often, it is helpful to observe the set of operations that BOS has enacted on
behalf of a session as they apply to a single failing node. The records of operations that have been applied for a
node, as well as the intended next steps, can be viewed through the BOS v2 component information for the affected hardware.

```bash
cray bos v2 components describe x3000c0s1b0n0 --format toml
```

Truncated example output:

```toml
enabled = false
error = ""
id = "x3000c0s1b0n0"
session = ""
```

This command coupled with the Linux `watch` command is an often used way to get continuous updates on the most recent
actions applied to the node.

## Examine the node console

If a node has been booted with BOS as part of a boot or reboot operation, and the node was powered on, but has not
begun configuring, then the node may be stuck in early initialization. This could be caused by things such as
failure to `iPXE` chain, network setup issues, failure to obtain a root filesystem, or other dracut module issues.
In this case, it is best to connect to the node's console logs to obtain specific information about the failed node.
To learn more about ConMan, refer to [ConMan](../conman/ConMan.md). A node's console data can be accessed through
its log file, as described in [Access Compute Node Logs](../conman/Access_Compute_Node_Logs.md)).
This information can also be accessed by connecting to the node's console with `ipmitool`.
Refer to online documentation to learn more about using `ipmitool`.

## Check the node's state in CFS

If the node has booted into a multi-user target phase, but BOS has not completed booting the node, the node may have
encountered a configuration error. A similar set of records for configuration for a given node can be obtained from
[CFS](../../glossary.md#configuration-management-service-cfs) for the same hardware component. In this case, BOS will indicate the
component status is `configuring`, and further querying information from CFS for the same component may be in order.

(`ncn-mw#`) Verify the configuration status of a CFS component of the same name.

```bash
cray cfs v3 components describe x3000c0s1b0n0 --state-details true --format toml
```

Example output:

```toml
configuration_status = "configured"
desired_config = "management-1.4"
enabled = false
error_count = 0
id = "x3000c0s1b0n0"
logs = "ara.cmn.site/hosts?name=x3000c0s1b0n0"
[[state]]
clone_url = "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git"
commit = "ae77176a946cc06aabde32e53815dc4dea8039dd"
last_updated = "2023-03-02T13:58:05Z"
playbook = "site.yml"
session_name = "batcher-2df030b8-1bc5-4afb-ac29-df93815473f2"
```

Here, `session_name` corresponds to the [CFS session](../configuration_management/Configuration_Sessions.md) that is acting on the
[CFS component](../configuration_management/Configuration_Management_of_System_Components.md) (`x3000c0s1b0n0` in this example), and not the BOS session.
