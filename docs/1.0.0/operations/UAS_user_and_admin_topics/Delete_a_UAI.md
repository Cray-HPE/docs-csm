# Delete a UAI

The cray uas command allows users to manage UAIs. This procedure deletes one of the user's UAIs. To delete all UAIs on the system, see [List and Delete All UAIs](List_and_Delete_All_UAIs.md) for more information.

### Prerequisites

A UAI is up and running.

### Limitations

Currently, the user must SSH to the system as `root`.

### Procedure

1.  Log in to an NCN as `root`.

2.  List existing UAIs.

    ```bash
    ncn-w001# cray uas list

    username = "user"
    uai_host = "ncn-w001"
    uai_status = "Running: Ready"
    uai_connect_string = "ssh user@203.0.113.0 -i ~/.ssh/id_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_age = "0m"
    uai_name = "uai-user-be3a6770"

    username = "user"
    uai_host = "ncn-s001"
    uai_status = "Running: Ready"
    uai_connect_string = "ssh user@203.0.113.0 -i ~/.ssh/id_rsa"
    uai_img = "registry.local/cray/cray-uas-sles15sp1-slurm:latest"
    uai_age = "11m"
    uai_name = "uai-user-f488eef6"
    ```

3.  Delete a UAI.

    To delete one or more UAIs, use a command of the following form:

    ```
    cray uas admin uais delete [options]
    ```

    Where options may be any of the following:

    * `--uai-list '<list-of-uai-names>'` - Delete all the listed UAIs
    * `--owner <owner-name>` - Delete all UAIs owned by the named owner
    * `--class-id <uai-class-id>` - Delete all UAIs of the specified UAI class

    For example:

    ```bash
    ncn-w001# cray uas delete -–uai-list UAI_NAME
    results = [ "Successfully deleted uai-user-be3a6770",]
    ```

When a UAI is deleted, WLM jobs are not cancelled or cleaned up.

