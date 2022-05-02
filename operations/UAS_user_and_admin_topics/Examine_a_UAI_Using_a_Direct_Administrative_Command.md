# Examine a UAI Using a Direct Administrative Command

Print out information about a UAI.

## Prerequisites

Install and initialize the `cray` administrative CLI.

## Procedure

1.  Print out information about a UAI.

    To examine an existing UAI use a command of the following form:

    ```console
    linux# cray uas admin uais describe <uai-name>
    ```

    For example:

    ```console
    ncn-m001-pit# cray uas admin uais describe uai-vers-715fa89d
    ```

    Example output:

    ```text
    uai_age = "2d23h"
    uai_connect_string = "ssh vers@10.28.212.166"
    uai_host = "ncn-w001"
    uai_img = "registry.local/cray/cray-uai-sles15sp1:latest"
    uai_ip = "10.28.212.166"
    uai_msg = ""
    uai_name = "uai-vers-715fa89d"
    uai_status = "Running: Ready"
    username = "vers"

    [uai_portmap]
    ```
