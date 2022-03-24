# Node Boot Root Cause Analysis

The first step in debugging compute node boot-related issues is to determine the underlying cause, and the stage that the issue was encountered at.

The ConMan tool collects compute node logs. To learn more about ConMan, refer to [ConMan](../conman/ConMan.md).

A node's console data can be accessed through its log file, as described in [Access Compute Node Logs](../conman/Access_Compute_Node_Logs.md)). This information can also be accessed by connecting to the node's console with `ipmitool`. Refer to online documentation to learn more about using ipmitool.

