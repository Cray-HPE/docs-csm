# Modify a UAI Class

Update a UAI class with a modified configuration.

### Prerequisites

-   Install and initialize the `cray` administrative CLI.
-   Obtain the ID of the UAI class that will be modified.

### Limitations

The ID of the UAI class cannot be modified.

### Procedure

To update an existing UAI class, use a command of the following form:

```bash
cray uas admin config classes update OPTIONS UAI_CLASS_ID
```

`OPTIONS` are the same options supported for UAI class creation \(see [Create a UAI Class](Create_a_UAI_Class.md)\) and `UAI_CLASS_ID` is the ID of the UAI class.

1.  Modify a UAI class.

    The following example changes the comment on the UAI class with an ID of bb28a35a-6cbc-4c30-84b0-6050314af76b.

    ```bash
    ncn-m001-pit# cray uas admin config classes update \
    --comment "a new comment for my UAI class" \
    bb28a35a-6cbc-4c30-84b0-6050314af76b
    ```

    Any change made using this command affects only UAIs that are both created using the modified class and are created after the modification. Existing UAIs using the class will not change.

2.  **Optional:** Update currently running UAIs by deleting and recreating them.

