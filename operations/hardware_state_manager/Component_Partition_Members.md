# Component Partition Members

The members object in the partition definition has additional actions available for managing the members after the partition has been created.

The following is an example of partition members:

```screen
{
    "ids" : [
        "x0c0s0b0n0","x0c0s0b0n1","x0c0s0b1n0","x0c0s0b1n1"
    ]
}
```

### Retrieve Partition Members

Retrieving members of a partition is very similar to how group members are retrieved and modified. No filtering options are available in partitions. However, there are partition and group filtering parameters for the /hsm/v2/State/Components and /hsm/v2/memberships collections, with both essentially working the same way.

Retrieve only the members array for a single partition:

```screen
ncn-m# cray hsm partitions members list PARTITION_NAME
```

### Add a Component to Partition

Components can be added to a partition's member list, assuming it is not already a member or in another partition. This can be verified by looking at the membership information.

Add a component to a partition:

```screen
ncn-m# cray hsm partitions members create --id COMPONENT_ID PARTITION_NAME
```

For example:

```screen
ncn-m# cray hsm partitions members create --id x1c0s0b0n0 partition1
```

### Remove a Partition Member

Remove a single component from a partition, assuming it is a current member. It will no longer be in any partition and is free to be assigned to a new one.

```screen
ncn-m# cray hsm partitions members delete MEMBER_ID PARTITION_NAME
```

For example:

```screen
ncn-m# cray hsm partitions members delete x1c0s0b0n0 partition1
```

