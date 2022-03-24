# List UAIs

View the details of every UAI that is running by using a direct UAS administrative command.

### Prerequisites

* This procedure requires administrative privileges.
* Install and initialize the `cray` administrative CLI.

### Procedure

1. List the existing UAIs.

    Use a command of the following form:

    ```
    ncn-m001-pit# cray uas admin uais list [options]
    ```

    The `[options]` parameter includes the following selection options:
    * `--owner '<user-name>'` show only UAIs owned by the named user
    * `--class-id '<class-id'` show only UAIs of the specified UAI class

    For example:

    ```
    ncn-m001-pit# cray uas admin uais list --owner vers
    [[results]]
    uai_age = "6h22m"
    uai_connect_string = "ssh vers@10.28.212.166"
    uai_host = "ncn-w001"
    uai_img = "registry.local/cray/cray-uai-sles15sp1:latest"
    uai_ip = "10.28.212.166"
    uai_msg = ""
    uai_name = "uai-vers-715fa89d"
    uai_status = "Running: Ready"
    username = "vers"
    ```

