# Update a UAS Volume

Modify the configuration of an already-registered UAS volume. Almost any part of the configuration of a UAS volume can be modified.

### Prerequisites

-   Install and initialize the `cray` administrative CLI.
-   Obtain the UAS volume ID of a volume. Perform [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) if needed.
-   Read [Add a Volume to UAS](Add_a_Volume_to_UAS.md). The options and caveats for updating volumes are the same as for creating volumes.

### Procedure

1.  Modify the configuration of a UAS volume.

    Once a UAS volume has been configured, any part of it except for the `volume_id` can be updated with a command of the following form:

    ```
    cray uas admin config volumes update [options] <volume-id>
    ```

    For example:

    ```
    ncn-m001-pit# cray uas admin config volumes update --volumename 'my-example-volume' a0066f48-9867-4155-9268-d001a4430f5c
    ```

    The `--volumename`, `--volume-description`, and `--mount-path` options may be used in any combination to update the configuration of a given volume.

