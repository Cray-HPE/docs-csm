# Limit the Scope of a BOS Session

The Boot Orchestration Service \(BOS\) supports an optional --limit parameter when creating a session. This parameter can be used to further limit the nodes that BOS runs against, and is applied to all boot sets.

The `--limit` parameter takes a comma-separated list of nodes, groups, or roles in any combination. The BOS session will be limited to run against components that match both the boot set information and one or more of the nodes, groups, or roles listed in the limit.

The table below describes the operations that can be used to further limit the scope of a BOS session. Components are treated as OR operations unless preceded by one of the operations listed in the following table.

|Operation|Description|
|---------|-----------|
|`&`|Added to the beginning of a group or role to specify an intersection of groups.|
|`!`|Added to the beginning of a node, group, or role to exclude it.|
|`all`|When only trying to exclude a node or group, the limit must start with "all".|

The table below helps demonstrate the logic used with the --limit parameter and includes examples of how to limit against different nodes, groups, and roles.

|Description|Pattern|Targets|
|-----------|-------|-------|
|All nodes|all \(or leave empty\)|All nodes|
|One node|node1|node1|
|Multiple nodes|node1,node2|node1 and node2|
|Excluding a node|all,!node1|All nodes except node1|
|One group|group1|Nodes in group1|
|Multiple groups|group1,group2|Nodes in group1 or group2|
|Excluding groups|group1,!group2|Nodes in group1 but not in group2|
|Intersection of groups|group1,&group2|Nodes in both group1 and group2|

The `--limit` parameter for BOS works similarly to the `--ansible-limit` parameter for CFS, as well as the `--limit` parameter for Ansible. Some limitations do apply for those familiar with the Ansible syntax. BOS accepts only a comma-separated list, not colons, and does not support regular expressions in the patterns. For more information on what it means to provide a limit, see [Specifying Hosts and Groups](../configuration_management/Specifying_Hosts_and_Groups.md).

