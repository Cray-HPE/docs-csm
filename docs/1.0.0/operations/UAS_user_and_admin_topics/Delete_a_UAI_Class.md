# Delete a UAI Class

Delete a UAI class. After deletion, the class will no longer be available for new UAIs.

### Prerequisites

-   Install and initialize the `cray` administrative CLI.
-   Obtain the ID of the UAI class that will be deleted.

### Procedure

Delete a UAI by using a command of the following form:

```bash
cray uas admin config classes delete UAI_CLASS_ID
```

`UAI_CLASS_ID` is the UAS ID of the UAI class.

1.  Delete a UAI class.

    ```screen
    ncn-m001-pit# cray uas admin config classes delete bb28a35a-6cbc-4c30-84b0-6050314af76b
    ```

