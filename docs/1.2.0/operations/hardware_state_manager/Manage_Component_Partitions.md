# Manage Component Partitions

The creation, deletion, and modification of partitions is enabled by the Hardware State Manager \(HSM\) APIs.

The following is an example partition that contains the optional tags field:

```screen
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

**Troubleshooting:** If the Cray CLI has not been initialized, the CLI commands will not work.

### Create a New Partition

Creating a partition is very similar to creating a group. Members can either be provided in an initial list, or the list can be initially empty and added to later. There is no exclusiveGroups field because partition memberships are always exclusive. The following are two different ways to create a partition.

Create a new partition with an empty members list and two optional tags:

```screen
ncn-m# cray hsm partitions create --name PARTITION_NAME \
--tags TAG1,TAG2 \
--description DESCRIPTION_OF_PARTITION_NAME
```

Create a new partition with a pre-set members list:

```screen
ncn-m# cray hsm partitions create --name PARTITION_NAME \
--description DESCRIPTION OF PARTITION_NAME \
--members-ids MEMBER_ID,MEMBER_ID,MEMBER_ID,MEMBER_ID
```

Create a new partition:

```screen
ncn-m# cray hsm partitions create -v --label PARTITION_LABEL
```

Add a description of the partition:

```screen
ncn-m# cray hsm partitions update test_group --description "Description of partition"
```

Add a new component to the partition:

```screen
ncn-m# cray hsm partitions members create --id XNAME PARTITION_LABEL
```

### Retrieve Partition Information

Information about a partition is retrieved with the partition name.

Retrieve all fields for a partition, including the members list:

```screen
ncn-m# cray hsm partitions describe PARTITION_NAME
```

### Delete a Partition

Once a partition is deleted, the former members will not have a partition assigned to them and are ready to be assigned to a new partition.

Delete a partition so all members are no longer in it:

```screen
ncn-m# cray hsm partitions delete PARTITION_NAME
```

