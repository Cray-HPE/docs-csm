## Component Group Members

The members object in the group definition has additional actions available for managing the members after the group has been created.

The following is an example of group members:

```bash
{
    "ids" : [
        "x0c0s0b0n0","x0c0s0b0n1","x0c0s0b1n0"
    ]
}
```

### Retrieve Group Members

Retrieve just the members array for a group:

```bash
ncn-m# cray hsm groups members list GROUP_LABEL
```

Retrieve only the members of a group that are also in a specific partition:

```bash
ncn-m# cray hsm groups members list --partition PARTITION_NAME GROUP_LABEL
```

Retrieve only the members of a group that are not in any partition currently:

```bash
ncn-m# cray hsm groups members list --partition NULL GROUP_LABEL
```

### Add Group Members

Add a single component to a group. The only time this is not permitted is if the component already exists, or the group has an exclusiveGroup label and the component is already a member of a group with that exclusive label.

Add a component to a group:

```bash
ncn-m# cray hsm groups members create --id MEMBER_ID GROUP_LABEL
```

For example:

```bash
ncn-m# cray hsm groups members create --id x1c0s0b0n0 blue
```

### Remove Group Members

Single members are removed with the component xname ID from the given group.

Remove a member from a group:

```bash
ncn-m# cray hsm groups members delete MEMBER_ID GROUP_LABEL
```

For example:

```bash
ncn-m# cray hsm groups members delete x1c0s0b0n0 blue
```



