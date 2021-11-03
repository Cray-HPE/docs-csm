## Manage Component Groups

The creation, deletion, and modification of groups is enabled by the Hardware State Manager \(HSM\) APIs.

The following is an example group that contains the optional fields tags and exclusiveGroup:

```bash
{
        "label" : "blue",
        "description" : "blue node group",
        "tags" : [
           "tag1",
           "tag2"
        ],
        "members" : {
            "ids" : [
                "x0c0s0b0n0",
                "x0c0s0b0n1",
                "x0c0s0b1n0",
                "x0c0s0b1n1"
            ]
        },
        "exclusiveGroup" : "colors"
}
```

**Troubleshooting:** If the Cray CLI has not been initialized, the CLI commands will not work.

### Create a New Group

A group is defined by its members list and identifying label. It is also possible to add a description and a free form set of tags to help organize groups.

The members list may be set initially with the full list of member IDs, or can begin empty and have components added individually. The following examples show two different ways to create a new group.

Create a new non-exclusive group with an empty members list and two optional tags:

```bash
ncn-m# cray hsm groups create --label GROUP_LABEL \
--tags TAG1,TAG2 \
--description DESCRIPTION_OF_GROUP_LABEL
```

Create a new group with a pre-set members list, which is part of an exclusive group:

```bash
ncn-m# cray hsm groups create --label GROUP_LABEL \
--description DESCRIPTION_OF_GROUP_LABEL \
--exclusive-group EXCLUSIVE_GROUP_LABEL \
--members-ids MEMBER_ID,MEMBER_ID,MEMBER_ID
```

Create a new group:

```bash
ncn-m# cray hsm groups create -v --label GROUP_LABEL
```

Add a description of the group:

```bash
ncn-m# cray hsm groups update test_group --description "Description of group"
```

Add a new component to a group:

```bash
ncn-m# cray hsm groups members create --id XNAME GROUP_LABEL
```

### Retrieve a Group

Retrieve the complete group object to learn more about a group. This is also submitted when the group is created, except it is up-to-date with any additions or deletions from the members set.

Retrieve all fields for a group, including the members list:

```bash
ncn-m# cray hsm groups describe GROUP_LABEL
```

### Delete a Group

Entire groups can be removed. The group label is deleted and removed from all members who were formerly a part of the group.

Delete a group with the following command:

```bash
ncn-m# cray hsm groups delete GROUP_LABEL
```



