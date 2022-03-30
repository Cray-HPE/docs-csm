# Delete a UAI Using an Administrative Command

Manually delete one or more UAIs.

### Prerequisites

Install and initialize the `cray` administrative CLI.

### Procedure

1.  Delete one or more UAIs using a command of the following form:

    ```bash
    ncn-m001-pit# cray uas admin uais delete OPTIONS
    ```

    OPTIONS is one or more of the following:

    -   `--owner USERNAME`: delete all UAIs owned by the named user
    -   `--class-id CLASS_ID`: delete all UAIs of the specified UAI class
    -   `--uai-list LIST_OF_UAI_NAMES`: delete all the listed UAIs

    The following example deletes two UAIs by name:

    ```bash
    ncn-m001-pit# cray uas admin uais delete --uai-list \
    'uai-vers-715fa89d,uai-ctuser-0aed4970'
    results = [ "Successfully deleted uai-vers-715fa89d", "Successfully deleted uai-ctuser-0aed4970",]
    ```

