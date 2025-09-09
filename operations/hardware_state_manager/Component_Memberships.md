# Component Memberships

Memberships are a read-only resource that is generated automatically by changes to groups and
partitions. Each component in `/hsm/v2/State/Components` is represented. Filter options are
available to prune the list, or a specific component name (xname) can be given. All groups and
the partition \(if any\) of each component are listed.

Membership information is only needed for node components. The `--type` node filter option is
used in the commands on this page to retrieve information about node memberships only.

* [Prerequisites](#prerequisites)
* [Retrieve membership data for a component](#retrieve-membership-data-for-a-component)
* [List component membership data](#list-component-membership-data)
* Related links
  * [Component Groups and Partitions](Component_Groups_and_Partitions.md)
  * [Component Group Members](Component_Group_Members.md)
  * [Component Partition Members](Component_Partition_Members.md)

## Prerequisites

The commands on this page will not work unless the Cray CLI has been initialized on the node where
the commands are being run. For more information, see
[Configure the Cray CLI](../configure_cray_cli.md).

## Retrieve membership data for a component

Any components in `/hsm/v2/State/Components` can have its group and memberships looked up with its
individual component name (xname).

Retrieve membership information for a component.

```screen
ncn-mw# cray hsm memberships describe MEMBER_ID --format json
```

Example output:

```json
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

## List component membership data

By default, the memberships collection contains all components, regardless of if they are in a
group. However, a filtered subset is desired more frequently. Querying the memberships collection
supports the same query options as `/hsm/v2/State/Components`.

* Retrieve all node memberships:

    ```screen
    ncn-mw# cray hsm memberships list --type Node
    ```

* Retrieve only nodes not in a partition:

    ```screen
    ncn-mw# cray hsm memberships list --type Node --partition NULL
    ```
