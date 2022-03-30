# Delete a Volume Configuration

Delete an existing volume configuration. This procedure does not delete the underlying object referred to by the UAS volume configuration.

### Prerequisites

-   Install and initialize the `cray` administrative CLI.
-   Obtain the `volume_id` of the UAS volume to delete. Perform [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) if necessary.

### Procedure

1.  Delete the target volume configuration.

    To delete a UAS Volume, use a command of the following form:

    ```
    ncn-m001-pit# cray uas admin config volumes delete <volume-id>
    ```

    For example:

    ```
    ncn-m001-pit# cray uas admin config volumes delete a0066f48-9867-4155-9268-d001a4430f5c
    ```

If wanted, perform [List Volumes Registered in UAS](List_Volumes_Registered_in_UAS.md) to confirm that the UAS volume has been deleted.

