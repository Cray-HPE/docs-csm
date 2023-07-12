# Manage Component Groups

The creation, deletion, and modification of groups is enabled by the Hardware State Manager \(HSM\) APIs.

* [Example group](#example-group)
* [Prerequisites](#prerequisites)
* [Create and modify a group](#create-and-modify-a-group)
  * [Create a group](#create-a-group)
  * [Modify a group](#modify-a-group)
* [Retrieve a group](#retrieve-a-group)
* [Delete a group](#delete-a-group)

## Example group

The following is an example group that contains the optional fields tags and `exclusiveGroup`:

```json
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

## Prerequisites

The commands on this page will not work unless the Cray CLI has been initialized on the node where the commands
are being run. For more information, see [Configure the Cray CLI](../configure_cray_cli.md).

## Create and modify a group

A group is defined by its members list and identifying label. It is also possible to add a description and a free form set of tags to help organize groups.

The members list may be set initially with the full list of member IDs, or can begin empty and have components added individually.
The following examples show different ways to create and modify a group.

### Create a group

* (`ncn-mw#`) Create a new non-exclusive group with an empty members list and two optional tags:

    ```bash
    cray hsm groups create --label GROUP_LABEL \
        --tags TAG1,TAG2 \
        --description DESCRIPTION_OF_GROUP_LABEL
    ```

* (`ncn-mw#`) Create a new group with a pre-set members list, which is part of an exclusive group:

    ```bash
    cray hsm groups create --label GROUP_LABEL \
        --description DESCRIPTION_OF_GROUP_LABEL \
        --exclusive-group EXCLUSIVE_GROUP_LABEL \
        --members-ids MEMBER_ID,MEMBER_ID,MEMBER_ID
    ```

* (`ncn-mw#`) Create a new group:

    ```bash
    cray hsm groups create -v --label GROUP_LABEL
    ```

### Modify a group

* (`ncn-mw#`) Add a description of a group:

    ```bash
    cray hsm groups update test_group --description "Description of group"
    ```

* (`ncn-mw#`) Add a new component to a group:

    ```bash
    cray hsm groups members create --id XNAME GROUP_LABEL
    ```

## Retrieve a group

Retrieve the complete group object to learn more about a group. This is also submitted when the group is created, except it is up-to-date with any additions or deletions from the members set.

(`ncn-mw#`) Retrieve all fields for a group, including the members list:

```bash
cray hsm groups describe GROUP_LABEL
```

## Delete a group

Entire groups can be removed. The group label is deleted and removed from all members who were formerly a part of the group.

(`ncn-mw#`) Delete a group with the following command:

```bash
cray hsm groups delete GROUP_LABEL
```
