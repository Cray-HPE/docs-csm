
## List UAIs Using a Direct Administrative Command

View the details of every UAI that is running by using a direct UAS administrative command.

### Prerequisites

Install and initialize the `cray` administrative CLI.

### Procedure

To list UAIs, use a command of the form:

```bash
cray uas admin uais list OPTIONS
```

where OPTIONS is one or both of the following:

-   --owner USERNAME: returns only UAIs owned by the named user
-   --class-id CLASS\_ID: returns only UAIs of the specified UAI class

1.  List all running UAIs.

    ```bash
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


