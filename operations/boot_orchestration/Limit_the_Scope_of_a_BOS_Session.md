# Limit the Scope of a BOS Session

- [Overview of session limits](#overview-of-session-limits)
- [NIDs in session limits](#nids-in-session-limits)
- [Requiring v2 session limits](#requiring-v2-session-limits)
- [Advanced session limit syntax](#advanced-session-limit-syntax)

## Overview of session limits

BOS v1 and v2 both support an optional `limit` parameter when creating a session.
This parameter can be used to further limit the nodes that BOS runs against, and is applied to all
[boot sets](Session_Templates.md#boot-sets).

The `limit` parameter takes a comma-separated list of nodes, groups, or roles in any combination.
The BOS session will be limited to run against components that match both the boot set information
and one or more of the nodes, groups, or roles listed in the limit.

For more details on creating a session, see [Create a session](Manage_a_BOS_Session.md#create-a-session).

## NIDs in session limits

When specifying nodes, component names (xnames) must be used. The use of NIDs is not supported.

## Requiring v2 session limits

If the [`session_limit_required` option](Options.md#session_limit_required) is enabled,
then the `limit` parameter is not optional when creating a BOS v2 session.
This option has no effect on BOS v1 sessions.

## Advanced session limit syntax

The table below describes the operations that can be used to further limit the scope of a BOS
session. Components are treated as OR operations unless preceded by one of the operations listed
in the following table.

| Operation | Description                                                                     |
|-----------|---------------------------------------------------------------------------------|
| `&`       | Added to the beginning of a group or role to specify an intersection of groups. |
| `!`       | Added to the beginning of a node, group, or role to exclude it.                 |
| `all`     | When only trying to exclude a node or group, the limit must start with `all`.   |
| `*`       | Same as `all`                                                                   |

The table below helps demonstrate the logic used with the `limit` parameter and includes examples
of how to limit against different nodes, groups, and roles.

| Description            | Pattern                         | Targets                               |
|------------------------|---------------------------------|---------------------------------------|
| All nodes              | `all` or `*` (or leave empty)   | All nodes                             |
| One node               | `node1`                         | `node1`                               |
| Multiple nodes         | `node1,node2`                   | `node1` and `node2`                   |
| Excluding a node       | `all,!node1`                    | All nodes except `node1`              |
| One group              | `group1`                        | Nodes in `group1`                     |
| Multiple groups        | `group1,group2`                 | Nodes in `group1` or `group2`         |
| Excluding groups       | `group1,!group2`                | Nodes in `group1` but not in `group2` |
| Intersection of groups | `group1,&group2`                | Nodes in both `group1` and `group2`   |

The `limit` parameter for BOS works similarly to the `--ansible-limit` parameter for
the [Configuration Framework Service (CFS)](../../glossary.md#configuration-framework-service-cfs),
as well as the `limit` parameter for Ansible. Some limitations do apply for those familiar with the Ansible syntax.
BOS accepts only a comma-separated list, not colons, and does not support regular expressions in the patterns.
For more information on what it means to provide a limit in CFS/Ansible, see
[Specifying Hosts and Groups](../configuration_management/Specifying_Hosts_and_Groups.md).
