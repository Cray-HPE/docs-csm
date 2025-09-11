# Component Partition Members

The members object in the partition definition has actions\
available for managing the members after the partition has been created.

* [Prerequisites](#prerequisites)
* [Retrieve partition members](#retrieve-partition-members)
* [Add partition members](#add partition members)
* [Remove partition members](#remove-partition-members)
* Related links
    * [Component Groups and Partitions](Component_Groups_and_Partitions.md)
    * [Manage Component Partitions](Manage_Component_Partitions.md)
    * [Component Group Members](Component_Group_Members.md)
    * [Component Membership](Component_Memberships.md)

## Prerequisites

The commands on this page will not work unless the Cray CLI has been initialized on the node where
the commands are being run. For more information, see
[Configure the Cray CLI](../configure_cray_cli.md).

## Retrieve partition members

Retrieving members of a partition is very similar to how group members are
retrieved and modified. No filtering options are available in partitions.
However, there are partition and group filtering parameters for the
`/hsm/v2/State/Components` and `/hsm/v2/memberships` collections, with
both essentially working the same way.

(`ncn-mw#`) Retrieve only the members array for a single partition:

```bash
cray hsm partitions members list PARTITION_NAME --format json
```

Example output:

```json
{
    "ids" : [
        "x0c0s0b0n0","x0c0s0b0n1","x0c0s0b1n0","x0c0s0b1n1"
    ]
}
```

## Add partition members

Components can be added to a partition's member list, assuming that the
component is not already a member of any partition.

(`ncn-mw#`) Add a component to a partition:

```bash
cray hsm partitions members create --id COMPONENT_ID PARTITION_NAME
```

For example:

```bash
cray hsm partitions members create --id x1c0s0b0n0 partition1
```

### Remove partition members

Single components may be removed from a given partition, assuming that they are currently a member
of that partition. After being removed, the component will no longer be in any partition and is
free to be assigned to a new one.

(`ncn-mw#`) Remove a member from a partition:

```bash
cray hsm partitions members delete MEMBER_ID PARTITION_NAME
```

For example:

```bash
cray hsm partitions members delete x1c0s0b0n0 partition1
```
