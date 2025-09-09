# Component Group Members

The members object in the group definition has actions available for managing the
members after the group has been created.

* [Prerequisites](#prerequisites)
* [Retrieve group members](#retrieve-group-members)
* [Add group members](#add-group-members)
* [Remove group members](#remove-group-members)
* Related links
    * [Component Groups and Partitions](Component_Groups_and_Partitions.md)
    * [Manage Component Groups](Manage_Component_Groups.md)
    * [Component Partition Members](Component_Partition_Members.md)
    * [Component Membership](Component_Memberships.md)

## Prerequisites

The commands on this page will not work unless the Cray CLI has been initialized on the node where
the commands are being run. For more information, see
[Configure the Cray CLI](../configure_cray_cli.md).

## Retrieve group members

* (`ncn-mw#`) Retrieve just the members array for a group:

    ```bash
    cray hsm groups members list GROUP_LABEL  --format json
    ```

    Example output:

    ```json
    {
        "ids" : [
            "x0c0s0b0n0","x0c0s0b0n1","x0c0s0b1n0"
        ]
    }
    ```

* (`ncn-mw#`) Retrieve only the members of a group that are also in a specific partition:

    ```bash
    cray hsm groups members list --partition PARTITION_NAME GROUP_LABEL
    ```

* (`ncn-mw#`) Retrieve only the members of a group that are not in any partition currently:

    ```bash
    cray hsm groups members list --partition NULL GROUP_LABEL
    ```

## Add group members

Only a single component at a time may be added to a group. The only times this is not permitted are
if the component already exists in the group, or if the group has an `exclusiveGroup` label and the
component is already a member of another group with that same exclusive label. For more information
on exclusive group labels, see [Groups](Component_Groups_and_Partitions.md#groups).

(`ncn-mw#`) Add a component to a group:

```bash
cray hsm groups members create --id MEMBER_ID GROUP_LABEL
```

For example:

```bash
cray hsm groups members create --id x1c0s0b0n0 blue
```

## Remove group members

Single components may be removed from a given group, assuming that they are currently a member
of that group.

(`ncn-mw#`) Remove a member from a group:

```bash
cray hsm groups members delete MEMBER_ID GROUP_LABEL
```

For example:

```bash
cray hsm groups members delete x1c0s0b0n0 blue
```
