# Manage Component Partitions

The creation, deletion, and modification of partitions is enabled by the Hardware State Manager (HSM) APIs.

* [Example partition](#example-partition)
* [Prerequisites](#prerequisites)
* [Create and modify a partition](#create-and-modify-a-partition)
    * [Create a partition](#create-a-partition)
    * [Modify a partition](#modify-a-partition)
* [Retrieve a partition](#retrieve-a-partition)
* [List partitions](#list-partitions)
* [Delete a partition](#delete-a-partition)
* Related links
    * [Component Groups and Partitions](Component_Groups_and_Partitions.md)
    * [Component Partition Members](Component_Partition_Members.md)
    * [Manage Component Groups](Manage_Component_Groups.md)
    * [Component Membership](Component_Memberships.md)

## Example partition

The following is an example partition that contains the optional tags field:

```json
{
    "name" : "partition 1",
    "description" : "partition 1",
    "tags" : [
    "tag2"
    ],
    "members" : {
        "ids" : [
            "x0c0s0b0n0",
            "x0c0s0b0n1",
            "x0c0s0b1n0"
        ]
    },
}
```

## Prerequisites

The commands on this page will not work unless the Cray CLI has been initialized on the node where
the commands are being run. For more information, see
[Configure the Cray CLI](../configure_cray_cli.md).

## Create and modify a partition

Members can either be provided in an initial list, or the list can be initially empty and added to
later. There is no `exclusiveGroups` field because partition memberships are always exclusive.

The following examples show different ways to create and modify a partition.

### Create a partition

* (`ncn-mw#`) Create a new partition with an empty members list and two optional tags:

    ```bash
    cray hsm partitions create --name PARTITION_NAME \
        --tags TAG1,TAG2 \
        --description DESCRIPTION_OF_PARTITION_NAME
    ```

* (`ncn-mw#`) Create a new partition with a specified members list:

    ```bash
    cray hsm partitions create --name PARTITION_NAME \
        --description DESCRIPTION OF PARTITION_NAME \
        --members-ids MEMBER_ID,MEMBER_ID,MEMBER_ID,MEMBER_ID
    ```

* (`ncn-mw#`) Create a new partition:

    ```bash
    cray hsm partitions create -v --label PARTITION_NAME
    ```

### Modify a partition

* (`ncn-mw#`) Add a description to a partition:

    ```bash
    cray hsm partitions update test_group --description "Description of partition"
    ```

* (`ncn-mw#`) Add a new component to a partition:

    > For more information, see [Component Partition Members](Component_Partition_Members.md).

    ```bash
    cray hsm partitions members create --id XNAME PARTITION_NAME
    ```

* (`ncn-mw#`) Remove a component from a partition:

    > For more information, see [Component Partition Members](Component_Partition_Members.md).

    ```bash
    cray hsm partitions members delete XNAME PARTITION_NAME
    ```

## Retrieve a partition

Information about a partition is retrieved with the partition name.

* (`ncn-mw#`) Retrieve all fields for a partition, including the members list:

    ```bash
    cray hsm partitions describe PARTITION_NAME
    ```

* (`ncn-mw#`) Retrieve only the members list for a partition:

    > For more information, see [Component Partition Members](Component_Partition_Members.md).

    ```bash
    cray hsm partitions members list PARTITION_NAME
    ```

## List partitions

(`ncn-mw#`) Retrieve a listing of all partitions, including all fields of those partitions.

```bash
cray hsm partitions list
```

## Delete a partition

Once a partition is deleted, the former members will not have a partition assigned to them and are
ready to be assigned to a new partition.

(`ncn-mw#`) Delete a partition:

```bash
cray hsm partitions delete PARTITION_NAME
```
