## Component Memberships

Memberships are a read-only resource that is generated automatically by changes to groups and partitions. Each component in /hsm/v1/State/Components is represented. Filter options are available to prune the list, or a specific xname ID can be given. All groups and the partition \(if any\) of each component are listed.

At this point in time, only information about node components is needed. The `--type` node filter option is used in the commands below to retrieve information about node memberships only.

The following is an example membership:

```screen
{
    "id" : "x2c3s0b0n0",
    "groupLabels" : [
        "grp1",
        "red",
        "my_nodes"
    ],    
    "partitionName" : "partition2"
}
```

**Troubleshooting:** If the Cray CLI has not been initialized, the CLI commands will not work. 

### Retrieve Group and Partition Memberships

By default, the memberships collection contains all components, regardless of if they are in a group. However, a filtered subset is desired more frequently. Querying the memberships collection supports the same query options as /hsm/v1/State/Components.

Retrieve all node memberships:

```screen
ncn-m# cray hsm memberships list --type node
```

Retrieve only nodes not in a partition:

```screen
ncn-m# cray hsm memberships list --type node --partition NULL
```

### Retrieve Membership Data for a Given Component

Any components in /hsm/v1/State/Components can have its group and memberships looked up with its individual component xname ID.

```screen
ncn-m# cray hsm memberships describe MEMBER_ID
```



