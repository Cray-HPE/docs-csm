---
category: numbered
---

# Examine a UAI Using a Direct Administrative Command

Administrators can retrieve information about a UAI using the UAI name and one command.

Install and initialize the cray administrative CLI.

-   **ROLE**

    System Administrator

-   **OBJECTIVE**

    Print out information about a UAI.

-   **LIMITATIONS**

    None.


1.  Print out information about a UAI.

    ```screen
    ncn-m001-pit# cray uas admin uais describe uai-vers-715fa89d
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


